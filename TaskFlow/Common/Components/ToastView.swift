// ToastView.swift
// TaskFlow — Common / Components
//
// Bottom toast / snackbar shown after task complete or delete actions.
// Displays a message with an optional undo action button.
// Spec: US-03 AC-03.4, US-04 AC-04.3.
// Positioned above the FAB (parent sets bottom padding).

import SwiftUI

struct ToastView: View {

    // MARK: - Properties

    let toast: ToastMessage
    let onDismiss: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            Text(toast.message)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            // Action button only rendered when a label is provided (e.g. hidden for "Task reopened.")
            if !toast.actionLabel.isEmpty {
                Button(toast.actionLabel) {
                    toast.action()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.white.opacity(0.2))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color(uiColor: .label))
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .onTapGesture { onDismiss() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(toast.message). \(toast.actionLabel) button available.")
    }
}

// MARK: - Preview

#Preview {
    ZStack(alignment: .bottom) {
        Color(.systemGroupedBackground).ignoresSafeArea()
        ToastView(
            toast: ToastMessage(message: "Task completed.", actionLabel: "Undo", action: {}),
            onDismiss: {}
        )
        .padding(.bottom, 80)
    }
}
