//
//  FloatingRootView.swift
//  Noto
//

import AppKit
import SwiftData
import SwiftUI

struct FloatingRootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = TaskPanelViewModel.empty()
    @StateObject private var hotKeyService = GlobalHotKeyService()
    @StateObject private var speechInputService = SpeechInputService()
    @StateObject private var menuBarController = MenuBarController()
    private let launchAtLoginService = LaunchAtLoginService()
    private let completionSoundService = CompletionSoundService()
    private let appUpdateService = AppUpdateService()
    @State private var isPanelOpen = true
    @State private var isPanelPresentedByHotKey = false
    @State private var isRecordingHotKey = false
    @State private var isCheckingForUpdate = false
    @State private var updateCheckAlert: UpdateCheckAlert?
    @State private var systemColorScheme = TaskPanelSettings.Theme.currentSystemColorScheme
    @State private var characterScreenOrigin = CGPoint(x: 72, y: 74)
    @State private var characterLocalOrigin = CGPoint(x: 28, y: 28)
    @State private var panelLocalOrigin = CGPoint(x: 98, y: 28)
    @State private var rootContentSize = CGSize(width: 420, height: 488)
    @State private var dragStartOrigin: CGPoint?
    @State private var dragStartMouseLocation: CGPoint?
    @State private var dragPointerOffset: CGSize?
    @State private var floatingWindow: NSWindow?
    @State private var persistenceStore: TaskPanelStore?
    @State private var didLoadPersistedState = false
    @State private var didResolveInitialPosition = false
    #if DEBUG
    @State private var didPresentDebugUpdateAlerts = false
    @State private var pendingDebugUpdateAlerts: [UpdateCheckAlert] = []
    #endif
    @GestureState private var isPressing = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            if isPanelOpen {
                TaskPanelView(
                    viewModel: viewModel,
                    isSpeechRecording: speechInputService.isRecording,
                    speechTranscript: speechInputService.transcript,
                    speechErrorMessage: speechInputService.errorMessage,
                    onCollapse: { setPanelOpen(false) },
                    onTaskCompleted: playCompletionSoundIfNeeded,
                    onQuickAddMic: toggleSpeechInput,
                    onQuickAddSubmit: submitQuickTask,
                    onToggleLaunchAtLogin: toggleLaunchAtLogin,
                    onToggleMenuBarIcon: viewModel.toggleMenuBarIcon,
                    onHotKeyRecordingChange: { isRecording in
                        isRecordingHotKey = isRecording
                        updateGlobalHotKeyRegistration()
                    },
                    isCheckingForUpdate: isCheckingForUpdate,
                    updateCheckAlert: updateCheckAlert,
                    onCheckUpdate: checkForUpdate,
                    onDismissUpdateAlert: dismissUpdateCheckAlert,
                    onOpenUpdateStore: openUpdateStorePage,
                    onPreviewUpToDateAlert: previewUpToDateAlert,
                    onPreviewUpdateAvailableAlert: previewUpdateAvailableAlert
                )
                .position(
                    x: panelLocalOrigin.x + DesignTokens.Size.panelWidth / 2,
                    y: panelLocalOrigin.y + currentPanelHeight / 2
                )
                .zIndex(1)
            }

            FloatingCharacterView(
                remainingCount: viewModel.remainingCount,
                characterKind: viewModel.settings.characterKind,
                isActive: isPanelOpen,
                isDragging: dragStartOrigin != nil,
                isPressed: isPressing
            )
            .frame(width: DesignTokens.Size.characterSize, height: DesignTokens.Size.characterSize)
            .contentShape(Rectangle())
            .onTapGesture(perform: togglePanel)
            .gesture(characterDragGesture())
            .position(
                x: characterLocalOrigin.x + DesignTokens.Size.characterSize / 2,
                y: characterLocalOrigin.y + DesignTokens.Size.characterSize / 2
            )
            .zIndex(2)
        }
        .frame(width: rootContentSize.width, height: rootContentSize.height)
        .background(Color.clear)
        .containerBackground(.clear, for: .window)
        .preferredColorScheme(viewModel.settings.theme.resolvedColorScheme(systemColorScheme: systemColorScheme))
        .background(
            FloatingWindowAccessor { window in
                if floatingWindow !== window {
                    floatingWindow = window
                }
                updateFloatingWindowAppearance(window)
                updateFloatingWindowLevel(window)
                updateFloatingWindowLayout()
            }
        )
        .onAppear {
            configureMenuBarController()
            updateSystemColorScheme()
            configurePersistenceIfNeeded()
            presentDebugUpdateAlertsIfNeeded()
            if let floatingWindow {
                updateFloatingWindowAppearance(floatingWindow)
            }
            updateFloatingWindowLayout()
            updateGlobalHotKeyRegistration()
            updateMenuBarController()
        }
        .onChange(of: isPanelOpen) { _, _ in
            withoutAnimation {
                updateFloatingWindowLayout(animated: false)
            }
            updateMenuBarController()
        }
        .onChange(of: viewModel.screen) { _, _ in
            withoutAnimation {
                updateFloatingWindowLayout(animated: false)
            }
        }
        .onChange(of: viewModel.settings.keepOnTop) { _, _ in
            if let floatingWindow {
                updateFloatingWindowLevel(floatingWindow)
                bringFloatingWindowForward()
            }
        }
        .onChange(of: viewModel.settings.theme) { _, _ in
            if let floatingWindow {
                updateFloatingWindowAppearance(floatingWindow)
            }
        }
        .onChange(of: viewModel.settings.showsMenuBarIcon) { _, _ in
            updateMenuBarController()
        }
        .onChange(of: viewModel.remainingCount) { _, _ in
            updateMenuBarController()
        }
        .onReceive(DistributedNotificationCenter.default().publisher(for: .appleInterfaceThemeChanged)) { _ in
            updateSystemColorScheme()
            if let floatingWindow {
                updateFloatingWindowAppearance(floatingWindow)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            guard speechInputService.isRecording,
                  !speechInputService.isRequestingPermission else { return }
            stopSpeechInputPreservingText()
        }
        .onChange(of: viewModel.settings.hotKey) { _, _ in
            updateGlobalHotKeyRegistration()
        }
        .onChange(of: isRecordingHotKey) { _, _ in
            updateGlobalHotKeyRegistration()
        }
        .onDisappear {
            hotKeyService.unregister()
            menuBarController.invalidate()
        }
    }

    private func configurePersistenceIfNeeded() {
        guard !didLoadPersistedState else { return }

        let store = TaskPanelStore(modelContext: modelContext)
        persistenceStore = store

        do {
            let snapshot = try store.loadOrSeed(default: viewModel.snapshot)
            viewModel.applySnapshot(snapshot)
            reconcileLaunchAtLoginSetting()
            if let floatingWindow {
                updateFloatingWindowAppearance(floatingWindow)
            }

            if let storedOrigin = try store.loadCharacterOrigin() {
                characterScreenOrigin = storedOrigin
                didResolveInitialPosition = true
            }
        } catch {
            logPersistenceError("load", error)
        }

        viewModel.onSnapshotChange = { snapshot in
            do {
                try store.save(snapshot)
            } catch {
                logPersistenceError("save", error)
            }
        }
        didLoadPersistedState = true
    }

    private func logPersistenceError(_ operation: String, _ error: Error) {
        #if DEBUG
        print("Noto persistence \(operation) failed: \(error)")
        #endif
    }

    private var currentPanelHeight: CGFloat {
        viewModel.screen == .settings
            ? DesignTokens.Size.settingsPanelHeight
            : DesignTokens.Size.panelHeight
    }

    private func updateFloatingWindowLevel(_ window: NSWindow) {
        window.level = viewModel.settings.keepOnTop ? .floating : .normal
    }

    private func updateFloatingWindowAppearance(_ window: NSWindow) {
        let appearance = viewModel.settings.theme.nsAppearance(systemColorScheme: systemColorScheme)
        window.appearance = appearance
        window.contentView?.appearance = appearance
    }

    private func updateSystemColorScheme() {
        systemColorScheme = TaskPanelSettings.Theme.currentSystemColorScheme
    }

    private func updateGlobalHotKeyRegistration() {
        guard !isRecordingHotKey else {
            hotKeyService.unregister()
            return
        }

        hotKeyService.register(viewModel.settings.hotKey) {
            handleHotKeyTrigger()
        }
    }

    private func configureMenuBarController() {
        menuBarController.onTogglePanel = {
            togglePanelFromMenuBar()
        }
        menuBarController.onOpenSettings = {
            openSettingsFromMenuBar()
        }
        menuBarController.onCheckForUpdates = {
            checkForUpdateFromMenuBar()
        }
        menuBarController.onQuit = {
            NSApplication.shared.terminate(nil)
        }
    }

    private func updateMenuBarController() {
        menuBarController.update(
            isVisible: viewModel.settings.showsMenuBarIcon,
            remainingCount: viewModel.remainingCount,
            isPanelOpen: isPanelOpen
        )
    }

    private func togglePanelFromMenuBar() {
        isPanelPresentedByHotKey = false
        setPanelOpen(!isPanelOpen, activateAppWhenOpening: true)
    }

    private func openSettingsFromMenuBar() {
        isPanelPresentedByHotKey = false
        bringFloatingWindowForward(activateApp: true)

        withoutAnimation {
            viewModel.showSettings()
            isPanelOpen = true
            updateFloatingWindowLayout(animated: false)
        }
    }

    private func checkForUpdateFromMenuBar() {
        isPanelPresentedByHotKey = false
        setPanelOpen(true, activateAppWhenOpening: true)
        checkForUpdate()
    }

    private func bringFloatingWindowForward(activateApp: Bool = false) {
        guard let floatingWindow else { return }

        updateFloatingWindowLevel(floatingWindow)
        if activateApp {
            NSApp.activate(ignoringOtherApps: true)
        }
        floatingWindow.orderFrontRegardless()
        floatingWindow.makeKey()
    }

    private func withoutAnimation(_ updates: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, updates)
    }

    private func updateFloatingWindowLayout(animated: Bool = false) {
        guard let screen = activeScreen else { return }
        let visibleFrame = FloatingScreenGeometry.topLeftVisibleFrame(for: screen)
        resolveInitialCharacterPositionIfNeeded(in: visibleFrame)
        let clampedOrigin = PanelPlacementResolver.clampedCharacterOrigin(
            characterScreenOrigin,
            visibleScreenFrame: visibleFrame
        )
        if characterScreenOrigin != clampedOrigin {
            characterScreenOrigin = clampedOrigin
        }

        let characterFrame = CGRect(
            origin: clampedOrigin,
            size: CGSize(width: DesignTokens.Size.characterSize, height: DesignTokens.Size.characterSize)
        )
        let panelSize = CGSize(width: DesignTokens.Size.panelWidth, height: currentPanelHeight)
        let placement = PanelPlacementResolver.resolve(
            characterFrame: characterFrame,
            visibleScreenFrame: visibleFrame,
            panelSize: panelSize
        )
        let panelFrame = CGRect(origin: placement.origin, size: panelSize)
        let contentFrame = contentFrame(characterFrame: characterFrame, panelFrame: isPanelOpen ? panelFrame : nil)
        let windowFrame = FloatingScreenGeometry.appKitFrame(fromTopLeftRect: contentFrame, on: screen)

        updateLocalLayout(
            contentFrame: contentFrame,
            characterFrame: characterFrame,
            panelFrame: panelFrame
        )

        guard let floatingWindow else { return }
        if floatingWindow.frame.integral != windowFrame.integral {
            floatingWindow.setFrame(windowFrame, display: true, animate: animated)
        }
    }

    private var activeScreen: NSScreen? {
        FloatingScreenGeometry.screen(containingTopLeftPoint: characterScreenOrigin)
            ?? floatingWindow?.screen
            ?? NSScreen.main
    }

    private func resolveInitialCharacterPositionIfNeeded(in visibleFrame: CGRect) {
        guard !didResolveInitialPosition else { return }

        characterScreenOrigin = PanelPlacementResolver.clampedCharacterOrigin(
            CGPoint(x: visibleFrame.minX + 72, y: visibleFrame.minY + 74),
            visibleScreenFrame: visibleFrame
        )
        didResolveInitialPosition = true
    }

    private func contentFrame(characterFrame: CGRect, panelFrame: CGRect?) -> CGRect {
        let padding = panelFrame == nil
            ? DesignTokens.Size.floatingBadgeContentPadding
            : DesignTokens.Size.floatingContentPadding
        let unionFrame = panelFrame.map { characterFrame.union($0) } ?? characterFrame

        return unionFrame
            .insetBy(dx: -padding, dy: -padding)
            .integral
    }

    private func updateLocalLayout(contentFrame: CGRect, characterFrame: CGRect, panelFrame: CGRect) {
        let newContentSize = CGSize(width: contentFrame.width, height: contentFrame.height)
        let newCharacterOrigin = CGPoint(
            x: characterFrame.minX - contentFrame.minX,
            y: characterFrame.minY - contentFrame.minY
        )
        let newPanelOrigin = CGPoint(
            x: panelFrame.minX - contentFrame.minX,
            y: panelFrame.minY - contentFrame.minY
        )

        if rootContentSize != newContentSize {
            rootContentSize = newContentSize
        }
        if characterLocalOrigin != newCharacterOrigin {
            characterLocalOrigin = newCharacterOrigin
        }
        if panelLocalOrigin != newPanelOrigin {
            panelLocalOrigin = newPanelOrigin
        }
    }

    private func persistCharacterPosition() {
        guard let persistenceStore else { return }

        do {
            try persistenceStore.saveCharacterOrigin(characterScreenOrigin, settings: viewModel.settings)
        } catch {
            logPersistenceError("save character position", error)
        }
    }

    private func togglePanel() {
        isPanelPresentedByHotKey = false
        setPanelOpen(!isPanelOpen, activateAppWhenOpening: true)
    }

    private func playCompletionSoundIfNeeded() {
        completionSoundService.playIfEnabled(viewModel.settings.completionSound)
    }

    private func submitQuickTask() {
        if speechInputService.isRecording {
            stopSpeechInputPreservingText()
            return
        }
        viewModel.addQuickTask()
    }

    private func toggleSpeechInput() {
        if speechInputService.isRecording {
            stopSpeechInputPreservingText()
            return
        }

        speechInputService.start()
    }

    private func stopSpeechInputPreservingText() {
        let transcript = speechInputService.stop()
        let currentText = viewModel.quickAddText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard currentText.isEmpty else { return }

        let recognizedText = transcript.displayText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !recognizedText.isEmpty else { return }
        viewModel.quickAddText = recognizedText
    }

    private func checkForUpdate() {
        guard !isCheckingForUpdate else { return }

        isCheckingForUpdate = true

        Task {
            let nextAlert: UpdateCheckAlert

            do {
                let status = try await appUpdateService.checkForUpdate(
                    currentVersion: AppVersionService.current.marketingVersion
                )
                switch status {
                case .upToDate(let currentVersion):
                    nextAlert = .upToDate(currentVersion: currentVersion)
                case .updateAvailable(let currentVersion, let latestVersion, let appStoreURL):
                    nextAlert = .updateAvailable(
                        currentVersion: currentVersion,
                        latestVersion: latestVersion,
                        appStoreURL: appStoreURL
                    )
                }
            } catch {
                nextAlert = .failed(message: error.localizedDescription)
            }

            await MainActor.run {
                isCheckingForUpdate = false
                updateCheckAlert = nextAlert
            }
        }
    }

    private func previewUpToDateAlert() {
        updateCheckAlert = .upToDate(currentVersion: AppVersionService.current.marketingVersion)
    }

    private func previewUpdateAvailableAlert() {
        updateCheckAlert = .updateAvailable(
            currentVersion: "1.0.0",
            latestVersion: "1.1.0",
            appStoreURL: NotoSupportLink.appPage
        )
    }

    private func dismissUpdateCheckAlert() {
        #if DEBUG
        if !pendingDebugUpdateAlerts.isEmpty {
            updateCheckAlert = pendingDebugUpdateAlerts.removeFirst()
            return
        }
        #endif

        updateCheckAlert = nil
    }

    private func openUpdateStorePage(_ url: URL?) {
        guard let url else {
            NSSound.beep()
            dismissUpdateCheckAlert()
            return
        }

        NSWorkspace.shared.open(url)
        dismissUpdateCheckAlert()
    }

    private func presentDebugUpdateAlertsIfNeeded() {
        #if DEBUG
        guard !didPresentDebugUpdateAlerts,
              ProcessInfo.processInfo.arguments.contains("--preview-update-alerts")
        else { return }

        didPresentDebugUpdateAlerts = true
        viewModel.showSettings()
        pendingDebugUpdateAlerts = [
            .updateAvailable(
                currentVersion: "1.0.0",
                latestVersion: "1.1.0",
                appStoreURL: NotoSupportLink.appPage
            )
        ]
        updateCheckAlert = .upToDate(currentVersion: AppVersionService.current.marketingVersion)
        #endif
    }

    private func toggleLaunchAtLogin() {
        let nextValue = !viewModel.settings.launchAtLogin

        do {
            let appliedValue = try launchAtLoginService.setEnabled(nextValue)
            viewModel.setLaunchAtLogin(appliedValue)
        } catch {
            NSSound.beep()
            #if DEBUG
            print("Noto launch at login update failed: \(error)")
            #endif
        }
    }

    private func reconcileLaunchAtLoginSetting() {
        let currentValue = launchAtLoginService.isEnabledForSettings
        viewModel.setLaunchAtLogin(currentValue)
    }

    private func handleHotKeyTrigger() {
        guard isPanelOpen else {
            isPanelPresentedByHotKey = true
            setPanelOpen(true, activateAppWhenOpening: true)
            return
        }

        if !viewModel.settings.keepOnTop,
           !isPanelPresentedByHotKey,
           NSApp.isActive == false || floatingWindow?.isKeyWindow == false {
            isPanelPresentedByHotKey = true
            bringFloatingWindowForward(activateApp: true)
            updateFloatingWindowLayout(animated: false)
            return
        }

        isPanelPresentedByHotKey = false
        setPanelOpen(false)
    }

    private func setPanelOpen(_ isOpen: Bool, activateAppWhenOpening: Bool = false) {
        let shouldActivate = activateAppWhenOpening && isOpen
        bringFloatingWindowForward(activateApp: shouldActivate)

        guard isPanelOpen != isOpen else {
            withoutAnimation {
                updateFloatingWindowLayout(animated: false)
            }
            return
        }

        withoutAnimation {
            if isOpen {
                viewModel.showList()
            } else {
                isPanelPresentedByHotKey = false
                if speechInputService.isRecording {
                    stopSpeechInputPreservingText()
                } else {
                    speechInputService.cancel()
                }
            }
            isPanelOpen = isOpen
            updateFloatingWindowLayout(animated: false)
        }
    }

    private func characterDragGesture() -> some Gesture {
        DragGesture(minimumDistance: 3)
            .updating($isPressing) { _, state, _ in
                state = true
            }
            .onChanged { _ in
                let mouseLocation = FloatingScreenGeometry.topLeftPoint(fromAppKitPoint: NSEvent.mouseLocation)

                if dragStartOrigin == nil {
                    dragStartOrigin = characterScreenOrigin
                    dragStartMouseLocation = mouseLocation
                    dragPointerOffset = CGSize(
                        width: mouseLocation.x - characterScreenOrigin.x,
                        height: mouseLocation.y - characterScreenOrigin.y
                    )
                }

                let pointerOffset = dragPointerOffset ?? .zero
                let proposedOrigin = CGPoint(
                    x: mouseLocation.x - pointerOffset.width,
                    y: mouseLocation.y - pointerOffset.height
                )
                guard let screen = FloatingScreenGeometry.screen(containingTopLeftPoint: proposedOrigin) ?? activeScreen else { return }
                let visibleFrame = FloatingScreenGeometry.topLeftVisibleFrame(for: screen)
                characterScreenOrigin = PanelPlacementResolver.clampedCharacterOrigin(
                    proposedOrigin,
                    visibleScreenFrame: visibleFrame
                )
                updateFloatingWindowLayout()
            }
            .onEnded { _ in
                let mouseLocation = FloatingScreenGeometry.topLeftPoint(fromAppKitPoint: NSEvent.mouseLocation)
                let startMouseLocation = dragStartMouseLocation ?? mouseLocation
                let movedDistance = hypot(
                    mouseLocation.x - startMouseLocation.x,
                    mouseLocation.y - startMouseLocation.y
                )
                dragStartOrigin = nil
                dragStartMouseLocation = nil
                dragPointerOffset = nil

                if movedDistance <= 4 {
                    togglePanel()
                } else {
                    persistCharacterPosition()
                    updateFloatingWindowLayout(animated: false)
                }
            }
    }
}

private extension TaskPanelSettings.Theme {
    func resolvedColorScheme(systemColorScheme: ColorScheme) -> ColorScheme {
        switch self {
        case .system:
            return systemColorScheme
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    func nsAppearance(systemColorScheme: ColorScheme) -> NSAppearance? {
        NSAppearance(named: resolvedColorScheme(systemColorScheme: systemColorScheme).nsAppearanceName)
    }

    static var currentSystemColorScheme: ColorScheme {
        UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" ? .dark : .light
    }
}

private extension ColorScheme {
    var nsAppearanceName: NSAppearance.Name {
        self == .dark ? .darkAqua : .aqua
    }
}

private extension Notification.Name {
    static let appleInterfaceThemeChanged = Notification.Name("AppleInterfaceThemeChangedNotification")
}

#Preview {
    FloatingRootView()
        .frame(width: 720, height: 520)
}
