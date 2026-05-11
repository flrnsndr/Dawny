# **Dawny - iOS Architecture Overview & Code Analysis V3**

> _V3: Factual corrections and significant additions over V2. Verified against source as of April 2026._

---

## **1. High-Level Architecture**

Dawny follows a structured **MVVM (Model-View-ViewModel)** pattern combined with a Service-Oriented Architecture (SOA) for core business logic. The application is built natively for iOS using **SwiftUI** and relies on **SwiftData** for domain-model persistence. A separate singleton (`AppSettings`) handles user preferences via `UserDefaults`, and `EventKit` provides a third external data surface through the Reminders sync.

---

## **2. Project Structure**

```
Dawny/
├── App/Sources/
│   ├── DawnyApp.swift              # App entry point, service wiring, EnvironmentKeys
│   ├── PreviewSupport.swift        # Xcode Preview helpers
│   ├── Extensions/
│   │   └── HapticFeedback.swift
│   ├── Intents/                    # Siri / App Intents integration
│   │   ├── AddTaskIntent.swift
│   │   ├── AddTaskTodayIntent.swift
│   │   └── DawnyShortcuts.swift
│   ├── Models/                     # SwiftData @Model classes + supporting types
│   │   ├── AppSettings.swift       # UserDefaults-backed @Observable singleton
│   │   ├── Backlog.swift
│   │   ├── BacklogTaskTransfer.swift
│   │   ├── Category.swift
│   │   ├── Task.swift
│   │   ├── TaskCategory.swift      # Enum for built-in category types
│   │   └── TaskStatus.swift        # Enum for task lifecycle states
│   ├── Protocols/
│   │   ├── CalendarServiceProtocol.swift
│   │   └── TimeProvider.swift
│   ├── Services/
│   │   ├── CategoryService.swift
│   │   ├── EventKitCalendarService.swift
│   │   ├── ResetEngine.swift
│   │   └── SyncEngine.swift
│   ├── Utilities/
│   │   ├── SelectTodayTabEnvironment.swift
│   │   └── TriggerWelcomeFlowEnvironment.swift
│   ├── ViewModels/
│   │   ├── ArchiveViewModel.swift
│   │   ├── BacklogViewModel.swift
│   │   └── DailyFocusViewModel.swift
│   └── Views/
│       ├── ArchiveView.swift
│       ├── BacklogView.swift
│       ├── ContentView.swift       # Root view + TabPager + UIKit gesture bridge
│       ├── DailyFocusView.swift
│       ├── QuickAddView.swift
│       ├── SettingsView.swift
│       ├── TaskRowView.swift
│       ├── WelcomeView.swift
│       └── Components/
│           ├── AddCategoryRow.swift
│           ├── CategoryHeaderView.swift
│           ├── CategorySelectionMenu.swift
│           ├── CategorySymbolPicker.swift
│           ├── EmptyStateView.swift
│           ├── ErrorBannerView.swift
│           ├── QuickEntryRow.swift
│           └── SyncStatusIndicator.swift
└── DawnyTests/
    ├── Integration/
    │   ├── PersistenceTests.swift
    │   └── TaskLifecycleTests.swift
    ├── Mocks/
    │   ├── MockCalendarService.swift
    │   ├── MockTimeProvider.swift
    │   └── TestModelContainer.swift
    ├── Models/
    ├── Services/
    │   ├── MakeItCountResetTests.swift
    │   ├── ResetEngineTests.swift
    │   └── SyncEngineTests.swift
    └── ViewModels/
```

---

## **3. Dependency Injection & State Management**

The application leverages SwiftUI's environment for Dependency Injection (DI). This provides a lightweight, native approach without the need for third-party DI containers.

- **Service Initialization:** Core services (`SystemTimeProvider`, `EventKitCalendarService`, `ResetEngine`, `SyncEngine`) are instantiated at the root level in `DawnyApp.swift`.
- **Environment Injection:** Services are injected into the SwiftUI hierarchy using custom `EnvironmentKey`s (`\.resetEngine`, `\.syncEngine`) defined at the bottom of `DawnyApp.swift`.
- **Settings Singleton:** `AppSettings.shared` is accessed directly throughout the codebase — in services, ViewModels, and Views — rather than being injected via Environment. It is an `@Observable` class, so SwiftUI views that read its properties re-render automatically.
- **ViewModel Lifecycle:** ViewModels (`BacklogViewModel`, `DailyFocusViewModel`, `ArchiveViewModel`) are `@State` optional properties on `ContentView`, initialized lazily in `initializeViewModels()` which is called from `.onAppear`. Because they are `@State`, they survive view re-renders. The pattern is safe for the current architecture since `ContentView` is the permanent root view, but if `ContentView` were ever to disappear and reappear (e.g., due to a deep scene reconstruction), ViewModels would be re-created. Moving initialization to a stable coordinator above `ContentView` would be more robust.

