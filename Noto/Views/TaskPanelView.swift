//
//  TaskPanelView.swift
//  Noto
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

private enum TaskPanelFocusField: Hashable {
    case quickAdd
}

struct TaskPanelView: View {
    @ObservedObject var viewModel: TaskPanelViewModel
    let onCollapse: () -> Void
    let onHotKeyRecordingChange: (Bool) -> Void

    @FocusState private var focusedField: TaskPanelFocusField?
    @State private var isEditingGoal = false
    @State private var draggingTaskID: SampleTask.ID?
    @State private var isRecordingHotKey = false

    private var panelHeight: CGFloat {
        viewModel.screen == .settings
            ? DesignTokens.Size.settingsPanelHeight
            : DesignTokens.Size.panelHeight
    }

    var body: some View {
        ZStack {
            Group {
                switch viewModel.screen {
                case .list:
                    listPanel
                case .settings:
                    settingsPanel
                }
            }
            .frame(width: DesignTokens.Size.panelWidth, height: panelHeight)
            .background(panelSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.panel, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.panel, style: .continuous)
                    .stroke(DesignTokens.Colors.hairline, lineWidth: 0.6)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
            .blur(radius: viewModel.showingDeleteAllConfirm ? 4 : 0)
            .allowsHitTesting(!viewModel.showingDeleteAllConfirm)

            if viewModel.showingDeleteAllConfirm {
                DeleteAllConfirmView(
                    onCancel: viewModel.cancelDeleteAll,
                    onDelete: viewModel.confirmDeleteAll
                )
                .frame(width: DesignTokens.Size.panelWidth, height: panelHeight)
                .transition(.opacity.combined(with: .scale(scale: DesignTokens.Motion.modalOpenInitialScale)))
            }
        }
        .animation(.easeOut(duration: DesignTokens.Motion.panelOpenDuration), value: viewModel.screen)
        .animation(.easeOut(duration: DesignTokens.Motion.modalOpenDuration), value: viewModel.showingDeleteAllConfirm)
        .onChange(of: viewModel.screen) { _, screen in
            guard screen != .settings else { return }
            setHotKeyRecording(false)
        }
        .onDisappear {
            setHotKeyRecording(false)
        }
    }

    private var listPanel: some View {
        VStack(spacing: 0) {
            TaskHeaderView(
                onDeleteAll: viewModel.requestDeleteAll,
                onSettings: viewModel.showSettings,
                onCollapse: onCollapse
            )

            GoalInputView(
                goal: $viewModel.goal,
                isEditing: $isEditingGoal,
                onCommit: viewModel.persistSnapshot
            )
            .padding(.horizontal, DesignTokens.Spacing.lg)

            Divider()
                .overlay(DesignTokens.Colors.divider)
                .padding(.top, 4)

            ProgressSummaryView(progress: viewModel.progress)
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.top, 8)

            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 3) {
                        if viewModel.tasks.isEmpty {
                            EmptyTaskListView()
                                .padding(.top, 24)
                        } else {
                            ForEach(viewModel.tasks) { task in
                                TaskRowView(
                                    task: task,
                                    isEditing: viewModel.editingTaskID == task.id,
                                    isDeleting: viewModel.deletingTaskID == task.id,
                                    onToggle: { viewModel.toggleDone(task) },
                                    onEdit: { viewModel.beginEditing(task) },
                                    onCommitEdit: { title in viewModel.commitEditing(task, title: title) },
                                    onDelete: { viewModel.deleteTask(task) },
                                    onDragStart: {
                                        draggingTaskID = task.id
                                        viewModel.beginReordering(task)
                                    }
                                )
                                .id(task.id)
                                .onDrop(
                                    of: [UTType.text],
                                    delegate: TaskRowDropDelegate(
                                        targetTaskID: task.id,
                                        draggingTaskID: $draggingTaskID,
                                        onMove: viewModel.moveTask
                                    )
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    .padding(.horizontal, 10)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: viewModel.tasks.count) { oldCount, newCount in
                    guard newCount > oldCount, let lastTaskID = viewModel.tasks.last?.id else { return }

                    DispatchQueue.main.async {
                        withAnimation(.easeOut(duration: 0.18)) {
                            scrollProxy.scrollTo(lastTaskID, anchor: .bottom)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            QuickAddView(
                text: $viewModel.quickAddText,
                focusedField: $focusedField,
                onSubmit: viewModel.addQuickTask,
                onMic: {}
            )
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, 14)
            .padding(.top, 10)
            .background(
                Rectangle()
                    .fill(DesignTokens.Colors.panelSurface.opacity(0.94))
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(DesignTokens.Colors.divider)
                            .frame(height: 1)
                }
            )
        }
    }

    private var settingsPanel: some View {
        SettingsPanelView(
            settings: viewModel.settings,
            onBack: viewModel.showList,
            onCollapse: onCollapse,
            onToggleLogin: viewModel.toggleLaunchAtLogin,
            onToggleOnTop: viewModel.toggleKeepOnTop,
            onToggleSound: viewModel.toggleCompletionSound,
            onTheme: viewModel.setTheme,
            isRecordingHotKey: Binding(
                get: { isRecordingHotKey },
                set: { setHotKeyRecording($0) }
            ),
            onHotKey: viewModel.setHotKey
        )
    }

    private func setHotKeyRecording(_ isRecording: Bool) {
        guard isRecordingHotKey != isRecording else { return }
        isRecordingHotKey = isRecording
        onHotKeyRecordingChange(isRecording)
    }

    private var panelSurface: some View {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.panel, style: .continuous)
            .fill(DesignTokens.Colors.panelSurface)
    }
}

private struct TaskHeaderView: View {
    let onDeleteAll: () -> Void
    let onSettings: () -> Void
    let onCollapse: () -> Void

