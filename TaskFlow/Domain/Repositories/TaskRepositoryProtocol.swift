// TaskRepositoryProtocol.swift
// TaskFlow — Domain Layer
//
// Defines the contract for all task persistence operations.
// Conforming to a protocol keeps ViewModels testable — tests inject a
// mock repository without touching SwiftData.
//
// All mutating methods are `throws` so callers can handle persistence errors.

import Foundation

protocol TaskRepositoryProtocol {

    // MARK: - Read

    /// Returns all active (non-deleted) tasks, sorted by creation date descending.
    func fetchActive() throws -> [TaskItem]

    /// Returns all soft-deleted tasks, sorted by deletedAt descending.
    func fetchTrashed() throws -> [TaskItem]

    /// Fetches a single task by its UUID. Returns `nil` if not found or deleted.
    func fetch(id: UUID) throws -> TaskItem?

    // MARK: - Create

    /// Creates and persists a new task with the given title and optional metadata.
    /// Returns the newly created `TaskItem`.
    @discardableResult
    func create(
        title: String,
        notes: String?,
        dueDate: Date?,
        dueTime: Date?,
        priority: Priority,
        projectId: UUID?,
        tags: [String]
    ) throws -> TaskItem

    // MARK: - Update

    /// Marks a task as complete. Sets `isCompleted = true` and `completedAt = Date()`.
    func complete(id: UUID) throws

    /// Reverses a completion. Sets `isCompleted = false`, `completedAt = nil`.
    func uncomplete(id: UUID) throws

    /// Updates the title of an existing task.
    func updateTitle(_ title: String, for id: UUID) throws

    /// Updates the notes of an existing task.
    func updateNotes(_ notes: String?, for id: UUID) throws

    /// Updates the due date/time of an existing task.
    func updateDueDate(_ date: Date?, time: Date?, for id: UUID) throws

    /// Updates the priority of an existing task.
    func updatePriority(_ priority: Priority, for id: UUID) throws

    // MARK: - Delete

    /// Soft-deletes a task. Sets `isDeleted = true`, `deletedAt = Date()`.
    func softDelete(id: UUID) throws

    /// Restores a soft-deleted task. Sets `isDeleted = false`, `deletedAt = nil`.
    func restore(id: UUID) throws

    /// Permanently removes a task from the store. Irreversible.
    func permanentlyDelete(id: UUID) throws

    /// Permanently removes all soft-deleted tasks. Used by "Empty Trash".
    func emptyTrash() throws

    // MARK: - Maintenance

    /// Purges tasks whose `deletedAt` is older than 30 days.
    /// Should be called once per app launch (AC-04.4).
    func purgeExpiredTrash() throws
}
