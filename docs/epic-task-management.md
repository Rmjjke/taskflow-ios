# Epic: Task Management
## Developer Story Breakdown — TaskFlow iOS

| Field | Detail |
|---|---|
| **Epic ID** | EPIC-01 |
| **Epic Name** | Task Management |
| **Product** | TaskFlow iOS |
| **Document Version** | 1.0 |
| **Status** | Ready for Development |
| **Author** | Product Owner |
| **Last Updated** | 2026-03-30 |
| **Target Release** | MVP + v1.0 |

---

## Epic Overview

The Task Management epic covers the entire lifecycle of a task: creation, viewing, editing, completing, and deleting. This is the **core value loop** of TaskFlow. Everything else (projects, sync, widgets) depends on this foundation being solid, fast, and delightful.

### Epic Goal
Enable a user to capture a task in under 5 seconds, act on it later with full context, and close the loop by completing or discarding it — all with zero friction.

### Stories in This Epic

| Story ID | Title | Release | Priority | Points |
|---|---|---|---|---|
| US-01 | Quick Task Capture | MVP | Must Have | 5 |
| US-02 | Set Due Date & Time | MVP | Must Have | 3 |
| US-03 | Complete a Task | MVP | Must Have | 3 |
| US-04 | Delete a Task | MVP | Must Have | 2 |
| US-05 | Assign Priority to a Task | v1.0 | Must Have | 2 |
| US-06 | Add Notes to a Task | v1.0 | Should Have | 3 |

**Total Estimated Points: 18**

---

## Dependencies & Order of Implementation

```
US-01 (Capture)         ← Must be built first. All other stories depend on tasks existing.
  └── US-02 (Due Date)  ← Extends the task creation sheet.
  └── US-03 (Complete)  ← Requires task list to be renderable.
  └── US-04 (Delete)    ← Requires task list to be renderable.
       └── US-05 (Priority) ← Extends both creation and edit flows.
            └── US-06 (Notes) ← Extends task detail / edit view.
```

**Recommended build order:** US-01 → US-03 → US-04 → US-02 → US-05 → US-06

---

---

## US-01 — Quick Task Capture

> **"As a user, I want to quickly capture a task so I don't lose an idea."**

### Context & Motivation
The most critical moment in any productivity tool is the first one: capturing something before it's forgotten. If this interaction has any friction — too many taps, required fields, slow animation — users will abandon the app. This story must be obsessively fast and simple.

### Story Details

| Field | Value |
|---|---|
| **Story ID** | US-01 |
| **Epic** | Task Management |
| **Release** | MVP |
| **Priority** | Must Have |
| **Story Points** | 5 |
| **Dependencies** | None — this is the foundational story |

---

### Acceptance Criteria

#### AC-01.1 — Quick-Add Entry Points
- [ ] A `+` button is permanently visible in the bottom-right of the Inbox and Today views (FAB — Floating Action Button).
- [ ] Tapping `+` opens the Quick-Add Sheet within 150ms (no full screen push).
- [ ] The keyboard appears automatically when the sheet opens, focused on the title field.

#### AC-01.2 — Minimum Required Input
- [ ] The **title** field is the only required field. All other fields are optional.
- [ ] Title input supports up to 255 characters.
- [ ] An empty title prevents saving; the `+` / confirm button is disabled while title is blank.

#### AC-01.3 — Saving a Task
- [ ] Tapping the "Add" button (or pressing Return on keyboard) saves the task and dismisses the sheet.
- [ ] The newly created task appears at the top of the Inbox list immediately (optimistic UI — no loading spinner).
- [ ] Task is persisted to local SwiftData store before the sheet is dismissed.
- [ ] Total interaction from tap on `+` to task saved: ≤ 3 taps / interactions.

#### AC-01.4 — Dismissing Without Saving
- [ ] Swiping down on the sheet or tapping outside dismisses it without saving.
- [ ] No confirmation dialog is shown when dismissing an empty or untouched sheet.
- [ ] If the user has typed a title and then tries to dismiss, show a confirmation: **"Discard task?"** with options "Discard" (destructive) and "Keep Editing."

