// TaskDetailView.swift
// TaskFlow — Presentation Layer
//
// Full-screen push view for editing a task and viewing its details.
// All fields are inline-editable with auto-save.
// Spec: US-02 (due date), US-03 (complete), US-04 (delete), US-06 (notes).

import SwiftUI

struct TaskDetailView: View {

    // MARK: - ViewModel & Environment

    @State var viewModel: TaskDetailViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Local State

    @FocusState private var focusedField: Field?

    private enum Field { case title, notes }

    // MARK: - Body

    var body: some View {
        Group {
            if let task = viewModel.task {
                content(task: task)
            } else {
                ProgressView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .onAppear { viewModel.onAppear() }
        .toolbar { toolbarItems }
    }

    // MARK: - Main Content

    @ViewBuilder
    private func content(task: TaskItem) -> some View {
        Form {
            // Title
            Section {
                HStack(alignment: .top, spacing: 12) {
                    CheckboxView(isCompleted: task.isCompleted) {
                        task.isCompleted ? viewModel.uncompleteTask() : viewModel.completeTask()
                    }
                    TextField("Task title", text: $viewModel.title, axis: .vertical)
                        .font(.title3.weight(.semibold))
                        .focused($focusedField, equals: .title)
                        .onSubmit { viewModel.commitTitle() }
                        .onChange(of: focusedField) { old, new in
                            if old == .title && new != .title { viewModel.commitTitle() }
                        }
                        .strikethrough(task.isCompleted, color: .secondary)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                }
            }

            // Metadata rows
            Section {
                // Due Date (US-02)
                dueDateRow

                // Priority (US-05)
                priorityRow
            }

            // Notes (US-06)
            Section {
                TextEditor(text: $viewModel.notes)
                    .font(.body)
                    .frame(minHeight: 100)
                    .focused($focusedField, equals: .notes)
                    .onChange(of: viewModel.notes) { viewModel.scheduleNoteSave() }
                    .accessibilityLabel("Notes for \(viewModel.title)")
                    .overlay(alignment: .topLeading) {
                        if viewModel.notes.isEmpty {
                            Text("Add notes, links, or details…")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
            } header: {
                HStack {
                    Text("Notes")
                    Spacer()
                    if viewModel.isSaved {
                        Text("Saved")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .transition(.opacity)
                    }
                }
            }

            // Metadata footer
            Section {
                Text("Created \(task.createdAt.formatted(date: .long, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Due Date Row (US-02)

    private var dueDateRow: some View {
        DisclosureGroup(
            isExpanded: .constant(false),
            content: {
                DatePicker(
                    "Date",
                    selection: Binding(
                        get: { viewModel.dueDate ?? Date() },
                        set: { viewModel.dueDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .onChange(of: viewModel.dueDate) { viewModel.commitDueDate() }

                Toggle("Add time", isOn: $viewModel.hasTime)
                    .onChange(of: viewModel.hasTime) { viewModel.commitDueDate() }

                if viewModel.hasTime {
                    DatePicker(
                        "Time",
                        selection: Binding(
                            get: { viewModel.dueTime ?? Date() },
                            set: { viewModel.dueTime = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .onChange(of: viewModel.dueTime) { viewModel.commitDueDate() }
                }
            },
            label: {
                Label {
                    if let dueDate = viewModel.dueDate {
                        Text(dueDate.taskDueDateLabel)
                            .foregroundStyle(viewModel.task?.isOverdue == true ? .red : .primary)
                    } else {
                        Text("No due date")
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "calendar")
                }
            }
        )
    }

    // MARK: - Priority Row (US-05)

    private var priorityRow: some View {
        HStack {
            Label("Priority", systemImage: "flag")
            Spacer()
            Menu {
                ForEach(Priority.allCases) { level in
                    Button {
                        viewModel.priority = level
                        viewModel.commitPriority()
                    } label: {
                        Label(level.label, systemImage: level.symbolName)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.priority.symbolName)
                        .foregroundStyle(viewModel.priority.color)
                    Text(viewModel.priority.label)
                        .foregroundStyle(viewModel.priority.color)
                }
                .font(.subheadline)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button(role: .destructive) {
                    viewModel.deleteTask()
                    dismiss()
                } label: {
                    Label("Delete Task", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        ToolbarItem(placement: .keyboard) {
            Button("Done") { focusedField = nil }
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TaskDetailView(
            viewModel: TaskDetailViewModel(
                taskId: UUID(),
                repository: PreviewTaskRepository()
            )
        )
    }
    .modelContainer(for: TaskItem.self, inMemory: true)
}
