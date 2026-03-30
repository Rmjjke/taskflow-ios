# Product Requirements Document (PRD)
## TaskFlow — iOS Task Management App

| Field | Detail |
|---|---|
| **Product** | TaskFlow iOS |
| **Document Version** | 1.1 |
| **Status** | Draft |
| **Author** | Product Owner |
| **Last Updated** | 2026-03-30 |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Problem Statement](#2-problem-statement)
3. [Goals & Success Metrics](#3-goals--success-metrics)
4. [Target Users & Personas](#4-target-users--personas)
5. [MVP — Minimum Viable Product](#5-mvp--minimum-viable-product)
6. [Scope](#6-scope)
7. [Feature Requirements](#7-feature-requirements)
8. [User Stories](#8-user-stories)
9. [Non-Functional Requirements](#9-non-functional-requirements)
10. [Information Architecture & Navigation](#10-information-architecture--navigation)
11. [Technical Constraints & Integrations](#11-technical-constraints--integrations)
12. [Release Milestones](#12-release-milestones)
13. [Open Questions & Risks](#13-open-questions--risks)
14. [Out of Scope](#14-out-of-scope)
15. [Appendix & Glossary](#15-appendix--glossary)

---

## 1. Executive Summary

**TaskFlow** is a native iOS task and project management application designed to help individuals and small teams capture, organize, prioritize, and complete work efficiently. TaskFlow differentiates itself through a clean, distraction-free UI, intelligent task prioritization, and seamless syncing across Apple devices—built for the way people actually work.

The v1.0 launch targets individual power users and freelancers. Subsequent releases will expand into team collaboration and enterprise features.

---

## 2. Problem Statement

### The Challenge
Existing task management apps on iOS either overwhelm users with complexity (Jira, Asana) or lack the depth needed for serious productivity (Apple Reminders, basic to-do apps). Users are caught between tools that are too simple or too heavy.

### Core Pain Points
- **Fragmentation**: Users juggle multiple apps—notes, reminders, calendars—with no unified view.
- **Prioritization friction**: No smart assistance for deciding what to work on next.
- **Context loss**: Tasks get created but lack enough context to act on later.
- **Weak iOS integration**: Third-party apps don't leverage Siri, Widgets, Focus Modes, or Shortcuts to their potential.
- **Sync unreliability**: iCloud or proprietary sync failures cause data loss and frustration.

---

## 3. Goals & Success Metrics

### Business Goals
- Launch on the App Store with a 4.5+ star rating within 90 days.
- Reach 50,000 downloads in the first 6 months.
- Achieve a 30-day retention rate of ≥ 40%.
- Drive 5% free-to-paid conversion via a Pro subscription tier.

### Product Goals
- Reduce time-to-capture a task to under 5 seconds.
- Enable users to identify their top 3 priorities each morning without manual sorting.
- Deliver a fully offline-capable experience with background sync.

### Key Metrics (KPIs)

| Metric | Target |
|---|---|
| Daily Active Users (DAU) | 10,000 by Month 3 |
| Tasks created per DAU | ≥ 5 |
| Task completion rate | ≥ 60% |
| Session length (avg) | 3–6 minutes |
| Crash-free sessions | ≥ 99.5% |
| App Store rating | ≥ 4.5 stars |

---

## 4. Target Users & Personas

### Persona 1 — "Focused Freelancer" (Primary)
- **Name**: Alex, 29, Freelance Designer
- **Goal**: Manage client projects, deadlines, and personal errands in one place.
- **Frustrations**: Forgets tasks without a reliable capture system; hates switching between Notion and Apple Reminders.
- **Behaviors**: Uses iPhone all day; occasionally on iPad; wants quick capture from lock screen.
- **Key Need**: Fast capture, project grouping, due-date reminders.

### Persona 2 — "Ambitious Professional" (Primary)
- **Name**: Jordan, 34, Product Manager
- **Goal**: Stay on top of work tasks and personal goals without being overwhelmed.
- **Frustrations**: Work spills into personal life; no clean separation of contexts.
- **Behaviors**: Heavy Siri Shortcuts user; uses Focus Modes; syncs across iPhone and Mac.
- **Key Need**: Context tagging, smart Today view, Siri integration.

### Persona 3 — "Student Planner" (Secondary)
- **Name**: Maya, 21, University Student
- **Goal**: Track assignments, exams, and part-time job schedule.
- **Frustrations**: Deadlines sneak up; existing apps feel too "corporate."
- **Behaviors**: Primarily iPhone; budget-conscious (free tier preferred).
- **Key Need**: Calendar integration, recurring tasks, clean visual design.

---

## 5. MVP — Minimum Viable Product

> The MVP is the **smallest functional version of TaskFlow** that delivers real value to a user, can be put in front of testers, and validates the core product hypothesis: *"A fast, frictionless task capture and completion loop keeps users coming back."*

### MVP Philosophy
Ship the loop, not the features. The MVP must support one complete user journey end-to-end:

> **Capture a task → See it in a list → Complete it (or delete it).**

Everything else is polish or expansion on top of this loop.

---

### MVP User Journey

```
1. User opens app for the first time
         ↓
2. Lands on Inbox (empty state with friendly illustration + "Add your first task" CTA)
         ↓
3. Taps + → Quick-Add Sheet opens → Types a title → Taps Add
         ↓
4. Task appears in the Inbox list
         ↓
5. (Optional) Taps the task → sets a due date
         ↓
6. Later: opens app → sees task in Inbox
         ↓
7. Swipes right or taps checkbox → task is marked complete → satisfying animation
         ↓
8. (Optional) Decides task is irrelevant → swipes left → deletes it → Undo if needed
```

This loop must work **100% reliably, 100% offline, with zero crashes** before any other feature is built.

---

### MVP Feature Set

| # | Feature | Details | Story |
|---|---|---|---|
| 1 | **Task creation (title only)** | `+` FAB → sheet → type title → Add | US-01 |
| 2 | **Inbox list view** | Flat list of all active tasks, sorted by creation date | — |
| 3 | **Task completion** | Tap checkbox or swipe right → animation + haptic | US-03 |
| 4 | **Task deletion** | Swipe left → soft delete → undo toast | US-04 |
| 5 | **Due date** | Inline date picker on creation + edit | US-02 |
| 6 | **Local persistence** | SwiftData, no sync (iCloud sync is v1.0) | — |
| 7 | **Empty state** | Friendly illustration + CTA on empty Inbox | — |
| 8 | **Basic navigation** | Single screen (Inbox) + Task Detail push | — |

### MVP Explicitly Excludes

The following features from v1.0 are **deferred past MVP**:

| Deferred Feature | Reason |
|---|---|
| Projects & Lists | Adds organizational complexity; not needed to prove core loop |
| Tags | Nice-to-have; doesn't affect core value |
| Priority levels | Useful but not critical for initial validation |
| Task notes | Adds a full detail screen; deferred to v1.0 |
| Today view | Requires due date + sorting logic; deferred |
| Upcoming view | Requires calendar — deferred |
| Search | Deferred until task volume justifies it |
| iCloud sync / CloudKit | Complexity too high for MVP; local-only first |
| Widgets | Requires WidgetKit — deferred |
| Siri integration | App Intents complexity — deferred |
| Notifications / Reminders | Deferred (due date stored but no notification fired) |
| Pro subscription / Paywall | No monetization in MVP |
| Onboarding flow | Replaced by empty state CTA |
| Dark mode polish | System dark mode works by default; custom polish deferred |

---

### MVP Screen Inventory

| Screen | Description |
|---|---|
| **Inbox** | Main list of all active tasks. FAB `+` in bottom-right. Empty state when no tasks. |
| **Quick-Add Sheet** | Half-sheet for fast task capture. Title field (required). Due date icon (optional). Dismiss or Add. |
| **Task Detail** | Full-screen push. Editable title. Due date row. Completed/Delete actions. |
| **Completed Section** | Collapsed section at bottom of Inbox. Expandable. Shows completed tasks with checkmark. |
| **Trash (minimal)** | Settings → Trash. List of soft-deleted tasks. Restore + permanent delete. |

---

### MVP Navigation Structure

```
App Launch
  └── Inbox (Root View)
        ├── Task Detail (push on row tap)
        │     └── back → Inbox
        ├── Quick-Add Sheet (modal, FAB tap)
        │     └── dismiss → Inbox
        └── Settings (gear icon, top right)
              └── Trash
```

No tab bar in MVP. Single-screen architecture keeps complexity low and keeps focus on the core loop.

---

### MVP Success Criteria

Before graduating MVP to v1.0 development, the following must be true:

| Criterion | Target |
|---|---|
| Internal testers can capture and complete 10 tasks without confusion | 100% |
| Zero data loss in 48 hours of heavy local usage | 0 losses |
| App cold launch on iPhone 12 | < 1.5s |
| Crash-free sessions in TestFlight beta | ≥ 99% |
| Task creation time (open app → task saved) | ≤ 5 seconds |
| Tester NPS on core loop ("was capturing tasks easy?") | ≥ 8 / 10 |

---

### MVP Tech Stack (Simplified)

| Area | Decision |
|---|---|
| **Language** | Swift 6, SwiftUI |
| **Data** | SwiftData (local only, no CloudKit in MVP) |
| **Architecture** | MVVM — `TaskRepository` as single source of truth |
| **Minimum iOS** | iOS 17.0 |
| **No sync** | iCloud/CloudKit added in v1.0 |
| **No analytics** | Added in v1.0 |

---

## 6. Scope

### In Scope — v1.0 (Post-MVP)
- Task creation, editing, and deletion
- Project / list grouping
- Due dates, times, and reminders
- Priority levels (High, Medium, Low, None)
- Tags / labels
- Today view with smart suggestions
- Search
- iCloud sync (CloudKit)
- Widgets (small, medium, large)
- Dark mode support
- Siri integration (create task, list tasks due today)
- Onboarding flow
- Pro subscription (via StoreKit 2)

### In Scope — v1.1 (Next Release)
- Recurring tasks
- Subtasks
- File & image attachments
- Apple Watch companion app

### Future Consideration
- Team collaboration & sharing
- Natural language input (NLP parsing of due dates)
- Calendar view
- Mac Catalyst / macOS app
- Third-party integrations (Slack, Notion, Google Calendar)

---

## 7. Feature Requirements

### 6.1 Task Management

#### FR-01: Task Creation
- Users can create a task with a title (required), notes (optional), due date (optional), time (optional), project (optional), priority (optional), and tags (optional).
- Quick-add support: tap `+` or use a swipe gesture to open a minimal capture sheet.
- Capture sheet must be dismissible in < 1 tap without saving.

#### FR-02: Task Editing
- All task fields must be editable inline.
- Changes must be auto-saved; no explicit "Save" button required.
- Undo/redo supported within the current session.

#### FR-03: Task Completion
- Swipe right or tap a checkbox to mark a task complete.
- Completion triggers a satisfying haptic + visual animation.
- Completed tasks move to a "Completed" section, hidden by default; accessible via filter.

#### FR-04: Task Deletion
- Swipe left → Delete with a confirmation prompt for tasks with notes/subtasks.
- Deleted tasks go to Trash; auto-purged after 30 days.
- Trash is manually clearable.

#### FR-05: Task Prioritization
- Four levels: 🔴 High, 🟡 Medium, 🔵 Low, ⚪ None.
- Priority is surfaced in list views via a colored flag indicator.
- The Today view intelligently surfaces High priority + upcoming due dates first.

---

### 6.2 Projects & Lists

#### FR-06: Projects
- Users can create unlimited projects (lists).
- Each project has a name, icon (SF Symbol), and color.
- Tasks can belong to exactly one project or remain in Inbox (default).
- Projects can be reordered via drag and drop.

#### FR-07: Inbox
- All tasks without an assigned project land in Inbox.
- Inbox is the default landing view on first launch.

#### FR-08: Sections within Projects
- Users can create named sections within a project to group tasks (e.g., "To Do", "In Progress", "Done").
- Sections are collapsible.

---

### 6.3 Today & Smart Views

#### FR-09: Today View
- Surfaces all tasks due today + overdue tasks.
- Grouped by: Overdue → Morning → Afternoon → Evening → No Time.
- Includes a motivational progress bar (tasks completed / total due today).

#### FR-10: Upcoming View
- 7-day rolling calendar view of tasks with due dates.
- Day headers show day of week + date.

#### FR-11: Filters & Search
- Global search across all tasks, projects, and tags.
- Search results update in real time (< 200ms).
- Filter options: by project, by tag, by priority, by due date range, by completion status.

---

### 6.4 Notifications & Reminders

#### FR-12: Reminders
- Users can set one or more time-based reminders per task.
- Notifications use iOS rich notifications with "Complete" and "Snooze 1h" actions.
- Location-based reminders (Pro feature): trigger when arriving at / leaving a saved location.

#### FR-13: Daily Digest
- Optional morning notification (user-configurable time) summarizing tasks due today.

---

### 6.5 Sync & Offline

#### FR-14: iCloud Sync (CloudKit)
- All data synced via CloudKit (private database).
- Full offline support: all CRUD operations work without internet.
- Conflict resolution: last-write-wins with a conflict log visible in Settings.

---

### 6.6 Widgets

#### FR-15: Home Screen Widgets
- **Small**: Next task due or top priority task.
- **Medium**: Today's task list (up to 5 items with completion checkboxes).
- **Large**: Today's full task list + project breakdown.
- Widgets are interactive (tap to complete a task — iOS 17+).
- Lock Screen widget: task count due today.

---

### 6.7 Siri & Shortcuts

#### FR-16: Siri Integration
- "Hey Siri, add [task] to TaskFlow" → creates task in Inbox.
- "Hey Siri, what's on my TaskFlow today?" → reads today's tasks.
- Siri Shortcuts app support: expose all key actions as Shortcuts intents.

---

### 6.8 Pro Subscription

#### FR-17: TaskFlow Pro
- Billing via StoreKit 2 (monthly and annual options).
- Pro features:
  - Unlimited projects (free tier: up to 5)
  - Location-based reminders
  - Custom themes & app icons
  - Advanced filters & saved filter views
  - Priority support
- Free trial: 7 days on annual plan.
- Paywall presented contextually when a free-tier limit is hit.

---

### 6.9 Onboarding

#### FR-18: Onboarding Flow
- 4-screen onboarding: Value prop → Core feature highlights → Notification permission → Sign in with Apple (optional, for iCloud).
- Skippable; re-accessible from Settings.
- Sample data offered ("Load sample tasks") to help users explore.

---

## 8. User Stories

### Epic: Task Management

| ID | User Story | Priority | Acceptance Criteria |
|---|---|---|---|
| US-01 | As a user, I want to quickly capture a task so I don't lose ideas. | Must Have | Task created in ≤ 3 taps; title is the only required field. |
| US-02 | As a user, I want to set a due date and time so I get reminded at the right moment. | Must Have | Date/time picker accessible from task creation and edit views. |
| US-03 | As a user, I want to mark tasks complete with a swipe so completion feels satisfying. | Must Have | Swipe-right completes task; haptic feedback fires; animation plays. |
| US-04 | As a user, I want to assign a priority level so I know what to focus on. | Must Have | Priority selector (High/Medium/Low/None) available in task sheet. |
| US-05 | As a user, I want to delete tasks I no longer need without permanent loss. | Must Have | Deleted tasks go to Trash; restorable within 30 days. |
| US-06 | As a user, I want to add notes to a task so I have context when I return to it. | Should Have | Rich-text notes field supports basic formatting (bold, bullet, link). |

### Epic: Organization

| ID | User Story | Priority | Acceptance Criteria |
|---|---|---|---|
| US-07 | As a user, I want to group tasks into projects so I can separate work and personal tasks. | Must Have | Projects can be created, renamed, colored, and deleted. |
| US-08 | As a user, I want to add tags to tasks so I can filter across projects. | Should Have | Tags created inline; multi-tag support; filterable globally. |
| US-09 | As a user, I want to create sections inside a project so I can see task stages. | Should Have | Sections are named, collapsible, and reorderable. |

### Epic: Smart Views

| ID | User Story | Priority | Acceptance Criteria |
|---|---|---|---|
| US-10 | As a user, I want a Today view so I immediately know what needs my attention. | Must Have | Shows overdue + due today tasks; sorted by priority & time. |
| US-11 | As a user, I want an Upcoming view so I can plan my week ahead. | Must Have | 7-day view; tasks grouped by day with date headers. |
| US-12 | As a user, I want to search all my tasks so I can find anything quickly. | Must Have | Search returns results in < 200ms; searches title, notes, and tags. |

### Epic: Sync & Reliability

| ID | User Story | Priority | Acceptance Criteria |
|---|---|---|---|
| US-13 | As a user, I want my tasks synced across my iPhone and iPad automatically. | Must Have | Changes on one device appear on another within 30 seconds on Wi-Fi. |
| US-14 | As a user, I want the app to work offline so I'm never blocked. | Must Have | All CRUD operations complete offline; sync on reconnect. |

### Epic: Monetization

| ID | User Story | Priority | Acceptance Criteria |
|---|---|---|---|
| US-15 | As a free user, I want to understand Pro benefits so I can decide to upgrade. | Must Have | Paywall appears when free limit is hit; clearly explains Pro value. |
| US-16 | As a Pro user, I want to manage my subscription from within the app so I feel in control. | Must Have | Subscription management accessible in Settings; links to App Store. |

---

## 9. Non-Functional Requirements

### 8.1 Performance
- App cold launch: < 1.5 seconds on iPhone 12 or later.
- Task list scroll: 60 fps minimum; 120 fps on ProMotion devices.
- Search response: < 200ms for up to 10,000 tasks.
- CloudKit sync: changes reflected within 30 seconds on the same Wi-Fi network.

### 8.2 Reliability & Availability
- Crash-free session rate: ≥ 99.5% (measured via Crashlytics or Xcode Organizer).
- No data loss under any sync conflict scenario.
- All critical data backed up to iCloud; recoverable after app reinstall.

### 8.3 Security & Privacy
- No third-party analytics SDKs that track personal data.
- All task data stored in CloudKit private database (user-owned).
- App Tracking Transparency (ATT) not required (no ad tracking).
- Privacy Nutrition Label accurately reflects data usage.
- Biometric lock (Face ID / Touch ID) available as optional app lock.

### 8.4 Accessibility
- Full VoiceOver support on all screens.
- Dynamic Type supported (all text scales with system font size).
- Minimum tap target size: 44×44 pt.
- Color is never the sole differentiator for information (priority labels include icons).
- Supports Reduce Motion preference.

### 8.5 Compatibility
- Minimum iOS version: iOS 17.0
- Supported devices: iPhone (primary), iPad (optimized layout)
- Localization: English (v1.0); Spanish, French, German (v1.1)

### 8.6 Scalability
- Local database (SwiftData / Core Data) must handle up to 50,000 tasks without performance degradation.

---

## 10. Information Architecture & Navigation

```
Tab Bar
├── Today          (clock icon)
├── Inbox          (tray icon)
├── Projects       (folder icon)
│   ├── Project Detail
│   │   ├── Section
│   │   │   └── Task Detail
│   └── + New Project
├── Upcoming       (calendar icon)
└── Search         (magnifying glass icon)

Settings (gear icon — top right)
├── Account & Sync
├── Notifications
├── Appearance (Theme, App Icon)
├── Subscription (TaskFlow Pro)
├── Siri & Shortcuts
├── Privacy
└── About
```

---

## 11. Technical Constraints & Integrations

| Area | Decision |
|---|---|
| **Language** | Swift 6, SwiftUI |
| **Data Layer** | SwiftData (with Core Data fallback for iOS 16 if needed) |
| **Sync** | CloudKit (private database) |
| **Auth** | Sign in with Apple (optional — for cross-device iCloud sync) |
| **Payments** | StoreKit 2 |
| **Notifications** | UserNotifications framework; UNLocationNotificationTrigger for location reminders |
| **Widgets** | WidgetKit (iOS 17 interactive widgets) |
| **Siri** | App Intents framework |
| **Analytics** | TelemetryDeck (privacy-first, no PII) |
| **Crash Reporting** | Xcode Organizer + optional Sentry |
| **CI/CD** | Xcode Cloud |
| **Minimum iOS** | iOS 17.0 |

---

## 12. Release Milestones

| Milestone | Target Date | Key Deliverables |
|---|---|---|
| **M0 — Discovery & Design** | 2026-04-30 | Finalized PRD v1.1, wireframes, design system, technical architecture |
| **M1 — MVP (Internal)** | 2026-05-30 | Task CRUD (US-01–04), Inbox view, Task Detail, local persistence, empty state, basic navigation — **no sync, no projects, no notifications** |
| **M1.5 — MVP TestFlight** | 2026-06-10 | MVP distributed to internal testers; success criteria validated |
| **M2 — Alpha (v1.0 features)** | 2026-07-15 | Due dates, Priority, Notes, Projects, Tags, Today View, iCloud sync |
| **M3 — Beta** | 2026-08-15 | Upcoming, Widgets, Siri, Notifications, Pro paywall (StoreKit 2), Onboarding |
| **M4 — Release Candidate** | 2026-09-01 | Accessibility audit, performance tuning, bug bash, App Store assets |
| **M5 — App Store Launch (v1.0)** | 2026-09-22 | Public launch on App Store |
| **M6 — v1.1** | 2026-11-17 | Recurring tasks, subtasks, attachments, Apple Watch app |

---

## 13. Open Questions & Risks

### Open Questions

| # | Question | Owner | Due |
|---|---|---|---|
| OQ-01 | Should onboarding require Sign in with Apple, or remain optional? | Product | 2026-04-10 |
| OQ-02 | What is the free tier project limit — 3 or 5? | Product + Growth | 2026-04-10 |
| OQ-03 | Should we support Mac Catalyst in v1.0 or defer to v1.2? | Engineering | 2026-04-15 |
| OQ-04 | What is the pricing strategy for Pro (monthly / annual)? | Product + Finance | 2026-04-20 |
| OQ-05 | Do we build a custom NLP date parser or rely on system APIs? | Engineering | 2026-05-01 |

### Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| CloudKit sync complexity causes launch delays | Medium | High | Spike on sync architecture in M0; allocate buffer in M2 schedule |
| App Store review rejection for subscription model | Low | High | Follow Apple HIG subscription guidelines strictly; pre-review checklist |
| Low day-30 retention due to feature gaps | Medium | High | Prioritize daily habit loops (Today view, morning digest) in v1.0 |
| SwiftData instability on edge-case devices | Medium | Medium | Maintain Core Data migration path as fallback |
| Competitive response from Todoist / Things 3 | Low | Medium | Focus on differentiated UX and iOS-native depth |

---

## 14. Out of Scope

The following items are explicitly **not** included in v1.0:

- Team collaboration, task sharing, or comments
- Web app or Android app
- Natural language input / NLP date parsing
- Calendar view (dedicated)
- Third-party integrations (Slack, Zapier, Notion, Google Calendar)
- Email-to-task creation
- Time tracking
- Kanban board view
- AI-powered task suggestions

---

## 15. Appendix & Glossary

### Glossary

| Term | Definition |
|---|---|
| **Task** | A single unit of work with a title, optional metadata, and a completion state. |
| **Project** | A named collection of tasks, optionally divided into Sections. |
| **Inbox** | The default container for tasks not assigned to a Project. |
| **Section** | A named group within a Project used to organize tasks by stage or category. |
| **Tag** | A free-form label applied to a Task, used for cross-project filtering. |
| **Today View** | A smart view aggregating all tasks due today and overdue tasks. |
| **Pro** | The paid subscription tier of TaskFlow unlocking premium features. |
| **CloudKit** | Apple's cloud backend service used for syncing data across devices. |
| **SwiftData** | Apple's modern data persistence framework (Swift-native Core Data layer). |
| **WidgetKit** | Apple's framework for building Home Screen and Lock Screen widgets. |

### Related Documents
- `epic-task-management.md` — Developer-ready story breakdown for Epic: Task Management ✅
- `wireframes/` — High-fidelity Figma wireframes (link TBD)
- `architecture.md` — Technical architecture document (TBD)
- `design-system.md` — UI component library and design tokens (TBD)
- `user-research.md` — User interview notes and synthesis (TBD)
