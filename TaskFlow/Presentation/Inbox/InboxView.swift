// InboxView.swift
// TaskFlow — Presentation Layer
//
// Root screen for MVP. Displays active and completed tasks.
// No tab bar in MVP — this IS the app (PRD §5 MVP Navigation).
//
// Screens reachable from here:
//   • QuickAddView  — presented as a sheet via FAB
//   • TaskDetailView — pushed via NavigationLink on row tap
//   • SettingsView   — presented as a sheet via gear icon

import SwiftUI

struct InboxView: View {

    // MARK: - ViewModel

    @State var viewModel: InboxViewModel

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            taskList
            fabButton
            if let toast = viewModel.toastMessage {
                ToastView(toast: toast) {
                    viewModel.dismissToast()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 80) // above FAB
                .zIndex(1)
            }
        }
        .navigationTitle("Inbox")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { settingsButton }
        .sheet(isPresented: $viewModel.isShowingQuickAdd, onDismiss: { viewModel.loadTasks() }) {
            QuickAddView(viewModel: QuickAddViewModel(repository: viewModel.repository))
        }
        .sheet(isPresented: $viewModel.isShowingSettings) {
            SettingsView()
        }
        .onAppear { viewModel.onAppear() }
        .animation(.easeInOut(duration: 0.3), value: viewModel.toastMessage?.id)
    }

    // MARK: - Task List

    private var taskList: some View {
        List {
            if viewModel.activeTasks.isEmpty && viewModel.completedTasks.isEmpty {
                emptyStateView
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                // Active tasks
                ForEach(viewModel.activeTasks) { task in
                    NavigationLink(destination: TaskDetailView(
                        viewModel: TaskDetailViewModel(taskId: task.id, repository: viewModel.repository)
                    )) {
                        TaskRowView(task: task) {
                            viewModel.completeTask(id: task.id)
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        completeSwipeAction(for: task)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        deleteSwipeAction(for: task)
                    }
                }

                // Completed section
                if !viewModel.completedTasks.isEmpty {
                    completedSection
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Completed Section (AC-03.3)

    private var completedSection: some View {
        Section {
            if viewModel.isCompletedSectionExpanded {
                ForEach(viewModel.completedTasks) { task in
                    NavigationLink(destination: TaskDetailView(
                        viewModel: TaskDetailViewModel(taskId: task.id, repository: viewModel.repository)
                    )) {
                        TaskRowView(task: task) {
                            viewModel.completeTask(id: task.id)
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

    private func deleteSwipeAction(for task: TaskItem) -> some View {
        Button(role: .destructive) {
            viewModel.deleteTask(id: task.id)
        } label: {
            Label("Delete", systemImage: "trash.fill")
        }
    }

    // MARK: - FAB (AC-01.1)

    private var fabButton: some View {
        Button {
            viewModel.isShowingQuickAdd = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
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
                .foregroundStyle(.primary)

            Text("Tap + to add your first task")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        InboxView(
            viewModel: InboxViewModel(
                repository: PreviewTaskRepository()
            )
        )
    }
    .modelContainer(for: TaskItem.self, inMemory: true)
}
