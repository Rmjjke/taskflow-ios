// TaskActionHandler.swift
// TaskFlow — Common / ViewModels
//
// Shared write-operation handler used by TodayView, ScheduledView, and ArchiveView.
// Handles: complete, uncomplete, soft-delete, restore, undo, and toast lifecycle.
// Read operations are handled by each view's @Query properties for full reactivity.
//
// Spec: US-03 (complete/undo), US-04 (delete/undo), US-M6 AC-M6.4 (reopen).

import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class TaskActionHandler {

    // MARK: - Dependencies

    let repository: TaskRepositoryProtocol

    // MARK: - Toast State

    var toastMessage: ToastMessage? = nil

    // MARK: - Delete Confirmation

    /// Set when a task with notes is about to be deleted — triggers the alert (AC-04.1).
    var taskPendingDeleteConfirmation: TaskItem? = nil

    // MARK: - Stay-Delay Completion Animation (AC-03.2)

    /// IDs currently in the 400ms "stay" window after being marked complete.
    private(set) var pendingCompletionIds: Set<UUID> = []

    // MARK: - Undo References

    private var lastCompletedId: UUID? = nil
    private var lastDeletedId:   UUID? = nil
    private var toastDismissWork: _Concurrency.Task<Void, Never>? = nil

    // MARK: - Init

    init(repository: TaskRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - US-03: Complete

    func completeTask(id: UUID) {
        do {
            try repository.complete(id: id)
            lastCompletedId = id
            HapticManager.success()

            // Phase 1 — keep row visible with strikethrough for 400ms (AC-03.2)
            pendingCompletionIds.insert(id)

            // Phase 2 — remove after delay so @Query animates the row out
            _Concurrency.Task { [weak self] in
                try? await _Concurrency.Task.sleep(for: .milliseconds(400))
                withAnimation(.easeOut(duration: 0.3)) {
                    self?.pendingCompletionIds.remove(id)
                }
            }

            showToast(ToastMessage(
                message: "Task completed.",
                actionLabel: "Undo",
                action: { [weak self] in self?.undoComplete() }
            ))
        } catch { }
    }

    func undoComplete() {
        guard let id = lastCompletedId else { return }
        try? repository.uncomplete(id: id)
        pendingCompletionIds.remove(id)
        lastCompletedId = nil
        dismissToast()
    }

    // MARK: - US-M6: Reopen (Archive → Today)

    func reopenTask(id: UUID) {
        try? repository.uncomplete(id: id)
        HapticManager.impact(.light)
        showToast(ToastMessage(
            message: "Task reopened.",
            actionLabel: "",
            action: {}
        ))
    }

    // MARK: - US-04: Delete

    /// Routes to immediate delete or notes-confirmation alert (AC-04.1).
    func requestDelete(task: TaskItem) {
        if task.hasNotes {
            taskPendingDeleteConfirmation = task
        } else {
            performDelete(id: task.id)
        }
    }

    func confirmDelete() {
        guard let task = taskPendingDeleteConfirmation else { return }
        taskPendingDeleteConfirmation = nil
        performDelete(id: task.id)
    }

    func cancelDelete() {
        taskPendingDeleteConfirmation = nil
    }

    private func performDelete(id: UUID) {
        try? repository.softDelete(id: id)
        lastDeletedId = id
        showToast(ToastMessage(
            message: "Task deleted.",
            actionLabel: "Undo",
            action: { [weak self] in self?.undoDelete() }
        ))
    }

    func undoDelete() {
        guard let id = lastDeletedId else { return }
        try? repository.restore(id: id)
        lastDeletedId = nil
        dismissToast()
    }

    // MARK: - Toast

    func showToast(_ toast: ToastMessage) {
        toastDismissWork?.cancel()
        toastMessage = toast
        toastDismissWork = _Concurrency.Task { [weak self] in
            try? await _Concurrency.Task.sleep(for: .seconds(4))
            guard !_Concurrency.Task.isCancelled else { return }
            self?.dismissToast()
        }
    }

    func dismissToast() {
        toastDismissWork?.cancel()
        toastMessage = nil
    }
}
