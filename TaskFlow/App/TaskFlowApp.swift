// TaskFlowApp.swift
// TaskFlow
//
// Entry point. Bootstraps the SwiftData ModelContainer and injects
// TaskRepository into the environment for all child views.
//
// MVP: local-only SwiftData store (no CloudKit).
// v1.0: add CloudKit configuration to ModelContainer.

import SwiftUI
import SwiftData

@main
struct TaskFlowApp: App {

    // MARK: - SwiftData Container

    /// Single shared ModelContainer for the app.
    /// MVP uses local store only — no CloudKit configuration.
    let container: ModelContainer = {
        let schema = Schema([TaskItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
