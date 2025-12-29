---
name: Dawn Teststrategie
overview: "Vollstandige Teststrategie fur Dawn mit Unit Tests, Integration Tests, UI Tests und einem manuellen Testplan. Abdeckung aller kritischen Bereiche: ResetEngine, SyncEngine, Task-Lifecycle, Datenpersistenz und Edge Cases."
todos:
  - id: mocks
    content: Test-Mocks erstellen (MockTimeProvider, MockCalendarService, TestModelContainer)
    status: completed
  - id: task-tests
    content: Task Model Unit Tests implementieren
    status: completed
  - id: reset-tests
    content: ResetEngine Unit Tests implementieren
    status: completed
  - id: sync-tests
    content: SyncEngine Unit Tests implementieren
    status: completed
  - id: backlog-tests
    content: Backlog Model Tests implementieren
    status: completed
  - id: integration-tests
    content: Integration Tests (Lifecycle, Persistenz)
    status: completed
  - id: ui-tests
    content: UI Tests fur Core Flows
    status: completed
---

# Dawn Teststrategie

## Ubersicht

Die Teststrategie folgt der **Test-Pyramide**:

- Unit Tests (viele, schnell)
- Integration Tests (wenige, mittlere Geschwindigkeit)
- UI Tests (minimal, langsam)
- Manueller Testplan (Checkliste)

---

## 1. Unit Tests

### 1.1 Task Model Tests

**Datei:** `Dawn/Tests/Models/TaskModelTests.swift`| Test | Beschreibung ||------|--------------|| `testTaskCreation` | Task mit korrekten Defaults erstellen || `testComplete` | `complete()` setzt `isCompleted=true`, `status=.completed` || `testResetToBacklog` | `resetToBacklog()` setzt Status, entfernt scheduledDate || `testMoveToDailyFocus` | `moveToDailyFocus()` setzt Status und Datum || `testNeedsReset` | `needsReset` ist true wenn dailyFocus + nicht completed |

### 1.2 ResetEngine Tests

**Datei:** `Dawn/Tests/Services/ResetEngineTests.swift`| Test | Beschreibung ||------|--------------|| `testResetNotNeededSameDay` | Kein Reset wenn heute schon resettet || `testResetNeededAfter3AM` | Reset wenn letzter Reset gestern war || `testResetMovesTasksToBacklog` | Tasks werden korrekt verschoben || `testResetRemovesCalendarLink` | externalReminderID wird geloscht || `testResetUpdatesLastResetDate` | UserDefaults wird aktualisiert || `testResetOrderPreserved` | Reihenfolge bleibt erhalten (sortPriority) || `testNoResetBefore3AM` | Kein Reset wenn vor 3 Uhr |

### 1.3 SyncEngine Tests

**Datei:** `Dawn/Tests/Services/SyncEngineTests.swift`| Test | Beschreibung ||------|--------------|| `testSyncCreatesReminder` | Neuer Task erstellt Reminder || `testSyncUpdatesReminder` | Anderung wird synchronisiert || `testSyncRemovesReminder` | Task aus DailyFocus entfernt Reminder || `testConflictResolutionCalendarWins` | Neuerer Kalender-Eintrag gewinnt || `testConflictResolutionAppWins` | Neuerer App-Eintrag gewinnt || `testHandleDeletedReminder` | Geloschter Reminder setzt Task zuruck |

### 1.4 Backlog Model Tests

**Datei:** `Dawn/Tests/Models/BacklogModelTests.swift`| Test | Beschreibung ||------|--------------|| `testAddTask` | Task wird korrekt hinzugefugt || `testBacklogTasks` | Filter zeigt nur inBacklog Tasks || `testTaskCount` | Zahlt nur inBacklog Tasks |---

## 2. Integration Tests

### 2.1 Task-Lifecycle Integration

**Datei:** `Dawn/Tests/Integration/TaskLifecycleTests.swift`| Test | Beschreibung ||------|--------------|| `testFullTaskLifecycle` | Backlog -> DailyFocus -> Completed || `testTaskResetCycle` | DailyFocus -> Reset -> Backlog -> DailyFocus || `testMultipleTasksInDailyFocus` | Mehrere Tasks gleichzeitig |

### 2.2 Persistenz Integration

**Datei:** `Dawn/Tests/Integration/PersistenceTests.swift`| Test | Beschreibung ||------|--------------|| `testTaskPersistsAfterRelaunch` | Tasks uberleben App-Neustart || `testBacklogPersists` | Backlog uberleben App-Neustart || `testResetStatePersists` | LastResetDate uberleben |---

## 3. UI Tests

### 3.1 Core Flows

**Datei:** `Dawn/UITests/DawnUITests.swift`| Test | Beschreibung ||------|--------------|| `testCreateTaskInBacklog` | + Button -> Text eingeben -> Hinzufugen || `testMoveTaskToDailyFocus` | Swipe links -> "Heute" || `testCompleteTaskInDailyFocus` | Checkbox antippen || `testMoveTaskBackToBacklog` | Swipe rechts -> "Backlog" || `testTabNavigation` | Zwischen Tabs wechseln |---

## 4. Manueller Testplan

### 4.1 Happy Path Checkliste

- [ ] App starten - zeigt "Heute" Tab
- [ ] Zu "Backlog" wechseln
- [ ] Task erstellen (+ Button)
- [ ] Task erscheint in Liste
- [ ] Task nach links swipen -> "Heute"
- [ ] Zu "Heute" wechseln
- [ ] Task erscheint in "Offen" Section
- [ ] Checkbox antippen
- [ ] Task wandert zu "Erledigt" Section
- [ ] iOS Erinnerungen-App offnen
- [ ] Task erscheint dort als erledigt

### 4.2 Edge Cases Checkliste

- [ ] Leeres Backlog zeigt Empty State
- [ ] Leere Heute-Liste zeigt Empty State
- [ ] Langer Task-Titel wird korrekt angezeigt
- [ ] Task mit Notizen zeigt Notizen an
- [ ] Kalender-Berechtigung verweigern -> App crasht nicht
- [ ] Offline-Nutzung funktioniert

### 4.3 Reset-Test (manuell)

1. Task zu "Heute" hinzufugen (NICHT erledigen)
2. App schliesen
3. Systemzeit auf nach 3:00 Uhr nachsten Tag stellen
4. App offnen
5. Prufen: Task ist im Backlog (ganz oben)

---

## 5. Test-Infrastruktur

### 5.1 Mocks benotigt

| Mock | Zweck ||------|-------|| `MockTimeProvider` | Kontrollierte Zeit fur Reset-Tests || `MockCalendarService` | Kein echter Kalender-Zugriff || `MockModelContext` | In-Memory SwiftData |

### 5.2 Test-Ordnerstruktur

```javascript
Dawn/Tests/
├── Mocks/
│   ├── MockTimeProvider.swift
│   ├── MockCalendarService.swift
│   └── TestModelContainer.swift
├── Models/
│   ├── TaskModelTests.swift
│   └── BacklogModelTests.swift
├── Services/
│   ├── ResetEngineTests.swift
│   └── SyncEngineTests.swift
└── Integration/
    ├── TaskLifecycleTests.swift
    └── PersistenceTests.swift

Dawn/UITests/
└── DawnUITests.swift
```

---

## 6. Priorisierte Implementierungsreihenfolge

1. **Mocks erstellen** (MockTimeProvider, MockCalendarService)