<h1 align="center">Dawny</h1>

<p align="center">
  <strong>Plan each day on its own terms, without yesterday's unfinished noise.</strong>
</p>

<p align="center">
  Platform iOS 18 plus, Swift 6, SwiftUI, SwiftData, Public Beta on TestFlight
</p>

<p align="center">
  <img alt="Dawny logo hero" src="App/Assets.xcassets/AppIcon.appiconset/Dawny%20Icon%20Gemini%201024x1024%20300dpi.png" width="300">
</p>

Dawny is a minimalist iOS task manager built around a single, opinionated idea: **nothing is ever overdue.** If you did not finish something today, that is usually a signal. Your day had different priorities, different constraints, or simply more important work to do.

Every day is different. Every day deserves its own plan. Dawny helps you plan intentionally each morning without clogging your list with stale, unfinished tasks, so your mind stays clear for what truly matters.

## Why Dawny?

Most task apps punish you. Tasks you did not finish yesterday turn red and stay red. The list grows, context changes, and yesterday's leftovers compete with today's real priorities.

Dawny takes the opposite stance: **overdue tasks are a design bug, not a feature.** Unfinished does not automatically mean failed. Often it just means "not the right priority for that day."

### The 3 AM Reset

Dawny has two lists: **Backlog** (someday) and **Daily Focus** (today). Each day you pull a handful of tasks from the backlog into focus. At 3 AM, while you are asleep, anything still unchecked in Daily Focus is moved back to the backlog. Nothing is deleted, but nothing clutters today by default either.

This gives you a true daily reset: plan each day on its own terms, keep old noise out of sight, and stay focused on what counts now.

### How Dawny differs from general purpose task apps

- Overdue tasks: Dawny has none. Typical task apps accumulate them.
- Due dates: Dawny uses today or unscheduled. Typical task apps allow arbitrary dates and times.
- Lists: Dawny keeps one backlog and one daily focus. Typical task apps support many nested lists.
- Features: Dawny intentionally skips recurring tasks, subtasks, and tags.
- Platforms: Dawny is iOS only by design.
- Philosophy: Dawny is opinionated and minimal. Typical task apps are flexible and feature rich.

## Who is this for?

- **The overwhelmed planner** who has tried several task apps and ended up with old red items from days that no longer matter.
- **The deliberate minimalist** who wants fewer choices and a tool that supports today's priorities.
- **The iOS native user** who lives in Apple Reminders and Siri and wants a truly native experience.

### Dawny is probably *not* for you if you need…

- Cross platform sync across Android, Web, and Windows.
- Recurring tasks, subtasks, or tags.
- Multiple projects or nested lists.
- Arbitrary due dates and specific time reminders.

That's fine. Dawny is deliberately small. If it doesn't fit, the tools above are excellent.

## Features

- **Two list system** keeps Backlog for someday and Daily Focus for today.
- **3 AM reset** returns unfinished focus tasks to Backlog overnight, creating space for a fresh morning plan.
- **Bidirectional iOS Reminders sync** shows Daily Focus tasks in Apple Reminders and syncs changes both ways.
- **Siri shortcuts** support voice input such as "Hey Siri, add milk to Dawny today."
- **Categories** provide lightweight grouping when needed.
- **Native feel** comes from SwiftUI, haptic feedback, Dynamic Type, and localization scaffolding in `Localizable.xcstrings`.
- **Built for tests** through protocol based time and calendar access, so daily reset behavior can be validated deterministically.

<p align="center">
  <img alt="Backlog" src="docs/screenshots/backlog.png" width="240">
  <img alt="Daily Focus" src="docs/screenshots/dailyfocus.png" width="240">
  <img alt="Siri" src="docs/screenshots/siri.png" width="240">
</p>

## Get Dawny

### Join the TestFlight beta

Dawny is currently in public beta on TestFlight:

<p align="center">
  <a href="https://testflight.apple.com/join/h9JSWasd">
    Join the TestFlight Beta
  </a>
</p>

> Dawny is built by a single developer. Your feedback shapes the app. Use the in app feedback button in TestFlight to tell me what works, what does not, and what is missing from your workflow.

Requirements: iPhone running **iOS 18 or later**.

If a task was not done today, that can be useful information, not failure. Dawny is designed around that mindset.

### Or build from source

See the section "Build from source" below.

## Tech stack

- **Platform** iOS 18 plus
- **Language** Swift 6
- **UI** SwiftUI
- **Persistence** SwiftData
- **Calendar integration** EventKit
- **Voice** App Intents with Siri
- **Background execution** BackgroundTasks framework
- **Testing** XCTest with unit, integration, and UI tests

### Architecture

Dawny follows MVVM with `@Observable` view models and protocol based services for testability.

- **Models** in `App/Sources/Models/`: `Task`, `Backlog`, `Category`, `TaskStatus`, `AppSettings`
- **Services** in `App/Sources/Services/`: `ResetEngine`, `SyncEngine`, `EventKitCalendarService`, `CategoryService`
- **ViewModels** in `App/Sources/ViewModels/`: `BacklogViewModel`, `DailyFocusViewModel`
- **Views** in `App/Sources/Views/`: `ContentView`, `BacklogView`, `DailyFocusView`, `QuickAddView`, `SettingsView`, `WelcomeView`, `TaskRowView`
- **Intents** in `App/Sources/Intents/`: `AddTaskIntent`, `AddTaskTodayIntent`, `DawnyShortcuts`
- **Protocols** in `App/Sources/Protocols/`: `TimeProvider`, `CalendarServiceProtocol`, these abstractions make reset and sync logic testable

App wiring lives in [`App/Sources/DawnyApp.swift`](App/Sources/DawnyApp.swift); the reset mechanic is implemented in [`App/Sources/Services/ResetEngine.swift`](App/Sources/Services/ResetEngine.swift).

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

Run the unit tests and UI tests from Xcode using the Test navigator.

Need a step by step beginner walkthrough? See [`docs/EINFACHE_ANLEITUNG.md`](docs/EINFACHE_ANLEITUNG.md) (German).

## Roadmap

Intentionally small for now. Possible future additions are welcome only if they do not violate the Zero Overdue Philosophy.

- Home Screen widget
- Apple Watch companion app
- Multiple backlogs (e.g. work / personal)
- Stats and insights ("how often does a task survive to the next day?")
- iCloud sync across iOS devices

Explicitly **not** on the roadmap: recurring tasks, subtasks, tags, arbitrary due dates, and cross platform clients. The goal is a clear mind and a clean daily planning surface, not a bigger feature set.

## Contributing

Contributions are welcome, with one caveat: **the Zero Overdue Philosophy is fixed.** Features that reintroduce overdue states, arbitrary due dates, or unlimited list nesting are out of scope by design.

Good ways to contribute:

- **Report bugs** using the templates in [`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/).
- **Request features** that fit the philosophy using [`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/).
- **Suggest improvements** using [`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/).
- **Polish the docs** using [`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/).

Please run the test suite before opening a PR, and keep PRs focused and small.

## Documentation

- [`docs/PRD.md`](docs/PRD.md) full product requirements and architecture (German)
- [`docs/EINFACHE_ANLEITUNG.md`](docs/EINFACHE_ANLEITUNG.md) beginner setup and smoke test guide (German)

## License

License TBD. A `LICENSE` file will be added shortly. Until then, all rights reserved by the author.

<p align="center">
  Built with care by <a href="https://github.com/flrnsndr">@flrnsndr</a>.<br>
  <sub>Every morning is a blank page.</sub>
</p>