    var body: some View {
        HStack(spacing: 7) {
            AppGlyph()

            Text("Noto")
                .font(DesignTokens.Typography.panelTitle)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Spacer(minLength: 10)

            Button("전체 삭제", action: onDeleteAll)
                .font(DesignTokens.Typography.sans(size: 11, weight: .medium))
                .foregroundStyle(DesignTokens.Colors.destructive)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .buttonStyle(.plain)

            HeaderIconButton(systemName: "slider.horizontal.3", accessibilityLabel: "설정", action: onSettings)
            HeaderIconButton(systemName: "chevron.down", accessibilityLabel: "접기", action: onCollapse)
        }
        .padding(.leading, 15)
        .padding(.trailing, 12)
        .padding(.top, 13)
        .padding(.bottom, 9)
    }
}

private struct AppGlyph: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        DesignTokens.Colors.primaryGradientStart,
                        DesignTokens.Colors.primaryGradientEnd
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 15, height: 15)
            .overlay {
                Circle()
                    .fill(DesignTokens.Colors.onPrimary.opacity(0.92))
                    .frame(width: 4, height: 4)
            }
            .shadow(color: Color.black.opacity(0.18), radius: 2, x: 0, y: 1)
    }
}

private struct HeaderIconButton: View {
    let systemName: String
    let accessibilityLabel: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
                .frame(width: DesignTokens.Size.headerIconButton, height: DesignTokens.Size.headerIconButton)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                        .fill(isHovering ? DesignTokens.Colors.controlSurface : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .onHover { isHovering = $0 }
    }
}

private struct GoalInputView: View {
    @Binding var goal: String
    @Binding var isEditing: Bool
    let onCommit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("목표 · GOAL")
                .font(DesignTokens.Typography.labelMono)
                .foregroundStyle(DesignTokens.Colors.labelMuted)

            InlineGoalTextView(text: $goal, isEditing: $isEditing, onCommit: onCommit)
                .frame(height: 18, alignment: .center)
        }
        .frame(height: 38, alignment: .topLeading)
        .padding(.top, 2)
    }
}

private struct InlineGoalTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var isEditing: Bool
    var onCommit: () -> Void = {}

    func makeNSView(context: Context) -> GoalTextView {
        let textView = GoalTextView()
        textView.delegate = context.coordinator
        textView.placeholder = "오늘의 목표를 입력하세요"
        textView.font = NSFont(name: "IBM Plex Sans KR", size: 13.5)
            ?? .systemFont(ofSize: 13.5, weight: .medium)
        textView.textColor = DesignTokens.AppKitColors.textPrimary
        textView.placeholderColor = DesignTokens.AppKitColors.goalPlaceholder
        textView.insertionPointColor = DesignTokens.AppKitColors.insertionPoint
        textView.drawsBackground = false
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.usesFindBar = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.maximumNumberOfLines = 1
        textView.textContainer?.lineBreakMode = .byTruncatingTail
        textView.textContainer?.widthTracksTextView = true
        textView.onTextChange = { value in
            context.coordinator.updateText(value)
        }
        textView.onBeginEditing = { view, event in
            context.coordinator.beginEditing(view, event: event)
        }
        textView.onCommit = {
            context.coordinator.commitEditing()
        }
        textView.setExternalText(text)
        context.coordinator.configure(textView)
        return textView
    }

    func updateNSView(_ nsView: GoalTextView, context: Context) {
        context.coordinator.parent = self
        if !isEditing && nsView.string != text {
            nsView.setExternalText(text)
        }
        context.coordinator.configure(nsView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: InlineGoalTextView
        private var isCommitting = false

        init(parent: InlineGoalTextView) {
            self.parent = parent
        }

        func configure(_ textView: GoalTextView) {
            textView.isEditingMode = parent.isEditing
            textView.isEditable = parent.isEditing
            textView.isSelectable = parent.isEditing
            textView.needsDisplay = true

            if parent.isEditing {
                textView.startOutsideClickMonitoring()
            } else {
                textView.stopOutsideClickMonitoring()
            }

            guard !parent.isEditing, textView.window?.firstResponder === textView else { return }
            textView.setSelectedRange(NSRange(location: 0, length: 0))
            textView.window?.makeFirstResponder(nil)
        }

        func updateText(_ value: String) {
            let singleLineText = value.replacingOccurrences(of: "\n", with: " ")
            guard parent.text != singleLineText else { return }
            parent.text = singleLineText
        }

        func beginEditing(_ textView: GoalTextView, event: NSEvent) {
            isCommitting = false
            textView.isEditingMode = true
            textView.isEditable = true
            textView.isSelectable = true
            textView.startOutsideClickMonitoring()
            textView.window?.makeFirstResponder(textView)

            let clickPoint = textView.convert(event.locationInWindow, from: nil)
            let insertionIndex = min(textView.characterIndexForInsertion(at: clickPoint), textView.string.utf16.count)
            textView.setSelectedRange(NSRange(location: insertionIndex, length: 0))

            updateBindingState { [weak self] in
                self?.parent.isEditing = true
            }
        }

        func commitEditing() {
            guard !isCommitting else { return }
            isCommitting = true

            updateBindingState { [weak self] in
                guard let self else { return }
                self.parent.isEditing = false
                self.parent.onCommit()
            }
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? GoalTextView else { return }
            textView.notifyTextChanged()
        }

        func textDidEndEditing(_ notification: Notification) {
            updateBindingState { [weak self] in
                self?.parent.isEditing = false
            }
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.insertNewline(_:)),
                 #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)):
                commitEditing()
                return true
            default:
                return false
            }
        }

        private func updateBindingState(_ update: @escaping () -> Void) {
            DispatchQueue.main.async(execute: update)
        }
    }
}

