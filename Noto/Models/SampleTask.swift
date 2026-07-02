//
//  SampleTask.swift
//  Noto
//

import Foundation

enum FloatingCharacterAnimationSlot: String, CaseIterable, Identifiable {
    case idle
    case blink
    case sleepy
    case alert
    case success
    case thinking
    case dragged

    var id: String { rawValue }
}

enum FloatingCharacterKind: String, CaseIterable, Identifiable {
    case noto
    case miniEarth
    case catLoaf
    case smallRobot
    case moonPiece

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .noto:
            return "Noto"
        case .miniEarth:
            return "지구"
        case .catLoaf:
            return "고양이"
        case .smallRobot:
            return "로봇"
        case .moonPiece:
            return "달"
        }
    }

    var accessibilityName: String {
        switch self {
        case .noto:
            return "Noto 기본 캐릭터"
        case .miniEarth:
            return "미니 지구"
        case .catLoaf:
            return "고양이 loaf"
        case .smallRobot:
            return "작은 로봇"
        case .moonPiece:
            return "달 조각"
        }
    }

    var animationSlots: [FloatingCharacterAnimationSlot] {
        FloatingCharacterAnimationSlot.allCases
    }
}

struct SampleTask: Identifiable, Equatable {
    let id: UUID
    var title: String
    var isDone: Bool

    init(id: UUID = UUID(), title: String, isDone: Bool) {
        self.id = id
        self.title = title
        self.isDone = isDone
    }
}

struct TaskPanelSnapshot: Equatable {
    var goal: String
    var tasks: [SampleTask]
    var settings: TaskPanelSettings
}

struct TaskPanelSettings: Equatable {
    var launchAtLogin: Bool
    var keepOnTop: Bool
    var completionSound: Bool
    var showsMenuBarIcon: Bool
    var characterKind: FloatingCharacterKind
    var theme: Theme
    var hotKey: TaskPanelHotKey

    enum Theme: String, CaseIterable, Identifiable {
        case system = "시스템"
        case light = "라이트"
        case dark = "다크"

        var id: String { rawValue }
    }
}

enum TaskPanelScreen: Equatable {
    case list
    case settings
}
