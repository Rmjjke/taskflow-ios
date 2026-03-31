// TaskRepository.swift
// TaskFlow — Domain Layer
//
// Concrete SwiftData implementation of TaskRepositoryProtocol.
// This is the **single source of truth** for all task data in the app (PRD §5).
//
// Threading: All operations run on the caller's actor. SwiftData's ModelContext
// is not Sendable — callers must ensure they access this repository from the
// correct actor (typically @MainActor in ViewModels).

import Foundation
import SwiftData

final class TaskRepository: TaskRepositoryProtocol {

    // MARK: - Dependencies

    private let modelContext: ModelContext

    // MARK: - Init

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Read

    func fetchActive() throws -> [TaskItem] {
        let predicate = #Predicate<TaskItem> { $0.isDeleted == false }
        let sort = [SortDescriptor<TaskItem>(\.createdAt, order: .reverse)]
        let descriptor = FetchDescriptor<TaskItem>(predicate: predicate, sortBy: sort)
        return try modelContext.fetch(descriptor)
    }

    func fetchTrashed() throws -> [TaskItem] {
        let predicate = #Predicate<TaskItem> { $0.isDeleted == true }
        let sort = [SortDescriptor<TaskItem>(\.deletedAt, order: .reverse)]
        let descriptor = FetchDescriptor<TaskItem>(predicate: predicate, sortBy: sort)
        return try modelContext.fetch(descriptor)
    }

    func fetch(id: UUID) throws -> TaskItem? {
        let predicate = #Predicate<TaskItem> { $0.id == id && $0.isDeleted == false }
        var descriptor = FetchDescriptor<TaskItem>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
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
        let task = TaskItem(
            title: title,
            notes: notes,
            dueDate: dueDate,
            dueTime: dueTime,
            priority: priority,
            projectId: projectId,
            tags: tags
        )
        modelContext.insert(task)
        try modelContext.save()
        return task
    }

    // MARK: - Update

    func complete(id: UUID) throws {
        guard let task = try fetch(id: id) else { return }
        task.isCompleted = true
        task.completedAt = Date()
        task.touch()
        try modelContext.save()
    }

    func uncomplete(id: UUID) throws {
        guard let task = try fetch(id: id) else { return }
        task.isCompleted = false
        task.completedAt = nil
        task.touch()
        try modelContext.save()
    }

    func updateTitle(_ title: String, for id: UUID) throws {
        guard let task = try fetch(id: id) else { return }
        task.title = title
        task.touch()
        try modelContext.save()
    }

    func updateNotes(_ notes: String?, for id: UUID) throws {
        guard let task = try fetch(id: id) else { return }
        task.notes = notes
        task.touch()
        try modelContext.save()
    }

    func updateDueDate(_ date: Date?, time: Date?, for id: UUID) throws {
        guard let task = try fetch(id: id) else { return }
        task.dueDate = date
        task.dueTime = time
        task.touch()
        try modelContext.save()
    }

    func updatePriority(_ priority: Priority, for id: UUID) throws {
        guard let task = try fetch(id: id) else { return }
        task.priority = priority
        task.touch()
        try modelContext.save()
    }

    // MARK: - Delete

    func softDelete(id: UUID) throws {
        guard let task = try fetch(id: id) else { return }
        task.isDeleted = true
        task.deletedAt = Date()
        task.touch()
        try modelContext.save()
    }

    func restore(id: UUID) throws {
        // Must fetch including deleted items for restore
        let predicate = #Predicate<TaskItem> { $0.id == id }
        var descriptor = FetchDescriptor<TaskItem>(predicate: predicate)
        descriptor.fetchLimit = 1
        guard let task = try modelContext.fetch(descriptor).first else { return }
        task.isDeleted = false
        task.deletedAt = nil
        task.touch()
        try modelContext.save()
    }

    func permanentlyDelete(id: UUID) throws {
        let predicate = #Predicate<TaskItem> { $0.id == id }
        var descriptor = FetchDescriptor<TaskItem>(predicate: predicate)
        descriptor.fetchLimit = 1
        guard let task = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(task)
        try modelContext.save()
    }

    func emptyTrash() throws {
        let trashed = try fetchTrashed()
        trashed.forEach { modelContext.delete($0) }
        try modelContext.save()
    }

    // MARK: - Maintenance

    func purgeExpiredTrash() throws {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        // SwiftData #Predicate does not support force-unwrap or nil-coalescing on
        // Optional properties, so we fetch all soft-deleted items and filter in-memory.
        let predicate = #Predicate<TaskItem> { $0.isDeleted == true }
        let descriptor = FetchDescriptor<TaskItem>(predicate: predicate)
        let trashed = try modelContext.fetch(descriptor)
        let expired = trashed.filter { ($0.deletedAt ?? Date()) < cutoff }
        expired.forEach { modelContext.delete($0) }
        if !expired.isEmpty {
            try modelContext.save()
        }
    }
}
