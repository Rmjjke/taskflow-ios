// Date+Formatting.swift
// TaskFlow — Common / Extensions
//
// Convenience date formatting helpers used across all views.
// Spec: US-02 AC-02.2 (readable label next to 📅 icon).

import Foundation

extension Date {

    // MARK: - Task Due Date Label

    /// Returns a human-friendly due date label as shown next to the 📅 icon.
    /// Examples: "Today", "Tomorrow", "Mon Apr 6", "Apr 6, 2025"
    var taskDueDateLabel: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: self)

        if calendar.isDateInToday(target) {
            return "Today"
        } else if calendar.isDateInTomorrow(target) {
            return "Tomorrow"
        } else if let daysAhead = calendar.dateComponents([.day], from: today, to: target).day,
                  daysAhead > 0 && daysAhead < 7 {
            // Within the next 7 days: "Mon Apr 6"
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE MMM d"
            return formatter.string(from: self)
        } else if calendar.component(.year, from: self) == calendar.component(.year, from: Date()) {
            // Same year: "Apr 6"
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: self)
        } else {
            // Different year: "Apr 6, 2025"
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: self)
        }
    }

    // MARK: - Overdue Check

    /// Returns `true` when the date (interpreted as a due date) is before the start of today.
    var isPastDue: Bool {
        self < Calendar.current.startOfDay(for: Date())
    }
}
