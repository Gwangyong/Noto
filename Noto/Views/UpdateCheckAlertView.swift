//
//  UpdateCheckAlertView.swift
//  Noto
//

import SwiftUI

enum UpdateCheckAlert: Equatable {
    case upToDate(currentVersion: String)
    case updateAvailable(currentVersion: String, latestVersion: String, appStoreURL: URL?)
    case failed(message: String)
}

struct UpdateCheckAlertView: View {
    let alert: UpdateCheckAlert
    let onDismiss: () -> Void
    let onOpenStore: (URL?) -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.panel, style: .continuous)
                .fill(DesignTokens.Colors.modalOverlay)

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconSurface)
                        .frame(width: DesignTokens.Size.modalIconSize, height: DesignTokens.Size.modalIconSize)

                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                VStack(spacing: 6) {
                    Text(title)
                        .font(DesignTokens.Typography.modalTitle)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text(message)
                        .font(DesignTokens.Typography.modalBody)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if case .updateAvailable(_, _, let appStoreURL) = alert {
                    HStack(spacing: 8) {
                        ModalActionButton(
                            title: "나중에",
                            font: DesignTokens.Typography.secondaryButton,
                            foreground: DesignTokens.Colors.primaryDeep,
                            background: DesignTokens.Colors.modalSecondaryButtonSurface,
                            stroke: DesignTokens.Colors.hairline,
                            action: onDismiss
                        )

                        ModalActionButton(
                            title: "스토어 열기",
                            font: DesignTokens.Typography.button,
                            foreground: DesignTokens.Colors.onPrimary,
                            background: DesignTokens.Colors.primary,
                            action: { onOpenStore(appStoreURL) }
                        )
                    }
                } else {
                    ModalActionButton(
                        title: "확인",
                        font: DesignTokens.Typography.button,
                        foreground: DesignTokens.Colors.onPrimary,
                        background: DesignTokens.Colors.primary,
                        action: onDismiss
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
                    .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 12)
            )
        }
    }

    private var iconName: String {
        switch alert {
        case .upToDate:
            return "checkmark"
        case .updateAvailable:
            return "arrow.down"
        case .failed:
            return "exclamationmark"
        }
    }

    private var iconSurface: Color {
        switch alert {
        case .upToDate, .updateAvailable:
            return DesignTokens.Colors.primary.opacity(0.14)
        case .failed:
            return DesignTokens.Colors.rowDeleteSurface
        }
    }

    private var iconColor: Color {
        switch alert {
        case .upToDate, .updateAvailable:
            return DesignTokens.Colors.primary
        case .failed:
            return DesignTokens.Colors.destructive
        }
    }

    private var title: String {
        switch alert {
        case .upToDate:
            return "최신 버전을 사용 중입니다."
        case .updateAvailable:
            return "새 버전이 나왔어요"
        case .failed:
            return "업데이트를 확인하지 못했어요"
        }
    }

    private var message: String {
        switch alert {
        case .upToDate(let currentVersion):
            return "현재 사용 중인 \(currentVersion) 버전이 최신입니다."
        case .updateAvailable(let currentVersion, let latestVersion, _):
            return "현재 \(currentVersion) 버전을 사용 중이에요.\n\(latestVersion) 버전으로 업데이트할 수 있습니다."
        case .failed(let message):
            return "\(message)\n잠시 후 다시 시도해주세요."
        }
    }
}
