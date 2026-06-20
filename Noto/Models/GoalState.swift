//
//  GoalState.swift
//  Noto
//

import Foundation
import SwiftData

@Model
final class GoalState {
    @Attribute(.unique) var key: String
    var text: String
    var updatedAt: Date

    init(key: String = "primary", text: String = "", updatedAt: Date = .now) {
        self.key = key
        self.text = text
        self.updatedAt = updatedAt
    }
}
