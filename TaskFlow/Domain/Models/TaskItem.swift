// TaskItem.swift
// TaskFlow — Domain Layer
//
// The core data model for a single unit of work.
// Named `TaskItem` to avoid collision with Swift's `Task` concurrency type.
//
// Field specification per PRD US-01 AC-01.6.
// Persisted via SwiftData (local-only in MVP; CloudKit added in v1.0).

import Foundation
import SwiftData

@Model
final class TaskItem {

    // MARK: - Identity

    /// Stable unique identifier. Used for navigation, undo references, and
    /// future CloudKit record naming.
    @Attribute(.unique) var id: UUID

    // MARK: - Core Fields

    /// Required. Maximum 255 characters (AC-01.2).
    var title: String

    /// Optional plain-text notes. Rich-text deferred to v1.1 (US-06).
    var notes: String?

    // MARK: - Scheduling

    /// Optional due date. Stored as a single Date combining calendar date.
    /// `nil` = no due date.
    var dueDate: Date?

    /// Optional due time component. Stored separately so that date-only
    /// tasks can be grouped as "No Time" in the Today view (AC-02.3).
    var dueTime: Date?

    // MARK: - Classification

    /// Four-level priority. Default `.none` (AC-05.2).
    /// Stored as Int (rawValue) by SwiftData.
    var priorityRaw: Int

    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .none }
        set { priorityRaw = newValue.rawValue }
    }

    /// Foreign key to a Project. `nil` means the task lives in Inbox (FR-07).
    /// Projects are introduced in v1.0 — reserved here for schema stability.
    var projectId: UUID?

    /// Free-form tags for cross-project filtering (v1.0, US-08).
    var tags: [String]

    // MARK: - State

    /// Whether the task has been completed.
    var isCompleted: Bool

    /// Timestamp of completion. Used for sorting the Completed section (AC-03.3).
    var completedAt: Date?

    // MARK: - Soft Delete

    /// Soft-delete flag. Deleted tasks are excluded from all live queries
    /// and shown only in the Trash view (US-04, AC-04.2).
    var isDeleted: Bool

    /// Timestamp of soft deletion. Tasks older than 30 days are auto-purged
    /// on app launch (AC-04.4).
    var deletedAt: Date?

    // MARK: - Audit

    /// Creation timestamp. Used as the default sort key in Inbox.
    var createdAt: Date

    /// Last-mutation timestamp. Required for CloudKit last-write-wins
    /// conflict resolution (v1.0).
    var updatedAt: Date

    // MARK: - Init

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        dueTime: Date? = nil,
        priority: Priority = .none,
        projectId: UUID? = nil,
        tags: [String] = [],
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        isDeleted: Bool = false,
        deletedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.dueTime = dueTime
        self.priorityRaw = priority.rawValue
        self.projectId = projectId
        self.tags = tags
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.isDeleted = isDeleted
        self.deletedAt = deletedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Helpers

    /// True when the task has non-empty notes content.
    /// Used to show the note indicator in task rows (AC-06.3) and to trigger
    /// the deletion confirmation (AC-04.1).
    var hasNotes: Bool {
        guard let notes else { return false }
        return !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// True when the due date is in the past (before start of today).
    /// Overdue tasks are highlighted in red in the Today view (AC-02.5).
    var isOverdue: Bool {
        guard let dueDate else { return false }
        return dueDate < Calendar.current.startOfDay(for: Date())
    }

    /// Updates `updatedAt` to now. Must be called on every mutation so that
    /// CloudKit conflict resolution works correctly in v1.0.
    func touch() {
        updatedAt = Date()
    }
}