---

## **4. Data Persistence & Schema**

The app uses **three distinct persistence mechanisms**:

| Layer | Technology | Scope |
| :---- | :--------- | :---- |
| Domain models | SwiftData (`ModelContainer`) | Tasks, Backlogs, Categories |
| User preferences | `UserDefaults` via `AppSettings` | Settings, reset hour, badge state, etc. |
| Last-reset timestamp | `UserDefaults` directly (key `DawnyLastResetDate`) | Reset gate for ResetEngine |

### **SwiftData Schema**

The schema is registered in `DawnyApp.init()` with `isStoredInMemoryOnly: false`.

#### **Task**

| Attribute | Type | Notes |
| :-------- | :--- | :---- |
| `id` | `UUID` | Primary key |
| `title` | `String` | |
| `notes` | `String?` | Optional. Synced to/from Reminders via SyncEngine. Currently not surfaced in UI. |
| `status` | `TaskStatus` | Core lifecycle state — see §5 |
| `parentBacklogID` | `UUID` | Denormalized FK; all tasks carry this regardless of status |
| `scheduledDate` | `Date?` | Set when status is `.dailyFocus` or `.scheduled` |
| `externalReminderID` | `String?` | EKReminder identifier when synced |
| `sortPriority` | `Date` | Controls display order; newer = higher. Set to `Date()` on reset to surface tasks at the top of Backlog. |
| `createdAt` | `Date` | Immutable after creation |
| `modifiedAt` | `Date` | Updated on every mutation; used for Last-Write-Wins conflict resolution in SyncEngine |
| `isCompleted` | `Bool` | |
| `recurringCloneID` | `UUID?` | Links a recurring task to the fresh Backlog clone created when it is completed in Daily Focus |
| `resetCount` | `Int` | Incremented each time the task is in Daily Focus and not completed at reset. Reset to 0 on manual move-to-backlog and on unarchive. |
| `archivedAt` | `Date?` | Timestamp set by `archive()`; nil when not archived |

**Relationships:**
- `backlog: Backlog?` — inverse of `Backlog.tasks` (nullify on Backlog delete)
- `category: Category?` — inverse of `Category.tasks` (nullify on Category delete)

**Key computed properties (not stored, cannot be used in SwiftData `#Predicate`):**
- `isRecurring: Bool` — derived from `category?.isRecurring == true`. **Not a stored column.** Filtering by this in a predicate will not compile.
- `needsReset: Bool` — `status == .dailyFocus && !isCompleted`
- `isCompletedToday: Bool` — checks if `scheduledDate` is today

#### **Backlog**

| Attribute | Type | Notes |
| :-------- | :--- | :---- |
| `id` | `UUID` | |
| `title` | `String` | |
| `orderIndex` | `Int` | Prepared for future multi-backlog support; currently a single default Backlog is used |
| `createdAt` | `Date` | |

**Relationship:** `tasks: [Task]` with `deleteRule: .cascade` — deleting a Backlog deletes all its Tasks.

> **Important:** `Backlog` is an organizational namespace for the task list, not a filter for task state. Every `Task`, regardless of whether it is in Backlog, Daily Focus, or Archive, maintains a `parentBacklogID` pointing to its Backlog. The current app uses a single default Backlog instance for all tasks.

#### **Category**

