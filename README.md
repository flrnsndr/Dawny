<h1 align="center">Dawny</h1>

<p align="center">
  <strong>The iOS task app where overdue tasks don't exist.</strong>
</p>

<p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/platform-iOS%2018%2B-blue">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-6-orange">
  <img alt="UI" src="https://img.shields.io/badge/UI-SwiftUI-0A84FF">
  <img alt="Persistence" src="https://img.shields.io/badge/Data-SwiftData-34C759">
  <a href="https://testflight.apple.com/join/h9JSWasd"><img alt="TestFlight" src="https://img.shields.io/badge/TestFlight-Join%20Beta-000000?logo=apple"></a>
  <img alt="Status" src="https://img.shields.io/badge/status-beta-yellow">
</p>

<p align="center">
  <!-- Drop a hero screenshot or a short GIF here: docs/screenshots/hero.png -->
  <img alt="Dawny hero" src="docs/screenshots/hero.png" width="640">
</p>

Dawny is a minimalist iOS task manager built around a single, opinionated idea: **nothing is ever overdue.** Every night at 3 AM, anything you didn't finish in today's focus list is quietly moved back to your backlog. You wake up to a clean slate and choose — consciously — what today is for.

No due dates. No recurring-task rabbit holes. No guilt-piles from last Tuesday. Just a backlog, a daily focus, and a fresh start every morning.

---

## Why Dawny?

Most task apps punish you. Tasks you didn't finish yesterday turn red and stay red. The list grows. You start ignoring it. Eventually you declare bankruptcy and make a new list.

Dawny takes the opposite stance: **overdue tasks are a design bug, not a feature.**

### The 3 AM Reset

Dawny has two lists: **Backlog** (someday) and **Daily Focus** (today). Each day you pull a handful of tasks from the backlog into focus. At 3 AM — while you're asleep — anything still unchecked in Daily Focus is moved back to the top of the backlog with today's date. Nothing is deleted; nothing is overdue. Tomorrow you get to decide again what today is for.

It's not a productivity hack. It's permission to stop dragging yesterday into today.

### How Dawny differs from general-purpose task apps

| | **Dawny** | Typical to-do apps |
|---|---|---|
| Overdue tasks | Don't exist | Accumulate forever |
| Due dates | Only "today" or unscheduled | Arbitrary dates, times, reminders |
| Lists | One backlog, one daily focus | Unlimited lists and sublists |
| Recurring tasks | No | Yes |
| Subtasks & tags | No | Yes |
| Platforms | iOS only | Cross-platform |
| Philosophy | Opinionated, minimal | Flexible, feature-rich |

---

## Who is this for?

- **The overwhelmed planner** — you've tried Todoist, Things, TickTick, MS To-Do, and each one has become a graveyard of ignored red items.
- **The deliberate minimalist** — you want fewer choices, not more; a tool that enforces intent, not one that rewards complexity.
- **The iOS-native user** — you live in Apple Reminders and Siri and want your task app to feel like it was made by Apple, not bolted on top of it.

### Dawny is probably *not* for you if you need…

- Cross-platform sync (Android, Web, Windows).
- Recurring tasks, subtasks, or tags.
- Multiple projects or nested lists.
- Arbitrary due dates and time-of-day reminders.

That's fine. Dawny is deliberately small. If it doesn't fit, the tools above are excellent.

---

## Features

- **Two-list system** — Backlog for "someday," Daily Focus for today. That's it.
- **3 AM auto-reset** — Unfinished focus tasks return to the top of the backlog overnight, with today's date.
- **Bidirectional iOS Reminders sync** — Daily Focus tasks appear in Apple Reminders via EventKit and sync both ways.
- **Siri shortcuts** — *"Hey Siri, add milk to Dawny today."* Powered by the App Intents framework.
- **Categories** — Lightweight grouping for when you need a touch of structure.
- **Native feel** — SwiftUI, haptic feedback, Dynamic Type, and full localization scaffolding (`Localizable.xcstrings`).
- **Built to be testable** — Time and calendar access are protocol-based so the reset logic can be tested deterministically.

<p align="center">
  <!-- Drop screenshots here: docs/screenshots/backlog.png, daily-focus.png, siri.png -->
  <img alt="Backlog" src="docs/screenshots/backlog.png" width="240">
  <img alt="Daily Focus" src="docs/screenshots/daily-focus.png" width="240">
  <img alt="Siri" src="docs/screenshots/siri.png" width="240">
</p>

---

## Get Dawny

### Join the TestFlight beta

Dawny is currently in public beta on TestFlight:

<p align="center">
  <a href="https://testflight.apple.com/join/h9JSWasd">
    <img alt="Join the TestFlight Beta" src="https://img.shields.io/badge/TestFlight-Join%20the%20Beta-000000?style=for-the-badge&logo=apple">
  </a>
</p>

> Dawny is built by a single developer. Your feedback shapes the app — use the in-app feedback button in TestFlight to tell me what works, what doesn't, and what's missing from your workflow.

Requirements: iPhone running **iOS 18 or later**.

### Or build from source

