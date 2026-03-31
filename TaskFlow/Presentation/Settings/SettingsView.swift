// SettingsView.swift
// TaskFlow — Presentation Layer
//
// Settings root screen.
// MVP exposes Trash with a live item-count badge (AC-04.5).
// v1.0 settings rows are shown as disabled placeholders.

import SwiftUI
import SwiftData

struct SettingsView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Live Trash Count (AC-04.5)
    // @Query fetches only soft-deleted items so the badge stays in sync
    // automatically whenever the trash changes — no manual refresh needed.
    @Query(filter: #Predicate<TaskItem> { $0.isDeleted == true })
    private var trashedItems: [TaskItem]

    private var trashCount: Int { trashedItems.count }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {

                // MARK: Data
                Section("Data") {
                    NavigationLink(destination: trashDestination) {
                        HStack {
                            Label("Trash", systemImage: "trash")
                            Spacer()
                            // Badge (AC-04.5) — visible only when trash has items
                            if trashCount > 0 {
                                Text("\(trashCount)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // MARK: Coming in v1.0 (disabled placeholders)
                Section("Coming in v1.0") {
                    disabledRow(label: "Account & Sync",   icon: "icloud")
                    disabledRow(label: "Notifications",    icon: "bell")
                    disabledRow(label: "Appearance",       icon: "paintpalette")
                    disabledRow(label: "TaskFlow Pro",     icon: "star.circle")
                    disabledRow(label: "Siri & Shortcuts", icon: "mic")
                    disabledRow(label: "Privacy",          icon: "hand.raised")
                }
                .disabled(true)

                // MARK: About
                Section("About") {
                    versionRow("Version", value: Bundle.main.appVersion)
                    versionRow("Build",   value: Bundle.main.buildNumber)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Destinations

    private var trashDestination: some View {
        TrashView(viewModel: TrashViewModel(repository: TaskRepository(modelContext: modelContext)))
    }

    // MARK: - Row Helpers

    private func disabledRow(label: String, icon: String) -> some View {
        Label(label, systemImage: icon)
            .foregroundStyle(.secondary)
    }

    private func versionRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Bundle Helpers

private extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}
