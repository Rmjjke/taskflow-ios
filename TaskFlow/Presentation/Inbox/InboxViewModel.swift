// InboxViewModel.swift
// TaskFlow — Presentation Layer
//
// Drives the InboxView. Single source of business logic for:
// task list state, completion, deletion, undo, and toast flow.
//
// Architecture: @Observable ViewModel on @MainActor.

import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class InboxViewModel {

    // MARK: - Dependencies

    /// Internal so InboxView can pass it to child ViewModels (QuickAdd, TaskDetail).
    let repository: TaskRepositoryProtocol

    // MARK: - Published State

    /// Active (non-deleted, non-completed) tasks shown in the main list.
    private(set) var activeTasks: [TaskItem] = []

    /// Completed tasks shown in the collapsible "Completed" section (AC-03.3).
    private(set) var completedTasks: [TaskItem] = []

    /// IDs of tasks that have been completed but are still rendering in the
    /// active list during the 400ms "stay" delay (AC-03.2).
    private(set) var pendingCompletionIds: Set<UUID> = []

    var isShowingQuickAdd: Bool = false
    var isCompletedSectionExpanded: Bool = false
    var isShowingSettings: Bool = false

    /// Toast shown after complete / delete (AC-03.4, AC-04.3).
    var toastMessage: ToastMessage? = nil

    /// Task awaiting a notes-confirmation before deletion (AC-04.1).
    var taskPendingDeleteConfirmation: TaskItem? = nil

    var errorMessage: String? = nil

    // MARK: - Undo References

    private var lastCompletedTaskId: UUID? = nil
    private var lastDeletedTaskId: UUID? = nil
    private var toastDismissTask: _Concurrency.Task<Void, Never>? = nil

    // MARK: - Init

    init(repository: TaskRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Lifecycle

    func onAppear() {
        loadTasks()
        runMaintenanceTasks()
    }

    // MARK: - Data Loading

    func loadTasks() {
        do {
            let all = try repository.fetchActive()
            // Rebuild active list — keep tasks in pendingCompletionIds visible
            // so the stay-delay animation can run to completion (AC-03.2).
            let active = all.filter { !$0.isCompleted || pendingCompletionIds.contains($0.id) }
            activeTasks = active

            completedTasks = all
                .filter { $0.isCompleted && !pendingCompletionIds.contains($0.id) }
                .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
        } catch {
            errorMessage = "Failed to load tasks."
        }
    }

    // MARK: - US-03: Complete a Task

    func completeTask(id: UUID) {
        do {
            try repository.complete(id: id)
            lastCompletedTaskId = id

            // Fire haptic immediately on completion (AC-03.2).
            HapticManager.success()

            // Phase 1 — mark as pending so the row stays visible with
            // strikethrough for 400ms before disappearing (AC-03.2).
            pendingCompletionIds.insert(id)
            loadTasks()

            // Phase 2 — after 400ms remove the pending ID → triggers
            // SwiftUI to animate the row out of activeTasks (600ms total).
            _Concurrency.Task { [weak self] in
                try? await _Concurrency.Task.sleep(for: .milliseconds(400))
                withAnimation(.easeOut(duration: 0.3)) {
                    self?.pendingCompletionIds.remove(id)
                    self?.loadTasks()
                }
            }

            showToast(ToastMessage(
                message: "Task completed.",
                actionLabel: "Undo",
                action: { [weak self] in self?.undoComplete() }
            ))
        } catch {
            errorMessage = "Could not complete task."
        }
    }

    func undoComplete() {
        guard let id = lastCompletedTaskId else { return }
        do {
            try repository.uncomplete(id: id)
            lastCompletedTaskId = nil
            // Cancel any pending animation for this task.
            pendingCompletionIds.remove(id)
            loadTasks()
            dismissToast()
        } catch {
            errorMessage = "Could not undo completion."
        }
    }

    // MARK: - US-04: Delete a Task

    /// Entry point from swipe-left action.
    /// If the task has notes, sets `taskPendingDeleteConfirmation` so
    /// InboxView can show a confirmation alert (AC-04.1).
    func requestDelete(task: TaskItem) {
        if task.hasNotes {
            taskPendingDeleteConfirmation = task
        } else {
            performDelete(id: task.id)
        }
    }

    /// Called from the confirmation alert's destructive button (AC-04.1).
    func confirmDelete() {
        guard let task = taskPendingDeleteConfirmation else { return }
        taskPendingDeleteConfirmation = nil
        performDelete(id: task.id)
    }

    func cancelDelete() {
        taskPendingDeleteConfirmation = nil
    }

    private func performDelete(id: UUID) {
        do {
            try repository.softDelete(id: id)
            lastDeletedTaskId = id
            loadTasks()
            showToast(ToastMessage(
                message: "Task deleted.",
                actionLabel: "Undo",
                action: { [weak self] in self?.undoDelete() }
            ))
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
        toastDismissTask = _Concurrency.Task { [weak self] in
            try? await _Concurrency.Task.sleep(for: .seconds(4))
            guard !_Concurrency.Task.isCancelled else { return }
            self?.dismissToast()
        }
    }

    func dismissToast() {
        toastDismissTask?.cancel()
        toastMessage = nil
    }

    // MARK: - Maintenance (AC-04.4)

    /// Trash auto-purge on launch. TaskRepository is @MainActor-bound so
    /// this runs on the main actor — the operation is fast (a few row deletions).
    private func runMaintenanceTasks() {
        _Concurrency.Task { [weak self] in
            try? self?.repository.purgeExpiredTrash()
        }
    }
}

// MARK: - ToastMessage

struct ToastMessage: Identifiable {
    let id = UUID()
    let message: String
    let actionLabel: String
    let action: () -> Void
}