See [Build from source](#build-from-source) below.

---

## Tech stack

- **Platform** — iOS 18+
- **Language** — Swift 6
- **UI** — SwiftUI
- **Persistence** — SwiftData
- **Calendar integration** — EventKit
- **Voice** — App Intents (Siri)
- **Background execution** — BackgroundTasks framework
- **Testing** — XCTest (unit, integration, UI)

### Architecture

Dawny follows MVVM with `@Observable` view models and protocol-based services for testability.

- **Models** (`App/Sources/Models/`) — `Task`, `Backlog`, `Category`, `TaskStatus`, `AppSettings`.
- **Services** (`App/Sources/Services/`) — `ResetEngine` (3 AM logic), `SyncEngine` (EventKit bridge), `EventKitCalendarService`, `CategoryService`.
- **ViewModels** (`App/Sources/ViewModels/`) — `BacklogViewModel`, `DailyFocusViewModel`.
- **Views** (`App/Sources/Views/`) — `ContentView`, `BacklogView`, `DailyFocusView`, `QuickAddView`, `SettingsView`, `WelcomeView`, `TaskRowView`.
- **Intents** (`App/Sources/Intents/`) — `AddTaskIntent`, `AddTaskTodayIntent`, `DawnyShortcuts`.
- **Protocols** (`App/Sources/Protocols/`) — `TimeProvider`, `CalendarServiceProtocol` — the seams that make reset and sync logic unit-testable.

App wiring lives in [`App/Sources/DawnyApp.swift`](App/Sources/DawnyApp.swift); the reset mechanic is implemented in [`App/Sources/Services/ResetEngine.swift`](App/Sources/Services/ResetEngine.swift).

---

## Project structure

```
Dawny/
├── App/
│   ├── Assets.xcassets/
│   └── Sources/
│       ├── DawnyApp.swift
│       ├── Models/
│       ├── Services/
│       ├── ViewModels/
│       ├── Views/
│       ├── Intents/
│       ├── Protocols/
│       ├── Extensions/
│       └── Utilities/
├── DawnyTests/
├── DawnyUITests/
├── Dawny.xcodeproj
└── docs/
    ├── PRD.md
    └── EINFACHE_ANLEITUNG.md
```

---

## Build from source

**Prerequisites:** macOS with Xcode 16+, an iOS 18+ simulator or device.

```bash
git clone https://github.com/flrnsndr/Dawny.git
cd Dawny
open Dawny.xcodeproj
```

Then in Xcode:

1. Select the **Dawny** scheme and an iOS 18+ simulator (or your device).
2. Press **⌘R** to build and run.

### Capabilities

If you're setting up signing from scratch, the target needs **Background Modes** with *Background fetch* and *Background processing* enabled (used by the 3 AM reset). Grant Reminders and Siri permission on first launch to enable sync and voice shortcuts.

### Running tests

```bash
xcodebuild test \
  -project Dawny.xcodeproj \
  -scheme Dawny \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Need a step-by-step beginner walkthrough? See [`docs/EINFACHE_ANLEITUNG.md`](docs/EINFACHE_ANLEITUNG.md) (German).

---

## Roadmap

Intentionally small for now. Possible future additions — but only if they don't violate the Zero-Overdue Philosophy:

- Home Screen widget
- Apple Watch companion app
- Multiple backlogs (e.g. work / personal)
- Stats and insights ("how often does a task survive to the next day?")
- iCloud sync across iOS devices

Explicitly **not** on the roadmap: recurring tasks, subtasks, tags, arbitrary due dates, cross-platform clients.

---

## Contributing

Contributions are welcome, with one caveat: **the Zero-Overdue Philosophy is non-negotiable.** Features that reintroduce overdue states, arbitrary due dates, or unlimited list nesting are out of scope by design.

Good ways to contribute:

- **Report bugs** via [`.github/ISSUE_TEMPLATE/bug_report.md`](.github/ISSUE_TEMPLATE/bug_report.md).
- **Request features** (that fit the philosophy) via [`.github/ISSUE_TEMPLATE/feature_request.md`](.github/ISSUE_TEMPLATE/feature_request.md).
- **Suggest improvements** via [`.github/ISSUE_TEMPLATE/improvement-request.md`](.github/ISSUE_TEMPLATE/improvement-request.md).
- **Polish the docs** via [`.github/ISSUE_TEMPLATE/docu-task.md`](.github/ISSUE_TEMPLATE/docu-task.md).

Please run the test suite before opening a PR, and keep PRs focused and small.

---

## Documentation

- [`docs/PRD.md`](docs/PRD.md) — full product requirements and architecture (German).
- [`docs/EINFACHE_ANLEITUNG.md`](docs/EINFACHE_ANLEITUNG.md) — beginner setup and smoke-test guide (German).

---

## License

<!-- TODO: Add a LICENSE file (MIT is a common choice for projects of this scope) and update this section. -->

License TBD — a `LICENSE` file will be added shortly. Until then, all rights reserved by the author.

---

<p align="center">
  Built with care by <a href="https://github.com/flrnsndr">@flrnsndr</a>.<br>
  <sub>Every morning is a blank page.</sub>
</p>
