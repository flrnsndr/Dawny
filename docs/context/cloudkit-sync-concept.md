# Dawny — iCloud Multi-Device Sync Concept (SwiftData + CloudKit)

> **Status: code and Xcode capabilities done on branch `feat/icloud-sync`,
> feature off by default.**
> PRs 1–5 of §15 are in the tree (schema defaults, opt-in toggle + container matrix +
> local fallback, dedup routine + remote-change observer, KVS settings sync, EventKit
> guard + Settings footers) together with the unit tests of §14.1. The capability steps
> of §3 are applied to the Dawny target (CloudKit container
> `iCloud.Florian.Dawny.MVP`, key-value storage, push notifications, Background Mode
> `remote-notification`); the widget target is untouched.
> The toggle is **opt-out**: sync is on by default (D2), so the Production schema
> deployment is a **release blocker**, not a nice-to-have.
> **Not yet done:** creating the Development schema by running the app once, deploying
> that schema to Production (§13.3), and the two-device matrix of §14.2. Until the schema
> is deployed, TestFlight and App Store builds have no Production schema to sync against —
> and with sync on by default that would hit every user, not just opt-ins. Read
> `docs/context/architecture.md` first; this document assumes its terminology.
>
> Guiding principle (explicit product decision): **robustness beats edge-case completeness.**
> Where the two conflict, the edge case is documented as accepted and NOT handled (see §12).

---

## 1. Goal & Scope

Sync all Dawny domain data (Tasks, Backlogs, Categories) plus the behavior-relevant
settings across the user's devices via the user's **private iCloud database** (CloudKit),
using SwiftData's built-in CloudKit integration.

**In scope**
- Opt-in iCloud sync toggle in Settings (default: **off**).
- Full sync of the SwiftData store (Task, Backlog, Category).
- Sync of the three behavior-relevant settings (`resetHour`, `makeItCountThreshold`,
  `defaultCategoryType`) via `NSUbiquitousKeyValueStore`.
- Convergent (idempotent-under-double-execution) 3 AM reset.
- Deduplication routine for seeded objects (built-in categories, default recurring
  category, the single default Backlog).
- Removal of the `fatalError` on ModelContainer init in favor of a local-only fallback.

**Out of scope (explicitly)**
- Sync inside the widget/intent extension process (widgets keep reading the shared
  App-Group store; see §9).
- Cross-device EventKit/Reminders link resolution (see §10).
- Shared/public CloudKit databases, sharing with other people.
- Live re-creation of the ModelContainer while the app is running (toggle takes effect
  on next launch, see §5.3).

**Baseline**: the app already requires iOS 18+ (`UIGestureRecognizerRepresentable` in
`ContentView`), so no additional OS gating is needed. Verify the deployment target is
≥ 18.0 before starting; if it is lower, raise it as part of this work.

---

## 2. Core Design Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | CloudKit **private database** via SwiftData (`ModelConfiguration(cloudKitDatabase:)`), no custom backend | No accounts, no server cost, matches the public "your data stays in your own iCloud" positioning |
| D2 | **Opt-out** toggle, default **on**, device-local | Product decision (2026-08-24): sync should just work without the user hunting for a switch. Cost: existing users are migrated to CloudKit on the update, so the Production schema must be deployed first (§13) |
| D3 | Reset stays **per-device**; correctness comes from **convergence, not coordination** | A synced "who resets" lock is fragile under offline/latency; a deterministic reset function applied twice converges under CloudKit's field-level last-writer-wins |
| D4 | Reset **parameters** are synced (`resetHour`, `makeItCountThreshold`) via `NSUbiquitousKeyValueStore` | Convergence only holds if all devices compute with the same inputs |
| D5 | Seeding stays as-is; a **dedup routine** repairs duplicates after remote imports | Simpler and more robust than making seeding sync-aware; the dedup pass doubles as a general repair mechanism |
| D6 | Sync runs **only in the main app process** | CloudKit sync in extensions is unsupported/unreliable; widgets keep their current read path |
| D7 | Toggle takes effect at **next app launch** | The container is built once in `DawnyApp.init()` and referenced by every service/context; rebuilding live risks dangling contexts for zero user value |
| D8 | `archiveReviewed` stays on the model (synced) | The auto-archive review overlay shows on whichever device is opened first; "first device wins" is the intended UX |

