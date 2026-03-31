// CheckboxView.swift
// TaskFlow — Common / Components
//
// Animated circular checkbox used in task rows and Task Detail.
// Spec: US-03 AC-03.1 (interactions), AC-03.2 (visual & haptic feedback).

import SwiftUI

struct CheckboxView: View {

    // MARK: - Properties

    let isCompleted: Bool
    let onTap: () -> Void

    // MARK: - Animation State

    @State private var isAnimating: Bool = false

    // MARK: - Body

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                Circle()
                    .strokeBorder(
                        isCompleted ? Color.accentColor : Color.secondary.opacity(0.4),
                        lineWidth: 1.5
                    )
                    .fill(isCompleted ? Color.accentColor : Color.clear)
                    .frame(width: 24, height: 24)
                    .scaleEffect(isAnimating ? 1.15 : 1.0)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isCompleted)
        }
        // Expand tap target to 44×44pt (NFR accessibility requirement)
        .frame(width: 44, height: 44)
        .buttonStyle(.plain)
        .accessibilityLabel(isCompleted ? "Completed, double-tap to uncomplete" : "Incomplete, double-tap to complete")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Interaction

    private func handleTap() {
        // Spring scale pulse — Swift 6 safe via structured Task (AC-03.2)
        withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
            isAnimating = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation { isAnimating = false }
        }
        onTap()
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        CheckboxView(isCompleted: false) { }
        CheckboxView(isCompleted: true) { }
    }
    .padding()
}