private final class GoalTextView: NSTextView {
    var placeholder = ""
    var placeholderColor = NSColor.secondaryLabelColor
    var isEditingMode = false
    var onTextChange: ((String) -> Void)?
    var onBeginEditing: ((GoalTextView, NSEvent) -> Void)?
    var onCommit: (() -> Void)?
    private var isApplyingExternalText = false
    private var outsideClickMonitor: Any?

    override var acceptsFirstResponder: Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        guard isEditingMode else {
            onBeginEditing?(self, event)
            return
        }
        super.mouseDown(with: event)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 || event.keyCode == 76 {
            finishEditing()
            return
        }
        super.keyDown(with: event)
    }

    override func insertText(_ insertString: Any, replacementRange: NSRange) {
        super.insertText(insertString, replacementRange: replacementRange)
        notifyTextChanged()
    }

    override func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        super.setMarkedText(string, selectedRange: selectedRange, replacementRange: replacementRange)
        notifyTextChanged()
    }

    override func unmarkText() {
        super.unmarkText()
        notifyTextChanged()
    }

    func setExternalText(_ value: String) {
        isApplyingExternalText = true
        string = value
        isApplyingExternalText = false
        needsDisplay = true
    }

    func notifyTextChanged() {
        guard !isApplyingExternalText else { return }
        onTextChange?(string)
        needsDisplay = true
    }

    func startOutsideClickMonitoring() {
        guard outsideClickMonitor == nil else { return }
        outsideClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, self.isEditingMode else { return event }
            guard event.window === self.window else {
                self.finishEditing()
                return event
            }

            let eventPoint = self.convert(event.locationInWindow, from: nil)
            if !self.bounds.contains(eventPoint) {
                self.finishEditing()
            }
            return event
        }
    }

    func stopOutsideClickMonitoring() {
        guard let outsideClickMonitor else { return }
        NSEvent.removeMonitor(outsideClickMonitor)
        self.outsideClickMonitor = nil
    }

    private func finishEditing() {
        stopOutsideClickMonitoring()
        isEditingMode = false
        isEditable = false
        isSelectable = false
        setSelectedRange(NSRange(location: 0, length: 0))
        onCommit?()
        window?.makeFirstResponder(nil)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard string.isEmpty else { return }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font ?? NSFont.systemFont(ofSize: 13.5, weight: .medium),
            .foregroundColor: placeholderColor
        ]
        placeholder.draw(at: .zero, withAttributes: attributes)
    }

    deinit {
        stopOutsideClickMonitoring()
    }
}

private struct ProgressSummaryView: View {
    let progress: Int

    private var progressFraction: CGFloat {
        CGFloat(max(0, min(progress, 100))) / 100
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("오늘의 집중도 · FOCUS")
                    .font(DesignTokens.Typography.labelMono)
                    .foregroundStyle(DesignTokens.Colors.labelMuted)

                Spacer()

                Text("\(progress)%")
                    .font(DesignTokens.Typography.percent)
                    .foregroundStyle(DesignTokens.Colors.primaryDeep)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DesignTokens.Colors.hairline)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignTokens.Colors.progressGradientStart,
                                    DesignTokens.Colors.primary
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: proxy.size.width * progressFraction)
                        .animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: DesignTokens.Motion.progressDuration), value: progress)
                }
            }
            .frame(height: 6)
        }
    }
}

private let taskTitleLineSpacing: CGFloat = 3

private struct InlineTaskTitleEditor: NSViewRepresentable {
    let text: String
    @Binding var measuredHeight: CGFloat
    let onCommit: (String) -> Void

    func makeNSView(context: Context) -> TaskTitleTextView {
        let textView = TaskTitleTextView()
        let textFont = NSFont(name: "IBM Plex Sans KR", size: 13)
            ?? .systemFont(ofSize: 13, weight: .regular)
        let textColor = DesignTokens.AppKitColors.textPrimary

        textView.delegate = context.coordinator
        textView.string = text
        textView.applyTaskTitleStyle(font: textFont, textColor: textColor)
        textView.insertionPointColor = DesignTokens.AppKitColors.insertionPoint
        textView.drawsBackground = false
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.usesFindBar = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.maximumNumberOfLines = 0
        textView.textContainer?.lineBreakMode = .byCharWrapping
        textView.textContainer?.widthTracksTextView = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.onCommit = { title in
            context.coordinator.commitEditing(title)
        }
        textView.onHeightChange = { height in
            context.coordinator.updateMeasuredHeight(height)
        }
        context.coordinator.configure(textView)
        return textView
    }