---

## 3. Project / Xcode Setup (GUI steps, main app target ONLY)

The Xcode project uses synchronized groups (no `project.pbxproj` file edits needed for
new files), but **capabilities are target settings and must be added via the Xcode GUI**:

1. Target **Dawny** → Signing & Capabilities → `+ Capability` → **iCloud**.
   - Check **CloudKit**.
   - Container: create/select `iCloud.<main-app-bundle-id>` (verify the bundle id in the
     target settings first; do not guess it from this document).
2. Same target → `+ Capability` → **Background Modes** → check **Remote notifications**
   (CloudKit delivers change pushes as silent pushes; without this, changes only arrive
   on foreground fetches).
3. Xcode adds the `aps-environment` entitlement automatically with the iCloud capability.
4. Also add (same target) the **iCloud → Key-value storage** checkbox (for
   `NSUbiquitousKeyValueStore`, §7).
5. **Do NOT add any iCloud capability to the `DawnyWidgets` target.** The extension keeps
   its current entitlements (App Group only).

Define the container identifier in one place, next to the existing App Group constant:

```swift
enum CloudKitConfig {
    /// Must match the container selected in Signing & Capabilities.
    static let containerID = "iCloud.<main-app-bundle-id>"
}
```

**CloudKit environments:** DEBUG builds talk to the *Development* environment.
**TestFlight and App Store builds talk to *Production*.** Before the first TestFlight
build, deploy the schema: CloudKit Console → your container → *Deploy Schema Changes*
(Development → Production). After that, the production schema is **additive-only
forever**: fields can be added (they must then be optional/defaulted, which §4 already
guarantees) but never removed or renamed. Renaming a `@Model` property later requires
`@Attribute(originalName:)` or a new field + migration.

---

## 4. Schema Changes (exact)

CloudKit-backed SwiftData models require: **no `@Attribute(.unique)`** (none exist today
— keep it that way), **every stored property optional or with an inline default in the
declaration** (init parameter defaults do NOT count), and **CloudKit-tolerant
relationships**.

The inits keep their current required parameters, so **no call site changes**. The inline
defaults are technical fallbacks for CloudKit record materialization, not new API.

### 4.1 `Task` ([App/Sources/Models/Task.swift](../../App/Sources/Models/Task.swift))

```swift
var id: UUID = UUID()
var title: String = ""
var notes: String?                          // unchanged (optional)
var status: TaskStatus = TaskStatus.inBacklog
var parentBacklogID: UUID = UUID()          // placeholder; init always overwrites
var scheduledDate: Date?                    // unchanged
var externalReminderID: String?             // unchanged
var sortPriority: Date = Date()
var createdAt: Date = Date()
var modifiedAt: Date = Date()
var isCompleted: Bool = false
// recurringCloneID, resetCount, archivedAt, archiveReason, archiveReviewed,
// completedAt, enteredBacklogAt: already optional or defaulted — unchanged.
var backlog: Backlog?                       // unchanged (already optional)
var category: Category?                     // unchanged (already optional)
```

Note: `status` and `archiveReason` are String-raw-value `Codable` enums; SwiftData stores
them as transformable/string columns and CloudKit accepts them. No change needed beyond
the defaults.

### 4.2 `Backlog` ([App/Sources/Models/Backlog.swift](../../App/Sources/Models/Backlog.swift))

```swift
var id: UUID = UUID()
var title: String = ""
var orderIndex: Int = 0
var createdAt: Date = Date()

@Relationship(deleteRule: .cascade, inverse: \Task.backlog)
var tasks: [Task] = []
```

### 4.3 `Category` ([App/Sources/Models/Category.swift](../../App/Sources/Models/Category.swift))