| Attribute | Type | Notes |
| :-------- | :--- | :---- |
| `id` | `UUID` | |
| `categoryType` | `TaskCategory` | Enum: `.quick`, `.nextFewDays`, `.nextFewWeeks`, `.nextFewMonths`, `.someday`, `.uncategorized`, `.custom` |
| `name` | `String` | Display name; may be dynamically re-localized (see `isNameCustomized`) |
| `iconName` | `String` | SF Symbol name |
| `orderIndex` | `Int` | User-configurable sort order |
| `isUncategorized` | `Bool` | Marks the protected "Uncategorized" catch-all; prevents rename, icon change, delete |
| `isRecurring` | `Bool` | Stored. When `true`, tasks in this category are exempt from Make It Count archiving and return to Backlog at reset. **This is the source of truth for `Task.isRecurring`.** |
| `isNameCustomized` | `Bool` | When `false`, UI renders the localized string from `categoryType.displayName` rather than the stored name, so language switches propagate correctly |
| `isIconCustomized` | `Bool` | Same pattern as `isNameCustomized` |
| `createdAt` | `Date` | |

**Relationship:** `tasks: [Task]` with `deleteRule: .nullify`, inverse `\Task.category`.

**Protection rules enforced by `CategoryService`:**
- The `Uncategorized` category cannot be renamed, re-iconned, deleted, or toggled.
- The `.quick` category type cannot be deleted.
- User-deletable categories offer two strategies: `.deleteTasks` or `.moveToUncategorized`.

---

## **5. TaskStatus — Core Lifecycle State Machine**

`TaskStatus` is the central enum that all services, ViewModels, and Views reason about. It is `String`-coded and stored in SwiftData.

```
             ┌──────────────────────────────────────────┐
             │                                          │
  create ──► inBacklog ──► dailyFocus ──► completed     │
                │  ▲           │                        │
                │  │ (manual   │ (reset, not            │
                │  │  move-    │  completed,            │
                │  │  back)    │  threshold not         │
                │  │           │  reached)              │
                │  └───────────┘                        │
                │                                       │
                │           (reset, threshold reached)  │
                └──────────────────► archived ──────────┘
                                        │
                         unarchive ─────┘
                      (to backlog or dailyFocus)
             ┌──────────────────────────────┐
             │                              │
  scheduled ◄─── dailyFocus (via SyncEngine date change in Reminders)
```

| Status | Description |
| :----- | :---------- |
| `.inBacklog` | Default state. Task is in the Backlog, waiting to be committed to a day. |
| `.scheduled` | Task has been rescheduled to a future date, typically via a date change made in Apple Reminders that the SyncEngine picks up. Not surfaced as a dedicated UI tab. |
| `.dailyFocus` | Task is committed to Today. Only this status triggers EventKit sync (`shouldSyncToCalendar == true`). |
| `.completed` | Task was checked off. Not subject to Make It Count archiving. |
| `.archived` | Task was moved here by ResetEngine after `resetCount` reached `makeItCountThreshold`. Recoverable via ArchiveView. |

**SwiftData predicate limitation:** Because `TaskStatus` is an enum, SwiftData `#Predicate` cannot filter on it directly. All status-based filtering throughout the codebase is done by fetching all tasks and filtering in Swift.

---

## **6. AppSettings — Third Persistence Layer**

`AppSettings` is an `@Observable` singleton (`AppSettings.shared`) backed entirely by `UserDefaults`. It is the configuration surface for the entire app and must not be confused with the SwiftData layer.

| Property | Default | Purpose |
| :------- | :------ | :------ |
| `resetHour` | `3` | Hour (0–23) at which the daily reset fires |
| `makeItCountThreshold` | `1` | Missed-reset count before a task is archived (user-configurable 1–7) |
| `calendarSyncEnabled` | `true` | Guards all SyncEngine operations |
| `showCompletedTasksInToday` | `true` | UI toggle for completed tasks in Daily Focus view |
| `showCategories` | `true` | UI toggle for category grouping in Backlog |
| `hasSeenWelcome` | `false` | First-launch onboarding gate |
| `hasNewArchivedTasks` | `false` | Drives the orange dot badge on the Archive tab button; set to `true` by ResetEngine when any task is archived; cleared when the user opens the Archive tab |
| `defaultCategoryType` | `.quick` | Default category for new tasks (JSON-encoded `TaskCategory` raw value) |

`AppSettings` is not injected via Environment. Services and ViewModels access `AppSettings.shared` directly.

---

## **7. Concurrency & Synchronization**

The app uses modern **Swift Concurrency (async/await)**. Because SwiftData contexts are thread-bound, both `ResetEngine` and `SyncEngine` are annotated `@MainActor`, ensuring all model mutations happen on the main thread.

