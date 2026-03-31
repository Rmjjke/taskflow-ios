// ContentView.swift
// TaskFlow — App Layer
//
// Root of the view hierarchy. Implements the 3-tab bottom navigation shell
// with a shared FAB (Today + Scheduled), shared Settings sheet, and per-tab
// NavigationStack with Task Detail destination registration.
//
// Spec: US-M1 (all ACs) — App Shell & Bottom Navigation.

import SwiftUI
import SwiftData

// MARK: - App Tab

enum AppTab: Int, Hashable {
    case today, scheduled, archive
}

// MARK: - Content View

struct ContentView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Shell State

    @State private var selectedTab: AppTab = .today   // AC-M1.1 — default Today
    @State private var showSettings  = false
    @State private var showQuickAdd  = false

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottomTrailing) {

            // ── Tab Bar (AC-M1.2) ─────────────────────────────────────────
            TabView(selection: $selectedTab) {

                // Today Tab
                NavigationStack {
                    TodayView(repository: repository)
                        .navigationTitle("Today")
                        .navigationBarTitleDisplayMode(.large)
                        .toolbar { settingsToolbar }
                        .navigationDestination(for: UUID.self) { taskDetailView(for: $0) }
                }
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
                .tag(AppTab.today)

                // Scheduled Tab
                NavigationStack {
                    ScheduledView(repository: repository)
                        .navigationTitle("Scheduled")
                        .navigationBarTitleDisplayMode(.large)
                        .toolbar { settingsToolbar }
                        .navigationDestination(for: UUID.self) { taskDetailView(for: $0) }
                }
                .tabItem { Label("Scheduled", systemImage: "calendar") }
                .tag(AppTab.scheduled)

                // Archive Tab (no FAB — AC-M1.4)
                NavigationStack {
                    ArchiveView(repository: repository)
                        .navigationTitle("Archive")
                        .navigationBarTitleDisplayMode(.large)
                        .toolbar { settingsToolbar }
                        .navigationDestination(for: UUID.self) { taskDetailView(for: $0) }
                }
                .tabItem { Label("Archive", systemImage: "archivebox.fill") }
                .tag(AppTab.archive)
            }
            .tint(.indigo)   // AC-M1.7 — indigo accent for selected tab item

            // ── FAB (AC-M1.4) — Today + Scheduled only, above tab bar ─────
            if selectedTab != .archive {
                FABButton { showQuickAdd = true }
                    .padding(.trailing, 20)
                    .padding(.bottom, 72)   // clears tab bar (~49pt) + safe area + gap
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.25), value: selectedTab)

        // ── Sheets ────────────────────────────────────────────────────────
        // Quick-Add (US-01)
        .sheet(isPresented: $showQuickAdd) {
            QuickAddView(viewModel: QuickAddViewModel(repository: repository))
        }
        // Settings (AC-M1.5)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Helpers

    /// Lightweight `TaskRepository` wrapper around the injected model context.
    /// Re-creating per call is safe — `modelContext` is stable and `TaskRepository`
    /// holds no state itself; all persistence lives in the SwiftData store.
    private var repository: TaskRepository {
        TaskRepository(modelContext: modelContext)
    }

    /// Builds a Task Detail push destination for the given task ID.
    private func taskDetailView(for taskId: UUID) -> TaskDetailView {
        TaskDetailView(
            viewModel: TaskDetailViewModel(
                taskId: taskId,
                repository: repository
            )
        )
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var settingsToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Settings")
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}
