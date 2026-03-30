// TrashView.swift
// TaskFlow — Presentation Layer
//
// Shows all soft-deleted tasks. Accessible from Settings.
// Spec: US-04 AC-04.4 — Trash view with restore, individual delete, and empty trash.

import SwiftUI

struct TrashView: View {

    // MARK: - ViewModel

    @State var viewModel: TrashViewModel

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.trashedTasks.isEmpty {
                emptyState
            } else {
                trashList
            }
        }
        .navigationTitle("Trash")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { emptyTrashButton }
        .onAppear { viewModel.onAppear() }
        .confirmationDialog(
            "Empty Trash?",
            isPresented: $viewModel.showEmptyTrashConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All (\(viewModel.trashedTasks.count))", role: .destructive) {
                viewModel.emptyTrash()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("All items in the Trash will be permanently deleted. This action cannot be undone.")
        }
    }

    // MARK: - Trash List

    private var trashList: some View {
        List {
            ForEach(viewModel.trashedTasks) { task in
                TrashRowView(task: task) {
                    viewModel.restore(id: task.id)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.permanentlyDelete(id: task.id)
                    } label: {
                        Label("Delete Forever", systemImage: "trash.slash.fill")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "trash")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text("Trash is empty")
                .font(.title3.weight(.semibold))
            Text("Deleted tasks appear here for 30 days.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var emptyTrashButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if !viewModel.trashedTasks.isEmpty {
                Button("Empty") {
                    viewModel.showEmptyTrashConfirmation = true
                }
                .foregroundStyle(.red)
            }
        }
    }
}

// MARK: - Trash Row View

private struct TrashRowView: View {
    let task: TaskItem
    let onRestore: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .strikethrough()
                    .foregroundStyle(.secondary)
                if let deletedAt = task.deletedAt {
                    Text("Deleted \(deletedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Button("Restore") { onRestore() }
                .font(.subheadline)
                .buttonStyle(.bordered)
                .accessibilityLabel("Restore task: \(task.title)")
        }
    }
}
