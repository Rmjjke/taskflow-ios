// InboxUITests.swift
// TaskFlowUITests
//
// End-to-end UI tests for the Inbox core loop.
// Maps directly to Definition of Done criteria in epic-task-management.md.
//
// Stories covered: US-01 (AC-01.1–01.4), US-03 (AC-03.1, AC-03.4), US-04 (AC-04.1, AC-04.3)

import XCTest

final class InboxUITests: XCTestCase {

    var app: XCUIApplication!

    // MARK: - Setup

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Launch args reset SwiftData store and skip onboarding in MVP
        app.launchArguments = ["--uitesting", "--reset-data"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - US-01: Quick Task Capture

    /// AC-01.1 — FAB opens Quick-Add Sheet with keyboard ready
    func test_tapFAB_opensQuickAddSheet() {
        app.buttons["Add new task"].tap()
        let titleField = app.textFields["Task title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 2), "Quick-Add sheet should open")
    }

    /// AC-01.2 — Add button disabled while title is empty
    func test_addButton_disabledWithEmptyTitle() {
        app.buttons["Add new task"].tap()
        let addButton = app.buttons["Add task"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 2))
        XCTAssertFalse(addButton.isEnabled, "Add should be disabled when title is blank")
    }

    /// AC-01.3 — Typing title enables Add; task appears in list after save
    func test_addTask_appearsInInboxList() {
        addTask(title: "Buy oat milk")
        XCTAssertTrue(
            app.staticTexts["Buy oat milk"].waitForExistence(timeout: 3),
            "New task should appear immediately in Inbox"
        )
    }

    /// AC-01.4 — Dismissing an empty sheet creates no task
    func test_dismissEmptySheet_createsNoTask() {
        let initialCount = app.cells.count
        app.buttons["Add new task"].tap()
        app.buttons["Cancel"].tap()
        XCTAssertEqual(app.cells.count, initialCount)
    }

    /// AC-01.4 — Dismissing after typing title shows "Discard task?" confirmation
    func test_dismissWithTitle_showsDiscardConfirmation() {
        app.buttons["Add new task"].tap()
        app.textFields["Task title"].typeText("Unfinished thought")
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["Discard"].waitForExistence(timeout: 2), "Discard confirmation should appear")
    }

    /// AC-01.4 — "Keep Editing" dismisses the confirmation without losing work
    func test_keepEditing_preservesTitle() {
        app.buttons["Add new task"].tap()
        app.textFields["Task title"].typeText("Keep this")
        app.buttons["Cancel"].tap()
        app.buttons["Keep Editing"].tap()
        XCTAssertTrue(app.textFields["Task title"].waitForExistence(timeout: 1))
    }

    // MARK: - US-03: Complete a Task

    /// AC-03.1, AC-03.4 — Tapping checkbox completes task and shows Undo toast
    func test_tapCheckbox_completesTask_andShowsUndoToast() {
        addTask(title: "Task to complete")

        let checkbox = app.buttons["Incomplete, double-tap to complete"].firstMatch
        XCTAssertTrue(checkbox.waitForExistence(timeout: 2))
        checkbox.tap()

        XCTAssertTrue(
            app.staticTexts["Task completed."].waitForExistence(timeout: 2),
            "Completion toast should appear"
        )
        XCTAssertTrue(app.buttons["Undo"].exists, "Undo button should be visible in toast")
    }

    /// AC-03.4 — Tapping Undo restores the task to active list
    func test_undoCompletion_restoresTask() {
        addTask(title: "Undo-complete me")

        app.buttons["Incomplete, double-tap to complete"].firstMatch.tap()
        app.staticTexts["Task completed."].waitForExistence(timeout: 2)
        app.buttons["Undo"].tap()

        XCTAssertTrue(
            app.staticTexts["Undo-complete me"].waitForExistence(timeout: 3),
            "Task should return to active list after Undo"
        )
    }

    /// AC-03.1 — Swipe right completes a task
    func test_swipeRight_completesTask() {
        addTask(title: "Swipe to complete")
        let cell = app.staticTexts["Swipe to complete"]
        XCTAssertTrue(cell.waitForExistence(timeout: 2))
        cell.swipeRight()
        XCTAssertTrue(app.staticTexts["Task completed."].waitForExistence(timeout: 2))
    }

    // MARK: - US-04: Delete a Task

    /// AC-04.1 — Swipe left deletes task without confirmation (no notes)
    func test_swipeLeft_deletesTask_noNotes() {
        addTask(title: "Delete me immediately")
        let cell = app.staticTexts["Delete me immediately"]
        XCTAssertTrue(cell.waitForExistence(timeout: 2))
        cell.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertFalse(
            app.staticTexts["Delete me immediately"].waitForExistence(timeout: 2),
            "Task should be gone after deletion"
        )
    }

    /// AC-04.3 — Undo delete restores task to Inbox
    func test_undoDelete_restoresTask() {
        addTask(title: "Restore after delete")
        let cell = app.staticTexts["Restore after delete"]
        cell.waitForExistence(timeout: 2)
        cell.swipeLeft(velocity: .fast)
        app.buttons["Undo"].tap()
        XCTAssertTrue(
            app.staticTexts["Restore after delete"].waitForExistence(timeout: 3),
            "Task should return to Inbox after Undo"
        )
    }

    // MARK: - Helpers

    private func addTask(title: String) {
        app.buttons["Add new task"].tap()
        let field = app.textFields["Task title"]
        _ = field.waitForExistence(timeout: 2)
        field.typeText(title)
        app.buttons["Add task"].tap()
        // Allow optimistic insert to settle
        _ = app.staticTexts[title].waitForExistence(timeout: 2)
    }
}
