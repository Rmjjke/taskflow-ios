// TodayView.swift
// TaskFlow — Presentation Layer
//
// Default tab. Shows Overdue, Today, and No-Date task sections plus a
// collapsible Completed Today footer. Reactive via @Query.
//
// Spec: US-M2 (all ACs), US-M3 AC-M3.2 (empty state), US-03, US-04.

import SwiftUI
import SwiftData

struct TodayView: View {

    // MARK: - State-owned Action Handler (persisted across re-renders via @State)

    @State private var actions: TaskActionHandler

    init(repository: TaskRepositoryProtocol) {
        _actions = State(initialValue: TaskActionHandler(repository: repository))
    }

    // MARK: - Reactive Data (@Query handles SwiftData change propagation)
    // One query for all non-deleted tasks; sections are computed in-memory.
    // This avoids SwiftData #Predicate's force-unwrap limitation on optional dates.

    @Query(filter: #Predicate<TaskItem> { $0.isDeleted == false })
    private var allTasks: [TaskItem]

    // MARK: - Local State

    @State private var isCompletedSectionExpanded = false

    // MARK: - Date Boundaries (computed once per render — not inside #Predicate)

    private var startOfToday: Date    { Calendar.current.startOfDay(for: Date()) }
    private var startOfTomorrow: Date { Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)! }

    // MARK: - Computed Sections (AC-M2.1)

    private var overdueTasks: [TaskItem] {
        allTasks
            .filter { !$0.isCompleted && $0.dueDate != nil && $0.dueDate! < startOfToday }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private var todayTasks: [TaskItem] {
        allTasks
            .filter {
                !$0.isCompleted &&
                $0.dueDate != nil &&
                $0.dueDate! >= startOfToday &&
                $0.dueDate! < startOfTomorrow
            }
            .sorted {
                // Time ascending first, then createdAt for date-only tasks
                let lhs = $0.dueTime ?? $0.dueDate ?? .distantFuture
                let rhs = $1.dueTime ?? $1.dueDate ?? .distantFuture
                return lhs < rhs
            }
    }

    private var noDateTasks: [TaskItem] {
        allTasks
            .filter { !$0.isCompleted && $0.dueDate == nil }
            .sorted { $0.createdAt > $1.createdAt }   // newest first (AC-M2.1)
    }

    private var completedTodayTasks: [TaskItem] {
        allTasks
            .filter {
                $0.isCompleted &&
                $0.completedAt != nil &&
                $0.completedAt! >= startOfToday
            }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private var hasAnyActiveTask: Bool {
        !overdueTasks.isEmpty || !todayTasks.isEmpty || !noDateTasks.isEmpty
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if !hasAnyActiveTask && completedTodayTasks.isEmpty {
                // US-M3 AC-M3.2 — Today empty state
                EmptyStateView(
                    icon: "checkmark.circle.fill",
                    iconColor: .indigo,
                    headline: "You're all clear",
                    message: "Tap + to add a task, or check Scheduled for upcoming work."
                )
                .animation(.easeInOut(duration: 0.3), value: hasAnyActiveTask)
            } else {
                taskList
                    .animation(.easeInOut(duration: 0.3), value: hasAnyActiveTask)
            }

            // Undo toast — above FAB (AC-03.4, AC-04.3)
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
        // Notes-delete confirmation alert (AC-04.1)
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
            // ── Overdue (AC-M2.1, AC-M2.2) ─────────────────────────────
            if !overdueTasks.isEmpty {
                Section {
                    ForEach(overdueTasks) { task in
                        taskRow(task, isOverdue: true)
                    }
                } header: {
                    Label("Overdue", systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.subheadline.weight(.semibold))
                        .textCase(nil)
                }
            }

            // ── Today (AC-M2.1, AC-M2.2) ────────────────────────────────
            if !todayTasks.isEmpty {
                Section {
                    ForEach(todayTasks) { task in
                        taskRow(task, isOverdue: false)
                    }
                } header: {
                    Text("TODAY")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            // ── No Date (AC-M2.1, AC-M2.2) ─────────────────────────────
            if !noDateTasks.isEmpty {
                Section {
                    ForEach(noDateTasks) { task in
                        taskRow(task, isOverdue: false)
                    }
                } header: {
                    Text("NO DATE")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            // ── Completed Today — collapsible footer (AC-M2.4) ──────────
            if !completedTodayTasks.isEmpty {
                Section {
                    if isCompletedSectionExpanded {
                        ForEach(completedTodayTasks) { task in
                            completedRow(task)
                        }
                    }
                } header: {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isCompletedSectionExpanded.toggle()
                        }
                    } label: {
                        Label(
                            "Completed (\(completedTodayTasks.count))",
                            systemImage: isCompletedSectionExpanded
                                ? "checkmark.circle.fill"
                                : "checkmark.circle"
                        )
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Bottom inset so last row clears the FAB (AC-M2.5)
            Color.clear
                .frame(height: 88)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .animation(.easeOut(duration: 0.3), value: overdueTasks.map(\.id))
        .animation(.easeOut(duration: 0.3), value: todayTasks.map(\.id))
        .animation(.easeOut(duration: 0.3), value: noDateTasks.map(\.id))
    }

    // MARK: - Active Task Row (AC-M2.3)

    private func taskRow(_ task: TaskItem, isOverdue: Bool) -> some View {
        NavigationLink(value: task.id) {
            TaskRowView(
                task: task,
                isPendingCompletion: actions.pendingCompletionIds.contains(task.id)
            ) {
                actions.completeTask(id: task.id)
            }
        }
        // Swipe right → Complete (AC-M2.3 / US-03)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                actions.completeTask(id: task.id)
            } label: {
                Label("Complete", systemImage: "checkmark.circle.fill")
            }
            .tint(.green)
        }
        // Swipe left → Delete (US-04 AC-04.1)
        .swipeActions(edge: .trailing, allowsFullSwipe: !task.hasNotes) {
            Button(role: .destructive) {
                actions.requestDelete(task: task)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Completed Today Row (AC-M2.4)

    private func completedRow(_ task: TaskItem) -> some View {
        HStack {
            CheckboxView(isCompleted: true) {
                // Re-open the task (moves back to active section)
                actions.reopenTask(id: task.id)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .strikethrough(true, color: .secondary)
                    .foregroundStyle(.secondary)
                    .opacity(0.6)
                    .lineLimit(1)
                if let completedAt = task.completedAt {
                    Text(completedAt.relativeCompletionLabel)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
        // Swipe left to delete a completed task too
        .swipeActions(edge: .trailing, allowsFullSwipe: !task.hasNotes) {
            Button(role: .destructive) {
                actions.requestDelete(task: task)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Relative Completion Label Helper

extension Date {
    /// "Completed just now", "Completed 2h ago", "Completed yesterday", "Completed Mar 28"
    var relativeCompletionLabel: String {
        let interval = Date().timeIntervalSince(self)
        if interval < 60        { return "Completed just now" }
        if interval < 3600      { return "Completed \(Int(interval / 60))m ago" }
        if interval < 86400     { return "Completed \(Int(interval / 3600))h ago" }
        let cal = Calendar.current
        if cal.isDateInYesterday(self) { return "Completed yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Completed \(formatter.string(from: self))"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TodayView(repository: PreviewTaskRepository())
            .navigationTitle("Today")
    }
    .modelContainer(for: TaskItem.self, inMemory: true)
}
