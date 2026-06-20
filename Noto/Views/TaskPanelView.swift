//
//  TaskPanelView.swift
//  Noto
//

import SwiftUI

struct TaskPanelView: View {
    @ObservedObject var viewModel: TaskPanelViewModel
    let onCollapse: () -> Void

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
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            .shadow(color: Color.black.opacity(0.30), radius: 44, x: 0, y: 20)

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
    }

    private var listPanel: some View {
        VStack(spacing: 0) {
            TaskHeaderView(
                onDeleteAll: viewModel.requestDeleteAll,
                onSettings: viewModel.showSettings,
                onCollapse: onCollapse
            )

            GoalInputView(goal: $viewModel.goal)
                .padding(.horizontal, DesignTokens.Spacing.lg)

            Divider()
                .overlay(DesignTokens.Colors.divider)
                .padding(.top, 8)

            ProgressSummaryView(progress: viewModel.progress)
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.top, 8)

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
                            onDelete: { viewModel.showDeletingState(task) }
                        )
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.top, 12)

            QuickAddView(
                text: $viewModel.quickAddText,
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
            onTheme: viewModel.setTheme
        )
    }

    private var panelSurface: some View {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.panel, style: .continuous)
            .fill(DesignTokens.Colors.panelSurfaceGlass)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.panel, style: .continuous))
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

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("목표 · GOAL")
                .font(DesignTokens.Typography.labelMono)
                .foregroundStyle(DesignTokens.Colors.labelMuted)

            TextField("오늘의 목표를 입력하세요", text: $goal)
                .font(DesignTokens.Typography.bodyStrong)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .textFieldStyle(.plain)
                .lineLimit(1)
        }
        .frame(height: 44, alignment: .topLeading)
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

private struct TaskRowView: View {
    let task: SampleTask
    let isEditing: Bool
    let isDeleting: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onCommitEdit: (String) -> Void
    let onDelete: () -> Void

    @State private var draftTitle = ""
    @State private var isHovering = false

    private var showsActions: Bool {
        isHovering || isEditing || isDeleting
    }

    var body: some View {
        HStack(spacing: 7) {
            Group {
                if showsActions {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                        .frame(width: 8)
                } else {
                    Color.clear.frame(width: 8)
                }
            }

            Button(action: onToggle) {
                CheckboxView(isDone: task.isDone)
            }
            .buttonStyle(.plain)

            if isEditing {
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignTokens.Colors.primary)

                TextField("", text: $draftTitle)
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .textFieldStyle(.plain)
                    .lineLimit(1)
                    .onSubmit {
                        onCommitEdit(draftTitle)
                    }
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
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 4)

            if showsActions {
                HStack(spacing: 4) {
                    if !isEditing && !task.isDone {
                        RowIconButton(systemName: "pencil", color: DesignTokens.Colors.primary, action: onEdit)
                    }

                    RowIconButton(systemName: "trash", color: DesignTokens.Colors.destructive, action: onDelete)
                }
                .transition(.opacity)
            }
        }
        .padding(7)
        .frame(height: 35)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .onHover { isHovering = $0 }
        .onAppear {
            draftTitle = task.title
        }
        .onChange(of: isEditing) { _, newValue in
            if newValue {
                draftTitle = task.title
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

private struct QuickAddView: View {
    @Binding var text: String
    let onSubmit: () -> Void
    let onMic: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("다음 할 일은?", text: $text)
                .font(DesignTokens.Typography.input)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .textFieldStyle(.plain)
                .onSubmit(onSubmit)

            Button(action: onMic) {
                Image(systemName: "mic.fill")
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
            .accessibilityLabel("음성 입력")
        }
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
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.panel, style: .continuous))

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(DesignTokens.Colors.rowDeleteSurface)
                        .frame(width: DesignTokens.Size.modalIconSize, height: DesignTokens.Size.modalIconSize)

                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DesignTokens.Colors.destructive)
                }

                VStack(spacing: 5) {
                    Text("모든 할 일을 삭제할까요?")
                        .font(DesignTokens.Typography.modalTitle)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text("이 작업은 되돌릴 수 없습니다.")
                        .font(DesignTokens.Typography.modalBody)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }

                HStack(spacing: 8) {
                    Button("취소", action: onCancel)
                        .font(DesignTokens.Typography.secondaryButton)
                        .foregroundStyle(DesignTokens.Colors.primaryDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                                .fill(Color.white.opacity(0.48))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                                        .stroke(DesignTokens.Colors.hairline, lineWidth: 1)
                                )
                        )
                        .buttonStyle(.plain)

                    Button("삭제", action: onDelete)
                        .font(DesignTokens.Typography.button)
                        .foregroundStyle(DesignTokens.Colors.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                                .fill(DesignTokens.Colors.destructive)
                        )
                        .buttonStyle(.plain)
                }
            }
            .padding(DesignTokens.Spacing.xl)
            .frame(width: DesignTokens.Size.modalWidth)
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

private struct SettingsPanelView: View {
    let settings: TaskPanelSettings
    let onBack: () -> Void
    let onCollapse: () -> Void
    let onToggleLogin: () -> Void
    let onToggleOnTop: () -> Void
    let onToggleSound: () -> Void
    let onTheme: (TaskPanelSettings.Theme) -> Void

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
                .padding(.bottom, 4)

            VStack(spacing: 0) {
                SettingsToggleRow(title: "로그인 시 실행", subtitle: "Launch at login", isOn: settings.launchAtLogin, action: onToggleLogin)
                SettingsDivider()
                SettingsToggleRow(title: "항상 위에 표시", subtitle: "Always on top", isOn: settings.keepOnTop, action: onToggleOnTop)
                SettingsDivider()
                SettingsToggleRow(title: "완료 효과음", subtitle: "Completion sound", isOn: settings.completionSound, action: onToggleSound)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)

            ThemePickerRow(selectedTheme: settings.theme, onTheme: onTheme)
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.top, 8)

            Button(action: {}) {
                HStack {
                    Text("위치 초기화")
                        .font(DesignTokens.Typography.body)
                    Spacer()
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(DesignTokens.Colors.primaryDeep)
                .padding(.vertical, 9)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .buttonStyle(.plain)

            Spacer(minLength: 12)

            VStack(spacing: 5) {
                HStack {
                    Text("VERSION")
                    Spacer()
                    Text("0.1.0")
                }
                HStack {
                    Text("SHORTCUT")
                    Spacer()
                    Text("⌥ Space 로 열기")
                }
            }
            .font(DesignTokens.Typography.settingsMeta)
            .foregroundStyle(DesignTokens.Colors.textMuted)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, 16)
        }
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(DesignTokens.Typography.sans(size: 13, weight: .medium))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text(subtitle)
                        .font(DesignTokens.Typography.sans(size: 11, weight: .regular))
                        .foregroundStyle(DesignTokens.Colors.labelMuted)
                }

                Spacer()

                NotoSwitch(isOn: isOn)
            }
            .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
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
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                                    .fill(theme == selectedTheme ? Color.white.opacity(0.72) : Color.clear)
                                    .shadow(color: theme == selectedTheme ? Color.black.opacity(0.08) : Color.clear, radius: 4, x: 0, y: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 8)
        .background(alignment: .bottom) {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .fill(DesignTokens.Colors.controlSurface)
                .frame(height: 31)
        }
    }
}

#Preview {
    TaskPanelView(viewModel: .sample(), onCollapse: {})
        .padding(40)
        .background(DesignTokens.Colors.documentBackground)
}
