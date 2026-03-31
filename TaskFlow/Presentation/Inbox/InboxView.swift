// InboxView.swift
// TaskFlow — Presentation Layer
//
// Root screen for MVP. No tab bar — this IS the app (PRD §5 MVP Navigation).
//
// Reachable from here:
//   • QuickAddView  — sheet via FAB tap  (US-01)
//   • TaskDetailView — NavigationLink on row tap
//   • SettingsView   — sheet via gear icon

import SwiftUI

struct InboxView: View {

    // MARK: - ViewModel

    @State var viewModel: InboxViewModel

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            taskList
            fabButton

            // Undo toast — sits above the FAB (AC-03.4, AC-04.3)
            if let toast = viewModel.toastMessage {
                ToastView(toast: toast) { viewModel.dismissToast() }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 84)
                    .zIndex(1)
            }
        }
        .navigationTitle("Inbox")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { settingsButton }
        // Quick-Add sheet (US-01)
        .sheet(isPresented: $viewModel.isShowingQuickAdd, onDismiss: { viewModel.loadTasks() }) {
            QuickAddView(viewModel: QuickAddViewModel(repository: viewModel.repository))
        }
        // Settings sheet
        .sheet(isPresented: $viewModel.isShowingSettings) {
            SettingsView()
        }
        // Notes-confirmation alert before deletion (US-04 AC-04.1)
        .alert(
            "Delete \"\(viewModel.taskPendingDeleteConfirmation?.title ?? "")\"?",
            isPresented: Binding(
                get: { viewModel.taskPendingDeleteConfirmation != nil },
                set: { if !$0 { viewModel.cancelDelete() } }
            )
        ) {
            Button("Delete", role: .destructive) { viewModel.confirmDelete() }
            Button("Cancel", role: .cancel) { viewModel.cancelDelete() }
        } message: {
            Text("This task has notes and will be moved to Trash.")
        }
        .onAppear { viewModel.onAppear() }
        .animation(.easeInOut(duration: 0.25), value: viewModel.toastMessage?.id)
    }

    // MARK: - Task List

    private var taskList: some View {
        List {
            if viewModel.activeTasks.isEmpty && viewModel.completedTasks.isEmpty {
                emptyStateView
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                activeTasksSection
                if !viewModel.completedTasks.isEmpty {
                    completedSection
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.easeOut(duration: 0.3), value: viewModel.activeTasks.map { $0.id })
    }

    // MARK: - Active Tasks

    @ViewBuilder
    private var activeTasksSection: some View {
        ForEach(viewModel.activeTasks) { task in
            NavigationLink(destination: taskDetailDestination(for: task)) {
                TaskRowView(
                    task: task,
                    isPendingCompletion: viewModel.pendingCompletionIds.contains(task.id)
                ) {
                    viewModel.completeTask(id: task.id)
                }
            }
            // Swipe right → Complete (AC-03.1)
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                completeSwipeAction(for: task)
            }
            // Swipe left → Delete (AC-04.1)
            .swipeActions(edge: .trailing, allowsFullSwipe: !task.hasNotes) {
                deleteSwipeAction(for: task)
            }
        }
    }

    // MARK: - Completed Section (AC-03.3)

    private var completedSection: some View {
        Section {
            if viewModel.isCompletedSectionExpanded {
                ForEach(viewModel.completedTasks) { task in
                    NavigationLink(destination: taskDetailDestination(for: task)) {
                        TaskRowView(task: task, isPendingCompletion: false) {
                            viewModel.completeTask(id: task.id) // uncomplete (AC-03.5)
                        }
                    }
                }
            }
        } header: {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.isCompletedSectionExpanded.toggle()
                }
            } label: {
                Label(
                    "Completed (\(viewModel.completedTasks.count))",
                    systemImage: viewModel.isCompletedSectionExpanded
                        ? "checkmark.circle.fill"
                        : "checkmark.circle"
                )
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Swipe Actions

    private func completeSwipeAction(for task: TaskItem) -> some View {
        Button {
            viewModel.completeTask(id: task.id)
        } label: {
            Label("Complete", systemImage: "checkmark.circle.fill")
        }
        .tint(.green)
    }

    @ViewBuilder
    private func deleteSwipeAction(for task: TaskItem) -> some View {
        Button(role: .destructive) {
            // requestDelete checks for notes and routes to confirmation if needed (AC-04.1)
            viewModel.requestDelete(task: task)
        } label: {
            Label("Delete", systemImage: "trash.fill")
        }
    }

    // MARK: - FAB (AC-01.1)

    private var fabButton: some View {
        Button {
            viewModel.isShowingQuickAdd = true
            HapticManager.impact(.light)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
        }
        .accessibilityLabel("Add new task")
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var settingsButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.isShowingSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Settings")
        }
    }

    // MARK: - Empty State (PRD §5 MVP Screen Inventory)

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)

            Text("Your Inbox is empty")
                .font(.title3.weight(.semibold))

            Text("Tap + to add your first task")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    // MARK: - Helpers

    private func taskDetailDestination(for task: TaskItem) -> TaskDetailView {
        TaskDetailView(
            viewModel: TaskDetailViewModel(
                taskId: task.id,
                repository: viewModel.repository
            )
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        InboxView(viewModel: InboxViewModel(repository: PreviewTaskRepository()))
    }
    .modelContainer(for: TaskItem.self, inMemory: true)
}
