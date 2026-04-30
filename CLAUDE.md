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

## Further Documentation

The following files exist but are excluded from auto-indexing. Read them explicitly when relevant.

| File | When to read |
|---|---|
| [`docs/AI Input/architecture.md`](docs/AI%20Input/architecture.md) | Detailed technical architecture (V3, April 2026): full SwiftData schema with all fields and constraints, `TaskStatus` state machine diagram, `AppSettings` property table, `ResetEngine` algorithm step-by-step, custom `TabPager` / UIKit gesture bridge, `CategoryService` rules, app launch sequence, known constraints (SwiftData predicate limitations, tombstoned objects, `fatalError` on schema mismatch). Read for any architectural decision, schema question, or work touching `ResetEngine`/`SyncEngine`/`CategoryService`. |
| [`docs/AI Input/AI_INPUT.md`](docs/AI%20Input/AI_INPUT.md) | Complete marketing context document: product identity, full feature inventory, target audiences, competitive positioning, tone & voice guidelines, approved phrases, hard marketing constraints. Read for any App Store copy, marketing, or communication task. |
| [`docs/AI Input/PRD.md`](docs/AI%20Input/PRD.md) | Product Requirements Document: high-level architecture overview, core philosophy, main features, user flows, planned future features. Read to understand product goals or when evaluating scope of new features. |
| [`docs/AI Input/Zielgruppe.md`](docs/AI%20Input/Zielgruppe.md) | Detailed target audience analysis: primary audience, neurodivergence relevance and framing rules, secondary audiences. Read for UX decisions, onboarding copy, or audience-sensitive wording. |
| [`docs/AI Input/Dawny Make it count explanation.md`](<docs/AI Input/Dawny Make it count explanation.md>) | Early product description of the Make It Count mechanic and reset logic with example flows. Supplementary to `architecture.md`. |
| [`docs/AI Input/EINFACHE_ANLEITUNG.md`](docs/AI%20Input/EINFACHE_ANLEITUNG.md) | Quick-start guide for developers: project structure, Xcode setup steps, manual test scenarios, common build issues. Read for onboarding or build setup questions. |
| [`docs/APP_STORE_CONNECT_CHECKLIST.md`](docs/APP_STORE_CONNECT_CHECKLIST.md) | App Store Connect checklist: EULA, Privacy Policy URL, App Privacy Labels, Privacy Manifest, Export Compliance, trademark notes. Read before any TestFlight or App Store submission. |
| [`docs/QA_checklist.md`](docs/QA_checklist.md) | Manual QA release checklist: Siri/App Intents, Reset mechanic, EventKit sync edge cases, SwiftData persistence, UI/Accessibility. Read when preparing a release build. |
| [`docs/PRIVACY.de.md`](docs/PRIVACY.de.md) | German privacy policy (incomplete: postal address still missing). Read before hosting or updating the privacy policy. |
| [`docs/PRIVACY.en.md`](docs/PRIVACY.en.md) | English privacy policy (incomplete: postal address still missing). Read before hosting or updating the privacy policy. |
