// TaskRowView.swift
// TaskFlow — Common / Components
//
// A single task row for Inbox and Completed section.
// Supports a `isPendingCompletion` state that shows the row with strikethrough
// during the 400ms "stay" delay before it animates out (US-03 AC-03.2).

import SwiftUI

struct TaskRowView: View {

    // MARK: - Properties

    let task: TaskItem
    /// True during the 400ms stay window after completion (AC-03.2).
    var isPendingCompletion: Bool = false
    let onToggleComplete: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {

            // Checkbox (US-03 AC-03.1)
            CheckboxView(
                isCompleted: task.isCompleted || isPendingCompletion,
                onTap: onToggleComplete
            )

            // Title + metadata
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(task.title)
                        .font(.body)
                        .strikethrough(task.isCompleted || isPendingCompletion, color: .secondary)
                        .foregroundStyle((task.isCompleted || isPendingCompletion) ? .secondary : .primary)
                        .lineLimit(2)

                    // Notes indicator — small icon signals extra context (AC-06.3)
                    if task.hasNotes {
                        Image(systemName: "note.text")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                // Due date badge
                if let dueDate = task.dueDate {
                    Label {
                        Text(dueDate.taskDueDateLabel)
                    } icon: {
                        if task.isOverdue {
                            Image(systemName: "exclamationmark.circle")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(task.isOverdue ? .red : .secondary)
                }
            }

            Spacer(minLength: 8)

            // Priority flag — only shown for non-.none priority (AC-05.3)
            if task.priority.showsFlag {
                Image(systemName: task.priority.symbolName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(task.priority.color)
                    .accessibilityLabel("Priority: \(task.priority.label)")
            }
        }
        .padding(.vertical, 2)
        // Full row is tappable for NavigationLink
        .contentShape(Rectangle())
        // Fade the row when pending completion — sets up the exit animation (AC-03.2)
        .opacity(isPendingCompletion ? 0.55 : 1.0)
        .animation(.easeIn(duration: 0.2).delay(0.35), value: isPendingCompletion)
    }
}

// MARK: - Preview

#Preview {
    List {
        TaskRowView(
            task: TaskItem(title: "Buy groceries", priority: .high),
            isPendingCompletion: false,
            onToggleComplete: {}
        )
        TaskRowView(
            task: {
                let t = TaskItem(title: "Write release notes", priority: .medium)
                t.notes = "Include changelog items from sprint"
                t.dueDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
                return t
            }(),
            isPendingCompletion: false,
            onToggleComplete: {}
        )
        TaskRowView(
            task: TaskItem(title: "Just completed this one"),
            isPendingCompletion: true,
            onToggleComplete: {}
        )
        TaskRowView(
            task: {
                let t = TaskItem(title: "Already in completed section")
                t.isCompleted = true
                return t
            }(),
            isPendingCompletion: false,
            onToggleComplete: {}
        )
    }
}