- **SyncEngine:** Handles bidirectional synchronization between Dawny and Apple Reminders via EventKit. It subscribes to `.EKEventStoreChanged` using a Swift `AsyncStream` wrapper, with a 1-second debounce to avoid thrashing. Only tasks with status `.dailyFocus` are synced.
- **Conflict Resolution:** Implements a _Last-Write-Wins_ strategy based on `modifiedAt` timestamps. If a Reminder's `modificationDate` is newer than the task's `modifiedAt`, the Reminder wins. Resolved fields: completion status, title, notes, due date. If a Reminder is deleted in the Reminders app, the task is moved back to Backlog.
- **`calendarSyncEnabled` guard:** Every SyncEngine operation checks `AppSettings.shared.calendarSyncEnabled` before touching EventKit.
- **`EventKitCalendarService`:** A concrete implementation of `CalendarServiceProtocol`, allowing the SyncEngine to be fully mocked in tests.
- _Architectural note:_ Running all database mutations and EventKit fetching on `@MainActor` ensures thread safety but risks frame drops during heavy sync loads. Moving background sync to a private `ModelActor` would reduce main-thread contention.

---

## **8. Core Business Logic: ResetEngine & "Make It Count"**

The **ResetEngine** enforces Dawny's "Zero-Overdue" philosophy. It is `@MainActor`.

### Trigger points

| Trigger | Code path |
| :------ | :-------- |
| App cold launch | `performAppLaunchTasks()` → `resetEngine.checkAndPerformResetIfNeeded()` |
| App becomes active (scene phase) | `handleScenePhaseChange()` → `checkAndPerformResetIfNeeded()` |
| iOS background refresh | `BGAppRefreshTaskRequest` with identifier `Flo.Dawny.reset`, scheduled for `resetHour + 5 min` of the next day. Skipped on Simulator. |

### Reset gate