    func updateNSView(_ nsView: TaskTitleTextView, context: Context) {
        context.coordinator.parent = self
        if !nsView.hasUserEditedText, nsView.string != text {
            nsView.string = text
            nsView.applyTaskTitleAttributes()
        }
        context.coordinator.configure(nsView)
    }

    static func dismantleNSView(_ nsView: TaskTitleTextView, coordinator: Coordinator) {
        nsView.stopOutsideClickMonitoring()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: InlineTaskTitleEditor

        init(parent: InlineTaskTitleEditor) {
            self.parent = parent
        }

        func configure(_ textView: TaskTitleTextView) {
            textView.isEditable = true
            textView.isSelectable = true
            textView.startOutsideClickMonitoring()
            textView.focusForEditingIfNeeded()
            textView.updateMeasuredHeight()
        }

        func commitEditing(_ title: String) {
            let singleLineText = title.replacingOccurrences(of: "\n", with: " ")
            parent.onCommit(singleLineText)
        }

        func updateMeasuredHeight(_ height: CGFloat) {
            DispatchQueue.main.async {
                guard abs(self.parent.measuredHeight - height) > 0.5 else { return }
                self.parent.measuredHeight = height
            }
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            (textView as? TaskTitleTextView)?.hasUserEditedText = true
            (textView as? TaskTitleTextView)?.updateMeasuredHeight()
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.insertNewline(_:)),
                 #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)):
                if let taskTextView = textView as? TaskTitleTextView {
                    taskTextView.finishEditing()
                } else {
                    commitEditing(textView.string)
                }
                return true
            default:
                return false
            }
        }
    }
}

private final class TaskTitleTextView: NSTextView {
    var onCommit: ((String) -> Void)?
    var onHeightChange: ((CGFloat) -> Void)?
    var hasUserEditedText = false
    private var outsideClickMonitor: Any?
    private var didRequestInitialFocus = false
    private var currentMeasuredHeight: CGFloat = 18
    private var taskTitleAttributes: [NSAttributedString.Key: Any] = [:]

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: currentMeasuredHeight)
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateMeasuredHeight()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        focusForEditingIfNeeded()
        updateMeasuredHeight()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 || event.keyCode == 76 {
            finishEditing()
            return
        }
        super.keyDown(with: event)
    }

    func applyTaskTitleStyle(font: NSFont, textColor: NSColor) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping
        paragraphStyle.lineSpacing = taskTitleLineSpacing

        self.font = font
        self.textColor = textColor
        defaultParagraphStyle = paragraphStyle
        taskTitleAttributes = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]
        typingAttributes = taskTitleAttributes
        applyTaskTitleAttributes()
    }

    func applyTaskTitleAttributes() {
        guard !taskTitleAttributes.isEmpty else { return }
        typingAttributes = taskTitleAttributes

        let range = NSRange(location: 0, length: string.utf16.count)
        guard range.length > 0 else { return }
        textStorage?.addAttributes(taskTitleAttributes, range: range)
    }

    func focusForEditingIfNeeded() {
        guard !didRequestInitialFocus else { return }
        guard window != nil else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard !self.didRequestInitialFocus else { return }
            guard self.window != nil else { return }
            self.didRequestInitialFocus = true
            self.window?.makeFirstResponder(self)
            self.setSelectedRange(NSRange(location: self.string.utf16.count, length: 0))
        }
    }

    func updateMeasuredHeight() {
        guard bounds.width > 0, let textContainer, let layoutManager else { return }
        textContainer.containerSize = NSSize(width: bounds.width, height: .greatestFiniteMagnitude)
        layoutManager.ensureLayout(for: textContainer)

        let usedRect = layoutManager.usedRect(for: textContainer)
        let height = max(18, ceil(usedRect.height + textContainerInset.height * 2))
        guard abs(currentMeasuredHeight - height) > 0.5 else { return }
        currentMeasuredHeight = height
        invalidateIntrinsicContentSize()
        onHeightChange?(height)
    }

    func startOutsideClickMonitoring() {
        guard outsideClickMonitor == nil else { return }
        outsideClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self else { return event }
            guard event.window === self.window else {
                self.finishEditing()
                return event
            }

            let eventPoint = self.convert(event.locationInWindow, from: nil)
            if !self.bounds.contains(eventPoint) {
                self.finishEditing()
            }
            return event
        }
    }

    func stopOutsideClickMonitoring() {
        guard let outsideClickMonitor else { return }
        NSEvent.removeMonitor(outsideClickMonitor)
        self.outsideClickMonitor = nil
    }

    func finishEditing() {
        stopOutsideClickMonitoring()
        isEditable = false
        isSelectable = false
        setSelectedRange(NSRange(location: 0, length: 0))
        onCommit?(string)
        window?.makeFirstResponder(nil)
    }

    deinit {
        stopOutsideClickMonitoring()
    }
}

private struct TaskRowView: View {
    let task: SampleTask
    let isEditing: Bool
    let isDeleting: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onCommitEdit: (String) -> Void
    let onDelete: () -> Void
    let onDragStart: () -> Void

    @State private var isHovering = false
    @State private var draftTitleHeight: CGFloat = 18

    private var showsActions: Bool {
        isHovering || isEditing || isDeleting
    }

