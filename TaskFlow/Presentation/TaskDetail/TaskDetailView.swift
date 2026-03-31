// TaskDetailView.swift
// TaskFlow — Presentation Layer
//
// Full-screen push for editing a task and viewing its complete details.
// All fields are inline-editable with auto-save.
//
// Spec:
//   US-02 — Set Due Date & Time (AC-02.1 – AC-02.6)
//   US-03 — Complete a Task    (AC-03.1, AC-03.5)
//   US-04 — Delete a Task      (AC-04.1 via toolbar)

import SwiftUI

struct TaskDetailView: View {

    // MARK: - ViewModel & Environment

    @State var viewModel: TaskDetailViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Local View State

    @FocusState private var focusedField: Field?
    @State private var isDueDateExpanded: Bool = false    // AC-02.1 — controls date picker visibility

    private enum Field { case title, notes }

    // MARK: - Body

    var body: some View {
        Group {
            if let task = viewModel.task {
                content(task: task)
            } else {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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

            // ── Title & Checkbox ─────────────────────────────────────────
            Section {
                HStack(alignment: .top, spacing: 12) {
                    // Inline complete / uncomplete (AC-03.1, AC-03.5)
                    CheckboxView(isCompleted: task.isCompleted) {
                        task.isCompleted
                            ? viewModel.uncompleteTask()
                            : viewModel.completeTask()
                    }
                    TextField("Task title", text: $viewModel.title, axis: .vertical)
                        .font(.title3.weight(.semibold))
                        .focused($focusedField, equals: .title)
                        .onSubmit { viewModel.commitTitle() }
                        .onChange(of: focusedField) { old, new in
                            if old == .title, new != .title { viewModel.commitTitle() }
                        }
                        .strikethrough(task.isCompleted, color: .secondary)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                }
            }

            // ── Scheduling ───────────────────────────────────────────────
            Section {
                dueDateRow(task: task)
                priorityRow
            }

            // ── Notes (US-06 placeholder) ────────────────────────────────
            // Notes field is included in MVP detail screen per PRD §5 MVP Screen Inventory.
            // Full US-06 auto-save debounce and note indicator are wired here.
            Section {
                ZStack(alignment: .topLeading) {
                    if viewModel.notes.isEmpty {
                        Text("Add notes, links, or details…")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $viewModel.notes)
                        .font(.body)
                        .frame(minHeight: 100)
                        .focused($focusedField, equals: .notes)
                        .onChange(of: viewModel.notes) { viewModel.scheduleNoteSave() }
                        .accessibilityLabel("Notes for \(viewModel.title)")
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
                            .animation(.easeOut, value: viewModel.isSaved)
                    }
                }
            }

            // ── Metadata Footer ──────────────────────────────────────────
            Section {
                Text("Created \(task.createdAt.formatted(date: .long, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Due Date Row (US-02 AC-02.1 – AC-02.5)

    @ViewBuilder
    private func dueDateRow(task: TaskItem) -> some View {
        // Tappable label row — expands/collapses the inline picker (AC-02.1)
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isDueDateExpanded.toggle()
            }
        } label: {
            HStack {
                Label {
                    if let dueDate = viewModel.dueDate {
                        Text(dueDate.taskDueDateLabel)
                            .foregroundStyle(task.isOverdue ? .red : .primary)
                    } else {
                        Text("No due date")
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "calendar")
                        .foregroundStyle(viewModel.dueDate != nil ? Color.accentColor : Color.secondary)
                }
                Spacer()
                // Clear button visible only when a date is set (AC-02.4)
                if viewModel.dueDate != nil {
                    Button {
                        viewModel.dueDate = nil
                        viewModel.dueTime = nil
                        viewModel.hasTime = false
                        viewModel.commitDueDate()
                        isDueDateExpanded = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear due date")
                }
                Image(systemName: isDueDateExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.dueDate == nil ? "No due date, tap to set" : "Due \(viewModel.dueDate!.taskDueDateLabel), tap to change")

        // Expanded date picker section (AC-02.2 – AC-02.3)
        if isDueDateExpanded {
            // Quick-select chips (AC-02.2)
            HStack(spacing: 8) {
                quickChip("Today",     selected: viewModel.isToday) {
                    viewModel.selectToday()
                    viewModel.commitDueDate()
                }
                quickChip("Tomorrow",  selected: viewModel.isTomorrow) {
                    viewModel.selectTomorrow()
                    viewModel.commitDueDate()
                }
                quickChip("Next Week", selected: false) {
                    viewModel.selectNextWeek()
                    viewModel.commitDueDate()
                }
            }

            // Calendar grid (AC-02.2)
            DatePicker(
                "Date",
                selection: Binding(
                    get: { viewModel.dueDate ?? Date() },
                    set: {
                        viewModel.dueDate = $0
                        viewModel.commitDueDate()
                    }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()

            // Optional time row (AC-02.3)
            Toggle("Add time", isOn: $viewModel.hasTime)
                .onChange(of: viewModel.hasTime) { viewModel.commitDueDate() }

            if viewModel.hasTime {
                DatePicker(
                    "Time",
                    selection: Binding(
                        get: { viewModel.dueTime ?? Date() },
                        set: {
                            viewModel.dueTime = $0
                            viewModel.commitDueDate()
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .frame(height: 120)
                .labelsHidden()
            }
        }
    }

    // MARK: - Priority Row (US-05 — wired in detail for v1.0)

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
                    Text(viewModel.priority.label)
                }
                .font(.subheadline)
                .foregroundStyle(viewModel.priority.color)
            }
        }
    }

    // MARK: - Quick Chip Helper

    private func quickChip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(selected ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selected ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        // Overflow menu — delete action (AC-04.1 via detail)
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
        // Keyboard dismiss button
        ToolbarItem(placement: .keyboard) {
            Button("Done") { focusedField = nil }
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

// MARK: - TaskDetailViewModel Helpers (date chips)

private extension TaskDetailViewModel {
    var isToday: Bool {
        guard let d = dueDate else { return false }
        return Calendar.current.isDateInToday(d)
    }
    var isTomorrow: Bool {
        guard let d = dueDate else { return false }
        return Calendar.current.isDateInTomorrow(d)
    }
    func selectToday() {
        dueDate = Calendar.current.startOfDay(for: Date())
    }
    func selectTomorrow() {
        dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))
    }
    func selectNextWeek() {
        dueDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Calendar.current.startOfDay(for: Date()))
    }
}

// MARK: - Preview

#Preview {
    let repo = PreviewTaskRepository()
    let task = (try? repo.fetchActive().first) ?? TaskItem(title: "Preview task", priority: .high)
    NavigationStack {
        TaskDetailView(
            viewModel: TaskDetailViewModel(taskId: task.id, repository: repo)
        )
    }
}
