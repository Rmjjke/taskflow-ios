// QuickAddView.swift
// TaskFlow — Presentation Layer
//
// Half-sheet for fast task capture. Opens within 150ms via FAB.
// Spec: US-01 — Quick Task Capture, AC-01.1 through AC-01.5.

import SwiftUI

struct QuickAddView: View {

    // MARK: - ViewModel & Environment

    @State var viewModel: QuickAddViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Focus

    @FocusState private var isTitleFocused: Bool // AC-01.1 — keyboard auto-appears

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Title field
                titleField

                Divider().padding(.horizontal)

                // Inline pickers (collapsed by default)
                if viewModel.isDatePickerExpanded {
                    DatePickerPanel(viewModel: viewModel)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if viewModel.isPriorityPickerExpanded {
                    PriorityPickerPanel(selectedPriority: $viewModel.priority)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Toolbar row: date, priority, project icons + Add button
                toolbarRow

                Spacer()
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar { cancelButton }
        }
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(viewModel.isDirty) // force confirmation if dirty
        .onAppear { isTitleFocused = true }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isDatePickerExpanded)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isPriorityPickerExpanded)
        .confirmationDialog(
            "Discard task?",
            isPresented: $viewModel.showDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) { }
        }
    }

    // MARK: - Title Field

    private var titleField: some View {
        TextField("Task title…", text: $viewModel.title, axis: .vertical)
            .font(.body)
            .focused($isTitleFocused)
            .submitLabel(.done)
            .onSubmit { trySave() }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .accessibilityLabel("Task title")
    }

    // MARK: - Toolbar Row (AC-01.5)

    private var toolbarRow: some View {
        HStack(spacing: 4) {
            // Due Date icon
            ToolbarIconButton(
                systemImage: "calendar",
                isActive: viewModel.dueDate != nil,
                accessibilityLabel: "Set due date"
            ) {
                withAnimation { viewModel.isDatePickerExpanded.toggle() }
            }

            // Priority icon
            ToolbarIconButton(
                systemImage: "flag",
                isActive: viewModel.priority != .none,
                tintColor: viewModel.priority.color,
                accessibilityLabel: "Set priority"
            ) {
                withAnimation { viewModel.isPriorityPickerExpanded.toggle() }
            }

            // Project icon (v1.0 — disabled in MVP)
            ToolbarIconButton(
                systemImage: "folder",
                isActive: false,
                accessibilityLabel: "Assign to project"
            ) { }
            .disabled(true)
            .opacity(0.4)

            Spacer()

            // Add button (AC-01.3)
            Button(action: trySave) {
                Text("Add")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(viewModel.canSave ? Color.accentColor : Color.secondary.opacity(0.3))
                    .foregroundStyle(viewModel.canSave ? .white : .secondary)
                    .clipShape(Capsule())
            }
            .disabled(!viewModel.canSave)
            .accessibilityLabel("Add task")
            .sensoryFeedback(.success, trigger: viewModel.canSave) // haptic on enable
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Cancel Button (AC-01.4)

    @ToolbarContentBuilder
    private var cancelButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") {
                if viewModel.isDirty {
                    viewModel.showDiscardConfirmation = true
                } else {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Helpers

    private func trySave() {
        guard viewModel.canSave else { return }
        do {
            try viewModel.save()
            dismiss()
        } catch {
            viewModel.errorMessage = "Could not save task."
        }
    }
}

// MARK: - Inline Date Picker Panel

private struct DatePickerPanel: View {

    @Bindable var viewModel: QuickAddViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Quick chips (AC-02.2)
            HStack(spacing: 8) {
                QuickChip(label: "Today")    { viewModel.selectToday() }
                QuickChip(label: "Tomorrow") { viewModel.selectTomorrow() }
                QuickChip(label: "Next Week") { viewModel.selectNextWeek() }
                if viewModel.dueDate != nil {
                    Button {
                        viewModel.clearDueDate()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Clear due date")
                }
            }
            .padding(.horizontal)

            // Calendar grid
            DatePicker(
                "",
                selection: Binding(
                    get: { viewModel.dueDate ?? Date() },
                    set: { viewModel.dueDate = $0 }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .padding(.horizontal)

            // Optional time toggle (AC-02.3)
            Toggle(isOn: $viewModel.hasTime) {
                Label("Add time", systemImage: "clock")
                    .font(.subheadline)
            }
            .toggleStyle(.button)
            .padding(.horizontal)

            if viewModel.hasTime {
                DatePicker(
                    "Time",
                    selection: Binding(
                        get: { viewModel.dueTime ?? Date() },
                        set: { viewModel.dueTime = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .datePickerStyle(.wheel)
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Inline Priority Picker Panel

private struct PriorityPickerPanel: View {

    @Binding var selectedPriority: Priority

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Priority.allCases) { level in
                Button {
                    selectedPriority = level
                } label: {
                    Label(level.label, systemImage: level.symbolName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(selectedPriority == level ? .white : level.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(selectedPriority == level ? level.color : level.color.opacity(0.12))
                        )
                }
                .accessibilityLabel("Priority: \(level.label)")
                .accessibilityAddTraits(selectedPriority == level ? .isSelected : [])
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Quick Chip Button

private struct QuickChip: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.quaternary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Toolbar Icon Button

private struct ToolbarIconButton: View {
    let systemImage: String
    var isActive: Bool = false
    var tintColor: Color = .accentColor
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isActive ? systemImage + ".fill" : systemImage)
                .foregroundStyle(isActive ? tintColor : .secondary)
                .font(.title3)
                .frame(width: 36, height: 36)
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Preview

#Preview {
    QuickAddView(viewModel: QuickAddViewModel(repository: PreviewTaskRepository()))
        .modelContainer(for: TaskItem.self, inMemory: true)
}
