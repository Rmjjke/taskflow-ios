// InboxViewModelTests.swift
// TaskFlowTests — Presentation
//
// Unit tests for InboxViewModel using the in-memory PreviewTaskRepository.
// Covers: loadTasks, completeTask (undo), deleteTask (undo).

import XCTest
@testable import TaskFlow

@MainActor
final class InboxViewModelTests: XCTestCase {

    // MARK: - Setup

    private var repository: PreviewTaskRepository!
    private var viewModel: InboxViewModel!

    override func setUp() async throws {
        try await super.setUp()
        repository = PreviewTaskRepository()
        viewModel = InboxViewModel(repository: repository)
    }

    override func tearDown() async throws {
        repository = nil
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Load Tasks

    func test_loadTasks_separatesActiveAndCompleted() {
        viewModel.loadTasks()
        XCTAssertFalse(viewModel.activeTasks.isEmpty)
        // Preview data includes 1 completed task
        XCTAssertFalse(viewModel.completedTasks.isEmpty)
    }

    func test_activeTasks_excludesCompletedAndDeleted() {
        viewModel.loadTasks()
        let hasCompletedInActive = viewModel.activeTasks.contains { $0.isCompleted }
        let hasDeletedInActive   = viewModel.activeTasks.contains { $0.isDeleted }
        XCTAssertFalse(hasCompletedInActive)
        XCTAssertFalse(hasDeletedInActive)
    }

    // MARK: - Complete Task (US-03)

    func test_completeTask_movesTaskToCompletedList() {
        viewModel.loadTasks()
        guard let task = viewModel.activeTasks.first else {
            return XCTFail("No active tasks to complete")
        }
        let initialCompletedCount = viewModel.completedTasks.count

        viewModel.completeTask(id: task.id)

        XCTAssertFalse(viewModel.activeTasks.contains { $0.id == task.id })
        XCTAssertEqual(viewModel.completedTasks.count, initialCompletedCount + 1)
    }

    func test_completeTask_showsUndoToast() {
        viewModel.loadTasks()
        guard let task = viewModel.activeTasks.first else { return XCTFail() }

        viewModel.completeTask(id: task.id)

        XCTAssertNotNil(viewModel.toastMessage)
        XCTAssertEqual(viewModel.toastMessage?.actionLabel, "Undo")
    }

    func test_undoComplete_restoresTaskToActiveList() {
        viewModel.loadTasks()
        guard let task = viewModel.activeTasks.first else { return XCTFail() }

        viewModel.completeTask(id: task.id)
        viewModel.undoComplete()

        XCTAssertTrue(viewModel.activeTasks.contains { $0.id == task.id })
        XCTAssertNil(viewModel.toastMessage)
    }

    // MARK: - Delete Task (US-04)

    func test_deleteTask_removesFromActiveList() {
        viewModel.loadTasks()
        guard let task = viewModel.activeTasks.first else { return XCTFail() }

        viewModel.deleteTask(id: task.id)

        XCTAssertFalse(viewModel.activeTasks.contains { $0.id == task.id })
    }

    func test_deleteTask_showsUndoToast() {
        viewModel.loadTasks()
        guard let task = viewModel.activeTasks.first else { return XCTFail() }

        viewModel.deleteTask(id: task.id)

        XCTAssertNotNil(viewModel.toastMessage)
        XCTAssertEqual(viewModel.toastMessage?.actionLabel, "Undo")
    }

    func test_undoDelete_restoresTaskToActiveList() {
        viewModel.loadTasks()
        guard let task = viewModel.activeTasks.first else { return XCTFail() }

        viewModel.deleteTask(id: task.id)
        viewModel.undoDelete()

        XCTAssertTrue(viewModel.activeTasks.contains { $0.id == task.id })
        XCTAssertNil(viewModel.toastMessage)
    }
}
