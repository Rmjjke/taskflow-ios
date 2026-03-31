// ArchiveView.swift
// TaskFlow — Presentation Layer
//
// Shows all completed (non-deleted) tasks grouped by completion time:
// Today / Yesterday / This Week / Earlier. Supports Reopen and Delete.
// No FAB — task creation is not available here.
//
// Spec: US-M6 (all ACs), US-M3 AC-M3.4 (empty state).

import SwiftUI
import SwiftData

struct ArchiveView: View {

    // MARK: - State-owned Action Handler

    @State private var actions: TaskActionHandler

    init(repository: TaskRepositoryProtocol) {
        _actions = State(initialValue: TaskActionHandler(repository: repository))
    }

    // MARK: - Reactive Data

    @Query(
        filter: #Predicate<TaskItem> { $0.isDeleted == false && $0.isCompleted == true },
        sort: \TaskItem.completedAt,
        order: .reverse
    )
    private var completedTasks: [TaskItem]

    // MARK: - Date Boundaries

    private var startOfToday: Date {
        Calendar.current.startOfDay(for: Date())
    }
    private var startOfYesterday: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: startOfToday)!
    }
    private var startOfWeek: Date {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
    }

    // MARK: - Archive Groups (AC-M6.2)

    enum ArchiveGroup: String, CaseIterable {
        case today     = "TODAY"
        case yesterday = "YESTERDAY"
        case thisWeek  = "THIS WEEK"
        case earlier   = "EARLIER"
    }

    private func group(for task: TaskItem) -> ArchiveGroup {
        guard let completedAt = task.completedAt else { return .earlier }
        if completedAt >= startOfToday     { return .today }
        if completedAt >= startOfYesterday { return .yesterday }
        if completedAt >= startOfWeek      { return .thisWeek }
        return .earlier
    }

    private var groupedTasks: [(group: ArchiveGroup, tasks: [TaskItem])] {
        let dict = Dictionary(grouping: completedTasks, by: group)
        return ArchiveGroup.allCases.compactMap { g in
            guard let tasks = dict[g], !tasks.isEmpty else { return nil }
            return (group: g, tasks: tasks)
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if completedTasks.isEmpty {
                // US-M3 AC-M3.4 — Archive empty state (no CTA, no FAB)
                EmptyStateView(
                    icon: "archivebox",
                    iconColor: .secondary,
                    headline: "No completed tasks yet",
                    message: "Tasks you complete will be saved here."
                )
            } else {
                archiveList
            }

            // Toast for "Task reopened." / "Task deleted." (AC-M6.4, AC-M6.5)
            if let toast = actions.toastMessage {
                VStack {
                    Spacer()
                    ToastView(toast: toast) { actions.dismissToast() }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 24)   // Archive has no FAB — smaller clearance
                }
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: actions.toastMessage?.id)
    }

    // MARK: - Archive List

    private var archiveList: some View {
        List {
            ForEach(groupedTasks, id: \.group) { section in
                Section {
                    ForEach(section.tasks) { task in
                        archiveRow(task)
                    }
                } header: {
                    Text(section.group.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Archive Row (AC-M6.3)

    private func archiveRow(_ task: TaskItem) -> some View {
        HStack(spacing: 12) {
            // Green filled checkmark (AC-M6.3)
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .accessibilityLabel("Completed task")

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .strikethrough()
                    .foregroundStyle(.secondary)
                    .opacity(0.7)
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
        // Swipe right → Reopen (AC-M6.4)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                actions.reopenTask(id: task.id)
            } label: {
                Label("Reopen", systemImage: "arrow.uturn.left")
            }
            .tint(.blue)
        }
        // Swipe left → Delete (AC-M6.5)
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
        ArchiveView(repository: PreviewTaskRepository())
            .navigationTitle("Archive")
    }
    .modelContainer(for: TaskItem.self, inMemory: true)
}
