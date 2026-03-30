// TaskRowView.swift
// TaskFlow — Common / Components
//
// A single task row used in the Inbox list and the Completed section.
// Displays: checkbox, title, due date label, priority flag, and notes indicator.
// Spec: US-03 (completion UI), US-04 (deletion via swipe — applied by parent),
//       US-05 AC-05.3 (priority flag in list), US-06 AC-06.3 (notes indicator).

import SwiftUI

struct TaskRowView: View {

    // MARK: - Properties

    let task: TaskItem
    let onToggleComplete: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            // Checkbox (US-03)
            CheckboxView(isCompleted: task.isCompleted, onTap: onToggleComplete)

            // Title + metadata
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(task.title)
                        .font(.body)
                        .strikethrough(task.isCompleted, color: .secondary)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        .lineLimit(2)

                    // Notes indicator (AC-06.3)
                    if task.hasNotes {
                        Image(systemName: "note.text")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                // Due date label
                if let dueDate = task.dueDate {
                    Text(dueDate.taskDueDateLabel)
                        .font(.caption)
                        .foregroundStyle(task.isOverdue ? .red : .secondary)
                }
            }

            Spacer()

            // Priority flag (AC-05.3) — shown only when priority is not .none
            if task.priority.showsFlag {
                Image(systemName: task.priority.symbolName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(task.priority.color)
                    .accessibilityLabel("Priority: \(task.priority.label)")
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle()) // makes the full row tappable for NavigationLink
    }
}

// MARK: - Preview

#Preview {
    List {
        TaskRowView(
            task: TaskItem(title: "Buy groceries", priority: .high),
            onToggleComplete: {}
        )
        TaskRowView(
            task: {
                let t = TaskItem(title: "Write PRD notes", priority: .medium)
                t.notes = "Some notes here"
                t.dueDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
                return t
            }(),
            onToggleComplete: {}
        )
        TaskRowView(
            task: {
                let t = TaskItem(title: "Completed task")
                t.isCompleted = true
                return t
            }(),
            onToggleComplete: {}
        )
    }
}
