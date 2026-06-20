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
    var themeRawValue: String
    var updatedAt: Date

    init(
        key: String = "primary",
        launchAtLogin: Bool = true,
        keepOnTop: Bool = true,
        completionSound: Bool = false,
        theme: TaskPanelSettings.Theme = .system,
        updatedAt: Date = .now
    ) {
        self.key = key
        self.launchAtLogin = launchAtLogin
        self.keepOnTop = keepOnTop
        self.completionSound = completionSound
        self.themeRawValue = theme.rawValue
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
}