#### AC-01.5 — Inline Optional Fields on Quick-Add Sheet
- [ ] Below the title field, a single toolbar row shows shortcut icons: 📅 Due Date, 🚩 Priority, 📁 Project.
- [ ] Tapping each icon expands an inline picker within the sheet (does not navigate away).
- [ ] All inline pickers are collapsible by tapping the icon again.

#### AC-01.6 — Task Data Model
The created task must store:

| Field | Type | Required | Default |
|---|---|---|---|
| `id` | UUID | Yes | Auto-generated |
| `title` | String | Yes | — |
| `notes` | String? | No | nil |
| `dueDate` | Date? | No | nil |
| `dueTime` | Date? | No | nil |
| `priority` | Enum (high/medium/low/none) | No | `.none` |
| `projectId` | UUID? | No | nil (= Inbox) |
| `tags` | [String] | No | [] |
| `isCompleted` | Bool | Yes | false |
| `completedAt` | Date? | No | nil |
| `createdAt` | Date | Yes | Now |
| `updatedAt` | Date | Yes | Now |
| `isDeleted` | Bool | Yes | false |
| `deletedAt` | Date? | No | nil |

---

### UI / UX Specification

```
┌─────────────────────────────────┐
│  ────                           │  ← drag indicator
│                                 │
│  New Task                       │  ← sheet title (small)
│  ┌─────────────────────────┐    │
│  │ Task title...           │    │  ← auto-focused text field
│  └─────────────────────────┘    │
│                                 │
│  [📅] [🚩] [📁]        [Add →] │  ← toolbar row
└─────────────────────────────────┘
```

- Sheet height: ~35% of screen (compact), expands if inline pickers open.
- Sheet style: `.presentationDetents([.medium])` with drag to dismiss enabled.
- Background: system grouped background (adapts to dark mode).
- "Add" button: tinted with app accent color; disabled state when title is empty.
- Haptic feedback: `.medium` impact on successful save.

---

### Technical Notes

- Use `SwiftUI.sheet` with `.presentationDetents([.height(220)])`.
- Bind title to `@State var title: String = ""`.
- On save: call `TaskRepository.create(title:...)` which writes to SwiftData `ModelContext`.
- Use `@FocusState` to auto-focus title field on sheet appear.
- Optimistic insert: append to local list before async persistence completes.
- `updatedAt` must be set on every mutation — required for CloudKit conflict resolution later.

---

### Definition of Done

- [ ] Unit tests: `TaskRepository.create()` persists correctly to SwiftData.
- [ ] UI test: open sheet → type title → tap Add → task appears in list.
- [ ] UI test: open sheet → swipe down → no task created.
- [ ] UI test: open sheet → type title → swipe down → confirmation dialog shown.
- [ ] Accessibility: VoiceOver reads sheet title, title field label, and Add button.
- [ ] Tested on iPhone SE (small screen) and iPhone 15 Pro Max.
- [ ] Dark mode verified.
- [ ] Performance: sheet open animation runs at 60fps on iPhone 12.

---

---

## US-02 — Set Due Date & Time

> **"As a user, I want to set a due date and time on a task so I get reminded at the right moment."**

### Context & Motivation
A task without a due date is a wish. This story gives tasks temporal context, feeding the Today view and future notification delivery. The picker must feel native and fast — users shouldn't need to "go somewhere else" to set a date.

### Story Details

| Field | Value |
|---|---|
| **Story ID** | US-02 |
| **Epic** | Task Management |
| **Release** | MVP |
| **Priority** | Must Have |
| **Story Points** | 3 |
| **Dependencies** | US-01 (task must exist before a date can be set) |

---

### Acceptance Criteria

#### AC-02.1 — Date Picker Entry Points
- [ ] The 📅 icon on the Quick-Add Sheet opens an inline date picker.
- [ ] The date field on the Task Detail screen is tappable and opens the same picker experience.
- [ ] The picker is accessible both during creation and editing.

