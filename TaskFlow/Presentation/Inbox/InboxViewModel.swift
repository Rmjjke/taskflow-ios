// InboxViewModel.swift
// TaskFlow — Presentation Layer
//
// Drives the InboxView. Owns all business logic for the Inbox screen:
// task list state, completion, deletion, and undo flows.
//
// Architecture: MVVM — ViewModel is @Observable so SwiftUI auto-tracks
// property reads for minimal re-renders.

import Foundation
import Observation

@Observable
@MainActor
final class InboxViewModel {

    // MARK: - Dependencies

    private let repository: TaskRepositoryProtocol

    // MARK: - Published State

    /// Active (non-deleted, non-completed) tasks shown in the main list.
    private(set) var activeTasks: [TaskItem] = []

    /// Completed tasks shown in the collapsible "Completed" section.
    private(set) var completedTasks: [TaskItem] = []

    /// Controls whether the Quick-Add sheet is presented.
    var isShowingQuickAdd: Bool = false

    /// Controls whether the Completed section is expanded.
    var isCompletedSectionExpanded: Bool = false

    /// Controls whether the Settings sheet is presented.
    var isShowingSettings: Bool = false

    /// Toast message displayed after complete or delete actions.
    var toastMessage: ToastMessage? = nil

    /// Error surfaced to the view (e.g., persistence failure).
    var errorMessage: String? = nil

    // MARK: - Undo State (internal)

    private var lastCompletedTaskId: UUID? = nil
    private var lastDeletedTaskId: UUID? = nil
    private var toastDismissTask: _Concurrency.Task<Void, Never>? = nil

    // MARK: - Init

    init(repository: TaskRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Lifecycle

    /// Called when the view appears. Loads tasks and runs trash maintenance.
    func onAppear() {
        loadTasks()
        runMaintenanceTasks()
    }

    // MARK: - Data Loading

    func loadTasks() {
        do {
            let all = try repository.fetchActive()
            activeTasks   = all.filter { !$0.isCompleted }
            completedTasks = all.filter { $0.isCompleted }
                                .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
        } catch {
            errorMessage = "Failed to load tasks."
        }
    }

    // MARK: - Task Completion (US-03)

    func completeTask(id: UUID) {
        do {
            try repository.complete(id: id)
            lastCompletedTaskId = id
            loadTasks()
            showToast(.init(message: "Task completed.", actionLabel: "Undo", action: undoComplete))
        } catch {
            errorMessage = "Could not complete task."
        }
    }

    func undoComplete() {
        guard let id = lastCompletedTaskId else { return }
        do {
            try repository.uncomplete(id: id)
            lastCompletedTaskId = nil
            loadTasks()
            dismissToast()
        } catch {
            errorMessage = "Could not undo completion."
        }
    }

    // MARK: - Task Deletion (US-04)

    func deleteTask(id: UUID) {
        do {
            try repository.softDelete(id: id)
            lastDeletedTaskId = id
            loadTasks()
            showToast(.init(message: "Task deleted.", actionLabel: "Undo", action: undoDelete))
        } catch {
            errorMessage = "Could not delete task."
        }
    }

    func undoDelete() {
        guard let id = lastDeletedTaskId else { return }
        do {
            try repository.restore(id: id)
            lastDeletedTaskId = nil
            loadTasks()
            dismissToast()
        } catch {
            errorMessage = "Could not restore task."
        }
    }

    // MARK: - Toast

    private func showToast(_ toast: ToastMessage) {
        toastDismissTask?.cancel()
        toastMessage = toast
        toastDismissTask = _Concurrency.Task {
            try? await _Concurrency.Task.sleep(for: .seconds(4))
            guard !_Concurrency.Task.isCancelled else { return }
            dismissToast()
        }
    }

    func dismissToast() {
        toastDismissTask?.cancel()
        toastMessage = nil
    }

    // MARK: - Maintenance

    private func runMaintenanceTasks() {
        _Concurrency.Task.detached(priority: .background) { [weak self] in
            try? self?.repository.purgeExpiredTrash()
        }
    }
}

// MARK: - Supporting Types

/// Data for the undo toast shown after complete/delete actions.
struct ToastMessage: Identifiable {
    let id = UUID()
    let message: String
    let actionLabel: String
    let action: () -> Void
}