    var body: some View {
        HStack(alignment: .center, spacing: 7) {
            Group {
                if showsActions {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                        .frame(width: 12, height: 24)
                        .contentShape(Rectangle())
                        .onDrag {
                            onDragStart()
                            return NSItemProvider(object: task.id.uuidString as NSString)
                        } preview: {
                            Color.clear
                                .frame(width: 1, height: 1)
                        }
                } else {
                    Color.clear.frame(width: 12, height: 24)
                }
            }

            Button(action: onToggle) {
                CheckboxView(isDone: task.isDone)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            if isEditing {
                InlineTaskTitleEditor(text: task.title, measuredHeight: $draftTitleHeight) { title in
                    onCommitEdit(title)
                }
                .frame(height: draftTitleHeight, alignment: .center)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(DesignTokens.Colors.primary)
                            .frame(height: 1.5)
                            .offset(y: 5)
                    }
            } else {
                Text(task.title)
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(task.isDone ? DesignTokens.Colors.textCompleted : DesignTokens.Colors.textPrimary)
                    .strikethrough(task.isDone, color: DesignTokens.Colors.textCompleted)
                    .lineSpacing(taskTitleLineSpacing)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !task.isDone else { return }
                        onEdit()
                    }
            }

            HStack(spacing: 4) {
                if !isEditing && !task.isDone {
                    RowIconButton(systemName: "pencil", color: DesignTokens.Colors.primary, action: onEdit)
                } else {
                    Color.clear
                        .frame(width: 22, height: 22)
                }

                RowIconButton(systemName: "trash", color: DesignTokens.Colors.destructive, action: onDelete)
            }
            .frame(width: 48, alignment: .trailing)
            .opacity(showsActions ? 1 : 0)
            .allowsHitTesting(showsActions)
        }
        .padding(7)
        .frame(maxWidth: .infinity, minHeight: 35, alignment: .center)
        .background(rowBackground)
        .contentShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .onHover { isHovering = $0 }
        .onChange(of: isEditing) { _, newValue in
            if newValue {
                draftTitleHeight = 18
            }
        }
    }

    private var rowBackground: Color {
        if isDeleting {
            return DesignTokens.Colors.rowDeleteSurface
        }
        if isHovering || isEditing {
            return DesignTokens.Colors.rowHoverSurface
        }
        return Color.clear
    }
}

private struct TaskRowDropDelegate: DropDelegate {
    let targetTaskID: SampleTask.ID
    @Binding var draggingTaskID: SampleTask.ID?
    let onMove: (SampleTask.ID, SampleTask.ID) -> Void

    func validateDrop(info: DropInfo) -> Bool {
        draggingTaskID != nil
    }

    func dropEntered(info: DropInfo) {
        guard let draggingTaskID, draggingTaskID != targetTaskID else { return }

        withAnimation(.easeOut(duration: 0.14)) {
            onMove(draggingTaskID, targetTaskID)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingTaskID = nil
        return true
    }
}

private struct CheckboxView: View {
    let isDone: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(isDone ? DesignTokens.Colors.primary : DesignTokens.Colors.checkboxBorder, lineWidth: 1.6)
                .background(
                    Circle()
                        .fill(isDone ? DesignTokens.Colors.primary : Color.clear)
                )

            if isDone {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DesignTokens.Colors.onPrimary)
            }
        }
        .frame(width: DesignTokens.Size.checkboxSize, height: DesignTokens.Size.checkboxSize)
    }
}

private struct RowIconButton: View {
    let systemName: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyTaskListView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("오늘 할 일이 비어 있어요")
                .font(DesignTokens.Typography.bodyStrong)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            Text("아래 입력창에서 다음 할 일을 추가하세요")
                .font(DesignTokens.Typography.input)
                .foregroundStyle(DesignTokens.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct QuickAddTextEditor: NSViewRepresentable {
    @Binding var text: String
    let focusedField: FocusState<TaskPanelFocusField?>.Binding
    let onSubmit: () -> Void

    func makeNSView(context: Context) -> QuickAddTextView {
        let textView = QuickAddTextView()
        textView.delegate = context.coordinator
        textView.placeholder = "다음 할 일은?"
        textView.placeholderColor = DesignTokens.AppKitColors.placeholder
        textView.font = NSFont(name: "IBM Plex Sans KR", size: 12.5)
            ?? .systemFont(ofSize: 12.5, weight: .regular)
        textView.textColor = DesignTokens.AppKitColors.textPrimary
        textView.insertionPointColor = DesignTokens.AppKitColors.insertionPoint
        textView.drawsBackground = false
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.usesFindBar = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.textContainerInset = NSSize(width: 0, height: 1.5)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.maximumNumberOfLines = 1
        textView.textContainer?.lineBreakMode = .byClipping
        textView.textContainer?.widthTracksTextView = true
        textView.onTextChange = { value in
            context.coordinator.updateText(value)
        }
        textView.onSubmit = { value in
            context.coordinator.submit(value)
        }
        textView.setExternalText(text)
        return textView
    }

    func updateNSView(_ nsView: QuickAddTextView, context: Context) {
        context.coordinator.parent = self
        if nsView.string != text {
            nsView.setExternalText(text)
        }
        if focusedField.wrappedValue == .quickAdd {
            nsView.focusIfPossible()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: QuickAddTextEditor

        init(parent: QuickAddTextEditor) {
            self.parent = parent
        }

        func updateText(_ value: String) {
            let singleLineText = value.replacingOccurrences(of: "\n", with: " ")
            guard parent.text != singleLineText else { return }
            parent.text = singleLineText
        }

        func submit(_ value: String) {
            updateText(value)
            parent.onSubmit()
            parent.focusedField.wrappedValue = .quickAdd
        }

        func textDidBeginEditing(_ notification: Notification) {
            parent.focusedField.wrappedValue = .quickAdd
        }

        func textDidEndEditing(_ notification: Notification) {
            guard parent.focusedField.wrappedValue == .quickAdd else { return }
            parent.focusedField.wrappedValue = nil
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? QuickAddTextView else { return }
            textView.notifyTextChanged()
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.insertNewline(_:)),
                 #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)):
                submit(textView.string)
                return true
            default:
                return false
            }
        }
    }
}

private final class QuickAddTextView: NSTextView {
    var placeholder = ""
    var placeholderColor = NSColor.secondaryLabelColor
    var onTextChange: ((String) -> Void)?
    var onSubmit: ((String) -> Void)?
    private var isApplyingExternalText = false

