// QuickAddViewModel.swift
// TaskFlow — Presentation Layer
//
// Drives the QuickAddView (half-sheet for fast task capture).
// Spec: US-01 — Quick Task Capture.

import Foundation
import Observation

@Observable
@MainActor
final class QuickAddViewModel {

    // MARK: - Dependencies

    let repository: TaskRepositoryProtocol

    /// Speech-to-text service for the dictation mic button.
    let speech = SpeechRecognitionService()

    // MARK: - Input State

    var title: String = ""
    var dueDate: Date? = nil
    var dueTime: Date? = nil
    var hasTime: Bool = false
    var priority: Priority = .none
    var projectId: UUID? = nil

    // MARK: - UI State

    /// Whether the date picker is expanded inline.
    var isDatePickerExpanded: Bool = false

    /// Whether the priority picker is expanded inline.
    var isPriorityPickerExpanded: Bool = false

    /// Set to `true` by the view when the user dismisses with unsaved content,
    /// to trigger the "Discard task?" confirmation (AC-01.4).
    var showDiscardConfirmation: Bool = false

    /// Shown when microphone/speech permission is denied — prompts user to open Settings.
    var showMicPermissionAlert: Bool = false

    /// Error surfaced to the view.
    var errorMessage: String? = nil

    // MARK: - Computed

    /// The "Add" button is disabled while the title is blank (AC-01.2).
    var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    /// True when the user has entered any content — triggers discard confirmation on dismiss.
    var isDirty: Bool { !title.isEmpty }

    /// Whether the selected due date is today — used to highlight the "Today" chip (AC-02.2).
    var isToday: Bool {
        guard let d = dueDate else { return false }
        return Calendar.current.isDateInToday(d)
    }

    /// Whether the selected due date is tomorrow — used to highlight the "Tomorrow" chip.
    var isTomorrow: Bool {
        guard let d = dueDate else { return false }
        return Calendar.current.isDateInTomorrow(d)
    }

    // MARK: - Init

    init(repository: TaskRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Actions

    /// Persists the task and returns the saved item. Caller should dismiss the sheet.
    @discardableResult
    func save() throws -> TaskItem {
        let task = try repository.create(
            title: title.trimmingCharacters(in: .whitespaces),
            notes: nil,
            dueDate: dueDate,
            dueTime: hasTime ? dueTime : nil,
            priority: priority,
            projectId: projectId,
            tags: []
        )
        return task
    }

    // MARK: - Quick Date Chips (AC-02.2)

    func selectToday() {
        dueDate = Calendar.current.startOfDay(for: Date())
        isDatePickerExpanded = true
    }

    func selectTomorrow() {
        dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))
        isDatePickerExpanded = true
    }

    func selectNextWeek() {
        dueDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Calendar.current.startOfDay(for: Date()))
        isDatePickerExpanded = true
    }

    func clearDueDate() {
        dueDate = nil
        dueTime = nil
        hasTime = false
        isDatePickerExpanded = false
    }

    // MARK: - Dictation

    /// Toggles speech recognition on/off.
    /// Requests permission on first use; shows alert when denied.
    func toggleDictation() {
        if speech.isRecording {
            speech.stopRecording()
            return
        }

        switch speech.permissionStatus {
        case .authorized:
            startDictation()
        case .notDetermined:
            Task { [weak self] in
                await self?.speech.requestPermission()
                if self?.speech.isPermitted == true {
                    self?.startDictation()
                }
            }
        default:
            // .denied or .restricted — direct user to Settings
            showMicPermissionAlert = true
        }
    }

    private func startDictation() {
        try? speech.startRecording { [weak self] transcription in
            // Replace title with live transcription as user speaks
            self?.title = transcription
        }
    }
}
