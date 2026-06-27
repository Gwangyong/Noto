//
//  TaskPanelViewModel.swift
//  Noto
//

import Combine
import Foundation

final class TaskPanelViewModel: ObservableObject {
    @Published var goal: String
    @Published var tasks: [SampleTask]
    @Published var quickAddText: String
    @Published var screen: TaskPanelScreen
    @Published var editingTaskID: SampleTask.ID?
    @Published var deletingTaskID: SampleTask.ID?
    @Published var showingDeleteAllConfirm: Bool
    @Published var settings: TaskPanelSettings

    var onSnapshotChange: ((TaskPanelSnapshot) -> Void)?
    private var isApplyingSnapshot = false

    init(
        goal: String,
        tasks: [SampleTask],
        quickAddText: String = "",
        screen: TaskPanelScreen = .list,
        editingTaskID: SampleTask.ID? = nil,
        deletingTaskID: SampleTask.ID? = nil,
        showingDeleteAllConfirm: Bool = false,
        settings: TaskPanelSettings
    ) {
        self.goal = goal
        self.tasks = tasks
        self.quickAddText = quickAddText
        self.screen = screen
        self.editingTaskID = editingTaskID
        self.deletingTaskID = deletingTaskID
        self.showingDeleteAllConfirm = showingDeleteAllConfirm
        self.settings = settings
    }

    var snapshot: TaskPanelSnapshot {
        TaskPanelSnapshot(goal: goal, tasks: tasks, settings: settings)
    }

    var progress: Int {
        guard !tasks.isEmpty else { return 0 }
        let doneCount = tasks.filter(\.isDone).count
        guard doneCount < tasks.count else { return 100 }

        let roundedProgress = Int((Double(doneCount) / Double(tasks.count) * 100).rounded())
        return min(99, roundedProgress)
    }

    var remainingCount: Int {
        tasks.filter { !$0.isDone }.count
    }

    static func empty() -> TaskPanelViewModel {
        TaskPanelViewModel(
            goal: "",
            tasks: [],
            settings: TaskPanelSettings(
                launchAtLogin: true,
                keepOnTop: true,
                completionSound: false,
                showsMenuBarIcon: true,
                theme: .system,
                hotKey: .default
            )
        )
    }

    static func sample() -> TaskPanelViewModel {
        empty()
    }

    func applySnapshot(_ snapshot: TaskPanelSnapshot) {
        isApplyingSnapshot = true
        goal = snapshot.goal
        tasks = snapshot.tasks
        settings = snapshot.settings
        quickAddText = ""
        editingTaskID = nil
        deletingTaskID = nil
        showingDeleteAllConfirm = false
        screen = .list
        isApplyingSnapshot = false
    }

    func persistSnapshot() {
        guard !isApplyingSnapshot else { return }
        onSnapshotChange?(snapshot)
    }

    @discardableResult
    func toggleDone(_ task: SampleTask) -> Bool {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return false }
        tasks[index].isDone.toggle()
        persistSnapshot()
        return tasks[index].isDone
    }

    func beginEditing(_ task: SampleTask) {
        editingTaskID = task.id
        deletingTaskID = nil
    }

    func commitEditing(_ task: SampleTask, title: String) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let shouldPersist = tasks[index].title != trimmed
            tasks[index].title = trimmed
            if shouldPersist {
                persistSnapshot()
            }
        }
        editingTaskID = nil
    }

    func showDeletingState(_ task: SampleTask) {
        deletingTaskID = task.id
        editingTaskID = nil
    }

    func beginReordering(_ task: SampleTask) {
        guard tasks.contains(where: { $0.id == task.id }) else { return }
        editingTaskID = nil
        deletingTaskID = nil
    }

    func moveTask(draggingID: SampleTask.ID, over targetID: SampleTask.ID) {
        guard draggingID != targetID,
              let sourceIndex = tasks.firstIndex(where: { $0.id == draggingID }),
              let targetIndex = tasks.firstIndex(where: { $0.id == targetID })
        else { return }

        let task = tasks.remove(at: sourceIndex)
        tasks.insert(task, at: targetIndex)
        persistSnapshot()
    }

    func deleteTask(_ task: SampleTask) {
        let previousCount = tasks.count
        tasks.removeAll { $0.id == task.id }
        if editingTaskID == task.id {
            editingTaskID = nil
        }
        if deletingTaskID == task.id {
            deletingTaskID = nil
        }
        if tasks.count != previousCount {
            persistSnapshot()
        }
    }

    func addQuickTask() {
        let trimmed = quickAddText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks.append(SampleTask(title: trimmed, isDone: false))
        quickAddText = ""
        persistSnapshot()
    }

    func showSettings() {
        screen = .settings
        editingTaskID = nil
        deletingTaskID = nil
        showingDeleteAllConfirm = false
    }

    func showList() {
        screen = .list
    }

    func requestDeleteAll() {
        screen = .list
        showingDeleteAllConfirm = true
    }

    func cancelDeleteAll() {
        showingDeleteAllConfirm = false
    }

    func confirmDeleteAll() {
        let shouldPersist = !tasks.isEmpty
        tasks.removeAll()
        editingTaskID = nil
        deletingTaskID = nil
        showingDeleteAllConfirm = false
        if shouldPersist {
            persistSnapshot()
        }
    }

    func setLaunchAtLogin(_ isEnabled: Bool) {
        guard settings.launchAtLogin != isEnabled else { return }
        settings.launchAtLogin = isEnabled
        persistSnapshot()
    }

    func toggleKeepOnTop() {
        settings.keepOnTop.toggle()
        persistSnapshot()
    }

    func toggleCompletionSound() {
        settings.completionSound.toggle()
        persistSnapshot()
    }

    func toggleMenuBarIcon() {
        settings.showsMenuBarIcon.toggle()
        persistSnapshot()
    }

    func setTheme(_ theme: TaskPanelSettings.Theme) {
        guard settings.theme != theme else { return }
        settings.theme = theme
        persistSnapshot()
    }

    func setHotKey(_ hotKey: TaskPanelHotKey) {
        guard settings.hotKey != hotKey else { return }
        settings.hotKey = hotKey
        persistSnapshot()
    }
}
