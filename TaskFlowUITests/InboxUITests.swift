// InboxUITests.swift
// TaskFlowUITests
//
// UI automation tests for the Inbox core loop.
// Covers Definition of Done criteria from US-01, US-03, US-04.

import XCTest

final class InboxUITests: XCTestCase {

    // MARK: - Setup

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-data"]
        app.launch()
    }

    // MARK: - US-01: Quick Task Capture

    /// AC-01.1 — FAB opens Quick-Add Sheet
    func test_tapFAB_opensQuickAddSheet() throws {
        app.buttons["Add new task"].tap()
        XCTAssertTrue(app.textFields["Task title"].waitForExistence(timeout: 2))
    }

    /// AC-01.2, AC-01.3 — Type title and tap Add → task appears in list
    func test_addTask_appearsInInboxList() throws {
        app.buttons["Add new task"].tap()
        let titleField = app.textFields["Task title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        titleField.typeText("Buy oat milk")

        app.buttons["Add task"].tap()

        XCTAssertTrue(app.staticTexts["Buy oat milk"].waitForExistence(timeout: 2))
    }

    /// AC-01.3 — Add button is disabled when title is empty
    func test_addButton_disabledWithEmptyTitle() throws {
        app.buttons["Add new task"].tap()
        let addButton = app.buttons["Add task"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 2))
        XCTAssertFalse(addButton.isEnabled)
    }

    /// AC-01.4 — Dismissing empty sheet creates no task
    func test_dismissEmptySheet_createsNoTask() throws {
        app.buttons["Add new task"].tap()
        app.buttons["Cancel"].tap()
        XCTAssertFalse(app.staticTexts["Buy oat milk"].exists)
    }

    // MARK: - US-03: Complete a Task

    /// AC-03.1, AC-03.4 — Tap checkbox → task completes → undo toast appears
    func test_tapCheckbox_completesTask_andShowsUndoToast() throws {
        // Add a task first
        addTask(title: "Test task for completion")

        // Complete via checkbox
        let checkbox = app.buttons["Incomplete, double-tap to complete"].firstMatch
        XCTAssertTrue(checkbox.waitForExistence(timeout: 2))
        checkbox.tap()

        // Toast should appear
        XCTAssertTrue(app.staticTexts["Task completed."].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Undo"].exists)
    }

    /// AC-03.4 — Undo toast restores task
    func test_undoCompletion_restoresTaskToActiveList() throws {
        addTask(title: "Undo complete me")

        let checkbox = app.buttons["Incomplete, double-tap to complete"].firstMatch
        checkbox.waitForExistence(timeout: 2)
        checkbox.tap()

        app.buttons["Undo"].tap()

        XCTAssertTrue(app.staticTexts["Undo complete me"].waitForExistence(timeout: 2))
    }

    // MARK: - US-04: Delete a Task

    /// AC-04.1 — Swipe left on a task row triggers delete
    func test_swipeLeft_deletesTask() throws {
        addTask(title: "Delete me via swipe")

        let cell = app.staticTexts["Delete me via swipe"]
        XCTAssertTrue(cell.waitForExistence(timeout: 2))
        cell.swipeLeft()

        app.buttons["Delete"].tap()

        XCTAssertFalse(app.staticTexts["Delete me via swipe"].waitForExistence(timeout: 2))
    }

    /// AC-04.3 — Undo delete restores task
    func test_undoDelete_restoresTask() throws {
        addTask(title: "Restore me")

        let cell = app.staticTexts["Restore me"]
        cell.waitForExistence(timeout: 2)
        cell.swipeLeft(velocity: .fast)

        app.buttons["Undo"].tap()

        XCTAssertTrue(app.staticTexts["Restore me"].waitForExistence(timeout: 3))
    }

    // MARK: - Helpers

    private func addTask(title: String) {
        app.buttons["Add new task"].tap()
        let titleField = app.textFields["Task title"]
        titleField.waitForExistence(timeout: 2)
        titleField.typeText(title)
        app.buttons["Add task"].tap()
    }
}
