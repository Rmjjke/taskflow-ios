# TaskFlow iOS

> A native iOS task and project management app — fast, frictionless, and built the Apple way.

[![CI](https://github.com/Rmjjke/taskflow-ios/actions/workflows/ci.yml/badge.svg)](https://github.com/Rmjjke/taskflow-ios/actions/workflows/ci.yml)
![Swift 6](https://img.shields.io/badge/Swift-6.0-orange.svg)
![iOS 17+](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)

---

## Overview

TaskFlow captures, organises, and helps you complete work without switching apps.
Built with **Swift 6**, **SwiftUI**, and **SwiftData** — 100% native, 100% Apple stack.

| Milestone | Target | Status |
|---|---|---|
| **M0 — Discovery & Design** | 2026-04-30 | 🟡 In Progress |
| **M1 — MVP (Internal)** | 2026-05-30 | ⬜ Not Started |
| **M1.5 — MVP TestFlight** | 2026-06-10 | ⬜ Not Started |
| **M2 — Alpha v1.0** | 2026-07-15 | ⬜ Not Started |
| **M3 — Beta** | 2026-08-15 | ⬜ Not Started |
| **M4 — Release Candidate** | 2026-09-01 | ⬜ Not Started |
| **M5 — App Store Launch** | 2026-09-22 | ⬜ Not Started |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 6 (strict concurrency) |
| UI | SwiftUI |
| Data | SwiftData (local — MVP) |
| Sync | CloudKit / iCloud (v1.0) |
| Architecture | MVVM · `TaskRepository` as single source of truth |
| Min iOS | iOS 17.0 |
| CI/CD | GitHub Actions + Xcode Cloud |
| Testing | XCTest (unit) + XCUITest (UI) |
| Linting | SwiftLint |
| Project gen | XcodeGen |

---

## Project Structure

```
TaskFlow/
├── App/                        # Entry point, root ContentView
├── Domain/
│   ├── Models/                 # TaskItem (SwiftData), Priority enum
│   └── Repositories/           # TaskRepositoryProtocol + TaskRepository
├── Presentation/
│   ├── Inbox/                  # InboxView + InboxViewModel
│   ├── QuickAdd/               # QuickAddView + QuickAddViewModel
│   ├── TaskDetail/             # TaskDetailView + TaskDetailViewModel
│   ├── Trash/                  # TrashView + TrashViewModel
│   └── Settings/               # SettingsView
└── Common/
    ├── Components/             # CheckboxView, TaskRowView, ToastView
    ├── Extensions/             # Date+Formatting, Color+App
    └── Haptics/                # HapticManager

TaskFlowTests/
├── Domain/                     # TaskRepositoryTests
└── Presentation/               # InboxViewModelTests

TaskFlowUITests/
└── InboxUITests                # End-to-end Inbox loop tests
```

---

## Architecture

TaskFlow follows **MVVM** with a unidirectional data flow:

```
View  ──(actions)──►  ViewModel  ──(reads/writes)──►  TaskRepository
 ▲                         │                                  │
 └──────(state/bindings)───┘                          SwiftData ModelContext
```

- **`TaskRepository`** is the single source of truth. ViewModels never touch `ModelContext` directly.
- **`TaskRepositoryProtocol`** enables dependency injection — tests use `PreviewTaskRepository` (in-memory mock).
- **`@Observable`** ViewModels keep re-renders minimal.
- **`SwiftData`** handles all local persistence. CloudKit sync is added in v1.0 without changing the `TaskRepository` API.

---

## Getting Started

### Prerequisites

| Tool | Install |
|---|---|
| Xcode 15.4+ | [Mac App Store](https://apps.apple.com/app/xcode/id497799835) |
| XcodeGen | `brew install xcodegen` |
| SwiftLint | `brew install swiftlint` |

### Setup

```bash
git clone https://github.com/Rmjjke/taskflow-ios.git
cd taskflow-ios
xcodegen generate
open TaskFlow.xcodeproj
```

Select the **TaskFlow** scheme, choose an iPhone 17 simulator, and hit **⌘R**.

---

## Branching Strategy

| Branch | Purpose |
|---|---|
| `main` | Production-ready code. Protected — PRs only. |
| `develop` | Integration branch for active development. |
| `feature/US-XX-description` | Individual story branches cut from `develop`. |
| `fix/short-description` | Bug fix branches. |
| `release/vX.X` | Release stabilisation branches. |

```
main
 └── develop
       └── feature/US-01-quick-capture
       └── feature/US-02-due-date
       └── fix/inbox-empty-state-crash
```

---

## MVP Scope (M1 — 2026-05-30)

The MVP ships the **core task loop**: capture → view → complete → delete.

| Story | Description | Points |
|---|---|---|
| US-01 | Quick Task Capture | 5 |
| US-02 | Set Due Date & Time | 3 |
| US-03 | Complete a Task | 3 |
| US-04 | Delete a Task (Trash) | 2 |
| **Total** | | **13** |

Full requirements: [`docs/prd-taskflow.md`](docs/prd-taskflow.md)
Developer stories: [`docs/epic-task-management.md`](docs/epic-task-management.md)

---

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the development workflow, coding standards, and PR checklist.

---

## License

[MIT](LICENSE) © 2026 TaskFlow
