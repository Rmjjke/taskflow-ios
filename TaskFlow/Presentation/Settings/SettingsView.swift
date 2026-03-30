// SettingsView.swift
// TaskFlow — Presentation Layer
//
// Settings screen. MVP exposes Trash access only.
// Additional settings (Notifications, Appearance, Subscription, etc.) added in v1.0.
// PRD §10 — Settings navigation structure.

import SwiftUI
import SwiftData

struct SettingsView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // MARK: Data
                Section("Data") {
                    NavigationLink(destination: trashDestination) {
                        Label("Trash", systemImage: "trash")
                    }
                }

                // MARK: Coming in v1.0 (disabled placeholders)
                Section("Coming in v1.0") {
                    Label("Account & Sync", systemImage: "icloud")
                        .foregroundStyle(.secondary)
                    Label("Notifications", systemImage: "bell")
                        .foregroundStyle(.secondary)
                    Label("Appearance", systemImage: "paintpalette")
                        .foregroundStyle(.secondary)
                    Label("TaskFlow Pro", systemImage: "star.circle")
                        .foregroundStyle(.secondary)
                    Label("Siri & Shortcuts", systemImage: "mic")
                        .foregroundStyle(.secondary)
                }
                .disabled(true)

                // MARK: About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.appVersion)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.buildNumber)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
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