    override var acceptsFirstResponder: Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 || event.keyCode == 76 {
            onSubmit?(string)
            return
        }
        super.keyDown(with: event)
    }

    override func insertText(_ insertString: Any, replacementRange: NSRange) {
        super.insertText(insertString, replacementRange: replacementRange)
        notifyTextChanged()
    }

    override func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        super.setMarkedText(string, selectedRange: selectedRange, replacementRange: replacementRange)
        notifyTextChanged()
    }

    override func unmarkText() {
        super.unmarkText()
        notifyTextChanged()
    }

    func setExternalText(_ value: String) {
        isApplyingExternalText = true
        string = value
        isApplyingExternalText = false
        needsDisplay = true
    }

    func focusIfPossible() {
        guard window != nil, window?.firstResponder !== self else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.window != nil, self.window?.firstResponder !== self else { return }
            self.window?.makeFirstResponder(self)
        }
    }

    func notifyTextChanged() {
        guard !isApplyingExternalText else { return }
        onTextChange?(string)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard string.isEmpty else { return }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font ?? NSFont.systemFont(ofSize: 12.5),
            .foregroundColor: placeholderColor
        ]
        placeholder.draw(at: NSPoint(x: 0, y: textContainerInset.height), withAttributes: attributes)
    }
}

private struct QuickAddView: View {
    @Binding var text: String
    let focusedField: FocusState<TaskPanelFocusField?>.Binding
    let onSubmit: () -> Void
    let onMic: () -> Void

    private var hasDraftText: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submitDraftFromButton() {
        onSubmit()
        focusedField.wrappedValue = .quickAdd
    }

    var body: some View {
        HStack(spacing: 8) {
            QuickAddTextEditor(
                text: $text,
                focusedField: focusedField,
                onSubmit: onSubmit
            )
            .frame(height: 18, alignment: .center)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField.wrappedValue = .quickAdd
            }

            Button {
                hasDraftText ? submitDraftFromButton() : onMic()
            } label: {
                Image(systemName: hasDraftText ? "arrow.up" : "mic.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DesignTokens.Colors.onPrimary)
                    .frame(width: DesignTokens.Size.quickAddMic, height: DesignTokens.Size.quickAddMic)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        DesignTokens.Colors.primaryGradientStart,
                                        DesignTokens.Colors.primaryGradientEnd
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: DesignTokens.Colors.primaryGradientEnd.opacity(0.35), radius: 6, x: 0, y: 2)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(hasDraftText ? "할 일 추가" : "음성 입력")
        }
        .animation(.easeOut(duration: 0.12), value: hasDraftText)
        .padding(.leading, 14)
        .padding(.trailing, 7)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.input, style: .continuous)
                .fill(DesignTokens.Colors.controlSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.input, style: .continuous)
                        .stroke(DesignTokens.Colors.hairline.opacity(0.55), lineWidth: 0.5)
                )
        )
    }
}

private struct DeleteAllConfirmView: View {
    let onCancel: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.panel, style: .continuous)
                .fill(DesignTokens.Colors.modalOverlay)

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(DesignTokens.Colors.rowDeleteSurface)
                        .frame(width: DesignTokens.Size.modalIconSize, height: DesignTokens.Size.modalIconSize)

                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DesignTokens.Colors.destructive)
                }

                VStack(spacing: 6) {
                    Text("모든 할 일을 삭제할까요?")
                        .font(DesignTokens.Typography.modalTitle)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text("이 작업은 되돌릴 수 없습니다.")
                        .font(DesignTokens.Typography.modalBody)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }

                HStack(spacing: 8) {
                    ModalActionButton(
                        title: "취소",
                        font: DesignTokens.Typography.secondaryButton,
                        foreground: DesignTokens.Colors.primaryDeep,
                        background: DesignTokens.Colors.modalSecondaryButtonSurface,
                        stroke: DesignTokens.Colors.hairline,
                        action: onCancel
                    )

                    ModalActionButton(
                        title: "삭제",
                        font: DesignTokens.Typography.button,
                        foreground: DesignTokens.Colors.onDestructive,
                        background: DesignTokens.Colors.destructive,
                        action: onDelete
                    )
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.vertical, DesignTokens.Spacing.xxl)
            .frame(width: DesignTokens.Size.modalWidth)
            .frame(minHeight: DesignTokens.Size.modalMinHeight)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.modal, style: .continuous)
                    .fill(DesignTokens.Colors.panelSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.modal, style: .continuous)
                            .stroke(DesignTokens.Colors.hairline, lineWidth: 0.6)
                    )
                    .shadow(color: Color.black.opacity(0.40), radius: 50, x: 0, y: 24)
            )
        }
    }
}

