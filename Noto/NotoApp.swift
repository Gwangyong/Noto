//
//  NotoApp.swift
//  Noto
//
import AppKit
import Combine
import SwiftData
import SwiftUI

@main
struct NotoApp: App {
    private let floatingPanelController = FloatingPanelController()
    @StateObject private var modelContainerState = SwiftDataContainerState()

    init() {
        AppFontRegistrar.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            if let modelContainer = modelContainerState.modelContainer {
                FloatingPanelLauncher(
                    modelContainer: modelContainer,
                    panelController: floatingPanelController
                )
            } else {
                SwiftDataContainerFailureView(modelContainerState: modelContainerState)
            }
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
    }
}

@MainActor
private final class SwiftDataContainerState: ObservableObject {
    @Published private(set) var modelContainer: ModelContainer?

    init() {
        retry()
    }

    func retryAfterAlertDismissal() {
        DispatchQueue.main.async { [weak self] in
            self?.retry()
        }
    }

    private func retry() {
        do {
            modelContainer = try Self.makeModelContainer()
        } catch {
            modelContainer = nil

            #if DEBUG
            print("Noto SwiftData container creation failed: \(error)")
            #endif
        }
    }

    private static func makeModelContainer() throws -> ModelContainer {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--simulate-swiftdata-container-failure") {
            throw SwiftDataContainerStartupError.simulatedFailure
        }
        #endif

        let schema = Schema([
            TaskItem.self,
            GoalState.self,
            AppPreference.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    }
}

private enum SwiftDataContainerStartupError: Error {
    case simulatedFailure
}

private struct SwiftDataContainerFailureView: View {
    @ObservedObject var modelContainerState: SwiftDataContainerState

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(DesignTokens.Colors.destructive)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(DesignTokens.Colors.destructive.opacity(0.12))
                )

            VStack(spacing: 5) {
                Text("데이터를 불러오지 못했어요")
                    .font(DesignTokens.Typography.modalTitle)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text("로컬 데이터를 여는 중 문제가 발생했어요. 잠시 후 다시 시도해주세요.")
                    .font(DesignTokens.Typography.modalBody)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                Button("앱 종료") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(FailureActionButtonStyle(role: .secondary))

                Button("다시 시도") {
                    modelContainerState.retryAfterAlertDismissal()
                }
                .buttonStyle(FailureActionButtonStyle(role: .primary))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(width: 286)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.modal, style: .continuous)
                .fill(DesignTokens.Colors.panelSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.modal, style: .continuous)
                .stroke(DesignTokens.Colors.hairline, lineWidth: 1)
        )
        .background(
            FloatingWindowAccessor { window in
                configureFailureWindow(window)
            }
        )
    }

    private func configureFailureWindow(_ window: NSWindow) {
        window.title = ""
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.isMovableByWindowBackground = true
    }
}

private struct FailureActionButtonStyle: ButtonStyle {
    enum Role {
        case primary
        case secondary
    }

    let role: Role

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(role == .primary ? DesignTokens.Typography.button : DesignTokens.Typography.secondaryButton)
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .stroke(borderColor, lineWidth: role == .primary ? 0 : 1)
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
    }

    private var foregroundColor: Color {
        switch role {
        case .primary:
            return DesignTokens.Colors.onDestructive
        case .secondary:
            return DesignTokens.Colors.textSecondary
        }
    }

    private var backgroundColor: Color {
        switch role {
        case .primary:
            return DesignTokens.Colors.destructive
        case .secondary:
            return DesignTokens.Colors.modalSecondaryButtonSurface
        }
    }

    private var borderColor: Color {
        switch role {
        case .primary:
            return .clear
        case .secondary:
            return DesignTokens.Colors.hairline
        }
    }
}
