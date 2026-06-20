//
//  DesignTokens.swift
//  Noto
//

import SwiftUI

enum DesignTokens {
    enum Colors {
        static let panelSurface = Color(hex: 0xF9F7F2)
        static let panelSurfaceGlass = Color(hex: 0xF9F7F2, opacity: 0.92)

        static let characterTop = Color(hex: 0xFFFEFB)
        static let characterMid = Color(hex: 0xF4F0E7)
        static let characterBottom = Color(hex: 0xECE5D8)

        static let textPrimary = Color(hex: 0x2A2823)
        static let textSecondary = Color(hex: 0x5A554B)
        static let textTertiary = Color(hex: 0x7C776C)
        static let textMuted = Color(hex: 0x9A958A)
        static let textCompleted = Color(hex: 0xABA69B)

        static let labelMuted = Color(hex: 0xA39E92)
        static let labelQuiet = Color(hex: 0xB3AEA2)

        static let primary = Color(hex: 0x4A6B78)
        static let primaryDeep = Color(hex: 0x3A5560)
        static let progressGradientStart = Color(hex: 0x5E7F8A)
        static let primaryGradientStart = Color(hex: 0x5A7B86)
        static let primaryGradientEnd = Color(hex: 0x3F606B)

        static let destructive = Color(hex: 0xB0573F)
        static let destructiveHover = Color(hex: 0x9C4A34)
        static let rating = Color(hex: 0xD99A1D)

        static let divider = Color(hex: 0x2A2823, opacity: 0.07)
        static let hairline = Color(hex: 0x2A2823, opacity: 0.08)
        static let controlSurface = Color(hex: 0x2A2823, opacity: 0.05)
        static let rowHoverSurface = Color(hex: 0x2A2823, opacity: 0.045)
        static let rowDeleteSurface = Color(hex: 0xB0573F, opacity: 0.08)
        static let checkboxBorder = Color(hex: 0x2A2823, opacity: 0.22)
        static let toggleOff = Color(hex: 0x2A2823, opacity: 0.16)
        static let modalOverlay = Color(hex: 0x26221A, opacity: 0.30)
        static let onPrimary = Color.white

        static let documentBackground = Color(hex: 0xE7E3DA)
        static let desktopMockGradient = LinearGradient(
            colors: [
                Color(hex: 0xDBD4C6),
                Color(hex: 0xC9C8BF),
                Color(hex: 0xAEB4B1)
            ],
            startPoint: UnitPoint(x: 0.05, y: 0),
            endPoint: UnitPoint(x: 0.95, y: 1)
        )
    }

    enum Typography {
        private static let sansFamily = "IBM Plex Sans KR"
        private static let monoFamily = "IBM Plex Mono"

        static let display = sans(size: 34, weight: .semibold)
        static let panelTitle = sans(size: 15, weight: .semibold)
        static let body = sans(size: 13, weight: .regular)
        static let bodyStrong = sans(size: 13.5, weight: .medium)
        static let input = sans(size: 12.5, weight: .regular)
        static let button = sans(size: 13, weight: .semibold)
        static let secondaryButton = sans(size: 13, weight: .medium)
        static let modalTitle = sans(size: 14.5, weight: .semibold)
        static let modalBody = sans(size: 12, weight: .regular)
        static let labelMono = mono(size: 9, weight: .medium)
        static let percent = mono(size: 15, weight: .semibold)
        static let badge = mono(size: 10.5, weight: .semibold)
        static let settingsMeta = mono(size: 10, weight: .regular)

        static func sans(size: CGFloat, weight: Font.Weight) -> Font {
            .custom(sansFamily, size: size).weight(weight)
        }

        static func mono(size: CGFloat, weight: Font.Weight) -> Font {
            .custom(monoFamily, size: size).weight(weight)
        }
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
    }

    enum Size {
        static let panelWidth: CGFloat = 300
        static let panelHeight: CGFloat = 440
        static let settingsPanelHeight: CGFloat = 360
        static let placementPanelHeight: CGFloat = 432
        static let characterSize: CGFloat = 58
        static let characterFloatOffset: CGFloat = 5
        static let panelGap: CGFloat = 12
        static let screenClampPadding: CGFloat = 12
        static let desktopMenuBarInset: CGFloat = 30
        static let badgeMinWidth: CGFloat = 20
        static let badgeHeight: CGFloat = 20
        static let checkboxSize: CGFloat = 21
        static let headerIconButton: CGFloat = 27
        static let quickAddMic: CGFloat = 30
        static let settingsToggleWidth: CGFloat = 34
        static let settingsToggleHeight: CGFloat = 20
        static let settingsToggleKnob: CGFloat = 16
        static let modalWidth: CGFloat = 248
        static let modalIconSize: CGFloat = 40
    }

    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 9
        static let xl: CGFloat = 10
        static let input: CGFloat = 11
        static let panel: CGFloat = 16
        static let modal: CGFloat = 15
        static let badge: CGFloat = 10
        static let toggle: CGFloat = 10
    }

    enum Motion {
        static let floatDuration: TimeInterval = 4.5
        static let blinkDuration: TimeInterval = 4.2
        static let pressedScale: CGFloat = 0.94
        static let panelOpenDuration: TimeInterval = 0.18
        static let panelOpenInitialScale: CGFloat = 0.94
        static let modalOpenDuration: TimeInterval = 0.16
        static let modalOpenInitialScale: CGFloat = 0.95
        static let progressDuration: TimeInterval = 0.35
    }
}

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