private struct ModalActionButton: View {
    let title: String
    let font: Font
    let foreground: Color
    let background: Color
    var stroke: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(font)
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: DesignTokens.Size.modalButtonHeight)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                        .fill(background)
                        .overlay {
                            if let stroke {
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                                    .stroke(stroke, lineWidth: 1)
                            }
                        }
                )
                .contentShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

private struct SettingsPanelView: View {
    let settings: TaskPanelSettings
    let onBack: () -> Void
    let onCollapse: () -> Void
    let onToggleLogin: () -> Void
    let onToggleOnTop: () -> Void
    let onToggleSound: () -> Void
    let onTheme: (TaskPanelSettings.Theme) -> Void
    @Binding var isRecordingHotKey: Bool
    let onHotKey: (TaskPanelHotKey) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                HeaderIconButton(systemName: "arrow.left", accessibilityLabel: "목록으로", action: onBack)

                Text("설정")
                    .font(DesignTokens.Typography.sans(size: 13.5, weight: .semibold))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text("SETTINGS")
                    .font(DesignTokens.Typography.labelMono)
                    .foregroundStyle(DesignTokens.Colors.labelQuiet)
                    .padding(.leading, 2)

                Spacer()

                HeaderIconButton(systemName: "chevron.down", accessibilityLabel: "접기", action: onCollapse)
            }
            .padding(.leading, 11)
            .padding(.trailing, 12)
            .padding(.top, 13)
            .padding(.bottom, 11)

            Divider()
                .overlay(DesignTokens.Colors.divider)
                .padding(.horizontal, 14)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        SettingsToggleRow(title: "시동 시 실행", subtitle: "노트북이 켜질 때마다 자동으로 실행돼요!", isOn: settings.launchAtLogin, action: onToggleLogin)
                        SettingsDivider()
                        SettingsToggleRow(title: "항상 위에 표시", subtitle: "언제나 다른 창에 가려지지 않아요!", isOn: settings.keepOnTop, action: onToggleOnTop)
                        SettingsDivider()
                        SettingsToggleRow(title: "완료 효과음", isOn: settings.completionSound, action: onToggleSound)
                    }

                    ThemePickerRow(selectedTheme: settings.theme, onTheme: onTheme)
                        .padding(.top, 8)

                    ShortcutSettingRow(
                        hotKey: settings.hotKey,
                        isRecording: $isRecordingHotKey,
                        onHotKey: onHotKey
                    )
                        .padding(.top, 13)

                    SupportSectionView(
                        onFeedback: {},
                        onShare: {},
                        onRate: {}
                    )
                    .padding(.top, 17)

                    HStack {
                        Spacer()
                        Text("version 1.0.0")
                    }
                    .font(DesignTokens.Typography.settingsMeta)
                    .foregroundStyle(DesignTokens.Colors.textMuted)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let subtitle: String?
    let isOn: Bool
    let action: () -> Void

    init(title: String, subtitle: String? = nil, isOn: Bool, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.isOn = isOn
        self.action = action
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignTokens.Typography.sans(size: 13, weight: .medium))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(DesignTokens.Typography.sans(size: 11, weight: .regular))
                        .foregroundStyle(DesignTokens.Colors.labelMuted)
                }
            }

            Spacer()

            Button(action: action) {
                NotoSwitch(isOn: isOn)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityLabel(title)
            .accessibilityValue(isOn ? "켜짐" : "꺼짐")
        }
        .padding(.vertical, subtitle == nil ? 14 : 9)
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Divider()
            .overlay(DesignTokens.Colors.divider.opacity(0.85))
    }
}

private struct NotoSwitch: View {
    let isOn: Bool

    var body: some View {
        Capsule()
            .fill(isOn ? DesignTokens.Colors.primary : DesignTokens.Colors.toggleOff)
            .frame(width: DesignTokens.Size.settingsToggleWidth, height: DesignTokens.Size.settingsToggleHeight)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(Color.white)
                    .frame(width: DesignTokens.Size.settingsToggleKnob, height: DesignTokens.Size.settingsToggleKnob)
                    .shadow(color: Color.black.opacity(0.20), radius: 2, x: 0, y: 1)
                    .padding(2)
            }
    }
}

private struct ThemePickerRow: View {
    let selectedTheme: TaskPanelSettings.Theme
    let onTheme: (TaskPanelSettings.Theme) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("테마 · THEME")
                .font(DesignTokens.Typography.labelMono)
                .foregroundStyle(DesignTokens.Colors.labelMuted)

