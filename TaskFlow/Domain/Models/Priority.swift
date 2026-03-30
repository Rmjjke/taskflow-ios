// Priority.swift
// TaskFlow — Domain Layer
//
// Four-level priority system per PRD US-05 / AC-05.2.
// RawRepresentable as Int for SwiftData storage.
// Conforms to Comparable so tasks can be sorted by priority within a date group.

import SwiftUI

/// Priority levels for a TaskItem.
///
/// Sort order: high (0) → medium (1) → low (2) → none (3).
/// Tasks are sorted by priority **within** the same date bucket — not globally —
/// to preserve the user's temporal intent (PRD AC-05 technical notes).
enum Priority: Int, Codable, CaseIterable, Comparable, Identifiable {

    case high   = 0
    case medium = 1
    case low    = 2
    case none   = 3

    // MARK: - Identifiable

    var id: Int { rawValue }

    // MARK: - Comparable

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    // MARK: - Display

    /// Human-readable label shown in pickers and accessibility announcements.
    var label: String {
        switch self {
        case .high:   return "High"
        case .medium: return "Medium"
        case .low:    return "Low"
        case .none:   return "None"
        }
    }

    /// SF Symbol name for the flag icon used in list rows and pickers.
    /// `none` uses the outline variant (no fill) to indicate absence of priority.
    var symbolName: String {
        switch self {
        case .none: return "flag"
        default:    return "flag.fill"
        }
    }

    /// Accent color per design spec (AC-05.2).
    /// Color is never the sole differentiator — icon + label are always co-present.
    var color: Color {
        switch self {
        case .high:   return Color(hex: "#FF3B30") // iOS system red
        case .medium: return Color(hex: "#FF9500") // iOS system orange
        case .low:    return Color(hex: "#007AFF") // iOS system blue
        case .none:   return .secondary
        }
    }

    /// Whether a flag indicator should be shown in the task list row.
    /// `none` priority tasks display no flag to keep the list clean.
    var showsFlag: Bool { self != .none }
}
