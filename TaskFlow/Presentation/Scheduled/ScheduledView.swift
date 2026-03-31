// ScheduledView.swift
// TaskFlow — Presentation Layer
//
// Shows all future-dated incomplete tasks grouped by calendar day.
// Reactive via @Query + in-memory grouping (SwiftData #Predicate limitation
// prevents filtering on optional Date fields directly).
//
// Spec: US-M5 (all ACs), US-M3 AC-M3.3 (empty state).

import SwiftUI
import SwiftData

struct ScheduledView: View {

    // MARK: - State-owned Action Handler

    @State private var actions: TaskActionHandler

    init(repository: TaskRepositoryProtocol) {
        _actions = State(initialValue: TaskActionHandler(repository: repository))
    }

    // MARK: - Reactive Data

    // Fetch all active (non-deleted, non-completed) tasks; filter for future dates in-memory.
    @Query(
        filter: #Predicate<TaskItem> { $0.isDeleted == false && $0.isCompleted == false },
        sort: \TaskItem.dueDate
    )
    private var activeTasks: [TaskItem]

    // MARK: - Date Boundary

    private var startOfTomorrow: Date {
        let today = Calendar.current.startOfDay(for: Date())
        return Calendar.current.date(byAdding: .day, value: 1, to: today)!
    }

    // MARK: - Grouped Sections (AC-M5.2)

    /// Tasks due from tomorrow onwards, grouped by start-of-day, sorted ascending.
    private var groupedByDay: [(key: Date, tasks: [TaskItem])] {
        let future = activeTasks.filter { ($0.dueDate ?? .distantPast) >= startOfTomorrow }
        let dict = Dictionary(grouping: future) {
            Calendar.current.startOfDay(for: $0.dueDate!)
        }
        return dict
            .map { (key: $0.key, tasks: sortedWithinDay($0.value)) }
            .sorted { $0.key < $1.key }
    }

    /// Within a day: timed tasks first (ascending), then date-only tasks (AC-M5.3).
    private func sortedWithinDay(_ tasks: [TaskItem]) -> [TaskItem] {
        tasks.sorted {
            let lhsHasTime = $0.dueTime != nil
            let rhsHasTime = $1.dueTime != nil
            if lhsHasTime != rhsHasTime { return lhsHasTime }   // timed before date-only
            let lTime = $0.dueTime ?? $0.dueDate ?? .distantFuture
            let rTime = $1.dueTime ?? $1.dueDate ?? .distantFuture
            return lTime < rTime
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if groupedByDay.isEmpty {
                // US-M3 AC-M3.3 — Scheduled empty state
                EmptyStateView(
                    icon: "calendar.badge.plus",
                    iconColor: .indigo,
                    headline: "Nothing scheduled",
                    message: "Tasks with a future due date will appear here."
                )
            } else {
                taskList
            }

            // Undo toast
            if let toast = actions.toastMessage {
                VStack {
                    Spacer()
                    ToastView(toast: toast) { actions.dismissToast() }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 100)
                }
                .zIndex(1)
            }
        }
        .alert(
            "Delete \"\(actions.taskPendingDeleteConfirmation?.title ?? "")\"?",
            isPresented: Binding(
                get: { actions.taskPendingDeleteConfirmation != nil },
                set: { if !$0 { actions.cancelDelete() } }
            )
        ) {
            Button("Delete", role: .destructive) { actions.confirmDelete() }
            Button("Cancel", role: .cancel)      { actions.cancelDelete() }
        } message: {
            Text("This task has notes. It will be moved to Trash.")
        }
        .animation(.easeInOut(duration: 0.25), value: actions.toastMessage?.id)
    }

    // MARK: - Task List

    private var taskList: some View {
        List {
            ForEach(groupedByDay, id: \.key) { group in
                Section {
                    ForEach(group.tasks) { task in
                        taskRow(task)
                    }
                } header: {
                    dayHeader(for: group.key)
                }
            }

            // FAB clearance (AC-M5.5 / AC-M2.5)
            Color.clear
                .frame(height: 88)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }

    // MARK: - Section Header (AC-M5.2)

    private func dayHeader(for date: Date) -> some View {
        let cal = Calendar.current
        let daysAhead = cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: date).day ?? 0

        let primary: String
        if cal.isDateInTomorrow(date) {
            primary = "Tomorrow"
        } else if daysAhead <= 6 {
            primary = date.formatted(.dateTime.weekday(.wide))   // "Wednesday"
        } else {
            primary = date.formatted(.dateTime.month().day())    // "Apr 8"
        }

        let subtitle: String = date.formatted(
            .dateTime.weekday(.abbreviated).month(.abbreviated).day()
        )

        return VStack(alignment: .leading, spacing: 1) {
            Text(primary)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
            if daysAhead > 0 {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .textCase(nil)
        .padding(.vertical, 4)
    }

    // MARK: - Task Row (AC-M5.4)

    private func taskRow(_ task: TaskItem) -> some View {
        NavigationLink(value: task.id) {
            TaskRowView(
                task: task,
                isPendingCompletion: actions.pendingCompletionIds.contains(task.id)
            ) {
                actions.completeTask(id: task.id)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                actions.completeTask(id: task.id)
            } label: {
                Label("Complete", systemImage: "checkmark.circle.fill")
            }
            .tint(.green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: !task.hasNotes) {
            Button(role: .destructive) {
                actions.requestDelete(task: task)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScheduledView(repository: PreviewTaskRepository())
            .navigationTitle("Scheduled")
    }
    .modelContainer(for: TaskItem.self, inMemory: true)
}