```swift
var id: UUID = UUID()
var categoryType: TaskCategory = TaskCategory.custom
var name: String = ""
var iconName: String = ""
var orderIndex: Int = 0
var isUncategorized: Bool = false
// isNameCustomized, isIconCustomized, isRecurring, autoArchiveDays: already defaulted.
var createdAt: Date = Date()

@Relationship(deleteRule: .nullify, inverse: \Task.category)
var tasks: [Task] = []
```

### 4.4 Relationships must be optional — confirmed, applied

The optimistic variant (non-optional arrays with `= []`) does **not** work. As soon as the
iCloud entitlement is present, Core Data validates the schema and refuses to load the
store:

```
CloudKit integration requires that all relationships be optional, the following are not:
Backlog: tasks
Category: tasks
```

Both to-many relationships are therefore declared `[Task]? = []`. The touch points, all
resolved with `?? []`:

- `Backlog.liveTasks`, `Backlog.addTask` (`tasks.append` → `tasks = (tasks ?? []) + [task]`),
  `Backlog.removeTask` (`removeAll` → `filter`)
- `Category.liveTasks`
- `CategoryService.delete(_:strategy:)` (the two `category.tasks` snapshots)
- `CloudDeduplicator` (both `loser.tasks` snapshots)
- `BacklogView` (two `category.tasks.count` in the delete confirmation)
- Tests: `PersistenceTests`, `BacklogModelTests`, `CloudDeduplicatorTests`

The `init` parameters stay `[Task]`, so no call site passes an optional.

### 4.4.1 In-memory stores must opt out of CloudKit explicitly

`ModelConfiguration`'s `cloudKitDatabase` defaults to `.automatic`. Without an iCloud
entitlement that resolved to "no CloudKit"; **with** the entitlement it starts binding
every store to the container — including `isStoredInMemoryOnly` ones. That broke the whole
unit-test suite (every `TestModelContainer.create()` failed with
`loadIssueModelContainer`) even though tests never enable sync.

Every in-memory configuration therefore passes `cloudKitDatabase: .none` explicitly:
`TestModelContainer`, `IntentDataStore.makeModelContainer(isStoredInMemoryOnly:)`,
`PreviewSupport`, and the `TaskRowView` preview.

### 4.5 Store-compat note

Adding inline defaults and `= []` does not change column types; the existing on-disk
store opens without a migration stage. No `VersionedSchema` needed for this step.

---

## 5. Container Configuration

All changes in [`IntentDataStore.makeModelContainer`](../../App/Sources/Intents/IntentDataStore.swift)
and [`DawnyApp.swift`](../../App/Sources/DawnyApp.swift).

### 5.1 New setting

`AppSettings.iCloudSyncEnabled: Bool` (default **`true`**), persisted in
`AppGroup.defaults` under key `DawnyICloudSyncEnabled`, **device-local by design** (each
device decides for itself; do NOT put this key into the KVS sync set). Read via
`object(forKey:) as? Bool ?? true` — `bool(forKey:)` would return `false` for the absent
key and silently turn the default off. The key is in `Keys.allKeys` so the
`AppGroupMigrator` carries it.

**Test isolation is mandatory with an on-by-default flag.** `CloudKitConfig.isDisabledForTesting`
forces both the CloudKit container and the KVS off whenever the process is a test run —
detected via `XCTestConfigurationFilePath` (unit tests share the app process) or the
`--uitesting` launch argument that both UI test suites already pass. Without this, the
suites would bind real stores and push seeded data and churned settings into the
developer's own iCloud.

### 5.2 Configuration matrix

`makeModelContainer` chooses the configuration:

| Condition | Configuration |
|---|---|
| In-memory (tests/previews) | unchanged |
| Widget/intent extension process | unchanged: plain `ModelConfiguration(schema:url:)` on the App-Group URL — **never** the CloudKit option |
| Main app, `iCloudSyncEnabled == false` | unchanged (plain App-Group config) |
| Main app, `iCloudSyncEnabled == true` | `ModelConfiguration(schema:url:cloudKitDatabase: .private(CloudKitConfig.containerID))` on the **same App-Group store URL** |

