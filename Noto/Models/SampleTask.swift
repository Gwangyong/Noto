//
//  SampleTask.swift
//  Noto
//

import Foundation

struct SampleTask: Identifiable, Equatable {
    let id: Int
    var title: String
    var isDone: Bool
}

struct TaskPanelSettings: Equatable {
    var launchAtLogin: Bool
    var keepOnTop: Bool
    var completionSound: Bool
    var theme: Theme

    enum Theme: String, CaseIterable, Identifiable {
        case system = "시스템"
        case light = "라이트"
        case dark = "다크"

        var id: String { rawValue }
    }
}

enum TaskPanelScreen {
    case list
    case settings
}
