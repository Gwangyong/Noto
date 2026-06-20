//
//  FloatingRootView.swift
//  Noto
//

import AppKit
import SwiftData
import SwiftUI

struct FloatingRootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = TaskPanelViewModel.sample()
    @State private var isPanelOpen = true
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
    @GestureState private var isPressing = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            if isPanelOpen {
                TaskPanelView(
                    viewModel: viewModel,
                    onCollapse: {
                        withAnimation(.easeOut(duration: DesignTokens.Motion.panelOpenDuration)) {
                            isPanelOpen = false
                        }
                    }
                )
                .position(
                    x: panelLocalOrigin.x + DesignTokens.Size.panelWidth / 2,
                    y: panelLocalOrigin.y + currentPanelHeight / 2
                )
                .transition(.opacity.combined(with: .scale(scale: DesignTokens.Motion.panelOpenInitialScale)))
                .zIndex(1)
            }

            FloatingCharacterView(
                remainingCount: viewModel.remainingCount,
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
        .preferredColorScheme(viewModel.settings.theme.preferredColorScheme)
        .background(
            FloatingWindowAccessor { window in
                if floatingWindow !== window {
                    floatingWindow = window
                }
                updateFloatingWindowLevel(window)
                updateFloatingWindowLayout()
            }
        )
        .onAppear {
            configurePersistenceIfNeeded()
            updateFloatingWindowLayout()
        }
        .onChange(of: isPanelOpen) { _, _ in
            updateFloatingWindowLayout(animated: true)
        }
        .onChange(of: viewModel.screen) { _, _ in
            updateFloatingWindowLayout(animated: true)
        }
        .onChange(of: viewModel.settings.keepOnTop) { _, _ in
            if let floatingWindow {
                updateFloatingWindowLevel(floatingWindow)
            }
        }
    }

    private func configurePersistenceIfNeeded() {
        guard !didLoadPersistedState else { return }

        let store = TaskPanelStore(modelContext: modelContext)
        persistenceStore = store

        do {
            let snapshot = try store.loadOrSeed(default: viewModel.snapshot)
            viewModel.applySnapshot(snapshot)

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
        window.level = viewModel.settings.keepOnTop ? .floating : NSWindow.Level(rawValue: 0)
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
        withAnimation(.easeOut(duration: DesignTokens.Motion.panelOpenDuration)) {
            isPanelOpen.toggle()
        }
        updateFloatingWindowLayout(animated: true)
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
                    updateFloatingWindowLayout(animated: true)
                }
            }
    }
}

private extension TaskPanelSettings.Theme {
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

#Preview {
    FloatingRootView()
        .frame(width: 720, height: 520)
}
