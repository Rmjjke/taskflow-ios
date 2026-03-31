// EmptyStateView.swift
// TaskFlow — Common / Components
//
// Reusable empty-state illustration + CTA used by Today, Scheduled, and Archive tabs.
// Spec: US-M3 AC-M3.2, AC-M3.3, AC-M3.4.

import SwiftUI

struct EmptyStateView: View {

    // MARK: - Properties

    let icon: String
    let iconColor: Color
    let headline: String
    let message: String
    var ctaTitle: String?   = nil
    var ctaAction: (() -> Void)? = nil

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(iconColor.opacity(0.7))

            Text(headline)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let ctaTitle, let ctaAction {
                Button(ctaTitle, action: ctaAction)
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .padding(.top, 4)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
        // Transition used by parent to fade in/out (AC-M3.5)
        .transition(.opacity)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        EmptyStateView(
            icon: "checkmark.circle.fill",
            iconColor: .indigo,
            headline: "You're all clear",
            message: "Tap + to add a task, or check Scheduled for upcoming work.",
            ctaTitle: "+ Add a task",
            ctaAction: {}
        )
        EmptyStateView(
            icon: "archivebox",
            iconColor: .secondary,
            headline: "No completed tasks yet",
            message: "Tasks you complete will be saved here."
        )
    }
}
