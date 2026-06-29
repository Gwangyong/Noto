//
//  AppPreference.swift
//  Noto
//

import Foundation
import SwiftData

@Model
final class AppPreference {
    @Attribute(.unique) var key: String
    var launchAtLogin: Bool
    var keepOnTop: Bool
    var completionSound: Bool
    var showsMenuBarIcon: Bool = true
    var themeRawValue: String
    var hotKeyKeyCode: Int?
    var hotKeyModifiers: Int?
    var characterOriginX: Double?
    var characterOriginY: Double?
    var updatedAt: Date

    init(
        key: String = "primary",
        launchAtLogin: Bool = true,
        keepOnTop: Bool = true,
        completionSound: Bool = false,
        showsMenuBarIcon: Bool = true,
        theme: TaskPanelSettings.Theme = .system,
        hotKey: TaskPanelHotKey = .default,
        characterOriginX: Double? = nil,
        characterOriginY: Double? = nil,
        updatedAt: Date = .now
    ) {
        self.key = key
        self.launchAtLogin = launchAtLogin
        self.keepOnTop = keepOnTop
        self.completionSound = completionSound
        self.showsMenuBarIcon = showsMenuBarIcon
        self.themeRawValue = theme.rawValue
        self.hotKeyKeyCode = hotKey.keyCodeValue
        self.hotKeyModifiers = hotKey.modifierValue
        self.characterOriginX = characterOriginX
        self.characterOriginY = characterOriginY
        self.updatedAt = updatedAt
    }

    var theme: TaskPanelSettings.Theme {
        get {
            TaskPanelSettings.Theme(rawValue: themeRawValue) ?? .system
        }
        set {
            themeRawValue = newValue.rawValue
            updatedAt = .now
        }
    }

    var hotKey: TaskPanelHotKey {
        get {
            TaskPanelHotKey(keyCodeValue: hotKeyKeyCode, modifierValue: hotKeyModifiers) ?? .default
        }
        set {
            hotKeyKeyCode = newValue.keyCodeValue
            hotKeyModifiers = newValue.modifierValue
            updatedAt = .now
        }
    }
}
