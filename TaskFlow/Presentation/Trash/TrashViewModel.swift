// TrashViewModel.swift
// TaskFlow — Presentation Layer
//
// Drives the TrashView. Handles soft-deleted tasks.
// Spec: US-04 AC-04.4 (Trash view), AC-04.3 (restore), AC-04.4 (permanent delete, empty trash).

import Foundation
import Observation

@Observable
@MainActor
final class TrashViewModel {

    // MARK: - Dependencies

    private let repository: TaskRepositoryProtocol

    // MARK: - State

    private(set) var trashedTasks: [TaskItem] = []
    var showEmptyTrashConfirmation: Bool = false
    var errorMessage: String? = nil

    // MARK: - Init

    init(repository: TaskRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Lifecycle

    func onAppear() {
        loadTrashedTasks()
    }

    // MARK: - Data

    func loadTrashedTasks() {
        do {
            trashedTasks = try repository.fetchTrashed()
        } catch {
            errorMessage = "Could not load trash."
        }
    }

    // MARK: - Actions

    func restore(id: UUID) {
        do {
            try repository.restore(id: id)
            loadTrashedTasks()
        } catch {
            errorMessage = "Could not restore task."
        }
    }

    func permanentlyDelete(id: UUID) {
        do {
            try repository.permanentlyDelete(id: id)
            loadTrashedTasks()
        } catch {
            errorMessage = "Could not delete task."
        }
    }

    func emptyTrash() {
        do {
            try repository.emptyTrash()
            loadTrashedTasks()
        } catch {
            errorMessage = "Could not empty trash."
        }
    }
}
