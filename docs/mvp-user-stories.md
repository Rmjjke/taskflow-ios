# MVP User Stories — Developer Specification
## TaskFlow iOS — Minimum Viable Product

| Field | Detail |
|---|---|
| **Product** | TaskFlow iOS |
| **Document Version** | 1.0 |
| **Status** | Ready for Development |
| **Author** | Product Owner |
| **Last Updated** | 2026-03-30 |
| **Target Milestone** | M1 — MVP Internal (2026-05-30) |
| **Target TestFlight** | M1.5 — MVP TestFlight (2026-06-10) |

> **This document is the single source of truth for MVP development.**
> All stories are self-contained and ordered for implementation. A developer can pick up any story whose dependencies are marked ✅ and begin immediately.

---

## Table of Contents

- [MVP at a Glance](#mvp-at-a-glance)
- [Story Map & Build Order](#story-map--build-order)
- [US-M0 — App Foundation & Data Layer](#us-m0--app-foundation--data-layer)
- [US-M1 — App Shell & Navigation](#us-m1--app-shell--navigation)
- [US-M2 — Inbox List View](#us-m2--inbox-list-view)
- [US-M3 — Empty State](#us-m3--empty-state)
- [US-01 — Quick Task Capture](#us-01--quick-task-capture)
- [US-03 — Complete a Task](#us-03--complete-a-task)
- [US-04 — Delete a Task](#us-04--delete-a-task)
- [US-M4 — Task Detail Screen (MVP)](#us-m4--task-detail-screen-mvp)
- [US-02 — Set Due Date & Time](#us-02--set-due-date--time)
- [Sprint Planning Summary](#sprint-planning-summary)

---

## MVP at a Glance

### The One Loop to Build
> **Open app → Capture a task → See it in a list → Complete it or delete it.**

That's the MVP. Everything outside this loop is deferred.

### MVP Screens (5 total)

```
┌─────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│                 │    │                  │    │                  │
│   INBOX         │───▶│  TASK DETAIL     │    │  QUICK-ADD SHEET │
│   (Root View)   │◀───│  (Push)          │    │  (Modal)         │
│                 │    │                  │    │                  │
└────────┬────────┘    └──────────────────┘    └──────────────────┘
         │ tap +
         ▼
         Quick-Add Sheet (modal)

         gear icon → SETTINGS ──▶ TRASH
```

### MVP Story Overview

| Story ID | Title | Points | Status |
|---|---|---|---|
| US-M0 | App Foundation & Data Layer | 3 | 🟡 Ready |
| US-M1 | App Shell & Navigation | 2 | 🔴 Blocked by M0 |
| US-M2 | Inbox List View | 3 | 🔴 Blocked by M1 |
| US-M3 | Empty State | 1 | 🔴 Blocked by M2 |
| US-01 | Quick Task Capture | 5 | 🔴 Blocked by M2 |
| US-03 | Complete a Task | 3 | 🔴 Blocked by US-01 |
| US-04 | Delete a Task | 2 | 🔴 Blocked by US-01 |
| US-M4 | Task Detail Screen (MVP) | 3 | 🔴 Blocked by US-01 |
| US-02 | Set Due Date & Time | 3 | 🔴 Blocked by M4 |
| **Total** | | **25** | |

---

## Story Map & Build Order

```
Sprint 1 (Foundation)
━━━━━━━━━━━━━━━━━━━━
  US-M0  App Foundation & Data Layer    [3 pts]
    └── US-M1  App Shell & Navigation   [2 pts]
          └── US-M2  Inbox List View    [3 pts]
                └── US-M3  Empty State  [1 pt]

Sprint 2 (Task Lifecycle)
━━━━━━━━━━━━━━━━━━━━━━━━
  US-01  Quick Task Capture             [5 pts]  ← needs M2 done
    ├── US-03  Complete a Task          [3 pts]
    └── US-04  Delete a Task            [2 pts]

Sprint 3 (Detail & Dates)
━━━━━━━━━━━━━━━━━━━━━━━━
  US-M4  Task Detail Screen (MVP)       [3 pts]  ← needs US-01 done
    └── US-02  Set Due Date & Time      [3 pts]

━━━━━━━━━━━━━━━━━━━━━━━
Total: 25 points / ~3 sprints (2-week sprints = 6 weeks)
```

---
---

## US-M0 — App Foundation & Data Layer

> **"As a developer, I need the SwiftData schema, model layer, and repository set up so all other stories have a reliable foundation to build on."**

### Story Details

| Field | Value |
|---|---|
| **Story ID** | US-M0 |
| **Type** | Technical / Foundation |
| **Release** | MVP |
| **Priority** | Must Have — Sprint 1 |
| **Story Points** | 3 |
| **Dependencies** | None — build first |
| **Blocks** | All other stories |

---

### Acceptance Criteria

#### AC-M0.1 — Xcode Project Structure
- [ ] Xcode project created with the name `TaskFlow`, bundle ID `com.taskflow.ios`.
- [ ] Minimum deployment target: **iOS 17.0**.
- [ ] SwiftUI lifecycle (`@main TaskFlowApp`), no UIKit app delegate.
- [ ] Folder structure follows MVVM:

```
TaskFlow/
├── App/
│   ├── TaskFlowApp.swift
│   └── AppEnvironment.swift
├── Data/
│   ├── Models/
│   │   ├── TaskItem.swift        ← SwiftData model
│   │   └── Priority.swift        ← Priority enum
│   └── Repository/
│       ├── TaskRepository.swift
│       └── TaskRepository+Mock.swift
├── Features/
│   ├── Inbox/
│   ├── TaskDetail/
│   └── Settings/
├── Shared/
│   ├── Components/
│   ├── Extensions/
│   └── Utils/
└── Resources/
    └── Assets.xcassets
```

#### AC-M0.2 — Task Data Model (`TaskItem`)

The `TaskItem` SwiftData model must define these fields exactly:

| Property | Type | Required | Default | Notes |
|---|---|---|---|---|
| `id` | `UUID` | Yes | `UUID()` | `@Attribute(.unique)` |
| `title` | `String` | Yes | — | max 255 chars enforced in UI |
| `notes` | `String?` | No | `nil` | plain text in MVP |
| `dueDate` | `Date?` | No | `nil` | stores date + time together |
| `priority` | `Priority` | Yes | `.none` | see AC-M0.3 |
| `projectId` | `UUID?` | No | `nil` | nil = Inbox |
| `tags` | `[String]` | Yes | `[]` | empty array default |
| `isCompleted` | `Bool` | Yes | `false` | |
| `completedAt` | `Date?` | No | `nil` | set when isCompleted = true |
| `isDeleted` | `Bool` | Yes | `false` | soft delete flag |
| `deletedAt` | `Date?` | No | `nil` | set when isDeleted = true |
| `createdAt` | `Date` | Yes | `Date()` | set once on creation |
| `updatedAt` | `Date` | Yes | `Date()` | updated on every mutation |

```swift
// Expected model signature
@Model
final class TaskItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String?
    var dueDate: Date?
    var priority: Priority
    var projectId: UUID?
    var tags: [String]
    var isCompleted: Bool
    var completedAt: Date?
    var isDeleted: Bool
    var deletedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    // ... init
}
```

#### AC-M0.3 — Priority Enum

```swift
enum Priority: Int, Codable, CaseIterable {
    case none   = 0
    case low    = 1
    case medium = 2
    case high   = 3

    var sortOrder: Int { ... }         // high=0, medium=1, low=2, none=3
    var label: String { ... }          // "High", "Medium", "Low", "None"
    var color: Color { ... }           // .red, .orange, .blue, .gray
    var iconName: String { ... }       // "flag.fill" or "flag"
}
```

- [ ] `Priority` conforms to `Codable` for SwiftData persistence.
- [ ] `Priority.sortOrder` returns inverse of rawValue (high priority = lowest sort number = appears first).
- [ ] `Priority.color` returns system semantic colors (not hex) to support dark mode.

#### AC-M0.4 — TaskRepository Protocol & Implementation

```swift
protocol TaskRepositoryProtocol {
    func fetchAll() throws -> [TaskItem]
    func fetchActive() throws -> [TaskItem]        // isDeleted == false, isCompleted == false
    func fetchCompleted() throws -> [TaskItem]     // isDeleted == false, isCompleted == true
    func fetchTrashed() throws -> [TaskItem]       // isDeleted == true

    func create(title: String, dueDate: Date?) throws -> TaskItem
    func update(_ task: TaskItem) throws
    func complete(_ task: TaskItem) throws
    func uncomplete(_ task: TaskItem) throws
    func softDelete(_ task: TaskItem) throws
    func restore(_ task: TaskItem) throws
    func permanentlyDelete(_ task: TaskItem) throws
    func purgeExpiredTrash() throws               // delete where deletedAt < 30 days ago
}
```

- [ ] `TaskRepository` is the concrete SwiftData implementation of `TaskRepositoryProtocol`.
- [ ] `TaskRepositoryMock` is an in-memory implementation used exclusively in unit tests and SwiftUI previews.
- [ ] Every mutating method updates `updatedAt = Date()` before writing.
- [ ] `fetchActive()` predicate: `isDeleted == false && isCompleted == false`.
- [ ] `fetchCompleted()` predicate: `isDeleted == false && isCompleted == true`.
- [ ] `fetchTrashed()` predicate: `isDeleted == true`.

#### AC-M0.5 — ModelContainer Setup

- [ ] `ModelContainer` is created once in `TaskFlowApp.swift` and injected via `.modelContainer(...)` modifier.
- [ ] Uses the default `ModelConfiguration` (stored in app's document directory, not in-memory).
- [ ] Preview container is a separate in-memory `ModelContainer` seeded with mock data.

```swift
// TaskFlowApp.swift
@main
struct TaskFlowApp: App {
    let container: ModelContainer = {
        let schema = Schema([TaskItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
```

#### AC-M0.6 — Computed Properties on TaskItem

- [ ] `var isOverdue: Bool` → `dueDate != nil && dueDate! < Calendar.current.startOfDay(for: Date()) && !isCompleted`
- [ ] `var isDueToday: Bool` → `dueDate != nil && Calendar.current.isDateInToday(dueDate!)`
- [ ] `var hasNotes: Bool` → `notes != nil && !notes!.isEmpty`
- [ ] `var formattedDueDate: String` → returns "Today", "Tomorrow", "Yesterday", or "Mon Apr 6" format

---

### Technical Notes

- Use `@Model` macro (SwiftData) — no manual `NSManagedObject` subclasses.
- `TaskItem` must be `final class` (SwiftData requirement).
- Do NOT put business logic in `TaskItem`. All mutations go through `TaskRepository`.
- `tags: [String]` is stored as a transformable attribute — verify SwiftData handles array of strings natively in iOS 17; use `@Attribute(.externalStorage)` if needed.
- `Priority` must be stored as `Int` (its `rawValue`) since SwiftData doesn't automatically persist custom enums without `Codable`.
- Previews: create a `PreviewRepository` extension returning `TaskRepositoryMock` pre-seeded with 5 sample tasks.

---

### Definition of Done

- [ ] Xcode project builds with zero warnings on a clean build.
- [ ] `TaskItem` schema compiles and `ModelContainer` initializes without crash.
- [ ] Unit tests for `TaskRepository`: `create`, `complete`, `uncomplete`, `softDelete`, `restore`, `permanentlyDelete`, `purgeExpiredTrash`.
- [ ] Unit tests for `Priority.sortOrder`, `Priority.color`, `Priority.label`.
- [ ] Unit tests for `TaskItem.isOverdue`, `isDueToday`, `hasNotes`, `formattedDueDate`.
- [ ] `TaskRepositoryMock` used in at least one SwiftUI Preview without crash.
- [ ] No force-unwraps outside of `fatalError` / app-init contexts.
- [ ] SwiftLint (or equivalent) passes with zero errors.

---
---

## US-M1 — App Shell & Navigation

> **"As a user, I want the app to open to a clear starting screen so I immediately know where I am and how to get around."**

### Story Details

| Field | Value |
|---|---|
| **Story ID** | US-M1 |
| **Type** | UI / Navigation Infrastructure |
| **Release** | MVP |
| **Priority** | Must Have — Sprint 1 |
| **Story Points** | 2 |
| **Dependencies** | US-M0 ✅ |
| **Blocks** | US-M2, US-M3, US-01, US-03, US-04 |

---

### Acceptance Criteria

#### AC-M1.1 — Root View
- [ ] App launches directly to the **Inbox screen** (no splash screen, no tab bar in MVP).
- [ ] App launch to first visible frame: **< 1.5 seconds** on iPhone 12.
- [ ] Root view is wrapped in a `NavigationStack` to support push navigation to Task Detail.

#### AC-M1.2 — Navigation Bar
- [ ] Navigation bar title: **"Inbox"** (`.large` title style).
- [ ] Trailing navigation item: **gear icon** (`gear` SF Symbol) that opens Settings.
- [ ] Settings opens as a **modal sheet** (not a push), presented with `.presentationDetents([.large])`.
- [ ] There is no back button on the Inbox (it is the root).

#### AC-M1.3 — Settings Screen (MVP Stub)
- [ ] Settings is a simple `List` with one section: **"Data"**.
- [ ] "Data" section contains one row: **"Trash"** (with trash SF symbol and a count badge if trash is non-empty).
- [ ] Tapping "Trash" pushes to the Trash view (see US-04).
- [ ] Settings has a **"Done"** button in the navigation bar (trailing) that dismisses the modal.
- [ ] Settings screen title: "Settings".
- [ ] Settings footer: app version string (e.g., "TaskFlow MVP 0.1.0 (Build 1)").

#### AC-M1.4 — Navigation to Task Detail
- [ ] Tapping a task row in the Inbox list pushes to `TaskDetailView`.
- [ ] `TaskDetailView` has a standard back chevron button (system default).
- [ ] Navigation uses `NavigationLink` or `.navigationDestination(for: UUID.self)` pattern — not sheet.

#### AC-M1.5 — FAB (Floating Action Button)
- [ ] A `+` circular FAB button is overlaid on the bottom-right of the Inbox screen.
- [ ] FAB position: `bottom: 28pt`, `trailing: 20pt` (safe area aware).
- [ ] FAB size: 56×56pt, circular, filled with accent color.
- [ ] FAB icon: `plus` SF Symbol, white, font weight `.semibold`.
- [ ] FAB has a subtle shadow: `radius: 8, y: 4, opacity: 0.2`.
- [ ] Tapping FAB opens the Quick-Add Sheet (US-01).
- [ ] FAB has a scale-down press animation: `scaleEffect(isPressed ? 0.92 : 1.0)`.

#### AC-M1.6 — Accent Color & Appearance
- [ ] App accent color: **Indigo** (`Color.indigo`) — defined in `Assets.xcassets` as `AccentColor`.
- [ ] Navigation bar uses default system appearance (no custom `UINavigationBarAppearance` in MVP).
- [ ] Dark mode: fully supported via system colors — no custom overrides needed in MVP.

---

### UI / UX Specification

```
┌──────────────────────────────────┐
│  Inbox                      ⚙️  │  ← NavigationBar, large title
├──────────────────────────────────┤
│                                  │
│   [task rows — see US-M2]        │
│                                  │
│                                  │
│                                  │
│                          ╭────╮  │
│                          │ +  │  │  ← FAB, bottom-right
│                          ╰────╯  │
└──────────────────────────────────┘

Settings Sheet:
┌──────────────────────────────────┐
│  Settings                  Done  │
├──────────────────────────────────┤
│  DATA                            │
│  ┌──────────────────────────┐    │
│  │ 🗑 Trash             (3) │    │
│  └──────────────────────────┘    │
│                                  │
│  TaskFlow MVP 0.1.0 (Build 1)    │  ← footer
└──────────────────────────────────┘
```

---

### Technical Notes

- `ContentView.swift` is the root — contains `NavigationStack` + `InboxView()` + FAB overlay.
- FAB overlay pattern:
  ```swift
  ZStack(alignment: .bottomTrailing) {
      InboxView()
      FABButton(action: { showQuickAdd = true })
          .padding(.bottom, 28)
          .padding(.trailing, 20)
  }
  ```
- Settings: use `@Environment(\.dismiss)` to close the sheet from the Done button.
- Version string: read from `Bundle.main.infoDictionary` keys `CFBundleShortVersionString` and `CFBundleVersion`.
- Navigation destination: register at root level —
  ```swift
  NavigationStack {
      InboxView()
          .navigationDestination(for: UUID.self) { taskId in
              TaskDetailView(taskId: taskId)
          }
  }
  ```

---

### Definition of Done

- [ ] App launches to Inbox in < 1.5s on iPhone 12 (measured in Release build).
- [ ] FAB renders correctly on iPhone SE (375pt), iPhone 15 (393pt), and iPhone 15 Pro Max (430pt).
- [ ] Gear icon opens Settings sheet; Done button dismisses it.
- [ ] Navigation to Task Detail works via `NavigationLink`.
- [ ] Dark mode: all elements render correctly with system colors.
- [ ] VoiceOver: FAB announced as "Add task, button." Settings gear announced as "Settings, button."
- [ ] No layout warnings in Xcode debug console.

---
---

## US-M2 — Inbox List View

> **"As a user, I want to see all my tasks in a list so I can quickly scan what needs to be done."**

### Story Details

| Field | Value |
|---|---|
| **Story ID** | US-M2 |
| **Type** | UI |
| **Release** | MVP |
| **Priority** | Must Have — Sprint 1 |
| **Story Points** | 3 |
| **Dependencies** | US-M0 ✅, US-M1 ✅ |
| **Blocks** | US-M3, US-01, US-03, US-04 |

---

### Acceptance Criteria

#### AC-M2.1 — Task List Display
- [ ] Inbox shows all tasks where `isDeleted == false`, split into two sections:
  1. **Active tasks** — `isCompleted == false`, sorted by `createdAt` descending (newest first).
  2. **Completed** — `isCompleted == true`, sorted by `completedAt` descending. Collapsed by default (see AC-M2.4).
- [ ] The list uses `List` style `.insetGrouped` or `.plain` — decision: **`.plain`** for MVP (cleaner feel).
- [ ] The list updates reactively — any change to the SwiftData store is reflected immediately without a manual refresh.

#### AC-M2.2 — Task Row Layout
Each active task row displays:

```
  ○  Buy groceries                     → Today
  ↑  ↑                                   ↑
checkbox  title (primary)               due date (secondary, trailing)
```

- [ ] **Checkbox**: 24×24pt circle outline. Tap target: 44×44pt.
- [ ] **Title**: `.body` font, primary label color. Single line in list; truncates with `…` if too long.
- [ ] **Due date label**: `.caption` font, secondary color. Shows relative label ("Today", "Tomorrow", "Mon Apr 6"). Color is **red** if task is overdue.
- [ ] No due date? → Due date area is empty (no placeholder text).
- [ ] Row height: minimum 48pt, self-sizing for multi-line titles.
- [ ] Row has a **disclosure indicator** (chevron) on the right, indicating it is tappable for detail.
- [ ] Row tap target: the entire row except the checkbox area opens Task Detail.
- [ ] Checkbox tap target: only the checkbox area triggers completion (US-03).

#### AC-M2.3 — Section Header (Active Tasks)
- [ ] No explicit section header for the active tasks section in MVP (title is in the nav bar).
- [ ] If there are zero active tasks but completed tasks exist → show the Completed section only.

#### AC-M2.4 — Completed Section
- [ ] Section header label: **"Completed (N)"** where N is the count of completed tasks.
- [ ] Section is **collapsed by default** (zero rows shown, only the header).
- [ ] Tapping the header toggles expand/collapse with a smooth animation.
- [ ] Expand/collapse state is preserved while the app is running (not persisted across launches).
- [ ] When expanded: completed task rows are shown with **strikethrough title** and **gray text**.
- [ ] Completed rows also show `completedAt` formatted as a relative date ("Completed 2h ago", "Completed yesterday").

#### AC-M2.5 — List Scroll Behavior
- [ ] List scrolls to reveal the FAB area (FAB does not cover the last row permanently).
- [ ] `contentInset` bottom = 88pt to ensure last row is above the FAB.
- [ ] Pull-to-refresh is **not** supported in MVP (no sync).

#### AC-M2.6 — List Performance
- [ ] List renders smoothly at 60fps with up to 200 tasks.
- [ ] `@Query` is used directly in the view for reactive updates — no manual `fetchAll()` calls in the view.

---

### UI / UX Specification

```
┌──────────────────────────────────┐
│  Inbox                      ⚙️  │
├──────────────────────────────────┤
│  ○  Buy groceries       Today 🔴 │  ← overdue → red date
│  ○  Call the dentist             │  ← no due date
│  ○  Finish project deck Tomorrow │
│  ○  Team meeting        Apr 5    │
│                                  │
│  ▶  Completed (3)                │  ← collapsed section header
│                                  │
│                          ╭────╮  │
│                          │ +  │  │
│                          ╰────╯  │
└──────────────────────────────────┘

Expanded Completed section:
│  ▼  Completed (3)                │
│     ✓  ~~Go to the gym~~         │  strikethrough, gray
│           Completed today        │
│     ✓  ~~Send invoice~~          │
│           Completed yesterday    │
```

- Row separator: system default (`.inset`).
- Overdue text: `Color.red` — always shown (not just on Today view in MVP).
- Completed section chevron: `chevron.right` (collapsed) / `chevron.down` (expanded), animated.
- Completed row opacity: `0.6` to visually de-emphasize.

---

### Technical Notes

- Use `@Query(filter: #Predicate<TaskItem> { !$0.isDeleted && !$0.isCompleted }, sort: \TaskItem.createdAt, order: .reverse)` for active tasks.
- Use a separate `@Query` for completed tasks or derive from a single query and split in the view model.
- Completed section toggle: `@State var isCompletedExpanded: Bool = false`.
- Section header toggle:
  ```swift
  Button {
      withAnimation(.easeInOut(duration: 0.25)) {
          isCompletedExpanded.toggle()
      }
  } label: {
      HStack {
          Image(systemName: isCompletedExpanded ? "chevron.down" : "chevron.right")
          Text("Completed (\(completedTasks.count))")
      }
  }
  ```
- Content inset for FAB clearance: use `List { ... }.safeAreaInset(edge: .bottom) { Color.clear.frame(height: 88) }`.
- Reactive updates: SwiftUI's `@Query` re-renders the list automatically when the ModelContext changes — no explicit `objectWillChange` needed.

---

### Definition of Done

- [ ] Active tasks list renders and scrolls at 60fps with 50 seeded tasks (test in Simulator).
- [ ] Completed section collapses/expands with animation.
- [ ] Overdue tasks show red date label.
- [ ] FAB is not obscured by the last list row.
- [ ] Tapping a task row navigates to Task Detail (placeholder `TaskDetailView` acceptable for now).
- [ ] VoiceOver: each task row reads "Task title, due date, active task" or "Task title, completed [date]."
- [ ] Dynamic Type: rows resize correctly at all text sizes.
- [ ] No crashes with 0 tasks, 1 task, or 200 tasks.

---
---

## US-M3 — Empty State

> **"As a first-time user, I want to see a welcoming empty state so I understand what the app is for and know exactly how to get started."**

### Story Details

| Field | Value |
|---|---|
| **Story ID** | US-M3 |
| **Type** | UI |
| **Release** | MVP |
| **Priority** | Must Have — Sprint 1 |
| **Story Points** | 1 |
| **Dependencies** | US-M2 ✅ |
| **Blocks** | Nothing — can be built in parallel with US-01 |

---

### Acceptance Criteria

#### AC-M3.1 — When to Show Empty State
- [ ] The empty state is shown when `activeTasks.isEmpty && completedTasks.isEmpty`.
- [ ] If only completed tasks exist (and no active tasks), show the Completed section only — **not** the empty state.
- [ ] The empty state replaces the list entirely (not shown as a row inside the list).

#### AC-M3.2 — Empty State Content
- [ ] **Illustration**: SF Symbol `checkmark.circle.badge.plus` (or similar) at large size (~80pt), tinted with accent color, slight opacity.
- [ ] **Headline**: `"You're all clear"` — `.title2` font weight, centered.
- [ ] **Body text**: `"Tap + to add your first task."` — `.body` font, `.secondary` color, centered.
- [ ] **CTA Button**: `"Add a task"` — `.borderedProminent` button style, accent color background.
  - Tapping this button opens the Quick-Add Sheet (same action as the FAB).
- [ ] The FAB remains visible over the empty state (it is a ZStack overlay, always rendered).

#### AC-M3.3 — Transitions
- [ ] When the first task is added, the empty state **fades out** and the list **fades in** (`withAnimation(.easeInOut)`).
- [ ] When the last task is deleted or completed, the list fades out and the empty state fades in.
- [ ] Transition duration: 0.3 seconds.

---

### UI / UX Specification

```
┌──────────────────────────────────┐
│  Inbox                      ⚙️  │
├──────────────────────────────────┤
│                                  │
│                                  │
│          ✅  (large icon)        │
│                                  │
│        You're all clear          │  ← .title2, centered
│                                  │
│    Tap + to add your first task. │  ← .body secondary, centered
│                                  │
│       ┌────────────────┐         │
│       │  + Add a task  │         │  ← .borderedProminent button
│       └────────────────┘         │
│                                  │
│                          ╭────╮  │
│                          │ +  │  │  ← FAB still visible
│                          ╰────╯  │
└──────────────────────────────────┘
```

- Empty state container: `VStack(spacing: 16)` centered vertically in the screen using `Spacer()`.
- Icon: `Image(systemName: "checkmark.circle.badge.plus").font(.system(size: 72)).foregroundStyle(.accent.opacity(0.7))`.
- Headline: `Text("You're all clear").font(.title2).fontWeight(.semibold)`.
- Body: `Text("Tap + to add your first task.").foregroundStyle(.secondary).multilineTextAlignment(.center)`.

---

### Technical Notes

- Conditional rendering in `InboxView`:
  ```swift
  if activeTasks.isEmpty && completedTasks.isEmpty {
      EmptyStateView(onAddTask: { showQuickAdd = true })
          .transition(.opacity)
  } else {
      TaskListView(...)
          .transition(.opacity)
  }
  ```
- Wrap the condition in `withAnimation(.easeInOut(duration: 0.3))` when the state changes.
- `EmptyStateView` is a standalone reusable component in `Shared/Components/`.

---

### Definition of Done

- [ ] Empty state shown on first launch (0 tasks).
- [ ] Empty state hidden after first task is created (fade transition).
- [ ] Empty state reappears when the last task is deleted (fade transition).
- [ ] CTA button opens the Quick-Add Sheet.
- [ ] FAB visible above the empty state.
- [ ] VoiceOver reads: "You're all clear. Tap + to add your first task. Add a task, button."
- [ ] Looks correct on iPhone SE and iPhone 15 Pro Max.

---
---

## US-01 — Quick Task Capture

> **"As a user, I want to quickly capture a task so I don't lose an idea."**

### Story Details

| Field | Value |
|---|---|
| **Story ID** | US-01 |
| **Epic** | Task Management |
| **Release** | MVP |
| **Priority** | Must Have — Sprint 2 |
| **Story Points** | 5 |
| **Dependencies** | US-M0 ✅, US-M1 ✅, US-M2 ✅ |
| **Blocks** | US-03, US-04, US-M4 |

---

### Acceptance Criteria

#### AC-01.1 — Entry Points
- [ ] Tapping the **FAB** (`+`) opens the Quick-Add Sheet.
- [ ] Tapping the **"Add a task"** CTA on the empty state also opens the Quick-Add Sheet.
- [ ] Sheet opens within **150ms** of tap (measured frame-by-frame in Instruments).
- [ ] The keyboard appears automatically, focused on the title field, as the sheet finishes opening.

#### AC-01.2 — Title Input (Required)
- [ ] The title field is a `TextField` with placeholder text: *"Task title…"*
- [ ] Title is the **only required field** — all others are optional.
- [ ] Maximum length: 255 characters. Characters beyond 255 are not accepted (no crash, no alert — just stops accepting input).
- [ ] The **"Add"** button is **disabled** (grayed out, non-tappable) when the title is empty or whitespace-only.
- [ ] The "Add" button becomes enabled as soon as the first non-whitespace character is typed.

#### AC-01.3 — Saving
- [ ] Tapping "Add" (or pressing Return on the keyboard) saves the task and dismisses the sheet.
- [ ] The task immediately appears at the **top of the Inbox list** (optimistic UI — no spinner, no delay).
- [ ] Task is persisted via `TaskRepository.create(title:dueDate:)` synchronously before the sheet dismisses.
- [ ] `createdAt` and `updatedAt` are set to `Date()` at creation time.
- [ ] Total interaction: FAB tap → type title → Add → **≤ 3 user interactions**.

#### AC-01.4 — Dismissing Without Saving
- [ ] **Empty sheet**: swiping down or tapping outside dismisses without any confirmation.
- [ ] **Title typed**: swiping down shows a confirmation action sheet:
  - Title: **"Discard this task?"**
  - Actions: **"Discard"** (`.destructive`) and **"Keep Editing"** (`.cancel`)
- [ ] "Discard" dismisses the sheet with no task created.
- [ ] "Keep Editing" returns focus to the title field.
- [ ] Dismissal with keyboard: tapping outside the sheet on the dimmed background dismisses it (triggers the same dirty-check as swipe).

#### AC-01.5 — Optional Fields Toolbar
- [ ] Below the title `TextField`, a horizontal toolbar row shows three icon-buttons:
  - 📅 **Due Date** — opens inline date picker (US-02; in MVP, shows placeholder "Date picker coming soon" if US-02 is not yet merged).
  - 🚩 **Priority** — deferred to v1.0 (button is hidden in MVP).
  - 📁 **Project** — deferred to v1.0 (button is hidden in MVP).
- [ ] In MVP, only the 📅 icon is shown. The toolbar is sparse but correctly positioned.

#### AC-01.6 — Sheet Layout & Behavior
- [ ] Sheet detent: `.presentationDetents([.height(180)])` — expands to `.medium` when the date picker opens.
- [ ] `presentationDragIndicator(.visible)` enabled.
- [ ] `interactiveDismissDisabled(titleIsDirty)` — disables drag-to-dismiss only if user has typed in the title.
- [ ] Sheet background: `Color(UIColor.systemGroupedBackground)`.

---

### UI / UX Specification

```
Quick-Add Sheet (default height ~180pt):
┌──────────────────────────────────┐
│            ────                  │  ← drag indicator
│                                  │
│  ┌────────────────────────────┐  │
│  │  Task title…               │  │  ← auto-focused TextField
│  └────────────────────────────┘  │
│                                  │
│  [📅]                   [Add →] │  ← toolbar: date icon left, Add button right
└──────────────────────────────────┘

Add button states:
  • Title empty:  [Add →]  grayed out, `.disabled(true)`
  • Title filled: [Add →]  accent color, active

Discard confirmation (action sheet):
  Discard this task?
  ┌────────────────┐
  │ Discard        │  ← .destructive
  ├────────────────┤
  │ Keep Editing   │  ← .cancel
  └────────────────┘
```

- "Add" button: `.bordered` + `.tint(.accent)` style, placed trailing in the toolbar row.
- Title field: `.font(.body)`, `.submitLabel(.done)` to show "Done" on keyboard return key.
- Haptic on save: `UIImpactFeedbackGenerator(style: .medium).impactOccurred()`.

---

### Technical Notes

```swift
// InboxView state
@State private var showQuickAdd = false

// Sheet presentation
.sheet(isPresented: $showQuickAdd) {
    QuickAddView()
        .presentationDetents([.height(180), .medium])
        .presentationDragIndicator(.visible)
}

// QuickAddView
@Environment(\.modelContext) private var context
@State private var title: String = ""
@FocusState private var isFocused: Bool
private var isDirty: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

// On appear
.onAppear { isFocused = true }

// Save
func save() {
    let trimmed = title.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return }
    let repo = TaskRepository(context: context)
    try? repo.create(title: trimmed, dueDate: nil)
}
```

- Use `.interactiveDismissDisabled(isDirty)` and handle `onDismissAttempt` (iOS 17+: `presentationContentInteraction`) or use a custom gesture.
- Optimistic UI: since SwiftData is synchronous and the `@Query` in `InboxView` is reactive, the new task will appear immediately after `context.insert(newTask)`.

---

### Definition of Done

- [ ] Unit test: `TaskRepository.create()` inserts a task with correct `createdAt`, `updatedAt`, `isCompleted = false`, `isDeleted = false`.
- [ ] Unit test: creating a task with whitespace-only title is rejected.
- [ ] UI test: FAB tap → type "Buy milk" → tap Add → "Buy milk" appears as first row in Inbox.
- [ ] UI test: FAB tap → swipe down → no task created, no confirmation shown.
- [ ] UI test: FAB tap → type "Test" → swipe down → confirmation sheet appears.
- [ ] UI test: confirmation → "Discard" → sheet dismissed → no task in list.
- [ ] UI test: confirmation → "Keep Editing" → sheet stays open, title preserved.
- [ ] VoiceOver: title field label "Task title", Add button label "Add task".
- [ ] Tested on iPhone SE (small screen).
- [ ] Sheet opens at 60fps animation.

---
---

## US-03 — Complete a Task

> **"As a user, I want to mark a task as complete so I can feel the satisfaction of finishing something."**

### Story Details

| Field | Value |
|---|---|
| **Story ID** | US-03 |
| **Epic** | Task Management |
| **Release** | MVP |
| **Priority** | Must Have — Sprint 2 |
| **Story Points** | 3 |
| **Dependencies** | US-M0 ✅, US-M2 ✅, US-01 ✅ |
| **Blocks** | Nothing in MVP |

---

### Acceptance Criteria

#### AC-03.1 — Completion Interactions (Two ways)
- [ ] **Tap checkbox**: tapping the circular checkbox on the left of any active task row completes it.
- [ ] **Swipe right**: a full right-swipe on the task row completes it (leading swipe action, green, checkmark icon).
- [ ] Both interactions trigger identical behavior, feedback, and outcome.
- [ ] Completion is **instantaneous from the user's perspective** — no loading state.

#### AC-03.2 — Visual & Haptic Feedback Sequence
The completion animation has a precise sequence:

| Time | What happens |
|---|---|
| t=0ms | Checkbox fills: empty circle → filled circle + checkmark (spring animation, 250ms) |
| t=0ms | Title gets strikethrough, text color shifts to `.secondary` |
| t=0ms | `.success` haptic fires (`UINotificationFeedbackGenerator().notificationOccurred(.success)`) |
| t=400ms | Row begins sliding down + fading out (spring animation, 350ms) |
| t=750ms | Row is gone from the active section |
| t=0ms | Undo toast appears at bottom of screen |

- [ ] All animations run at 60fps on iPhone 12 (no dropped frames).
- [ ] With **Reduce Motion** enabled: skip slide/fade animation; task disappears instantly. Haptic still fires.

#### AC-03.3 — Undo Toast
- [ ] Toast appears immediately at the bottom of the screen (above safe area, above FAB).
- [ ] Toast content: checkmark icon + **"Task completed"** + **"Undo"** tappable link.
- [ ] Toast auto-dismisses after **4 seconds**.
- [ ] A countdown progress indicator (thin line at bottom of toast) depletes over the 4 seconds.
- [ ] Tapping "Undo" immediately restores the task: sets `isCompleted = false`, `completedAt = nil`, re-inserts into active list at original position.
- [ ] Only **one undo toast** is shown at a time. If a second task is completed while the first toast is showing, the first toast updates to "2 tasks completed. Undo last." OR dismisses and a fresh toast appears for the new task. (MVP decision: **dismiss old, show new**.)
- [ ] Toast must **not** block taps on the list behind it.

#### AC-03.4 — Completed Section Behavior
- [ ] Completed task moves to the "Completed (N)" section at the bottom of the list.
- [ ] The count in the section header updates immediately: e.g., "Completed (0)" → "Completed (1)".
- [ ] Completed section remains collapsed unless the user has manually expanded it.
- [ ] Completed tasks in the expanded section show:
  - Strikethrough title, secondary color.
  - `completedAt` as relative string: "Completed just now", "Completed 2h ago", "Completed yesterday".

#### AC-03.5 — Re-opening a Completed Task (from Completed section)
- [ ] Tapping the filled checkbox on a completed task (in the expanded Completed section) unchecks it.
- [ ] The task moves back to the active list (at the top, as it has the most recent `updatedAt`).
- [ ] Same spring animation plays in reverse (fades into the active section).
- [ ] No undo toast for this action (it is its own undo).

#### AC-03.6 — Persistence
- [ ] `TaskRepository.complete(_ task:)` sets: `isCompleted = true`, `completedAt = Date()`, `updatedAt = Date()`.
- [ ] `TaskRepository.uncomplete(_ task:)` sets: `isCompleted = false`, `completedAt = nil`, `updatedAt = Date()`.
- [ ] Both are synchronous SwiftData writes, committed before animation starts.

---

### UI / UX Specification

```
Before completion:
  ○  Buy groceries              Today

Checkbox tap at t=0:
  ✓  ~~Buy groceries~~          Today   (strikethrough, gray)

After 400ms delay — row slides down and fades:
  [row disappears]

Toast (above safe area, below FAB):
  ┌────────────────────────────────────────────┐
  │  ✅ Task completed                   Undo  │
  │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░  (4s timer)   │
  └────────────────────────────────────────────┘

Swipe right gesture:
  ┌──────────────┬──────────────────────────────┐
  │  ✓ Done      │  Buy groceries               │
  │  (green)     │                              │
  └──────────────┴──────────────────────────────┘
  Full swipe = immediate completion.
```

- Checkbox: `Circle()` stroke (unchecked) → `Circle()` fill + `Image(systemName: "checkmark")` (checked).
- Swipe action: `.swipeActions(edge: .leading) { Button(...) { complete(task) }.tint(.green) }`.
- Toast: `VStack` overlay at `.bottomLeading` with padding, rounded rect background, shadow.
- Progress bar: `GeometryReader` + `Rectangle().frame(width: progress * totalWidth)` animated with `withAnimation(.linear(duration: 4))`.

---

### Technical Notes

```swift
// Completion with animation sequencing
func completeTask(_ task: TaskItem) {
    // 1. Instant visual update
    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
        task.isCompleted = true
        task.completedAt = Date()
        task.updatedAt = Date()
    }
    // 2. Haptic
    UINotificationFeedbackGenerator().notificationOccurred(.success)
    // 3. Show undo toast
    showUndoToast(for: task)
    // 4. Animate out of active section after delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            // @Query automatically removes from active section
            // triggering list diff animation
        }
    }
}
```

- `@Query` handles the reactive removal from the active list. SwiftData's change will propagate and the list will animate the row out automatically when `isCompleted` flips.
- Store `lastCompletedTask: TaskItem?` in `@State` on `InboxView` for the undo action.
- Undo timer: use `Task { try? await Task.sleep(for: .seconds(4)); dismissToast() }` — cancel the task if Undo is tapped.

---

### Definition of Done

- [ ] Unit test: `complete()` sets `isCompleted = true` and `completedAt != nil`.
- [ ] Unit test: `uncomplete()` sets `isCompleted = false` and `completedAt == nil`.
- [ ] UI test: tap checkbox → task disappears from active list within 1 second.
- [ ] UI test: tap checkbox → undo toast appears.
- [ ] UI test: tap Undo → task reappears in active list.
- [ ] UI test: swipe right → task completes (same result as checkbox tap).
- [ ] UI test: complete task → wait 4s → undo toast disappears.
- [ ] UI test: expand Completed section → tap checkbox → task moves back to active.
- [ ] Haptic feedback: tested on a physical device (not simulator).
- [ ] Reduce Motion: no slide animation; task disappears immediately, haptic still fires.
- [ ] VoiceOver: checkbox announced as "Mark complete, button." After completion: "Completed, checkmark button."

---
---

## US-04 — Delete a Task

> **"As a user, I want to delete tasks I no longer need, without fear of losing them permanently by accident."**

### Story Details

| Field | Value |
|---|---|
| **Story ID** | US-04 |
| **Epic** | Task Management |
| **Release** | MVP |
| **Priority** | Must Have — Sprint 2 |
| **Story Points** | 2 |
| **Dependencies** | US-M0 ✅, US-M2 ✅, US-01 ✅ |
| **Blocks** | Nothing in MVP |

---

### Acceptance Criteria

#### AC-04.1 — Delete Interaction (Swipe Left)
- [ ] Swiping **left** on any task row (active or completed) reveals a **red "Delete"** trailing swipe action.
- [ ] Icon: `trash` SF Symbol. Label: "Delete". Background: `.red`.
- [ ] A **partial swipe** (revealing the button) lets the user tap "Delete" to confirm.
- [ ] A **full swipe** (all the way) triggers deletion immediately without needing to tap the button.
- [ ] For tasks **without notes**: delete immediately, no confirmation alert.
- [ ] For tasks **with notes** (`task.hasNotes == true`): show a confirmation alert before deleting (see AC-04.2).

> **Note:** Notes are a v1.0 feature. In MVP all tasks have `notes = nil`, so the confirmation alert path will never be triggered in MVP. **However, the code must handle it correctly** for when notes are added in v1.0.

#### AC-04.2 — Confirmation Alert (Notes Present)
- [ ] Alert title: **"Delete '[task.title]'?"**
- [ ] Alert message: **"This task has notes. It will be moved to Trash."**
- [ ] Alert actions: **"Delete"** (`.destructive`) and **"Cancel"** (`.cancel`).
- [ ] "Cancel" dismisses the alert and returns the row to its normal state.

#### AC-04.3 — Soft Delete Behavior
- [ ] Deletion sets: `isDeleted = true`, `deletedAt = Date()`, `updatedAt = Date()`.
- [ ] The task **immediately disappears** from the Inbox list and the Completed section.
- [ ] All active `@Query` filters include `isDeleted == false` — the task is never fetched in normal views.
- [ ] The task is stored in SwiftData and accessible via `fetchTrashed()`.

#### AC-04.4 — Undo Delete Toast
- [ ] Same toast pattern as US-03: appears at bottom, above safe area.
- [ ] Content: trash icon + **"Task deleted"** + **"Undo"** tappable link.
- [ ] Auto-dismisses after **4 seconds**.
- [ ] Tapping "Undo" restores the task: `isDeleted = false`, `deletedAt = nil`, task reappears in list.
- [ ] Simultaneous undo toasts (delete + complete): **dismiss old, show new** (same as US-03).

#### AC-04.5 — Trash View
The Trash view is accessible via **Settings → Trash**.

- [ ] Lists all tasks where `isDeleted == true`, sorted by `deletedAt` descending.
- [ ] Each row shows:
  - Task title (primary, possibly with strikethrough if it was also completed before deletion).
  - `deletedAt` formatted as: "Deleted today", "Deleted yesterday", "Deleted Mar 28".
  - **"Restore"** button (trailing, `.tint(.blue)`).
- [ ] Swiping left on a trash row → **"Delete Forever"** action (red, `xmark.bin` icon).
  - Always shows confirmation: **"Permanently delete '[title]'? This cannot be undone."**
- [ ] **"Empty Trash"** button in the toolbar (`.destructive` style).
  - Always shows confirmation: **"Permanently delete all [N] items? This cannot be undone."**
- [ ] Trash item count badge shown in Settings row (e.g., "Trash (3)").
- [ ] If Trash is empty: show simple centered label "Trash is empty."

#### AC-04.6 — Auto-Purge
- [ ] On every app foreground activation (`ScenePhase.active`), check if tasks have been in Trash for > 30 days.
- [ ] Tasks where `deletedAt < Date.now - 30 days` are permanently deleted (removed from SwiftData entirely).
- [ ] Auto-purge runs at most once per 24 hours (store `lastPurgeDate` in `UserDefaults`).
- [ ] Auto-purge is silent — no notification to the user.

---

### UI / UX Specification

```
Swipe left on active row:
  ┌─────────────────────────────────┬──────────────┐
  │  ○  Buy groceries        Today  │  🗑  Delete  │
  └─────────────────────────────────┴──────────────┘
  Red background, white icon + label.

Delete Toast:
  ┌─────────────────────────────────────────────────┐
  │  🗑 Task deleted                          Undo  │
  │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░  (4s countdown)        │
  └─────────────────────────────────────────────────┘

Trash View:
┌──────────────────────────────────────┐
│  Trash           [Empty Trash]       │
├──────────────────────────────────────┤
│  Buy groceries                       │
│  Deleted today                 Restore│
│──────────────────────────────────────│
│  Call dentist                        │
│  Deleted yesterday             Restore│
└──────────────────────────────────────┘

If empty:
│         Trash is empty               │  ← centered, secondary color
```

---

### Technical Notes

```swift
// Swipe action
.swipeActions(edge: .trailing, allowsFullSwipe: true) {
    Button(role: .destructive) {
        deleteTask(task)
    } label: {
        Label("Delete", systemImage: "trash")
    }
}

func deleteTask(_ task: TaskItem) {
    if task.hasNotes {
        taskToConfirmDelete = task  // triggers alert
    } else {
        performSoftDelete(task)
    }
}

func performSoftDelete(_ task: TaskItem) {
    TaskRepository(context: context).softDelete(task)
    showDeleteUndoToast(for: task)
}
```

- Auto-purge:
  ```swift
  // AppEnvironment.onForeground()
  let lastPurge = UserDefaults.standard.object(forKey: "lastPurgeDate") as? Date ?? .distantPast
  if Date().timeIntervalSince(lastPurge) > 86400 {
      try? repo.purgeExpiredTrash()
      UserDefaults.standard.set(Date(), forKey: "lastPurgeDate")
  }
  ```
- Trash badge count: use a `@Query(filter: #Predicate { $0.isDeleted })` count in `SettingsView`.

---

### Definition of Done

- [ ] Unit test: `softDelete()` sets `isDeleted = true`, `deletedAt != nil`.
- [ ] Unit test: `restore()` sets `isDeleted = false`, `deletedAt == nil`.
- [ ] Unit test: `permanentlyDelete()` removes the item from the store.
- [ ] Unit test: `purgeExpiredTrash()` only deletes tasks with `deletedAt > 30 days ago`.
- [ ] UI test: swipe left → task disappears from list.
- [ ] UI test: delete → Undo in toast → task reappears.
- [ ] UI test: Settings → Trash → task visible → Restore → task back in Inbox.
- [ ] UI test: Settings → Trash → Delete Forever → confirmation → task gone.
- [ ] Confirmation alert shown for tasks with notes (unit test the condition, UI test with a seeded task).
- [ ] Auto-purge tested with a mocked date (tasks with `deletedAt` > 30 days are removed).
- [ ] VoiceOver: swipe action announced "Delete, button."

---
---

## US-M4 — Task Detail Screen (MVP)

> **"As a user, I want to tap on a task and see its full details so I can edit the title and manage it from one place."**

### Story Details

| Field | Value |
|---|---|
| **Story ID** | US-M4 |
| **Type** | UI / Feature |
| **Release** | MVP |
| **Priority** | Must Have — Sprint 3 |
| **Story Points** | 3 |
| **Dependencies** | US-M0 ✅, US-M1 ✅, US-01 ✅ |
| **Blocks** | US-02 |

> **Scope note:** This is the MVP version of the Task Detail screen. It includes editable title, due date (added by US-02), and complete/delete actions. Notes, priority, tags, and project fields are **v1.0 additions** — the screen must be designed to accommodate them later without a full rewrite.

---

### Acceptance Criteria

#### AC-M4.1 — Navigation to Task Detail
- [ ] Tapping anywhere on a task row in the Inbox (excluding the checkbox and swipe gesture zones) navigates to Task Detail.
- [ ] Navigation is a **push** (not a sheet) — back chevron at top-left returns to Inbox.
- [ ] Navigation title: the task's current `title` (`.inline` style in MVP).
- [ ] The transition animation is the standard iOS navigation push (slide from right).

#### AC-M4.2 — Editable Title
- [ ] The task title is displayed as an editable `TextField` at the top of the screen.
- [ ] Font: `.title2`, `.fontWeight(.semibold)`.
- [ ] The field has no visible border by default; it looks like styled text until tapped.
- [ ] Tapping the title activates editing mode; the keyboard appears.
- [ ] Title changes are **auto-saved** on every keystroke (debounced 500ms — not per keystroke for performance).
- [ ] The navigation title updates in real time as the user types.
- [ ] Empty title is not saved — if the user clears the title and navigates back, the original title is restored and a brief error shake animation plays.

#### AC-M4.3 — Due Date Row (MVP placeholder for US-02)
- [ ] A row shows the due date: `📅 [due date label]` or `📅 Add due date` if no date is set.
- [ ] Tapping this row opens the date picker (implemented as part of US-02).
- [ ] In MVP before US-02 is built: this row is present but tapping it shows a disabled state (or is omitted until US-02 is merged — dev decision).

#### AC-M4.4 — Complete Action
- [ ] A **"Mark as Complete"** button is shown prominently in the screen.
- [ ] If the task is already completed: button reads **"Mark as Active"** (reopen action).
- [ ] Tapping "Mark as Complete" calls `TaskRepository.complete()`, fires haptic, and navigates back to Inbox.
- [ ] After navigating back, the same undo toast from US-03 appears on the Inbox screen.
- [ ] Tapping "Mark as Active" calls `TaskRepository.uncomplete()` and navigates back.

#### AC-M4.5 — Delete Action
- [ ] A **"Delete Task"** button (`.destructive` style) is shown below the complete button.
- [ ] Tapping "Delete Task" shows a confirmation alert:
  - Title: **"Delete this task?"**
  - Actions: **"Delete"** (`.destructive`), **"Cancel"**
- [ ] Confirming deletion calls `TaskRepository.softDelete()` and navigates back to Inbox.
- [ ] The delete undo toast from US-04 appears after navigation.

#### AC-M4.6 — Metadata Footer
- [ ] At the bottom of the screen: `Created [formatted date]` in `.caption` secondary color.
- [ ] Formatted as: "Created Mar 30, 2026" (absolute date, not relative).
- [ ] Not interactive.

#### AC-M4.7 — Future-proofing Layout
- [ ] The detail screen uses a `Form` or `List` layout to make it easy to add new rows (priority, notes, tags) in v1.0 without restructuring the view.
- [ ] Each metadata row (due date, future: priority, project, tags) is a `Section` in the `Form`.

---

### UI / UX Specification

```
Task Detail — MVP:
┌──────────────────────────────────────┐
│  ← Inbox          Buy groceries      │  ← nav bar, inline title
├──────────────────────────────────────┤
│                                      │
│  Buy groceries                       │  ← editable TextField, .title2
│  ──────────────────────────────      │  ← subtle divider
│                                      │
│  DETAILS                             │  ← Form section header
│  ┌────────────────────────────────┐  │
│  │ 📅  Add due date           ›   │  │  ← due date row (US-02)
│  └────────────────────────────────┘  │
│                                      │
│  ACTIONS                             │  ← Form section header
│  ┌────────────────────────────────┐  │
│  │  ✓  Mark as Complete           │  │  ← accent color
│  │  🗑  Delete Task               │  │  ← .red / .destructive
│  └────────────────────────────────┘  │
│                                      │
│  Created Mar 30, 2026                │  ← footer, .caption, .secondary
└──────────────────────────────────────┘

Completed task state:
│  ACTIONS
│  ↩  Mark as Active              │  ← reopen action
│  🗑  Delete Task                │
```

- Title field: no border in `displayMode`, shows cursor on tap.
- "Mark as Complete" button: `Label("Mark as Complete", systemImage: "checkmark.circle")` tinted `.accent`.
- "Delete Task" button: `Label("Delete Task", systemImage: "trash")` tinted `.red`.
- Divider between title and form: `Divider().padding(.horizontal)`.

---

### Technical Notes

```swift
struct TaskDetailView: View {
    let taskId: UUID
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var tasks: [TaskItem]
    @State private var editableTitle: String = ""
    @State private var showDeleteConfirmation = false

    var task: TaskItem? { tasks.first(where: { $0.id == taskId }) }

    var body: some View {
        Form {
            // Title section (outside Form or as header)
            // Details section: due date row
            // Actions section: complete + delete
            // Footer: created date
        }
        .navigationTitle(editableTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { editableTitle = task?.title ?? "" }
        .onChange(of: editableTitle) { _, newValue in
            // debounced auto-save
        }
    }
}
```

- Load task by ID using `@Query` with a predicate — keeps the view reactive to external changes.
- Auto-save debounce: use `AsyncDebounce` or a custom `Task` with `sleep(for: .milliseconds(500))`.
- Title empty validation: `if editableTitle.trimmingCharacters(in: .whitespaces).isEmpty { editableTitle = task?.title ?? ""; /* shake */ }`.
- Navigate back after complete/delete: `dismiss()` — the parent `NavigationStack` handles the pop.
- Pass the undo toast state back via a shared `@Observable` or `@EnvironmentObject` view model.

---

### Definition of Done

- [ ] Tapping a task row in Inbox navigates to Task Detail.
- [ ] Editable title saves on debounce — change persists after navigating back.
- [ ] Empty title restores to previous value + shake animation.
- [ ] Navigation title updates in real time as title is edited.
- [ ] "Mark as Complete" action completes task and returns to Inbox.
- [ ] "Delete Task" action shows confirmation, then soft-deletes and returns to Inbox.
- [ ] Created date shown in footer.
- [ ] UI test: navigate to detail → change title to "Updated" → back → row shows "Updated".
- [ ] UI test: navigate to detail → tap "Mark as Complete" → task in Completed section.
- [ ] UI test: navigate to detail → tap "Delete" → confirm → task gone from Inbox.
- [ ] VoiceOver: all interactive elements have descriptive labels.
- [ ] No orphaned view (task loads correctly when navigated to from a deep link or state restore).

---
---

## US-02 — Set Due Date & Time

> **"As a user, I want to set a due date on a task so I can see what needs attention today and plan ahead."**

### Story Details

| Field | Value |
|---|---|
| **Story ID** | US-02 |
| **Epic** | Task Management |
| **Release** | MVP |
| **Priority** | Must Have — Sprint 3 |
| **Story Points** | 3 |
| **Dependencies** | US-M0 ✅, US-M4 ✅ (date row on Task Detail), US-01 ✅ (date icon on Quick-Add Sheet) |
| **Blocks** | Nothing in MVP |

---

### Acceptance Criteria

#### AC-02.1 — Entry Points
- [ ] **Quick-Add Sheet**: tapping the 📅 icon in the toolbar row expands an inline date picker inside the sheet.
- [ ] **Task Detail Screen**: tapping the "📅 Add due date" row opens the date picker inline within the form.
- [ ] The date picker experience is **identical** in both entry points.

#### AC-02.2 — Quick-Select Chips
- [ ] Above the calendar, three chips are shown:
  - **"Today"** → sets `dueDate = Calendar.current.startOfDay(for: Date())`
  - **"Tomorrow"** → sets `dueDate = Calendar.current.date(byAdding: .day, value: 1, to: today)!`
  - **"Next Week"** → sets `dueDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: today)!`
- [ ] Tapping a chip immediately selects that date and visually marks it as selected (filled background).
- [ ] Tapping a selected chip **deselects** it (clears the date).

#### AC-02.3 — Calendar Picker
- [ ] Below the chips: a `DatePicker` in `.graphical` display mode (full calendar grid).
- [ ] The selected date is highlighted in the calendar.
- [ ] Past dates are selectable (no restriction).
- [ ] Selecting a calendar date auto-dismisses the calendar and shows a selected chip.

#### AC-02.4 — Optional Time
- [ ] Below the calendar: a toggle row **"Add time"** (off by default).
- [ ] Toggling on shows a wheel-style time picker (`.hourAndMinute` component).
- [ ] When time is set, the due date label shows date + time: "Today, 3:00 PM".
- [ ] When time is not set, only the date is shown: "Today", "Tomorrow", "Apr 6".
- [ ] Toggling time off clears the time component (keeps the date).

#### AC-02.5 — Due Date Display Label
- [ ] Once set, the 📅 icon on the Quick-Add Sheet is replaced with a chip showing the date label + an `×` to clear it.
- [ ] On the Task Detail row: "📅 Add due date" → "📅 Today" (or specific date).
- [ ] Date labels:
  - Same day → "Today"
  - Next day → "Tomorrow"
  - Day before today → "Yesterday"
  - Within the current week → "Mon", "Tue", etc.
  - Beyond current week → "Apr 6", "Jan 12, 2027"
- [ ] Overdue dates are shown in **red** with a `exclamationmark` prefix: "⚠ Yesterday", "⚠ Apr 1".

#### AC-02.6 — Clearing a Due Date
- [ ] Tapping `×` on the date chip (in Quick-Add Sheet) clears the date and time.
- [ ] In Task Detail: a "Remove Date" option appears below the picker when a date is set.
- [ ] Clearing a date removes both `dueDate` and time component.

#### AC-02.7 — Persistence
- [ ] `dueDate` is stored as a single `Date?` on `TaskItem`, encoding both date and time.
- [ ] If only a date is set (no time), store as `startOfDay` (midnight) of that date.
- [ ] Auto-saved immediately on selection (no explicit confirm button needed on Task Detail).
- [ ] On Quick-Add Sheet: date is part of the task saved when "Add" is tapped.

---

### UI / UX Specification

```
Quick-Add Sheet — date picker expanded:
┌──────────────────────────────────────────┐
│  ────                                    │
│  ┌───────────────────────────────────┐   │
│  │  Task title…                      │   │
│  └───────────────────────────────────┘   │
│                                          │
│  [📅 Today ×]  ← chip after selection   │
│                                          │
│  [ Today ] [ Tomorrow ] [ Next Week ]    │  ← chips
│                                          │
│  ┌───────────────────────────────────┐   │
│  │         March  2026               │   │
│  │  Su Mo Tu We Th Fr Sa             │   │
│  │   1  2  3  4  5  6  7             │   │
│  │  ...   [30] ...                   │   │  ← selected date
│  └───────────────────────────────────┘   │
│                                          │
│  ○ Add time                             │  ← toggle
│                                          │
│  [📅 Today]                    [Add →] │
└──────────────────────────────────────────┘

Task Detail — due date row:
  Before: │ 📅  Add due date                ›  │
  After:  │ 📅  Today, 3:00 PM              ×  │
```

- Chips: `HStack` of `Button` with `.capsule` background; selected = accent fill, white label.
- Calendar: `DatePicker("", selection: $selectedDate, displayedComponents: .date).datePickerStyle(.graphical)`.
- Sheet expansion: when calendar opens, detent changes from `.height(180)` to `.medium` smoothly.
- Overdue color: `Color.red`, with `Image(systemName: "exclamationmark.circle.fill")`.

---

### Technical Notes

```swift
// Date label formatting helper
extension TaskItem {
    var formattedDueDate: String {
        guard let date = dueDate else { return "" }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        // Within this week: "Mon", "Tue"
        // Beyond: "Apr 6" or "Apr 6, 2027"
    }
    var isOverdue: Bool {
        guard let date = dueDate, !isCompleted else { return false }
        return date < Calendar.current.startOfDay(for: Date())
    }
}
```

- Sheet expansion on date picker open: use `@Binding var selectedDetent: PresentationDetent` passed into `QuickAddView`.
- Store date-only: `Calendar.current.startOfDay(for: selectedDate)` when time toggle is off.
- Store date+time: use `selectedDate` directly (contains full time component) when time toggle is on.

---

### Definition of Done

- [ ] Unit tests: `formattedDueDate` returns correct strings for today, tomorrow, yesterday, past week, future.
- [ ] Unit tests: `isOverdue` returns `true` only for past dates on incomplete tasks.
- [ ] Unit tests: quick chip date calculations (today, tomorrow, next week).
- [ ] UI test: Quick-Add Sheet → tap 📅 → select "Tomorrow" → tap Add → task row shows "Tomorrow".
- [ ] UI test: Quick-Add Sheet → select date → tap × chip → date cleared.
- [ ] UI test: Task Detail → tap due date row → select date → navigate back → date persists.
- [ ] UI test: overdue task → date shown in red.
- [ ] UI test: add time → task row shows time in label.
- [ ] VoiceOver: date picker accessible; chip buttons have correct labels.
- [ ] Dark mode: calendar grid renders correctly.
- [ ] Tested on iPhone SE (date picker doesn't overflow).

---
---

## Sprint Planning Summary

### Sprint 1 — Foundation (9 pts)

| Story | Points | Owner | Status |
|---|---|---|---|
| US-M0 App Foundation & Data Layer | 3 | iOS Dev | 🟡 Ready to start |
| US-M1 App Shell & Navigation | 2 | iOS Dev | Blocked by M0 |
| US-M2 Inbox List View | 3 | iOS Dev | Blocked by M1 |
| US-M3 Empty State | 1 | iOS Dev | Blocked by M2 |

**Sprint 1 exit criteria:** App launches, shows empty Inbox with empty state, navigates to Settings, FAB is visible.

---

### Sprint 2 — Task Lifecycle (10 pts)

| Story | Points | Owner | Status |
|---|---|---|---|
| US-01 Quick Task Capture | 5 | iOS Dev | Blocked by M2 |
| US-03 Complete a Task | 3 | iOS Dev | Blocked by US-01 |
| US-04 Delete a Task | 2 | iOS Dev | Blocked by US-01 |

**Sprint 2 exit criteria:** User can add, complete, and delete tasks. Undo toasts work. Trash view accessible.

---

### Sprint 3 — Detail & Dates (6 pts)

| Story | Points | Owner | Status |
|---|---|---|---|
| US-M4 Task Detail Screen (MVP) | 3 | iOS Dev | Blocked by US-01 |
| US-02 Set Due Date & Time | 3 | iOS Dev | Blocked by US-M4 |

**Sprint 3 exit criteria:** Tapping a task opens detail view with editable title and due date. Task rows show overdue dates in red.

---

### Total: 25 points | 3 × 2-week sprints = 6 weeks → Target: 2026-05-30

---

### MVP Acceptance Checklist (Before TestFlight)

- [ ] The entire MVP user journey works end-to-end without crashes.
- [ ] Zero data loss across 48 hours of use (delete app → reinstall → data preserved in SwiftData).
- [ ] All 9 stories have passed their Definitions of Done.
- [ ] Tested on: iPhone SE (4.7"), iPhone 15 (6.1"), iPhone 15 Pro Max (6.7").
- [ ] All unit tests pass (CI green).
- [ ] All UI tests pass (CI green).
- [ ] VoiceOver: all interactive elements are accessible.
- [ ] Dynamic Type: all text scales correctly at "Accessibility XL" size.
- [ ] App cold launch < 1.5s on iPhone 12 (Release build).
- [ ] No memory leaks detected in Instruments (Leaks instrument, 10-minute session).

---

### Related Documents

| Document | Location | Status |
|---|---|---|
| PRD (full product) | `docs/prd-taskflow.md` | ✅ v1.1 |
| Epic: Task Management (full detail, US-01–06) | `docs/epic-task-management.md` | ✅ v1.0 |
| **MVP User Stories (this document)** | `docs/mvp-user-stories.md` | ✅ v1.0 |
| Technical Architecture | `docs/architecture.md` | 🔴 TBD |
| Design System | `docs/design-system.md` | 🔴 TBD |

---

*This document is owned by the Product Owner. Developers should not begin work on any story until its dependency column shows ✅. For questions or clarifications, contact the product team before starting implementation.*