            HStack(spacing: 0) {
                ForEach(TaskPanelSettings.Theme.allCases) { theme in
                    Button(action: { onTheme(theme) }) {
                        Text(theme.rawValue)
                            .font(DesignTokens.Typography.sans(size: 12, weight: theme == selectedTheme ? .semibold : .regular))
                            .foregroundStyle(theme == selectedTheme ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: 30)
                            .background(themeBackground(for: theme))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                    .fill(DesignTokens.Colors.segmentControlSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                    .stroke(DesignTokens.Colors.hairline.opacity(0.8), lineWidth: 0.7)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private func themeBackground(for theme: TaskPanelSettings.Theme) -> some View {
        Group {
            if theme == selectedTheme {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .fill(DesignTokens.Colors.segmentSelectedSurface)
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 1)
            } else {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .fill(Color.clear)
            }
        }
    }
}

private struct ShortcutSettingRow: View {
    let hotKey: TaskPanelHotKey
    @Binding var isRecording: Bool
    let onHotKey: (TaskPanelHotKey) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            SettingsSectionLabel(title: "단축키", meta: "HOTKEY")

            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("핫키 변경")
                        .font(DesignTokens.Typography.sans(size: 13, weight: .semibold))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text("단축키로 패널을 열고 닫아요.")
                        .font(DesignTokens.Typography.sans(size: 11, weight: .regular))
                        .foregroundStyle(DesignTokens.Colors.labelMuted)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Button {
                    isRecording = true
                } label: {
                    Text(isRecording ? "입력 중..." : hotKey.displayText)
                        .font(DesignTokens.Typography.sans(size: 12, weight: .semibold))
                        .foregroundStyle(isRecording ? DesignTokens.Colors.destructive : DesignTokens.Colors.primaryDeep)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .frame(minWidth: 88)
                        .frame(height: 30)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                                .fill(isRecording ? DesignTokens.Colors.rowDeleteSurface : DesignTokens.Colors.keyCapSurface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                                .stroke(
                                    isRecording ? DesignTokens.Colors.destructive.opacity(0.55) : DesignTokens.Colors.hairline.opacity(0.85),
                                    lineWidth: 0.7
                                )
                        )
                }
                .buttonStyle(.plain)
                .background(
                    HotKeyRecorderView(
                        isRecording: $isRecording,
                        onCapture: { nextHotKey in
                            onHotKey(nextHotKey)
                            isRecording = false
                        },
                        onCancel: {
                            isRecording = false
                        }
                    )
                    .frame(width: 0, height: 0)
                )
            }
            .padding(.vertical, 3)
        }
    }
}

private struct HotKeyRecorderView: NSViewRepresentable {
    @Binding var isRecording: Bool
    let onCapture: (TaskPanelHotKey) -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> HotKeyRecorderNSView {
        let view = HotKeyRecorderNSView()
        view.onCapture = onCapture
        view.onCancel = onCancel
        view.configure(isRecording: isRecording)
        return view
    }

    func updateNSView(_ nsView: HotKeyRecorderNSView, context: Context) {
        nsView.onCapture = onCapture
        nsView.onCancel = onCancel
        nsView.configure(isRecording: isRecording)
    }

    static func dismantleNSView(_ nsView: HotKeyRecorderNSView, coordinator: ()) {
        nsView.configure(isRecording: false)
    }
}

private final class HotKeyRecorderNSView: NSView {
    var onCapture: ((TaskPanelHotKey) -> Void)?
    var onCancel: (() -> Void)?

    private var isRecording = false
    private var keyMonitor: Any?

    override var acceptsFirstResponder: Bool {
        true
    }

    func configure(isRecording: Bool) {
        guard self.isRecording != isRecording else { return }
        self.isRecording = isRecording

        if isRecording {
            startMonitoring()
        } else {
            stopMonitoring()
        }
    }

    private func startMonitoring() {
        guard keyMonitor == nil else { return }
        window?.makeFirstResponder(self)

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isRecording else { return event }

            if event.keyCode == 53 {
                self.onCancel?()
                return nil
            }

            guard let hotKey = TaskPanelHotKey(event: event) else {
                NSSound.beep()
                return nil
            }

            self.onCapture?(hotKey)
            return nil
        }
    }

    private func stopMonitoring() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
        }

        keyMonitor = nil
        if window?.firstResponder === self {
            window?.makeFirstResponder(nil)
        }
    }

    deinit {
        stopMonitoring()
    }
}

private struct SupportSectionView: View {
    let onFeedback: () -> Void
    let onShare: () -> Void
    let onRate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            SettingsDivider()

            SettingsSectionLabel(title: "지원", meta: "SUPPORT")
                .padding(.top, 6)

            SupportActionRow(title: "문의 및 피드백", systemName: "arrow.up.right.square", action: onFeedback)
            SupportActionRow(title: "앱 공유하기", systemName: "square.and.arrow.up", action: onShare)
            SupportActionRow(title: "별점 선물하기", action: onRate) {
                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 9, weight: .semibold))
                    }
                }
                .foregroundStyle(DesignTokens.Colors.rating)
            }
        }
    }
}

private struct SettingsSectionLabel: View {
    let title: String
    let meta: String

    var body: some View {
        Text("\(title)  ·  \(meta)")
            .font(DesignTokens.Typography.labelMono)
            .foregroundStyle(DesignTokens.Colors.labelMuted)
    }
}

private struct SupportActionRow<Trailing: View>: View {
    let title: String
    let action: () -> Void
    let trailing: Trailing

    init(title: String, systemName: String, action: @escaping () -> Void) where Trailing == Image {
        self.title = title
        self.action = action
        self.trailing = Image(systemName: systemName)
    }

    init(title: String, action: @escaping () -> Void, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.action = action
        self.trailing = trailing()
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(DesignTokens.Typography.sans(size: 13, weight: .semibold))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Spacer(minLength: 12)

                trailing
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                    .frame(minWidth: 50, alignment: .trailing)
            }
            .frame(minHeight: 26)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TaskPanelView(viewModel: .sample(), onCollapse: {}, onHotKeyRecordingChange: { _ in })
        .padding(40)
        .background(DesignTokens.Colors.documentBackground)
}