Keeping the same store URL means: enabling sync does not move data; SwiftData/Core Data
export the existing local objects to CloudKit on first open with the CloudKit option
(verify in the test plan, §14). Widgets keep working against the same file.

### 5.3 Toggle semantics

Flipping the Settings toggle only writes the flag. The Settings row shows a footnote
("takes effect after the app is relaunched", localized, see §11). No live container swap.

### 5.4 Replace the `fatalError`

`DawnyApp.init()` currently hard-crashes if the container fails. New behavior:

1. Try the configuration from the matrix above.
2. If that throws **and** the CloudKit option was used: log, set
   `iCloudSyncEnabled = false` (self-heal), retry with the plain App-Group config.
3. If the plain config also throws: keep today's `fatalError` (unchanged last resort —
   this is the pre-existing schema-incompatibility case, not a new failure mode).

### 5.5 iCloud account preconditions

There is no runtime permission prompt for CloudKit. Sync requires only that the device
is signed into iCloud and iCloud isn't disabled for Dawny in iOS Settings. Surface this
in Settings (§11) via `CKContainer(identifier:).accountStatus()`: show a passive status
line ("iCloud available" / "Not signed into iCloud — sync is paused"). Never block the
app on account status; the store works locally regardless.

---

## 6. Remote Change Handling (main app only)

When CloudKit imports remote changes into the store, the UI, widgets, and the dedup
routine must react. Implement a small `CloudSyncObserver` (new file,
`App/Sources/Services/CloudSyncObserver.swift`, `@MainActor`), started from
`performAppLaunchTasks()` only when `iCloudSyncEnabled == true`:

