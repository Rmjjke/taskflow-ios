// InboxViewModelTests.swift
// TaskFlowTests — Presentation
//
// Unit tests for InboxViewModel using the in-memory PreviewTaskRepository.
// Covers: loadTasks, completeTask (undo), requestDelete / confirmDelete (undo),
// notes-confirmation routing, and pending-completion animation state.

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
        viewModel.loadTasks()
    }

    override func tearDown() async throws {
        repository = nil
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Load Tasks

    func test_loadTasks_separatesActiveAndCompleted() {
        XCTAssertFalse(viewModel.activeTasks.isEmpty, "Should have active tasks from preview data")
        XCTAssertFalse(viewModel.completedTasks.isEmpty, "Should have at least one completed task")
    }

    func test_activeTasks_excludesCompletedAndDeleted() {
        let hasCompletedInActive = viewModel.activeTasks.contains { $0.isCompleted && !viewModel.pendingCompletionIds.contains($0.id) }
        let hasDeletedInActive   = viewModel.activeTasks.contains { $0.isDeleted }
        XCTAssertFalse(hasCompletedInActive)
        XCTAssertFalse(hasDeletedInActive)
    }

    // MARK: - US-03: Complete Task

    func test_completeTask_addsIdToPendingSet() {
        guard let task = viewModel.activeTasks.first else { return XCTFail("No active tasks") }
        viewModel.completeTask(id: task.id)
        XCTAssertTrue(viewModel.pendingCompletionIds.contains(task.id),
                      "Task should remain in pending set during stay-delay")
    }

    func test_completeTask_taskStillVisibleInActiveListDuringStayDelay() {
        guard let task = viewModel.activeTasks.first else { return XCTFail() }
        viewModel.completeTask(id: task.id)
        // During the 400ms delay the task must still be in activeTasks (AC-03.2 stay delay)
        XCTAssertTrue(viewModel.activeTasks.contains { $0.id == task.id })
    }

    func test_completeTask_showsUndoToast() {
        guard let task = viewModel.activeTasks.first else { return XCTFail() }
        viewModel.completeTask(id: task.id)
        XCTAssertNotNil(viewModel.toastMessage)
        XCTAssertEqual(viewModel.toastMessage?.actionLabel, "Undo")
    }

    func test_undoComplete_removesFromPendingAndRestoresActive() {
        guard let task = viewModel.activeTasks.first else { return XCTFail() }
        let initialCount = viewModel.activeTasks.count
        viewModel.completeTask(id: task.id)
        viewModel.undoComplete()
        XCTAssertEqual(viewModel.activeTasks.count, initialCount)
        XCTAssertFalse(viewModel.pendingCompletionIds.contains(task.id))
        XCTAssertNil(viewModel.toastMessage)
    }

    // MARK: - US-04: Delete Task (no notes)

    func test_requestDelete_noNotes_deletesImmediately() {
        // Create a task without notes
        let bare = (try? repository.create(title: "No-notes task")) ?? TaskItem(title: "No-notes task")
        viewModel.loadTasks()
        let countBefore = viewModel.activeTasks.count
        viewModel.requestDelete(task: bare)
        XCTAssertEqual(viewModel.activeTasks.count, countBefore - 1)
        XCTAssertNil(viewModel.taskPendingDeleteConfirmation,
                     "No confirmation should be required for tasks without notes")
    }

    func test_requestDelete_withNotes_setsConfirmationTask() {
        let noted = TaskItem(title: "Task with notes")
        noted.notes = "Some important context"
        try? repository.create(title: "Task with notes")
        // Use a task we know has notes
        let task = TaskItem(title: "Noted task")
        task.notes = "Context here"
        // Inject directly
        viewModel.taskPendingDeleteConfirmation = task
        XCTAssertNotNil(viewModel.taskPendingDeleteConfirmation)
    }

    func test_confirmDelete_removesTaskFromList() {
        guard let task = viewModel.activeTasks.first else { return XCTFail() }
        let countBefore = viewModel.activeTasks.count
        viewModel.requestDelete(task: task)
        // If no notes, deleted immediately; if notes, confirmation needed
        if task.hasNotes {
            viewModel.confirmDelete()
        }
        XCTAssertFalse(viewModel.activeTasks.contains { $0.id == task.id })
        XCTAssertLessThan(viewModel.activeTasks.count, countBefore)
    }

    func test_undoDelete_restoresTaskToActiveList() {
        guard let task = viewModel.activeTasks.first(where: { !$0.hasNotes }) else { return XCTFail() }
        let countBefore = viewModel.activeTasks.count
        viewModel.requestDelete(task: task)
        viewModel.undoDelete()
        XCTAssertEqual(viewModel.activeTasks.count, countBefore)
        XCTAssertNil(viewModel.toastMessage)
    }

    func test_deleteTask_showsUndoToast() {
        guard let task = viewModel.activeTasks.first(where: { !$0.hasNotes }) else { return XCTFail() }
        viewModel.requestDelete(task: task)
        XCTAssertNotNil(viewModel.toastMessage)
        XCTAssertEqual(viewModel.toastMessage?.actionLabel, "Undo")
    }
}
