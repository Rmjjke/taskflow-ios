// ContentView.swift
// TaskFlow
//
// Root view of the app. For MVP there is no tab bar — the Inbox is the
// single root screen. Tab bar navigation is introduced in v1.0.
//
// MVP Navigation:
//   ContentView
//     └── InboxView (root)
//           ├── TaskDetailView   (push)
//           ├── QuickAddView     (sheet / FAB)
//           └── SettingsView     (sheet / gear icon)

import SwiftUI
import SwiftData

struct ContentView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Body

    var body: some View {
        NavigationStack {
            InboxView(viewModel: InboxViewModel(repository: TaskRepository(modelContext: modelContext)))
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}
