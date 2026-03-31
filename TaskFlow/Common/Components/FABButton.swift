// FABButton.swift
// TaskFlow — Common / Components
//
// Reusable Floating Action Button used by Today and Scheduled tabs.
// Spec: US-M1 AC-M1.4 — FAB visible on Today + Scheduled, hidden on Archive.

import SwiftUI

struct FABButton: View {

    // MARK: - Properties

    let action: () -> Void

    @State private var isPressed = false

    // MARK: - Body

    var body: some View {
        Button {
            HapticManager.impact(.light)
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.indigo)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                .scaleEffect(isPressed ? 0.92 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        }
        .accessibilityLabel("Add new task")
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack(alignment: .bottomTrailing) {
        Color(.systemGroupedBackground).ignoresSafeArea()
        FABButton { }
            .padding(.trailing, 20)
            .padding(.bottom, 72)
    }
}