#### AC-02.2 — Date Selection
- [ ] A date can be selected using a native `DatePicker` in graphical (calendar grid) mode.
- [ ] "Today", "Tomorrow", and "Next Week" quick-select chips appear above the calendar for fast selection.
- [ ] Selecting a date does not require also selecting a time (time is optional).
- [ ] Once a date is selected, it is shown as a readable label (e.g., "Today", "Tomorrow", "Mon Apr 6") next to the 📅 icon.

#### AC-02.3 — Time Selection
- [ ] After selecting a date, an optional time row appears below.
- [ ] Time uses a wheel-style picker (`DatePicker` with `.hourAndMinute` component).
- [ ] If no time is set, the task appears in the "No Time" group of the Today view.
- [ ] If a time is set, the task appears in the Morning / Afternoon / Evening group based on time.

#### AC-02.4 — Clearing a Due Date
- [ ] A "Remove" or "×" button is shown next to the selected date chip to clear it.
- [ ] Clearing the date also clears the time.
- [ ] After clearing, the 📅 icon returns to its default unset state.

#### AC-02.5 — Past Dates
- [ ] Users can set past due dates (no restriction — useful for logging).
- [ ] Tasks with past due dates are displayed as **overdue** in the Today view (red date label).

#### AC-02.6 — Persistence
- [ ] `dueDate` and `dueTime` are saved to the task model on confirmation.
- [ ] Auto-save applies: no explicit "save" tap needed if editing an existing task.

---

### UI / UX Specification

```
Inline expansion inside Quick-Add Sheet:

  [📅 Today ×]  ← chip shown after selection; × clears it

  ┌──────────────────────────────┐
  │  [Today] [Tomorrow] [Next ▸] │  ← quick chips
  │                              │
  │     <Calendar Grid>          │
  │                              │
  │  Time  ○ None  ● 09:00 AM    │  ← optional time toggle
  └──────────────────────────────┘
```

- Quick chips use `.bordered` button style with rounded corners.
- Calendar grid: system `DatePicker` styled with `.graphical`.
- Overdue label color: `Color.red` (with SF Symbol `exclamationmark.circle` for accessibility).

---

### Technical Notes

- Use `DatePicker("", selection: $dueDate, displayedComponents: .date)` with `.graphical` style.
- Separate `@State var hasTime: Bool` toggle to control time component.
- Quick chip "Today" sets `dueDate = Calendar.current.startOfDay(for: Date())`.
- Quick chip "Tomorrow" sets `dueDate = Calendar.current.date(byAdding: .day, value: 1, to: today)`.
- Store date and time as a single `Date?` on the model; derive display grouping at render time.
- Overdue check: `dueDate < Calendar.current.startOfDay(for: Date())`.

---

### Definition of Done

- [ ] Unit tests: overdue logic returns correct bool for past/today/future dates.
- [ ] Unit tests: quick chip date calculations are correct.
- [ ] UI test: set due date → task appears in Today view.
- [ ] UI test: clear due date → task disappears from Today view.
- [ ] Accessibility: DatePicker is fully accessible via VoiceOver.
- [ ] Dark mode verified.

---

---

## US-03 — Complete a Task

> **"As a user, I want to mark a task as complete so I can track what I've accomplished."**

### Context & Motivation
Completion is the most emotionally significant moment in any productivity app. Done right, it creates a micro-reward loop that keeps users engaged. Done wrong (too hard to trigger, no feedback), users lose motivation. This interaction must be instant, satisfying, and reversible.

### Story Details

| Field | Value |
|---|---|
| **Story ID** | US-03 |
| **Epic** | Task Management |
| **Release** | MVP |
| **Priority** | Must Have |
| **Story Points** | 3 |
| **Dependencies** | US-01 (tasks must exist and be listed) |

---

### Acceptance Criteria

#### AC-03.1 — Completion Interactions
- [ ] Tapping the **circular checkbox** on the left of a task row marks it complete.
- [ ] Swiping **right** on a task row reveals a "Complete" action (green, checkmark icon) and confirms on full swipe.
- [ ] Both interactions produce the same result and the same feedback.

