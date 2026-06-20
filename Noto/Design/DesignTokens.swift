//
//  DesignTokens.swift
//  Noto
//

import AppKit
import SwiftUI

enum DesignTokens {
    enum Colors {
        static let panelSurface = Color(light: 0xF9F7F2, dark: 0x201F1C)
        static let panelSurfaceGlass = Color(light: 0xF9F7F2, dark: 0x201F1C, lightOpacity: 0.92, darkOpacity: 0.94)

        static let characterTop = Color(light: 0xFFFEFB, dark: 0xFFFEFB)
        static let characterMid = Color(light: 0xF4F0E7, dark: 0xF4F0E7)
        static let characterBottom = Color(light: 0xECE5D8, dark: 0xECE5D8)
        static let characterInk = Color(hex: 0x2A2823)
        static let characterHairline = Color(hex: 0x2A2823, opacity: 0.07)

        static let textPrimary = Color(light: 0x2A2823, dark: 0xECE7DC)
        static let textSecondary = Color(light: 0x5A554B, dark: 0xB6B0A4)
        static let textTertiary = Color(light: 0x7C776C, dark: 0x8F8773)
        static let textMuted = Color(light: 0x9A958A, dark: 0x8F8773)
        static let textCompleted = Color(light: 0xABA69B, dark: 0x8F8773)

        static let labelMuted = Color(light: 0xA39E92, dark: 0x8F8773)
        static let labelQuiet = Color(light: 0xB3AEA2, dark: 0x8F8773)

        static let primary = Color(light: 0x4A6B78, dark: 0x6E97A4)
        static let primaryDeep = Color(light: 0x3A5560, dark: 0x9DBEC8)
        static let progressGradientStart = Color(light: 0x5E7F8A, dark: 0x6E97A4)
        static let primaryGradientStart = Color(light: 0x5A7B86, dark: 0x9DBEC8)
        static let primaryGradientEnd = Color(light: 0x3F606B, dark: 0x6E97A4)

        static let destructive = Color(light: 0xB0573F, dark: 0xDB7E5E)
        static let destructiveHover = Color(light: 0x9C4A34, dark: 0xC96F53)
        static let rating = Color(light: 0xD99A1D, dark: 0xD99A1D)

        static let divider = Color(light: 0x2A2823, dark: 0xFFFFFF, lightOpacity: 0.07, darkOpacity: 0.08)
        static let hairline = Color(light: 0x2A2823, dark: 0xFFFFFF, lightOpacity: 0.08, darkOpacity: 0.10)
        static let controlSurface = Color(light: 0x2A2823, dark: 0xFFFFFF, lightOpacity: 0.05, darkOpacity: 0.10)
        static let rowHoverSurface = Color(light: 0x2A2823, dark: 0xFFFFFF, lightOpacity: 0.045, darkOpacity: 0.08)
        static let rowDeleteSurface = Color(light: 0xB0573F, dark: 0xDB7E5E, lightOpacity: 0.08, darkOpacity: 0.18)
        static let checkboxBorder = Color(light: 0x2A2823, dark: 0xECE7DC, lightOpacity: 0.22, darkOpacity: 0.36)
        static let toggleOff = Color(light: 0x2A2823, dark: 0xFFFFFF, lightOpacity: 0.16, darkOpacity: 0.22)
        static let modalOverlay = Color(light: 0x26221A, dark: 0x000000, lightOpacity: 0.30, darkOpacity: 0.46)
        static let segmentControlSurface = Color(light: 0x2A2823, dark: 0xFFFFFF, lightOpacity: 0.04, darkOpacity: 0.07)
        static let segmentSelectedSurface = Color(light: 0xFFFFFF, dark: 0x3F3B34, lightOpacity: 0.72, darkOpacity: 0.88)
        static let keyCapSurface = Color(light: 0xFFFFFF, dark: 0xFFFFFF, lightOpacity: 0.72, darkOpacity: 0.08)
        static let modalSecondaryButtonSurface = Color(light: 0xFFFFFF, dark: 0xFFFFFF, lightOpacity: 0.48, darkOpacity: 0.03)
        static let onPrimary = Color.white
        static let onDestructive = Color(light: 0xFFFFFF, dark: 0x201F1C)

        static let documentBackground = Color(light: 0xE7E3DA, dark: 0x26262B)
        static let desktopMockGradient = LinearGradient(
            colors: [
                Color(light: 0xDBD4C6, dark: 0x26262B),
                Color(light: 0xC9C8BF, dark: 0x201F1C),
                Color(light: 0xAEB4B1, dark: 0x343F3F)
            ],
            startPoint: UnitPoint(x: 0.05, y: 0),
            endPoint: UnitPoint(x: 0.95, y: 1)
        )
    }

    enum AppKitColors {
        static let textPrimary = NSColor(light: 0x2A2823, dark: 0xECE7DC)
        static let placeholder = NSColor(light: 0x9A958A, dark: 0x8F8773)
        static let goalPlaceholder = NSColor(light: 0x7C776C, dark: 0x8F8773)
        static let insertionPoint = NSColor(light: 0x4A6B78, dark: 0x9DBEC8)
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
        static let modalMinHeight: CGFloat = 184
        static let modalButtonHeight: CGFloat = 40
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

    init(light: UInt, dark: UInt, lightOpacity: Double = 1, darkOpacity: Double? = nil) {
        self.init(nsColor: NSColor(light: light, dark: dark, lightAlpha: lightOpacity, darkAlpha: darkOpacity ?? lightOpacity))
    }
}

extension NSColor {
    convenience init(light: UInt, dark: UInt, lightAlpha: Double = 1, darkAlpha: Double? = nil) {
        self.init(name: nil) { appearance in
            let colorScheme = appearance.bestMatch(from: [.darkAqua, .aqua])
            let usesDarkPalette = colorScheme == .darkAqua
            return NSColor.notoStatic(
                hex: usesDarkPalette ? dark : light,
                alpha: usesDarkPalette ? CGFloat(darkAlpha ?? lightAlpha) : CGFloat(lightAlpha)
            )
        }
    }

    private static func notoStatic(hex: UInt, alpha: CGFloat) -> NSColor {
        NSColor(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
