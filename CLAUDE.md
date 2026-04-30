# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Dawny is a zero-dependency iOS task app built on Swift 6, SwiftUI, and SwiftData. Its core philosophy: unfinished daily tasks reset automatically at 3 AM instead of becoming overdue — preventing task debt. The app targets iOS 26.2+ and uses only Apple frameworks (no third-party dependencies, by design).

## Build & Test

**Build:** Open `Dawny.xcodeproj` in Xcode 26.2+. No SPM root package or Makefile — build exclusively through Xcode or `xcodebuild`.

**Run tests:**
```bash
xcodebuild test -project Dawny.xcodeproj -scheme Dawny -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Add license headers** (required for new Swift files):
```bash
./scripts/add-license-headers.sh
```

Test files live in `DawnyTests/` and cover reset behavior, sync conflicts, recurring task lifecycle, and archival logic.

## Architecture

### Layers

**Models** (`App/Sources/Models/`) — SwiftData `@Model` types:
- `Task` — core entity with statuses: `inBacklog`, `scheduled`, `dailyFocus`, `completed`, `archived`
- `Backlog`, `Category` — organizational containers
- `AppSettings` — user preferences persisted via UserDefaults (reset hour, sync toggle, "make it count" threshold)

**Services** (`App/Sources/Services/`):
- `ResetEngine` — the core of the app. Runs at the configured reset hour; moves incomplete `dailyFocus` tasks back to backlog; increments `resetCount`; archives tasks that exceed the "make it count" threshold (default: 1 reset). Recurring tasks always reset to backlog and are never archived. Uses a `TimeProvider` protocol for testability.
- `SyncEngine` — bidirectional EventKit (Apple Reminders) sync. Observes `EKEventStoreChanged` notifications (debounced), syncs Daily Focus tasks as reminders, resolves conflicts via last-write-wins timestamp comparison.
- `EventKitCalendarService` — EventKit CRUD wrapper, behind `CalendarServiceProtocol` for mockability.

**ViewModels** (`App/Sources/ViewModels/`) — `@Observable` classes: `DailyFocusViewModel`, `BacklogViewModel`, `ArchiveViewModel`.

**Views** (`App/Sources/Views/`) — SwiftUI. `ContentView` drives a three-tab layout (Backlog / Today / Archive).

**Intents** (`App/Sources/Intents/`) — Siri/Shortcuts via `AppIntents`: `AddTaskIntent`, `AddTaskTodayIntent`.

### Key Patterns

**Recurring task clone pattern:** When a recurring task is completed, a clone is inserted into the backlog. If the user uncompletes it, the clone is deleted and the parent is reopened.

**Dependency injection via Environment:** Services (`ResetEngine`, `SyncEngine`) are injected as environment values, not singletons, enabling test isolation.

**Protocols for testability:** `CalendarServiceProtocol` and `TimeProvider` allow full mock substitution in `DawnyTests/`.

**SwiftData relationships:** Cascade deletes are configured on all relationships. Use computed properties (`needsReset`, `isCompletedToday`, `taskCount`) rather than re-deriving logic in views.

### Data Flow

```
Views → ViewModels → SwiftData ModelContext
                   ↘ Services (ResetEngine, SyncEngine)
                        ↘ EventKit / UserDefaults / BackgroundTasks
```

## Localization

Two active locales: **English (en)** and **German (de)**. All strings live in `App/Sources/Localizable.xcstrings` (modern Xcode format). Use `String(localized:defaultValue:)` — never hardcode user-facing strings.

## Website

`/website/` is an Astro 5 + Tailwind CSS 4 site deployed to IONOS via GitHub Actions (`.github/workflows/deploy-website.yml`). It is fully independent from the iOS app. Deploy triggers on pushes to `main` affecting `website/**`.
