<h1 align="center">Dawny</h1>

<p align="center">
  <strong>A task app that deletes yesterday's tasks. On purpose.</strong><br>
  <a href="https://dawnyapp.com">dawnyapp.com</a>
</p>

<p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/platform-iOS%2026.2%2B-blue">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-6-orange">
  <img alt="UI" src="https://img.shields.io/badge/UI-SwiftUI-0A84FF">
  <img alt="Persistence" src="https://img.shields.io/badge/Data-SwiftData-34C759">
  <img alt="Dependencies" src="https://img.shields.io/badge/dependencies-zero-brightgreen">
  <img alt="Status" src="https://img.shields.io/badge/status-beta-yellow">
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-PolyForm%20Noncommercial%201.0.0-lightgrey"></a>
</p>

<p align="center">
  <a href="https://testflight.apple.com/join/h9JSWasd">
    <img alt="Join the TestFlight Beta" src="https://img.shields.io/badge/TestFlight-Join%20the%20Beta-000000?style=for-the-badge&logo=apple">
  </a>
</p>

<p align="center">
  <img alt="Dawny app icon" src="App/Assets.xcassets/AppIcon.appiconset/Dawny%20Icon%20Gemini%201024x1024%20300dpi.png" width="120">
</p>

---

Dawny is an iOS task app built around a single mechanic: unfinished daily tasks reset instead of going overdue. Every night at 3 AM, anything left in **Daily Focus** either returns to the **Backlog** or moves to the **Archive**, depending on how many times it has slipped. No red dates. No carried-over guilt. A clean slate every morning.

The codebase is Swift 6 with SwiftUI and SwiftData, zero third-party dependencies. Daily Focus tasks optionally sync to Apple Reminders via EventKit: when you add something to your day in Dawny, it appears in Reminders (and Calendar's task list) automatically, and changes made externally sync back. Conflicts are resolved by last-write-wins using modification timestamps, and if a Reminder is deleted outside the app, the task quietly returns to the Backlog rather than disappearing.

---

## Getting Dawny

Install via the [TestFlight beta](https://testflight.apple.com/join/h9JSWasd). Dawny will be available on the App Store soon. Any feedback before the 1.0 release is much appreciated.

---

## Architecture

MVVM + Service-Oriented Architecture. Business logic lives in services injected via SwiftUI's `Environment`; views bind to `@Observable` ViewModels.

| Layer | Key types | Role |
|:---|:---|:---|
| Models | `Task`, `Backlog`, `Category` | SwiftData `@Model` classes; domain state |
| Services | `ResetEngine`, `SyncEngine` | Core business logic; `@MainActor` |
| ViewModels | `DailyFocusViewModel`, `BacklogViewModel`, `ArchiveViewModel` | `@Observable`; bridge models to views |
| Views | `ContentView`, `BacklogView`, `DailyFocusView`, `ArchiveView` | SwiftUI; three-tab layout via custom pager |
| Intents | `AddTaskIntent`, `AddTaskTodayIntent` | Siri / App Shortcuts via `AppIntents` |

Persistence uses three distinct layers: SwiftData for domain models, `UserDefaults` for `AppSettings` preferences, and a dedicated `UserDefaults` key (`DawnyLastResetDate`) as the reset gate.

### ResetEngine

Fires on app launch, every scene phase `.active` transition, and via `BGAppRefreshTask` as a background supplement. On each trigger: computes the most recent `resetHour` threshold (default 3 AM), compares it against `DawnyLastResetDate`, and, if a reset is due, processes all incomplete Daily Focus tasks. Recurring tasks (where `category.isRecurring == true`) always return to Backlog. Non-recurring tasks increment `resetCount`; once it reaches `makeItCountThreshold` (default: 1), the task is archived and `AppSettings.shared.hasNewArchivedTasks` is set to show the Archive badge dot.

### SyncEngine

Bidirectional sync between Daily Focus tasks and Apple Reminders via EventKit. Subscribes to `.EKEventStoreChanged` through an `AsyncStream` wrapper with a 1-second debounce. Conflict resolution: last-write-wins using `Task.modifiedAt` vs. `EKReminder.modificationDate`. If a Reminder is deleted externally, the task is moved back to Backlog.

---

## Key Patterns

**`TimeProvider` protocol:** abstracts `Date()` in `ResetEngine`. `MockTimeProvider` lets tests advance "current time" to trigger reset thresholds deterministically, no `sleep()` required.

**`CalendarServiceProtocol`:** abstracts EventKit in `SyncEngine`. `MockCalendarService` makes sync tests hermetic with no Reminders permission needed.

**DI via Environment:** `ResetEngine` and `SyncEngine` are instantiated at the root in `DawnyApp.swift` and injected as custom `EnvironmentKey`s (`\.resetEngine`, `\.syncEngine`). No global singletons for services.

**Recurring task clone pattern:** completing a recurring task immediately inserts a fresh clone into the Backlog. If the user uncompletes it, the clone is deleted and the original is restored.

**UIKit gesture bridge:** SwiftUI's `DragGesture` and `List` swipe actions compete for the same touch stream. `ContentView` uses a `UIPanGestureRecognizer` via `UIGestureRecognizerRepresentable` (iOS 18+) that only begins when horizontal velocity exceeds vertical by 1.2×, and bails if a `UICollectionViewCell` is found in the touch hierarchy. Any future work on list gestures or navigation transitions must account for this.

**SwiftData predicate workaround:** `TaskStatus` is an enum; SwiftData `#Predicate` does not support enum comparisons. All status-based filtering fetches all tasks and filters in Swift.

---

## Project Structure

```
Dawny/
├── App/Sources/
│   ├── DawnyApp.swift          # Entry point, service wiring, EnvironmentKeys
│   ├── Models/                 # SwiftData @Model types + AppSettings (UserDefaults)
│   ├── Protocols/              # TimeProvider, CalendarServiceProtocol
│   ├── Services/               # ResetEngine, SyncEngine, EventKitCalendarService
│   ├── ViewModels/             # @Observable VMs for each tab
│   ├── Views/                  # SwiftUI views + Components/
│   └── Intents/                # App Intents for Siri
├── DawnyTests/
│   ├── Mocks/                  # MockTimeProvider, MockCalendarService, TestModelContainer
│   ├── Services/               # ResetEngineTests, SyncEngineTests, MakeItCountResetTests
│   ├── ViewModels/             # VM-level unit tests
│   ├── Models/                 # Model unit tests
│   └── Integration/            # PersistenceTests, TaskLifecycleTests
├── website/                    # Astro 5 + Tailwind CSS marketing site (independent)
└── docs/                       # Architecture docs, PRD, QA checklists
```

---


## License

Dawny is **source-available, not open source**.

The source code in this repository is licensed under the [PolyForm Noncommercial License 1.0.0](LICENSE). In short: you may read, study, modify, and use the code for personal, educational, research, hobby, and other noncommercial purposes. You may **not** use the code (in original or modified form) as part of any product or service that generates revenue, including paid apps, ad-supported apps, or apps with in-app purchases.

The name "Dawny", the Dawny logo, and the app icon are **trademarks** of Florian Schneider and are not licensed under PolyForm. Forks must be renamed and rebranded. See [NOTICE](NOTICE) for details on trademarks, asset licensing, and contact info.

For commercial licensing inquiries, write to **info@dawnyapp.com**.
