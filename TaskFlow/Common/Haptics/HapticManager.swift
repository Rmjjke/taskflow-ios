// HapticManager.swift
// TaskFlow — Common / Haptics
//
// Centralized haptic feedback manager.
// Reduces scattered UIFeedbackGenerator instantiation across the app.
// Respects the system "Reduce Motion" accessibility setting for haptics.
// Spec: US-03 AC-03.2 (.success haptic on complete).

import UIKit

@MainActor
enum HapticManager {

    // MARK: - Feedback Types

    /// `.success` haptic — fires on task completion (AC-03.2).
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// `.warning` haptic — fires on delete confirmation alerts.
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    /// `.medium` impact — fires on sheet open / FAB tap (AC-01.3).
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Light selection haptic — fires when switching priority level.
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