The last successful reset timestamp is persisted in `UserDefaults` under key `DawnyLastResetDate`. On each trigger, `checkAndPerformResetIfNeeded()` computes the most recent threshold (today at `resetHour`, or yesterday's if current time is before `resetHour`) and compares it to the stored timestamp. If the stored timestamp is earlier, a reset is performed.

### Reset algorithm (`performReset`)

1. Fetch all tasks where `status == .dailyFocus && !isCompleted`.
2. For each task, first remove it from Apple Reminders if `isSyncedToCalendar`.
3. If `task.isRecurring` (i.e., its category has `isRecurring == true`): call `resetToBacklog()`. Set `sortPriority` to a slightly staggered offset from the reference date so order is stable.
4. Otherwise: increment `task.resetCount`. If `resetCount >= AppSettings.shared.makeItCountThreshold`: call `task.archive()` and set `AppSettings.shared.hasNewArchivedTasks = true`. If below threshold: call `resetToBacklog()`.
5. Save `ModelContext`.
6. Persist the reset timestamp to `UserDefaults`.

### "Make It Count" mechanic

- `resetCount` tracks how many times a non-recurring task was in Daily Focus and not completed at reset.
- `resetCount` is **not** reset by the automatic nightly reset — only by manual move-to-backlog and by unarchiving.
- Restoring a task from Archive (to Backlog or directly to Daily Focus) calls `unarchiveToBacklog()` or `unarchiveToDailyFocus(date:)`, both of which set `resetCount = 0`.
- `AppSettings.shared.hasNewArchivedTasks = true` is the signal from ResetEngine to the UI to show the orange badge dot on the Archive tab button.

---

## **9. Navigation Architecture**

Dawny does **not** use a standard `TabView` or bottom tab bar. The navigation model is:

- **Top bar (custom):** Left = Settings gear (opens a sheet), Center = Backlog/Today segmented control, Right = Archive icon button (with optional orange dot badge).
- **Pager:** Horizontal swipe between three full-screen pages (Backlog, Today, Archive) implemented as a custom `TabPager` in `ContentView.swift`.

### Custom `TabPager` and UIKit gesture bridge

SwiftUI's native `DragGesture` cannot coexist with the `swipeActions` of `List` rows because both compete for the same touch stream and SwiftUI has no gesture priority mechanism between them. To solve this, `ContentView` implements a custom `UIPanGestureRecognizer` via `UIGestureRecognizerRepresentable` (iOS 18+) with a `UIGestureRecognizerDelegate`:

- `gestureRecognizerShouldBegin` only allows the pager gesture to start when horizontal velocity exceeds vertical velocity by a 1.2× factor — vertical list scrolling is unaffected.
- `gestureRecognizer(_:shouldReceive:)` walks up the touch's view hierarchy and returns `false` if a `UICollectionViewCell` or `UITableViewCell` is found — this prevents the pager from stealing touches that belong to list row swipe actions.

This is the same technique Apple uses in the Reminders app for its `interactivePopGestureRecognizer`. Any future work touching list gestures or navigation transitions must account for this bridge.

### Environment-based navigation callbacks

Two custom `EnvironmentKey`s — `\.triggerWelcomeFlow` and `\.selectTodayTab` — allow deeply nested views to trigger navigation at the `ContentView` level without direct coupling. These are defined in `Utilities/`.

### Initial tab selection

On first `onAppear`, `ContentView` checks whether any task has `status == .dailyFocus` and switches to the Today tab if so. This fetch is done in-memory (all tasks fetched, then filtered) because SwiftData predicates do not support enum comparisons.

---

## **10. App Intents / Siri Integration**

Dawny registers two `AppIntent`s for Siri and Shortcuts:

- `AddTaskIntent` — "Hey Siri, add [task] to Dawny" → creates task with `status = .inBacklog`
- `AddTaskTodayIntent` — "Hey Siri, add [task] to Dawny today" → creates task with `status = .dailyFocus`

`DawnyShortcuts` registers these via `AppShortcutsProvider` and `DawnyApp.init()` calls `DawnyShortcuts.updateAppShortcutParameters()`.

Intents run in a separate process context from the main app. They write directly to the shared `ModelContainer` (same store file). ViewModels are not involved — the Intent creates the task directly in the model context. This is an important seam: any invariants that ViewModels normally enforce (e.g., syncing a new Daily Focus task to Reminders) are bypassed by the Intent path.

---

## **11. CategoryService**

`CategoryService` is a plain `final class` (not `@MainActor`, not a service registered in Environment — it is instantiated on demand by the callers that need it, including `DawnyApp`'s launch sequence).

Responsibilities:
- **Default category seeding** (`initializeDefaultCategories()`): On first launch (when no Category records exist), inserts the full set of built-in categories: `.quick`, `.nextFewDays`, `.nextFewWeeks`, `.nextFewMonths`, `.someday`, `.uncategorized`. Also ensures a default "Recurring Tasks" category (`isRecurring = true`, `categoryType = .custom`) exists. This method is **idempotent** and runs on every launch.
- **Schema migrations** (executed via `UserDefaults`-gated flags on each launch): repositions the default recurring category to appear before `Someday` in the list order. These are one-shot, write-once-to-UserDefaults guards.
- **CRUD operations** on categories: `createCustom`, `rename`, `updateIcon`, `delete` (with `.deleteTasks` or `.moveToUncategorized` strategy), `setRecurring`.
- **Validation:** Name length capped at 40 characters. Protected categories throw `CategoryEditError` on disallowed operations.

> `initializeDefaultCategories()` is called **after** `ResetEngine.checkAndPerformResetIfNeeded()` in the app launch sequence. On a completely fresh install, the reset check fires first with zero categories in the database. The reset finds no Daily Focus tasks (there are none yet), so this ordering is safe.

---

## **12. BacklogTaskTransfer**

`BacklogTaskTransfer` is a lightweight `Codable, Transferable` struct used for **Drag & Drop** within the Backlog list. SwiftData `@Model` objects are not directly `Transferable` (they are context-bound), so drag sources encode only the `taskID: UUID` into this struct. Drop targets fetch the full task from the model context using that ID.

```swift
struct BacklogTaskTransfer: Codable, Hashable, Transferable {
    let taskID: UUID
}
```

This struct is app-internal only (uses `CodableRepresentation(contentType: .data)`, no custom UTI registered in `Info.plist`).

---

## **13. Test Infrastructure**

The test suite (`DawnyTests/`) is structured by layer:

| Directory | Contents |
| :-------- | :-------- |
| `Mocks/` | `MockCalendarService` (implements `CalendarServiceProtocol`), `MockTimeProvider` (implements `TimeProvider`), `TestModelContainer` (in-memory `ModelContainer` for isolation) |
| `Services/` | `ResetEngineTests`, `SyncEngineTests`, `MakeItCountResetTests` |
| `ViewModels/` | `BacklogViewModelPlacementTests`, `DailyFocusRecurringTests`, `MakeItCountDailyFocusTests`, `ArchiveViewModelTests` |
| `Models/` | `TaskModelTests`, `BacklogModelTests`, `AppSettingsTests` |
| `Integration/` | `PersistenceTests`, `TaskLifecycleTests` |
| `Views/` | `TabSelectionLogicTests` |

**Testability design:**
- `TimeProvider` protocol abstracts `Date()` — `MockTimeProvider` lets tests control "current time" to simulate reset thresholds crossing without sleeping.
- `CalendarServiceProtocol` abstracts EventKit — `MockCalendarService` lets reset and sync tests run without Reminders permission.
- `TestModelContainer` creates an `isStoredInMemoryOnly: true` container so each test is isolated and leaves no on-disk state.

---

## **14. App Launch Sequence**

`DawnyApp.init()` wires services synchronously; `performAppLaunchTasks()` is called once from `.task { }` on `ContentView`:

1. Request EventKit Reminders permission (async — result is advisory only; the app continues regardless)
2. `resetEngine.checkAndPerformResetIfNeeded()` — the reset gate fires before UI is interactive
3. `syncEngine.startObserving()` — starts the `.EKEventStoreChanged` listener and performs an initial sync
4. `resetEngine.registerBackgroundTask()` — submits the next `BGAppRefreshTaskRequest` to `BGTaskScheduler`
5. `CategoryService.initializeDefaultCategories()` — seeds default categories if absent, runs schema-migration repositioning

On every transition to `.active` scene phase, step 2 fires again. On every transition to `.background`, step 4 fires again.

---

## **15. Known Constraints & Operational Notes**

- **`fatalError` on ModelContainer init:** If SwiftData cannot open the store file (e.g., due to schema incompatibility after an update that lacks a migration), the app hard-crashes on launch. There is no recovery path.
- **`#Predicate` limitation:** SwiftData `#Predicate` does not support enum comparisons or computed properties. All status-based and `isRecurring`-based filtering is performed in Swift after a full fetch. This is a known SwiftData limitation and is documented with comments in the codebase.
- **SwiftData "tombstoned" objects:** When tasks are mass-deleted, SwiftData can retain stale references in `@Relationship` arrays until the next `save()`. `Backlog.liveTasks` and `Category.liveTasks` guard against this with an `!$0.isDeleted` filter. In DEBUG builds, `ContentView` uses a `listContentRemount` integer as a `.id()` modifier to force full list remount after mass deletion, avoiding crashes from rendering a deallocated SwiftData object.
- **Background task timing:** `BGAppRefreshTaskRequest` is scheduled for `resetHour + 5 minutes` of the next calendar day. iOS controls whether and when the task actually executes — it is best-effort. The in-foreground scene-phase trigger is the reliable path; the background task is a best-effort supplemental path.
- **Background task skipped on Simulator:** All `BGTaskScheduler` registration and scheduling is wrapped in `#if !targetEnvironment(simulator)` to avoid simulator-side scheduling errors.
- **Circular service reference:** `ResetEngine` holds a `weak var syncEngine: SyncEngine?` assigned after both are constructed in `DawnyApp.init()`. This is a post-init property assignment, not a constructor dependency. The reference is weak to avoid a retain cycle.
- **`notes` field:** `Task` has a `notes: String?` field that is synced to/from Apple Reminders via SyncEngine but is not currently exposed in the app's UI. It exists primarily as a round-trip storage field for notes set in Apple Reminders.
- **Localization:** The app is fully localized EN/DE. All user-visible strings use `String(localized:defaultValue:)`. Category display names support dynamic re-localization: as long as `Category.isNameCustomized == false`, the UI derives the display string from `categoryType.displayName` at render time rather than reading the stored `name`. This means a user who hasn't customized a category name will see it update if the device language changes.
- **`AppIntents` bypass:** Siri intents create tasks directly in the model context, bypassing ViewModels. Any logic that ViewModels perform on task creation (e.g., triggering an immediate Reminders sync for a new Daily Focus task) is not automatically applied via the Intent path.