- Subscribe to `NotificationCenter` for `.NSPersistentStoreRemoteChange` (posted by the
  underlying Core Data stack; SwiftData CloudKit configs enable remote-change
  notifications). Debounce 1 s (same pattern as `SyncEngine`'s EventKit stream).
- On each debounced batch, on the MainActor:
  1. Run the dedup routine (§8) on `modelContainer.mainContext`.
  2. `WidgetRefresher.reload()`.
  3. Post `.dawnyDidReset` (reusing the existing "reload your lists" contract in
     `ContentView` — see [ResetEngine.swift:272](../../App/Sources/Services/ResetEngine.swift)).
     If a semantic distinction is wanted, add `.dawnyDidReceiveRemoteChanges` and have
     `ContentView` handle both identically.
- Additionally run the dedup routine once during `performAppLaunchTasks()` (after
  `initializeDefaultCategories()`), so duplicates created while the app was closed are
  repaired at launch even if no new remote batch arrives.

---

## 7. Settings Sync via `NSUbiquitousKeyValueStore`

**Synced keys** (behavior-relevant — required for reset convergence, D4):

| Key | KVS key | Notes |
|---|---|---|
| `resetHour` | `DawnyKVSResetHour` | Int |
| `makeItCountThreshold` | `DawnyKVSMakeItCountThreshold` | Int |
| `defaultCategoryType` | `DawnyKVSDefaultCategoryType` | String raw value (not the JSON-encoded blob used in UserDefaults) |

**Deliberately NOT synced** (device-local): `calendarSyncEnabled` (see §10),
`iCloudSyncEnabled`, `showCompletedTasksInToday`, `showCategories`, `hasSeenWelcome`,
`hasNewArchivedTasks`, `lastArchiveVisitDate`, `appLaunchCount`, `totalResetEventCount`,
`lastReviewPromptDate`, `DawnyLastResetDate`, and all one-shot migration flags.

**Mechanics** (extend `AppSettings`; abstract the KVS behind a tiny protocol so tests can
inject a mock):

- All KVS activity is gated on `iCloudSyncEnabled == true`.
- On each synced property's `didSet`: also write to KVS and call `synchronize()`.
- Observe `NSUbiquitousKeyValueStore.didChangeExternallyNotification`; for each changed
  synced key, write the KVS value into the property (which re-persists to
  `AppGroup.defaults` via the existing `didSet` — guard against ping-pong by comparing
  values before writing).
- **On toggle-on** (first launch with sync enabled): if the KVS already contains a value
  for a key, the KVS value wins and overwrites local; otherwise the local value is pushed
  up. This makes the second device adopt the first device's settings deterministically.
- Conflict rule between devices: last writer wins (KVS default). Accepted.

---

## 8. Deduplication Routine (the critical piece)

**Problem:** a fresh install seeds default data before the first CloudKit download
completes. Afterward the store contains e.g. two "Quick" categories, two default
Backlogs, etc. `initializeDefaultCategories()`
([CategoryService.swift](../../App/Sources/Services/CategoryService.swift)) and
`findOrCreateBacklog` ([IntentDataStore.swift](../../App/Sources/Intents/IntentDataStore.swift))
stay **unchanged**; the dedup routine repairs afterwards.

New file `App/Sources/Services/CloudDeduplicator.swift`. One entry point:
`static func dedupe(in context: ModelContext) throws`. Requirements: **idempotent**
(running twice is a no-op the second time), **deterministic** (every device picks the
same winner, so dedup itself converges), saves once at the end, no-ops quickly when
nothing is duplicated.

**Winner rule (used everywhere):** within a duplicate group, the winner is the object
with the earliest `createdAt`; ties broken by lexicographically smallest `id.uuidString`.

### 8.1 Backlog dedup

- Fetch all `Backlog`s. If ≤ 1: done.
- Pick the winner. For every loser: reassign `task.backlog = winner` and
  `task.parentBacklogID = winner.id` for all its tasks (snapshot the array before
  iterating — inverse-relationship mutation), then `context.delete(loser)`.
  (`deleteRule: .cascade` is why tasks must be moved **before** deleting.)
- Do not touch `title`/`orderIndex` of the winner.

### 8.2 Built-in category dedup

- Group all categories with `categoryType != .custom` by `categoryType`.
- Per group with > 1 member: pick winner; for each loser, move its tasks
  (`task.category = winner`, snapshot first), then merge customization before deleting:
  - if `loser.isNameCustomized && !winner.isNameCustomized`: copy `name` and the flag.
  - if `loser.isIconCustomized && !winner.isIconCustomized`: copy `iconName` and the flag.
  - if `winner.autoArchiveDays == nil && loser.autoArchiveDays != nil && !winner.isRecurring`:
    copy `autoArchiveDays`.
  - `context.delete(loser)`.

### 8.3 Default recurring category dedup

The seeded "Recurring Tasks" category is `categoryType == .custom`, so the id-based rule
doesn't catch it. Treat as one dedup group: all categories where
`categoryType == .custom && isRecurring == true && isNameCustomized == false`
(mirrors `CategoryService.isLikelyDefaultRecurringCategory`, which additionally matches
the known default names — reuse that helper by making it internal). Same
winner/move/merge/delete procedure as §8.2.

**User-created custom categories are never deduplicated** (identity = `id`; two customs
with the same name on two devices are legitimately two categories).

### 8.4 After dedup

If anything was deleted: `try context.save()`, then `WidgetRefresher.reload()` and post
`.dawnyDidReset`. If `AppSettings.shared.defaultCategoryType` points at a type whose
instances were merged, nothing to do (type still exists via the winner).

---

## 9. Widgets, Intents, Background

- The extension process keeps its exact current behavior (plain shared store; no
  CloudKit). Consequence: a task completed via widget/Siri on device A is uploaded only
  the next time the **main app** on device A runs (SwiftData records history for the
  shared store; the CloudKit export happens in the app process). Accepted (§12).
- Remote changes reach widgets only after the main app has imported them
  (`WidgetRefresher.reload()` in §6). Accepted: a widget can show stale data until the
  app is opened. This matches the widget's existing "as-if" preview philosophy.
- `BGAppRefreshTask` reset scheduling is unchanged.

---

## 10. Reset Convergence & EventKit Policy

### 10.1 What changes in `ResetEngine`: **nothing structural.**

The per-device gate (`DawnyLastResetDate` in `AppGroup.defaults`) stays. Convergence is
guaranteed by three facts, two of which already hold:

1. `ResetOutcomePlanner.outcome(for:referenceDate:makeItCountThreshold:calendar:)` is a
   pure deterministic function of task state + parameters (already true — do not change).
2. All mutations it triggers write absolute values (`status`, `scheduledDate`,
   `archivedAt`, …). Two devices applying the same function to the same state write the
   same values; CloudKit's field-level last-writer-wins merges them into that same state.
   Even `resetCount += 1` converges: both read n, both write n+1, merge = n+1.
3. Parameters are equal across devices — **this is the new part**, delivered by §7 (D4).

The recurring-tasks invariant ("recurring tasks are never archived") is enforced inside
the planner and is therefore automatically preserved on every device.

Add the convergence unit test (§14.1) to lock this in.

### 10.2 EventKit / Apple Reminders

`calendarSyncEnabled` stays **device-local** (not in §7's KVS set). Policy: the
Reminders integration is a per-device feature; the user should enable it on one device
only. Devices with it disabled never touch EventKit (existing guard). Consequences:

- `Task.externalReminderID` syncs via CloudKit but refers to an EventKit identifier that
  may not resolve on another device. **Verified during implementation:**
  `EventKitCalendarService` stores `EKCalendarItem.calendarItemIdentifier`, which is the
  **device-local** identifier (the cross-device-stable one would be
  `calendarItemExternalIdentifier`). A link created on device A therefore never resolves
  on device B.
- `deleteReminder(id:)` already treats "not found" as a silent no-op, so no hardening was
  needed there.
- If the user enables Reminders sync on two devices anyway, duplicate reminders can
  appear. Accepted (§12). Add a footnote to the Settings row (§11).

#### 10.2.1 Unlink propagation — decided, implemented

`ResetEngine.performReset` used to call `syncEngine.removeTaskFromCalendar(task)` for
every synced task **without** a `calendarSyncEnabled` guard (unlike `syncTaskToCalendar`).
Combined with the local-identifier finding above, this sequence ran on a second device:
`deleteReminder` no-ops (identifier unknown locally) → `task.unlinkFromCalendar()` clears
`externalReminderID` → the cleared value syncs back to device A, whose real reminder is
now orphaned.

**Decision: `removeTaskFromCalendar` now guards on `calendarSyncEnabled`.** A device
without the Reminders integration never touches EventKit and never mutates the link, so
nothing can propagate back. This also makes the claim in `architecture.md` §7 ("every
SyncEngine operation checks `calendarSyncEnabled`") true, which it previously was not.

Accepted trade-off: a user who switches the Reminders integration off keeps leftover
reminders in the Reminders app instead of having the next reset clean them up. This
matches every other path — nothing else cleans up on disable either.

Covered by `SyncEngineTests.testRemoveIsNoOpWhileCalendarSyncIsDisabled`.

---

## 11. UI Changes (Settings only) + Localization

All strings go into `App/Sources/Localizable.xcstrings` in **both** locales (en + de).
Suggested keys/values:

| Key | en | de |
|---|---|---|
| `settings.icloud.section` | iCloud Sync | iCloud-Sync |
| `settings.icloud.toggle` | Sync with iCloud | Mit iCloud synchronisieren |
| `settings.icloud.footer.restart` | Takes effect after you relaunch Dawny. Your tasks sync through your personal iCloud account. | Wird nach einem Neustart von Dawny aktiv. Deine Aufgaben werden über dein persönliches iCloud-Konto synchronisiert. |
| `settings.icloud.status.available` | iCloud available | iCloud verfügbar |
| `settings.icloud.status.noAccount` | Not signed into iCloud. Sync is paused. | Nicht bei iCloud angemeldet. Der Sync pausiert. |
| `settings.icloud.footer.reminders` | Tip: enable the Apple Reminders integration on one device only. | Tipp: Aktiviere die Apple-Erinnerungen-Integration nur auf einem Gerät. |

Settings view: new section with the toggle, the account-status line (§5.5), and the two
footers. No other UI changes. (The auto-archive review overlay needs **no** change:
`archiveReviewed` syncs, so the overlay appears on the first device opened and is
suppressed elsewhere once synced — decision D8.)

---

## 12. Accepted Limitations (do not "fix" these)

1. **Duplicate recurring clone**: completing the same recurring task on two offline
   devices creates two backlog clones. User deletes one. No invariant broken.
2. **Backlog ordering drift** after a double reset (`sortPriority` differs by
   milliseconds between devices). Cosmetic.
3. **Review overlay may appear on two devices** if both are opened before the
   `archiveReviewed` write syncs. Self-heals.
4. **Archive tab dot badge (`hasNewArchivedTasks`) is per-device best-effort**: the
   device whose own reset run archived nothing (because the other device's result synced
   in first) shows no dot. The synced overlay is the primary surface.
5. **Widget/Siri writes sync late** (next main-app run, §9).
6. **Duplicate Apple Reminders** if the EventKit integration is enabled on two devices.
7. **Clock manipulation / timezone changes** around the reset threshold: same behavior
   as today, no additional handling.
8. **No sync-status UI** beyond the account-status line (no progress, no "last synced").
   SwiftData exposes no reliable API for this; do not fake one.

---

## 13. Migration & Rollout

1. Ship schema changes (§4) **first or together** with the container change — they are
   inert while the toggle is off (default). Existing users: zero behavior change.
2. User enables toggle on device A → relaunch → store opens with CloudKit → existing
   data uploads. Device B: install/update, enable toggle, relaunch → download + dedup.
3. CloudKit Console: after the first DEBUG run has created the Development schema,
   **verify the schema is complete, then deploy to Production before the first TestFlight
   build** (§3).

   **CloudKit materializes fields lazily — only for values actually uploaded.** An
   optional attribute that is `nil` across every record never gets a field, and
   Production does not let clients add fields later: the first record that does carry a
   value fails to export, permanently, and silently for that record.

   Hit for real on 2026-08-24: `CD_Task` came up with 20 record fields instead of 21.
   Missing was `CD_notes`, because `Task.notes` is never set from Dawny's UI — it only
   round-trips from Apple Reminders.

   Pre-deploy check, per record type: **console field count − 6 metadata fields
   (`createdTimestamp`, `createdUserRecordName`, `___etag`, `modifiedTimestamp`,
   `modifiedUserRecordName`, `recordName`) must equal the model's stored properties plus
   `entityName`.** To-many relationships do not count — Core Data stores the reference on
   the to-one side (`Task.backlog` → `CD_backlog`), so `Backlog.tasks` and
   `Category.tasks` produce no field of their own.

   Expected: `CD_Backlog` 11, `CD_Category` 18, `CD_Task` **27**. (`Users` is CloudKit's
   own record type and is not ours.)

   To materialize a missing field, get one real record to carry a value and let it sync —
   for `CD_notes` that means adding a note to a synced reminder in the Reminders app and
   letting `SyncEngine` pull it back in. Prefer that over adding the field by hand in the
   console, so Core Data picks the type and indexes itself.
4. Release as its own focused release; do not bundle with other feature work.
5. Website/App-Store copy: no privacy-label change needed (private database; the
   developer has no access to user data). Existing "data stays in your iCloud" copy
   remains accurate.

---

## 14. Test Plan

### 14.1 Unit tests (extend `DawnyTests/`, using the existing `MockTimeProvider` + in-memory `TestModelContainer`)

- **Reset convergence**: seed a mixed state (recurring in dailyFocus, non-recurring below
  threshold, non-recurring at threshold, stale backlog task for auto-tidy). Snapshot the
  full task state after one `performReset(referenceDate: T)`; run `performReset` again
  with the same `T` (simulating the second device applying the same function); assert
  the state is unchanged (statuses, `resetCount`s, no additional archives, recurring
  tasks still in backlog and never archived).
- **Dedup — backlogs**: two backlogs with tasks → one backlog, all tasks reassigned,
  `parentBacklogID` fixed, winner = earliest `createdAt`.
- **Dedup — built-ins**: duplicated `.quick`/`.uncategorized` → one each; customized
  name/icon on the loser is preserved onto an uncustomized winner.
- **Dedup — default recurring**: two seeded recurring customs → one; a user-created
  recurring custom (`isNameCustomized == true`) is untouched.
- **Dedup — idempotence**: running `dedupe` twice, second run changes nothing and
  performs no save.
- **KVS mirroring**: with a mocked KVS: local change propagates up; external change
  propagates down; toggle-on adopts existing KVS values over local ones; everything
  inert when `iCloudSyncEnabled == false`.
- **Container fallback**: CloudKit config failure falls back to plain config and clears
  the flag (inject the failure; if not injectable, cover the decision logic extracted
  into a testable function).

### 14.2 Manual two-device matrix (TestFlight, physical devices; CloudKit pushes do not reach the Simulator reliably)

| # | Scenario | Expected |
|---|---|---|
| 1 | Enable on device A with existing data; enable on fresh device B | B shows A's data; exactly one Backlog, one category per built-in type, one default recurring category |
| 2 | Create/complete/archive/unarchive tasks on A | Appears on B (foreground the app) |
| 3 | Both devices offline, edit different tasks, go online | Both edits present |
| 4 | Both devices offline, edit the SAME task's title | One title wins (LWW), no crash, no duplicate |
| 5 | Let the 3 AM reset pass, open A, then open B | Identical end state on both; recurring tasks in backlog on both, never archived; archived task appears once in the review overlay (first-opened device) |
| 6 | Change `resetHour`/`makeItCountThreshold` on A | Value appears on B (KVS); next reset uses it on both |
| 7 | Complete a recurring task on A while B is offline; complete it on B too; go online | Two clones in backlog (accepted limitation #1), nothing worse |
| 8 | Sign out of iCloud on B | App keeps working locally; Settings shows the paused hint; sign back in → sync resumes |
| 9 | Complete a task via widget/Siri on A, then open app A | Change reaches B after A's app ran |
| 10 | Toggle sync off on A, edit, toggle on again | Local edits upload on re-enable; no data loss |

---

## 15. Implementation Order (suggested PR slicing)

1. **PR 1 — Schema defaults + fatalError fallback** (§4, §5.4). Inert, releasable alone.
2. **PR 2 — Toggle + container matrix + capabilities** (§5, §3, §11). Feature dark-ships
   behind the off-by-default toggle.
3. **PR 3 — Dedup routine + CloudSyncObserver** (§8, §6) with unit tests.
4. **PR 4 — KVS settings sync** (§7) with unit tests, plus the reset convergence test
   (§14.1).
5. **PR 5 — EventKit no-op hardening + Settings footers** (§10.2, §11 leftovers).
6. TestFlight phase on the developer's own devices (matrix §14.2), then release.

### Implementation notes (deviations from the spec above)

- **Retry placement (§5.4):** the CloudKit→local retry lives inside
  `IntentDataStore.makeModelContainer` rather than `DawnyApp.init`, so every caller gets
  the fallback regardless of which one builds the container first. `DawnyApp`'s
  `fatalError` remains only as the last resort for the pre-existing
  schema-incompatibility case.
- **Widget target membership:** `IntentDataStore.swift` and `AppSettings.swift` are
  compiled into `DawnyWidgetsExtension`, so `CloudKitConfig.swift` and
  `UbiquitousKeyValueStoring.swift` had to be added to that target's
  `membershipExceptions` in `project.pbxproj`. Both are deliberately free of
  `import CloudKit`; the actual CloudKit call (`accountStatus()`) sits in the app-only
  `CloudSyncStatus`.
- **§10.2 hardening** turned out to be unnecessary at the EventKit layer
  (`deleteReminder` already no-ops on an unknown identifier), but surfaced the real
  problem one level up — resolved in §10.2.1 by guarding `removeTaskFromCalendar`.

Each PR must keep `xcodebuild test` green (see `CLAUDE.md` for the exact commands) and
follow the repo rules: localized strings in both locales, license headers on new Swift
files (`./scripts/add-license-headers.sh`), no unrelated refactoring.
