//
//  TaskPanelStore.swift
//  Noto
//

import Foundation
import CoreGraphics
import SwiftData

@MainActor
final class TaskPanelStore {
    private let modelContext: ModelContext
    private let primaryKey = "primary"

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadOrSeed(default defaultSnapshot: TaskPanelSnapshot) throws -> TaskPanelSnapshot {
        let storedGoalState = try goalState()
        let storedPreference = try appPreference()
        let taskItems = try taskItems()
        let isFirstLaunch = storedGoalState == nil && storedPreference == nil && taskItems.isEmpty
        let goalState = storedGoalState ?? insertGoalState(text: defaultSnapshot.goal)
        let preference = storedPreference ?? insertAppPreference(settings: defaultSnapshot.settings)

        if isFirstLaunch {
            insertTasks(defaultSnapshot.tasks)
            try modelContext.save()
            return defaultSnapshot
        }

        return TaskPanelSnapshot(
            goal: goalState.text,
            tasks: taskItems.map { taskItem in
                SampleTask(id: taskItem.id, title: taskItem.title, isDone: taskItem.isDone)
            },
            settings: TaskPanelSettings(
                launchAtLogin: preference.launchAtLogin,
                keepOnTop: preference.keepOnTop,
                completionSound: preference.completionSound,
                showsMenuBarIcon: preference.showsMenuBarIcon,
                characterKind: preference.characterKind,
                theme: preference.theme,
                hotKey: preference.hotKey
            )
        )
    }

    func save(_ snapshot: TaskPanelSnapshot) throws {
        let goalState = try goalState() ?? insertGoalState(text: snapshot.goal)
        goalState.text = snapshot.goal
        goalState.updatedAt = .now

        let preference = try appPreference() ?? insertAppPreference(settings: snapshot.settings)
        preference.launchAtLogin = snapshot.settings.launchAtLogin
        preference.keepOnTop = snapshot.settings.keepOnTop
        preference.completionSound = snapshot.settings.completionSound
        preference.showsMenuBarIcon = snapshot.settings.showsMenuBarIcon
        preference.characterKind = snapshot.settings.characterKind
        preference.theme = snapshot.settings.theme
        preference.hotKey = snapshot.settings.hotKey
        preference.updatedAt = .now

        try saveTasks(snapshot.tasks)
        try modelContext.save()
    }

    func loadCharacterOrigin() throws -> CGPoint? {
        guard let preference = try appPreference(),
              let x = preference.characterOriginX,
              let y = preference.characterOriginY
        else {
            return nil
        }

        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }

    func saveCharacterOrigin(_ origin: CGPoint, settings: TaskPanelSettings) throws {
        let preference = try appPreference() ?? insertAppPreference(settings: settings)
        preference.characterOriginX = Double(origin.x)
        preference.characterOriginY = Double(origin.y)
        preference.updatedAt = .now
        try modelContext.save()
    }

    private func taskItems() throws -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            sortBy: [
                SortDescriptor(\.sortOrder),
                SortDescriptor(\.createdAt)
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    private func goalState() throws -> GoalState? {
        var descriptor = FetchDescriptor<GoalState>(
            predicate: #Predicate<GoalState> { state in
                state.key == "primary"
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func appPreference() throws -> AppPreference? {
        var descriptor = FetchDescriptor<AppPreference>(
            predicate: #Predicate<AppPreference> { preference in
                preference.key == "primary"
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func insertGoalState(text: String) -> GoalState {
        let goalState = GoalState(key: primaryKey, text: text)
        modelContext.insert(goalState)
        return goalState
    }

    private func insertAppPreference(settings: TaskPanelSettings) -> AppPreference {
        let preference = AppPreference(
            key: primaryKey,
            launchAtLogin: settings.launchAtLogin,
            keepOnTop: settings.keepOnTop,
            completionSound: settings.completionSound,
            showsMenuBarIcon: settings.showsMenuBarIcon,
            characterKind: settings.characterKind,
            theme: settings.theme,
            hotKey: settings.hotKey
        )
        modelContext.insert(preference)
        return preference
    }

    private func insertTasks(_ tasks: [SampleTask]) {
        for (index, task) in tasks.enumerated() {
            modelContext.insert(
                TaskItem(
                    id: task.id,
                    title: task.title,
                    isDone: task.isDone,
                    sortOrder: Double(index)
                )
            )
        }
    }

    private func saveTasks(_ tasks: [SampleTask]) throws {
        let existingItems = try taskItems()
        var itemByID = Dictionary(uniqueKeysWithValues: existingItems.map { ($0.id, $0) })
        let activeIDs = Set(tasks.map(\.id))

        for item in existingItems where !activeIDs.contains(item.id) {
            modelContext.delete(item)
        }

        for (index, task) in tasks.enumerated() {
            let item = itemByID[task.id] ?? TaskItem(id: task.id, title: task.title, sortOrder: Double(index))
            item.title = task.title
            item.isDone = task.isDone
            item.sortOrder = Double(index)
            item.updatedAt = .now

            if itemByID[task.id] == nil {
                modelContext.insert(item)
                itemByID[task.id] = item
            }
        }
    }
}