#### AC-03.2 — Visual & Haptic Feedback
- [ ] The checkbox animates from empty circle → filled circle with checkmark (spring animation, ~250ms).
- [ ] The task title gains a strikethrough style immediately on completion.
- [ ] A `.success` haptic notification fires on completion.
- [ ] The completed task row slides down and fades out of the active list within 600ms (after a brief 400ms "stay" delay so the user sees it's done).

#### AC-03.3 — Completed Tasks Destination
- [ ] Completed tasks are moved to a **"Completed"** section at the bottom of the list.
- [ ] The "Completed" section is **collapsed by default** and shows a count badge (e.g., "Completed (3)").
- [ ] Tapping the section header expands/collapses the completed list.
- [ ] Completed tasks display their `completedAt` timestamp.

#### AC-03.4 — Undo Completion
- [ ] Immediately after completing a task, a system **toast / snackbar** appears: **"Task completed. Undo"** with a 4-second auto-dismiss timer.
- [ ] Tapping "Undo" restores the task to its previous incomplete state instantly.
- [ ] The undo toast must not block interaction with the rest of the UI.

#### AC-03.5 — Re-opening a Completed Task
- [ ] In the Completed section, tapping the checkbox on a completed task unchecks it and moves it back to the active list.
- [ ] The same animations play in reverse.

#### AC-03.6 — Persistence
- [ ] `isCompleted = true` and `completedAt = Date()` are written to SwiftData on completion.
- [ ] Undoing sets `isCompleted = false` and `completedAt = nil`.

---

### UI / UX Specification

```
Active task row:
  ○  Buy groceries          → Today 3 PM   🔴
  ↑ checkbox

On tap:
  ✓  ~~Buy groceries~~      (strikethrough, fades out after 400ms)

Toast (bottom, above tab bar):
  ┌──────────────────────────────────┐
  │  ✓ Task completed.       [Undo] │
  └──────────────────────────────────┘
  Auto-dismisses in 4 seconds.
```

- Checkbox size: 24×24pt; tap target: 44×44pt.
- Strikethrough: `Text(...).strikethrough(true, color: .secondary)`.
- Completed section header: `Label("Completed (3)", systemImage: "checkmark.circle")`.
- Toast: custom overlay anchored to `.bottom` with `.transition(.move(edge: .bottom).combined(with: .opacity))`.

---

### Technical Notes

- Completion state managed in `TaskRepository.complete(taskId:)`.
- The "stay delay" before animation: use `DispatchQueue.main.asyncAfter(deadline: .now() + 0.4)`.
- Undo implementation: store a `lastCompletedTask: Task?` in the view model; undo calls `TaskRepository.uncomplete(taskId:)`.
- Use `withAnimation(.spring(response: 0.3, dampingFraction: 0.7))` for the checkbox fill.
- Section data: filter tasks by `isCompleted`; sort completed by `completedAt` descending.

---

### Definition of Done

- [ ] Unit tests: `complete()` sets `isCompleted = true` and `completedAt`.
- [ ] Unit tests: `uncomplete()` sets `isCompleted = false` and `completedAt = nil`.
- [ ] UI test: tap checkbox → task moves to Completed section.
- [ ] UI test: complete task → tap Undo in toast → task returns to active list.
- [ ] UI test: swipe right → task completes.
- [ ] Haptic tested on physical device.
- [ ] Accessibility: checkbox role is announced as "button, double-tap to complete."
- [ ] Reduced Motion: animation replaced with instant state change (no slide/fade).

---

---

## US-04 — Delete a Task

> **"As a user, I want to delete tasks I no longer need without the fear of permanent loss."**

### Context & Motivation
Users need a confident way to remove noise from their list. But accidental deletion is one of the top sources of frustration in productivity apps. This story balances speed of deletion with a safety net (Trash) that makes users feel in control.

### Story Details

| Field | Value |
|---|---|
| **Story ID** | US-04 |
| **Epic** | Task Management |
| **Release** | MVP |
| **Priority** | Must Have |
| **Story Points** | 2 |
| **Dependencies** | US-01 |

---

### Acceptance Criteria

#### AC-04.1 — Delete Interaction
- [ ] Swiping **left** on a task row reveals a **"Delete"** action (red, trash icon).
- [ ] A full left-swipe immediately soft-deletes the task (no confirmation for simple tasks).
- [ ] Tasks that have **notes content** show a confirmation alert before deletion: **"Delete '[Task Title]'? This task has notes."** with "Delete" (destructive) and "Cancel."

#### AC-04.2 — Soft Delete (Trash)
- [ ] Deleted tasks are not permanently removed. They are soft-deleted: `isDeleted = true`, `deletedAt = Date()`.
- [ ] Soft-deleted tasks are excluded from all list views, search results, and the Today view immediately.
- [ ] The Trash is accessible from **Settings → Trash**.

#### AC-04.3 — Undo Delete
- [ ] Immediately after deletion, a toast appears: **"Task deleted. Undo"** with a 4-second auto-dismiss.
- [ ] Tapping "Undo" restores the task (`isDeleted = false`, `deletedAt = nil`) immediately.

#### AC-04.4 — Trash View
- [ ] Settings → Trash shows all soft-deleted tasks, sorted by `deletedAt` descending.
- [ ] Each trashed task shows: title, `deletedAt` date, and a "Restore" button.
- [ ] A "Delete All" button at the top of the Trash permanently deletes all items (with confirmation alert).
- [ ] Individual swipe-left on a trashed task → permanent delete (with confirmation).
- [ ] Auto-purge: tasks deleted > 30 days ago are permanently purged on app launch (background task).

#### AC-04.5 — Trash Badge
- [ ] If the Trash has items, a subtle count badge or "Trash (5)" label appears in Settings.

---

### UI / UX Specification

```
Swipe-left on task row:
  ┌─────────────────────────┬──────────┐
  │  Buy groceries          │ 🗑 Delete│
  └─────────────────────────┴──────────┘
  Red background, white trash icon + "Delete" label.

Toast (same style as US-03 Undo):
  ┌──────────────────────────────────┐
  │  🗑 Task deleted.        [Undo] │
  └──────────────────────────────────┘

Confirmation alert (tasks with notes):
  Title:   Delete "Buy groceries"?
  Message: This task has notes and will be moved to Trash.
  Actions: [Delete] (destructive)  [Cancel]
```

- Swipe action: `.destructive` role, system red tint.
- Confirmation: `Alert` with `.destructive` button style.
- Trash row: standard `List` row with title + secondary `deletedAt` text + "Restore" trailing button.

---

### Technical Notes

- `TaskRepository.softDelete(taskId:)` sets `isDeleted = true`, `deletedAt = Date()`.
- `TaskRepository.restore(taskId:)` sets `isDeleted = false`, `deletedAt = nil`.
- `TaskRepository.permanentlyDelete(taskId:)` removes the record from SwiftData entirely.
- List fetch predicates must always filter `isDeleted == false`.
- Auto-purge: run on `ScenePhase.active` if last purge > 24h ago. Delete where `deletedAt < Date() - 30 days`.
- Undo: same pattern as US-03 — `lastDeletedTask` stored in view model.

---

### Definition of Done

- [ ] Unit tests: `softDelete()`, `restore()`, `permanentlyDelete()` behaviors.
- [ ] Unit tests: auto-purge deletes tasks older than 30 days only.
- [ ] UI test: swipe left → task disappears from list → appears in Trash.
- [ ] UI test: delete → Undo → task reappears in list.
- [ ] UI test: Trash → Restore → task appears in Inbox.
- [ ] Confirmation alert shown when task has notes.
- [ ] No confirmation shown for tasks without notes.
- [ ] Accessibility: swipe action announced by VoiceOver as "Delete button."

---

---

## US-05 — Assign Priority to a Task

> **"As a user, I want to assign a priority level to a task so I know what to focus on first."**

### Context & Motivation
Not all tasks are equal. Priority gives users a signal for sequencing their work and powers the Today view's smart sorting. The four-level system (High / Medium / Low / None) maps to real-world urgency without overwhelming users with too many options.

### Story Details

| Field | Value |
|---|---|
| **Story ID** | US-05 |
| **Epic** | Task Management |
| **Release** | v1.0 |
| **Priority** | Must Have |
| **Story Points** | 2 |
| **Dependencies** | US-01 (task creation sheet must exist) |

---

### Acceptance Criteria

#### AC-05.1 — Priority Entry Points
- [ ] The 🚩 icon on the Quick-Add Sheet opens an inline priority picker.
- [ ] The priority field on the Task Detail screen is always visible and tappable.
- [ ] Priority can be changed at any time by tapping the field.

#### AC-05.2 — Priority Levels
The system supports exactly **four levels**:

| Level | Icon | Color | Label |
|---|---|---|---|
| High | `flag.fill` | Red (`#FF3B30`) | High |
| Medium | `flag.fill` | Orange (`#FF9500`) | Medium |
| Low | `flag.fill` | Blue (`#007AFF`) | Low |
| None | `flag` (outline) | Gray | None |

- [ ] All four levels are displayed as a horizontal segmented row or a menu.
- [ ] The currently selected priority is visually highlighted.
- [ ] Selecting "None" clears the priority.

#### AC-05.3 — Priority Display in Lists
- [ ] Every task row displays a small colored flag icon on the **right side** when priority is High, Medium, or Low.
- [ ] No icon shown when priority is None (clean list for unprioritized tasks).
- [ ] High priority tasks are always sorted above Medium, which is above Low, which is above None — within the same date group in the Today view.

#### AC-05.4 — Persistence
- [ ] `priority` field saved to SwiftData immediately on selection.
- [ ] Auto-save applies for existing task edits.

---

### UI / UX Specification

```
Inline picker on Quick-Add Sheet:

  Priority:
  [ 🔴 High ] [ 🟠 Medium ] [ 🔵 Low ] [ — None ]
     ↑ segmented control style, selected = filled/tinted

Task row with priority:
  ○  Design new onboarding      → Tomorrow       🔴
                                               ↑ right-aligned flag
```

- Segmented control: custom `HStack` of `Button`s styled with capsule background.
- Selected state: filled tint color background with white label.
- Unselected state: clear background with tinted label.

---

### Technical Notes

- `Priority` enum: `case high, medium, low, none` — `RawRepresentable` as `Int` for SwiftData storage.
- Sorting: `Priority.sortOrder` computed property returns Int (high=0, medium=1, low=2, none=3).
- List sort descriptor: primary by `dueDate`, secondary by `priority.sortOrder`.
- Do not sort globally by priority — only within same-date buckets to respect user's temporal intent.

---

### Definition of Done

- [ ] Unit tests: `Priority.sortOrder` returns correct values.
- [ ] Unit tests: task list sorted correctly by priority within a date group.
- [ ] UI test: set High priority → red flag appears on task row.
- [ ] UI test: set None → flag disappears.
- [ ] Accessibility: priority picker announced with current value and available options.
- [ ] Color is not the sole indicator — flag icon + label also used (colorblind safe).

---

---

## US-06 — Add Notes to a Task

> **"As a user, I want to add notes to a task so I have the context I need when I return to it."**

### Context & Motivation
A task title alone rarely captures the full picture. Notes transform a task from a reminder into a briefing document. This story introduces the Task Detail screen — a dedicated space for richer task information that doesn't clutter the task list.

### Story Details

| Field | Value |
|---|---|
| **Story ID** | US-06 |
| **Epic** | Task Management |
| **Release** | v1.0 |
| **Priority** | Should Have |
| **Story Points** | 3 |
| **Dependencies** | US-01 (task must exist); US-05 (task detail screen is shared) |

---

### Acceptance Criteria

#### AC-06.1 — Access to Notes
- [ ] Tapping anywhere on a task row (except the checkbox and swipe zones) opens the **Task Detail Screen**.
- [ ] The Task Detail Screen is a full-screen sheet or push navigation.
- [ ] The notes field is visible and tappable on the Task Detail Screen.

#### AC-06.2 — Notes Input
- [ ] Notes support **plain text** in MVP (rich text formatting is deferred to v1.1).
- [ ] The notes text area is multi-line, grows dynamically with content, and has no character limit (practical limit: SwiftData storage).
- [ ] Placeholder text: *"Add notes, links, or details…"*
- [ ] Keyboard toolbar shows a "Done" button to dismiss keyboard without closing the screen.

#### AC-06.3 — Notes in Task Row
- [ ] If a task has notes, a small **note icon** (`note.text`, gray) is shown in the task row, right of the title.
- [ ] This signals to the user that there is more context available.

#### AC-06.4 — Auto-Save
- [ ] Notes are auto-saved as the user types (debounced: save after 500ms of inactivity).
- [ ] No explicit "Save" button required.
- [ ] A subtle "Saved" confirmation (label fade, not a toast) may appear briefly after auto-save.

#### AC-06.5 — Notes in Deletion Confirmation
- [ ] If a task has non-empty notes, the deletion confirmation (US-04) explicitly mentions it (already covered in AC-04.1).

---

### UI / UX Specification

```
Task Detail Screen:
┌───────────────────────────────────────┐
│  ← Back           Buy groceries   [⋯]│  ← nav title = task title
├───────────────────────────────────────┤
│  ○  Buy groceries                     │  ← inline editable title
│                                       │
│  📅 Tomorrow, 3:00 PM                 │  ← tappable date row
│  🚩 High                              │  ← tappable priority row
│  📁 Personal                          │  ← tappable project row
│  🏷 errands, shopping                  │  ← tappable tags row
│                                       │
│  Notes                                │  ← section header
│  ┌─────────────────────────────────┐  │
│  │ Get oat milk, bananas,          │  │
│  │ and bread from the store.       │  │
│  │                                 │  │
│  └─────────────────────────────────┘  │
│                                       │
│  Created Mar 30, 2026                 │  ← footer metadata
└───────────────────────────────────────┘
```

- Title: large inline `TextField`, `.title2` font weight.
- Notes: `TextEditor` with `.body` font, minimum height 100pt.
- All metadata rows (date, priority, project, tags): `Form`-style rows with trailing value + chevron.
- Footer: secondary text, small font, not interactive.

---

### Technical Notes

- Task Detail: `TaskDetailView(taskId: UUID)` receives ID and loads from SwiftData `@Query`.
- Auto-save debounce: `onChange(of: notes)` triggers a `Task { await save() }` with 500ms sleep.
- Notes indicator on row: `task.notes?.isEmpty == false`.
- Navigation: use `NavigationLink` or `.navigationDestination` — do not use sheets for Task Detail (it's a full content view).
- For v1.1: replace `TextEditor` with a lightweight attributed string editor (e.g., using `NSTextView` via UIViewRepresentable or a SwiftUI attributed string editor).

---

### Definition of Done

- [ ] Unit tests: notes auto-save debounce (mock timer).
- [ ] Unit tests: `task.hasNotes` computed property.
- [ ] UI test: tap task row → detail opens.
- [ ] UI test: type notes → navigate away → return → notes persisted.
- [ ] Note icon visible in task list row when notes exist.
- [ ] Accessibility: TextEditor label reads "Notes for [task title]."
- [ ] Keyboard avoidance: notes field scrolls above keyboard when typing.
- [ ] Dark mode verified.
- [ ] Dynamic Type: all text scales correctly at largest accessibility size.

---

---

## Summary for Sprint Planning

| Story | Release | Points | Entry Point | Key Interaction | Key Risk |
|---|---|---|---|---|---|
| US-01 Quick Capture | MVP | 5 | FAB `+` button | Sheet → type title → Add | Keyboard animation lag on older devices |
| US-02 Due Date & Time | MVP | 3 | 📅 icon in sheet + detail | Inline date picker | DatePicker graphical mode heavy on layout |
| US-03 Complete Task | MVP | 3 | Checkbox + swipe right | Tap/swipe → animate → undo | Undo toast timing UX |
| US-04 Delete Task | MVP | 2 | Swipe left | Swipe → soft delete → undo | Accidental deletion without notes check |
| US-05 Priority | v1.0 | 2 | 🚩 icon in sheet + detail | Segmented picker | Sort order logic edge cases |
| US-06 Notes | v1.0 | 3 | Tap task row | Detail view + TextEditor | Auto-save debounce, keyboard avoidance |
| **Total** | | **18** | | | |

---

*This document is owned by the Product Owner. For questions, contact the product team before beginning development on any story.*
