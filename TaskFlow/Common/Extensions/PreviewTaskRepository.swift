// PreviewTaskRepository.swift
// TaskFlow — Common / Extensions
//
// In-memory mock repository for SwiftUI Previews and unit tests.
// Implements TaskRepositoryProtocol without touching SwiftData.

import Foundation

final class PreviewTaskRepository: TaskRepositoryProtocol {

    // MARK: - In-Memory Store

    private var store: [TaskItem] = [
        TaskItem(title: "Review PRD feedback from design", priority: .high,
                 dueDate: Calendar.current.startOfDay(for: Date())),
        TaskItem(title: "Buy groceries for the week", priority: .medium,
                 dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())),
        TaskItem(title: "Schedule dentist appointment", priority: .none),
        {
            let t = TaskItem(title: "Read Swift Concurrency book")
            t.notes = "Chapter 5 onwards"
            return t
        }(),
        {
            let t = TaskItem(title: "Submit expense report", priority: .high,
                             dueDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()))
            t.isCompleted = true
            t.completedAt = Date()
            return t
        }()
    ]

    // MARK: - Read

    func fetchActive() throws -> [TaskItem] {
        store.filter { !$0.isDeleted }
    }

    func fetchTrashed() throws -> [TaskItem] {
        store.filter { $0.isDeleted }
    }

    func fetch(id: UUID) throws -> TaskItem? {
        store.first { $0.id == id && !$0.isDeleted }
    }

    // MARK: - Create

    @discardableResult
    func create(
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        dueTime: Date? = nil,
        priority: Priority = .none,
        projectId: UUID? = nil,
        tags: [String] = []
    ) throws -> TaskItem {
        let task = TaskItem(title: title, notes: notes, dueDate: dueDate,
                            dueTime: dueTime, priority: priority,
                            projectId: projectId, tags: tags)
        store.insert(task, at: 0)
        return task
    }

    // MARK: - Update

    func complete(id: UUID) throws {
        guard let task = try fetch(id: id) else { return }
        task.isCompleted = true
        task.completedAt = Date()
    }

    func uncomplete(id: UUID) throws {
        guard let task = try fetch(id: id) else { return }
        task.isCompleted = false
        task.completedAt = nil
    }

    func updateTitle(_ title: String, for id: UUID) throws {
        try fetch(id: id)?.title = title
    }

    func updateNotes(_ notes: String?, for id: UUID) throws {
        try fetch(id: id)?.notes = notes
    }

    func updateDueDate(_ date: Date?, time: Date?, for id: UUID) throws {
        guard let task = try fetch(id: id) else { return }
        task.dueDate = date
        task.dueTime = time
    }

    func updatePriority(_ priority: Priority, for id: UUID) throws {
        try fetch(id: id)?.priority = priority
    }

    // MARK: - Delete

    func softDelete(id: UUID) throws {
        guard let task = try fetch(id: id) else { return }
        task.isDeleted = true
        task.deletedAt = Date()
    }

    func restore(id: UUID) throws {
        guard let task = store.first(where: { $0.id == id }) else { return }
        task.isDeleted = false
        task.deletedAt = nil
    }

    func permanentlyDelete(id: UUID) throws {
        store.removeAll { $0.id == id }
    }

    func emptyTrash() throws {
        store.removeAll { $0.isDeleted }
    }

    func purgeExpiredTrash() throws {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        store.removeAll { $0.isDeleted && ($0.deletedAt ?? Date()) < cutoff }
    }
}
