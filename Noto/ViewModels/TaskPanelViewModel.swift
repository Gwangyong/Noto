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

    static func sample() -> TaskPanelViewModel {
        TaskPanelViewModel(
            goal: "발표 끝내고 디자인 리뷰까지",
            tasks: [
                SampleTask(id: 1, title: "디자인 시스템 토큰 정리", isDone: true),
                SampleTask(id: 2, title: "컴포넌트 라이브러리 업데이트", isDone: false),
                SampleTask(id: 3, title: "클라이언트 발표 자료 준비", isDone: false),
                SampleTask(id: 4, title: "모닝 루틴 · 하루 계획", isDone: true),
                SampleTask(id: 5, title: "그리드 시스템 리팩토링", isDone: false)
            ],
            settings: TaskPanelSettings(
                launchAtLogin: true,
                keepOnTop: true,
                completionSound: false,
                theme: .system
            )
        )
    }

    func toggleDone(_ task: SampleTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isDone.toggle()
    }

    func beginEditing(_ task: SampleTask) {
        editingTaskID = task.id
        deletingTaskID = nil
    }

    func commitEditing(_ task: SampleTask, title: String) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            tasks[index].title = trimmed
        }
        editingTaskID = nil
    }

    func showDeletingState(_ task: SampleTask) {
        deletingTaskID = task.id
        editingTaskID = nil
    }

    func deleteTask(_ task: SampleTask) {
        tasks.removeAll { $0.id == task.id }
        if editingTaskID == task.id {
            editingTaskID = nil
        }
        if deletingTaskID == task.id {
            deletingTaskID = nil
        }
    }

    func addQuickTask() {
        let trimmed = quickAddText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let nextID = (tasks.map(\.id).max() ?? 0) + 1
        tasks.append(SampleTask(id: nextID, title: trimmed, isDone: false))
        quickAddText = ""
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
        tasks.removeAll()
        editingTaskID = nil
        deletingTaskID = nil
        showingDeleteAllConfirm = false
    }

    func toggleLaunchAtLogin() {
        settings.launchAtLogin.toggle()
    }

    func toggleKeepOnTop() {
        settings.keepOnTop.toggle()
    }

    func toggleCompletionSound() {
        settings.completionSound.toggle()
    }

    func setTheme(_ theme: TaskPanelSettings.Theme) {
        settings.theme = theme
    }
}
