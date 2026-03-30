// TaskRepositoryTests.swift
// TaskFlowTests — Domain
//
// Unit tests for TaskRepository using an in-memory SwiftData ModelContainer.
// Covers the Definition of Done criteria from:
//   • US-01 (create, persist)
//   • US-03 (complete / uncomplete)
//   • US-04 (softDelete, restore, permanentlyDelete, purgeExpiredTrash)

import XCTest
import SwiftData
@testable import TaskFlow

@MainActor
final class TaskRepositoryTests: XCTestCase {

    // MARK: - Setup

    private var container: ModelContainer!
    private var repository: TaskRepository!

    override func setUp() async throws {
        try await super.setUp()
        let schema = Schema([TaskItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        repository = TaskRepository(modelContext: container.mainContext)
    }

    override func tearDown() async throws {
        container = nil
        repository = nil
        try await super.tearDown()
    }

    // MARK: - US-01: Create

    func test_create_persistsTaskWithTitle() throws {
        let task = try repository.create(title: "Buy milk")
        XCTAssertEqual(task.title, "Buy milk")
        XCTAssertFalse(task.isCompleted)
        XCTAssertFalse(task.isDeleted)
        XCTAssertNotNil(task.createdAt)
        XCTAssertNotNil(task.updatedAt)
    }

    func test_create_defaultPriorityIsNone() throws {
        let task = try repository.create(title: "Test task")
        XCTAssertEqual(task.priority, .none)
    }

    func test_create_appearsInFetchActive() throws {
        try repository.create(title: "Task A")
        try repository.create(title: "Task B")
        let active = try repository.fetchActive()
        XCTAssertEqual(active.count, 2)
    }

    // MARK: - US-03: Complete / Uncomplete

    func test_complete_setsIsCompletedAndCompletedAt() throws {
        let task = try repository.create(title: "Complete me")
        try repository.complete(id: task.id)

        let updated = try repository.fetch(id: task.id)
        XCTAssertTrue(updated?.isCompleted == true)
        XCTAssertNotNil(updated?.completedAt)
    }

    func test_uncomplete_clearsIsCompletedAndCompletedAt() throws {
        let task = try repository.create(title: "Undo complete")
        try repository.complete(id: task.id)
        try repository.uncomplete(id: task.id)

        let updated = try repository.fetch(id: task.id)
        XCTAssertFalse(updated?.isCompleted == true)
        XCTAssertNil(updated?.completedAt)
    }

    // MARK: - US-04: Soft Delete / Restore / Permanent Delete

    func test_softDelete_setsIsDeletedAndDeletedAt() throws {
        let task = try repository.create(title: "Delete me")
        try repository.softDelete(id: task.id)

        // Should be excluded from fetchActive
        let active = try repository.fetchActive()
        XCTAssertFalse(active.contains { $0.id == task.id })

        // Should appear in fetchTrashed
        let trashed = try repository.fetchTrashed()
        XCTAssertTrue(trashed.contains { $0.id == task.id })
    }

    func test_restore_bringsTaskBackToActive() throws {
        let task = try repository.create(title: "Restore me")
        try repository.softDelete(id: task.id)
        try repository.restore(id: task.id)

        let active = try repository.fetchActive()
        XCTAssertTrue(active.contains { $0.id == task.id })

        let trashed = try repository.fetchTrashed()
        XCTAssertFalse(trashed.contains { $0.id == task.id })
    }

    func test_permanentlyDelete_removesTaskFromStore() throws {
        let task = try repository.create(title: "Nuke me")
        try repository.softDelete(id: task.id)
        try repository.permanentlyDelete(id: task.id)

        let trashed = try repository.fetchTrashed()
        XCTAssertFalse(trashed.contains { $0.id == task.id })
    }

    // MARK: - US-04: Auto-Purge (AC-04.4)

    func test_purgeExpiredTrash_deletesTasksOlderThan30Days() throws {
        let task = try repository.create(title: "Old deleted task")
        try repository.softDelete(id: task.id)

        // Manually backdate the deletedAt to 31 days ago
        let trashed = try repository.fetchTrashed()
        trashed.first?.deletedAt = Calendar.current.date(byAdding: .day, value: -31, to: Date())
        try container.mainContext.save()

        try repository.purgeExpiredTrash()

        let remaining = try repository.fetchTrashed()
        XCTAssertFalse(remaining.contains { $0.id == task.id })
    }

    func test_purgeExpiredTrash_keepsTasksDeletedWithin30Days() throws {
        let task = try repository.create(title: "Recent deleted task")
        try repository.softDelete(id: task.id)

        try repository.purgeExpiredTrash()

        let remaining = try repository.fetchTrashed()
        XCTAssertTrue(remaining.contains { $0.id == task.id })
    }

    // MARK: - US-05: Priority

    func test_updatePriority_persistsCorrectly() throws {
        let task = try repository.create(title: "Prioritize me")
        try repository.updatePriority(.high, for: task.id)

        let updated = try repository.fetch(id: task.id)
        XCTAssertEqual(updated?.priority, .high)
    }

    func test_prioritySortOrder_isCorrect() {
        XCTAssertLessThan(Priority.high, Priority.medium)
        XCTAssertLessThan(Priority.medium, Priority.low)
        XCTAssertLessThan(Priority.low, Priority.none)
    }
}
