// QuickAddView.swift
// TaskFlow — Presentation Layer
//
// Half-sheet for fast task capture. Opens within 150ms via FAB.
// Spec: US-01 — Quick Task Capture (AC-01.1 – AC-01.5)
//       US-02 — Due Date inline picker (AC-02.1 – AC-02.4)

import SwiftUI
import UIKit

struct QuickAddView: View {

    // MARK: - ViewModel & Environment

    @State var viewModel: QuickAddViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Focus & Sheet State

    /// Auto-focused on sheet appear — keyboard opens immediately (AC-01.1).
    @FocusState private var isTitleFocused: Bool

    /// Tracks the active detent so we can programmatically drive it to .large
    /// when the calendar opens — ensuring the Add button is always visible.
    @State private var selectedDetent: PresentationDetent = .height(260)

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                titleField

                Divider().padding(.horizontal)

                // Inline pickers — expand vertically inside the sheet.
                // The sheet detent reacts via .presentationDetents below.
                if viewModel.isDatePickerExpanded {
                    DatePickerPanel(viewModel: viewModel)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if viewModel.isPriorityPickerExpanded {
                    PriorityPickerPanel(selectedPriority: $viewModel.priority)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                toolbarRow

                Spacer()
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar { cancelButton }
        }
        // Detent set drives which stops are available; selectedDetent drives the actual position.
        .presentationDetents(currentDetents, selection: $selectedDetent)
        .presentationDragIndicator(.visible)
        // Prevent accidental swipe-dismiss when user has typed a title (AC-01.4).
        .interactiveDismissDisabled(viewModel.isDirty)
        .onAppear { isTitleFocused = true }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isDatePickerExpanded)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isPriorityPickerExpanded)
        // Auto-expand to .large when calendar opens so the Add button is never hidden.
        .onChange(of: viewModel.isDatePickerExpanded) { _, expanded in
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedDetent = expanded ? .large : .height(260)
            }
        }
        // Priority picker only needs .medium.
        .onChange(of: viewModel.isPriorityPickerExpanded) { _, expanded in
            withAnimation(.easeInOut(duration: 0.25)) {
                if expanded && !viewModel.isDatePickerExpanded {
                    selectedDetent = .medium
                } else if !expanded && !viewModel.isDatePickerExpanded {
                    selectedDetent = .height(260)
                }
            }
        }
        .confirmationDialog(
            "Discard task?",
            isPresented: $viewModel.showDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) {
                viewModel.speech.stopRecording()
                dismiss()
            }
            Button("Keep Editing", role: .cancel) { }
        }
        // Microphone permission denied alert
        .alert("Microphone Access Required", isPresented: $viewModel.showMicPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To dictate task titles, allow microphone access in Settings → Privacy → Microphone.")
        }
        .onDisappear { viewModel.speech.stopRecording() }
    }

    // MARK: - Dynamic Detents

    private var currentDetents: Set<PresentationDetent> {
        if viewModel.isDatePickerExpanded {
            return [.large]            // calendar needs full height
        }
        if viewModel.isPriorityPickerExpanded {
            return [.medium, .large]
        }
        return [.height(260)]
    }

    // MARK: - Title Field (AC-01.1, AC-01.2)

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

    // MARK: - Toolbar Row (AC-01.5, AC-02.2)

    private var toolbarRow: some View {
        HStack(spacing: 4) {

            // ── Due Date icon / chip ────────────────────────────────────────
            // When a date is selected, replace the bare icon with a readable
            // chip showing the formatted label (e.g. "Today", "Mon Apr 6").
            // Tapping again collapses/expands the picker (AC-02.2).
            if let dueDate = viewModel.dueDate {
                // Date chip
                Button {
                    withAnimation { viewModel.isDatePickerExpanded.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text(dueDate.taskDueDateLabel)
                            .font(.subheadline)
                        // Clear button (AC-02.4)
                        Button {
                            viewModel.clearDueDate()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear due date")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Due date: \(dueDate.taskDueDateLabel). Tap to edit.")
            } else {
                // Bare calendar icon
                ToolbarIconButton(
                    systemImage: "calendar",
                    isActive: false,
                    accessibilityLabel: "Set due date"
                ) {
                    withAnimation { viewModel.isDatePickerExpanded.toggle() }
                }
            }

            // ── Priority icon ───────────────────────────────────────────────
            ToolbarIconButton(
                systemImage: "flag",
                isActive: viewModel.priority != .none,
                tintColor: viewModel.priority.color,
                accessibilityLabel: "Set priority: \(viewModel.priority.label)"
            ) {
                withAnimation { viewModel.isPriorityPickerExpanded.toggle() }
            }

            // ── Project icon (v1.0 — disabled in MVP) ──────────────────────
            ToolbarIconButton(
                systemImage: "folder",
                isActive: false,
                accessibilityLabel: "Assign to project (not available in this version)"
            ) { }
            .disabled(true)
            .opacity(0.35)

            // ── Dictation mic ───────────────────────────────────────────────
            DictationButton(isRecording: viewModel.speech.isRecording) {
                viewModel.toggleDictation()
            }

            Spacer()

            // ── Add button (AC-01.3) ────────────────────────────────────────
            Button(action: trySave) {
                Text("Add")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 9)
                    .background(viewModel.canSave ? Color.accentColor : Color.secondary.opacity(0.25))
                    .foregroundStyle(viewModel.canSave ? .white : .secondary)
                    .clipShape(Capsule())
            }
            .disabled(!viewModel.canSave)
            .accessibilityLabel("Add task")
            .animation(.easeInOut(duration: 0.15), value: viewModel.canSave)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
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

    // MARK: - Save

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

// MARK: - Date Picker Panel (US-02 AC-02.1 – AC-02.4)

private struct DatePickerPanel: View {

    @Bindable var viewModel: QuickAddViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Quick chips (AC-02.2)
            HStack(spacing: 8) {
                QuickChip(label: "Today",     isSelected: viewModel.isToday)    { viewModel.selectToday() }
                QuickChip(label: "Tomorrow",  isSelected: viewModel.isTomorrow) { viewModel.selectTomorrow() }
                QuickChip(label: "Next Week", isSelected: false)                { viewModel.selectNextWeek() }
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
            HStack {
                Toggle(isOn: $viewModel.hasTime) {
                    Label("Add time", systemImage: "clock")
                        .font(.subheadline)
                }
                .toggleStyle(.button)
            }
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
                .frame(height: 120)
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Priority Picker Panel (US-05 — included in MVP Quick-Add toolbar)

private struct PriorityPickerPanel: View {

    @Binding var selectedPriority: Priority

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Priority.allCases) { level in
                    PriorityChip(level: level, isSelected: selectedPriority == level) {
                        selectedPriority = level
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Reusable Subviews

private struct PriorityChip: View {
    let level: Priority
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let bg = isSelected ? level.color : level.color.opacity(0.12)
        let fg: Color = isSelected ? .white : level.color
        Button(action: action) {
            Label(level.label, systemImage: level.symbolName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(fg)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(bg))
        }
        .accessibilityLabel("Priority: \(level.label)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct QuickChip: View {
    let label: String
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ToolbarIconButton: View {
    let systemImage: String
    var isActive: Bool = false
    var tintColor: Color = .accentColor
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isActive ? "\(systemImage).fill" : systemImage)
                .foregroundStyle(isActive ? tintColor : Color.secondary)
                .font(.title3)
                .frame(width: 36, height: 36)
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

/// Mic button that pulses red while recording (dictation active state).
private struct DictationButton: View {
    let isRecording: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isRecording {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 32, height: 32)
                }
                Image(systemName: isRecording ? "mic.fill" : "mic")
                    .foregroundStyle(isRecording ? .red : Color.secondary)
                    .font(.title3)
            }
            .frame(width: 36, height: 36)
        }
        .accessibilityLabel(isRecording ? "Stop dictation" : "Dictate task title")
        // Subtle pulse ring when recording
        .overlay {
            if isRecording {
                Circle()
                    .stroke(Color.red.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 32, height: 32)
                    .scaleEffect(isRecording ? 1.3 : 1.0)
                    .opacity(isRecording ? 0 : 1)
                    .animation(
                        .easeOut(duration: 0.8).repeatForever(autoreverses: false),
                        value: isRecording
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        QuickAddView(viewModel: QuickAddViewModel(repository: PreviewTaskRepository()))
    }
}
