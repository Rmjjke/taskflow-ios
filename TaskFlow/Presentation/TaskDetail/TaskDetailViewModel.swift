// TaskDetailViewModel.swift
// TaskFlow — Presentation Layer
//
// Drives the TaskDetailView. Handles inline editing of all task fields
// with auto-save debounce (AC-06.4).
// Spec: US-02 (due date), US-03 (complete), US-04 (delete), US-06 (notes).

import Foundation
import Observation

@Observable
@MainActor
final class TaskDetailViewModel {

    // MARK: - Dependencies

    private let taskId: UUID
    private let repository: TaskRepositoryProtocol

    // MARK: - State

    var task: TaskItem? = nil

    // Editable mirrors — changes are written back via auto-save
    var title: String = ""
    var notes: String = ""
    var dueDate: Date? = nil
    var dueTime: Date? = nil
    var hasTime: Bool = false
    var priority: Priority = .none

    var errorMessage: String? = nil
    var isSaved: Bool = false // brief "Saved" indicator (AC-06.4)

    // MARK: - Debounce

    private var saveTask: _Concurrency.Task<Void, Never>? = nil
    private let debounceDuration: Duration = .milliseconds(500)

    // MARK: - Init

    init(taskId: UUID, repository: TaskRepositoryProtocol) {
        self.taskId = taskId
        self.repository = repository
    }

    // MARK: - Lifecycle

    func onAppear() {
        loadTask()
    }

    // MARK: - Load

    func loadTask() {
        do {
            guard let loaded = try repository.fetch(id: taskId) else { return }
            task = loaded
            title = loaded.title
            notes = loaded.notes ?? ""
            dueDate = loaded.dueDate
            dueTime = loaded.dueTime
            hasTime = loaded.dueTime != nil
            priority = loaded.priority
        } catch {
            errorMessage = "Could not load task."
        }
    }

    // MARK: - Auto-save (AC-06.4)

    /// Debounced save — called from view's `.onChange` modifiers.
    func scheduleNoteSave() {
        saveTask?.cancel()
        saveTask = _Concurrency.Task { [weak self] in
            guard let self else { return }
            try? await _Concurrency.Task.sleep(for: self.debounceDuration)
            guard !_Concurrency.Task.isCancelled else { return }
            self.commitNotes()
        }
    }

    /// Immediate save for title (called on .onSubmit or focus loss).
    func commitTitle() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            try repository.updateTitle(title, for: taskId)
            flashSaved()
        } catch {
            errorMessage = "Could not save title."
        }
    }

    func commitNotes() {
        do {
            try repository.updateNotes(notes.isEmpty ? nil : notes, for: taskId)
            flashSaved()
        } catch {
            errorMessage = "Could not save notes."
        }
    }

    func commitDueDate() {
        do {
            try repository.updateDueDate(dueDate, time: hasTime ? dueTime : nil, for: taskId)
            loadTask()
        } catch {
            errorMessage = "Could not save due date."
        }
    }

    func commitPriority() {
        do {
            try repository.updatePriority(priority, for: taskId)
            loadTask()
        } catch {
            errorMessage = "Could not save priority."
        }
    }

    // MARK: - Complete / Delete

    func completeTask() {
        do {
            try repository.complete(id: taskId)
            loadTask()
        } catch {
            errorMessage = "Could not complete task."
        }
    }

    func uncompleteTask() {
        do {
            try repository.uncomplete(id: taskId)
            loadTask()
        } catch {
            errorMessage = "Could not uncomplete task."
        }
    }

    func deleteTask() {
        do {
            try repository.softDelete(id: taskId)
        } catch {
            errorMessage = "Could not delete task."
        }
    }

    // MARK: - Helpers

    private func flashSaved() {
        isSaved = true
        _Concurrency.Task { [weak self] in
            try? await _Concurrency.Task.sleep(for: .seconds(1.5))
            self?.isSaved = false
        }
    }
}
