# Dawny – iOS Task Management App

## Projektübersicht

Dawny ist eine minimalistische iOS-App für bewusstes tägliches Task-Management. Die App verfolgt eine einzigartige "Zero-Overdue-Philosophie": Es gibt keine überfälligen Tasks. Um 3 Uhr morgens werden alle nicht erledigten Tasks automatisch zurück ins Backlog verschoben.

Plattform: iOS 18.0+

Sprache: Swift 6

UI-Framework: SwiftUI

Datenpersistenz: SwiftData

Kalender-Integration: EventKit

Siri-Integration: App Intents Framework

------

## Kernphilosophie

### Zero-Overdue-Policy

Dawny basiert auf der Überzeugung, dass überfällige Tasks psychologischen Stress verursachen. Anstatt Tasks als "überfällig" zu markieren, werden sie automatisch um 3:00 Uhr morgens zurück ins Backlog verschoben. Jeden Tag beginnt der Nutzer mit einer sauberen Liste.

### Bewusste Tagesplanung

Der Nutzer entscheidet jeden Tag aktiv, welche Tasks er in den "Daily Focus" verschiebt. Es gibt keine automatischen Fälligkeitsdaten – nur "Backlog" (irgendwann) oder "Heute" (Daily Focus).

------

## Hauptfunktionen

### 1. Zwei-Listen-System

- Backlog: Sammlung aller ungeplanten Tasks

- Daily Focus: Tasks für den heutigen Tag

### 2. 3-AM-Reset

- Nicht erledigte Daily Focus Tasks werden um 3:00 Uhr zurück ins Backlog verschoben

- Die Reset-Zeit wurde gewählt, weil die meisten Menschen dann schlafen

- Der Reset passiert beim nächsten App-Start nach 3:00 Uhr

### 3. EventKit-Synchronisation

- Bidirektionale Synchronisation mit iOS Erinnerungen

- Daily Focus Tasks erscheinen in der Erinnerungen-App

- Änderungen in der Erinnerungen-App werden zurück zu Dawny synchronisiert

- Konfliktauflösung nach "Last-Write-Wins" Prinzip

### 4. Siri-Integration

- "Hey Siri, füge X zu Dawny hinzu" → Task ins Backlog

- "Hey Siri, füge X heute zu Dawny hinzu" → Task in Daily Focus

------

## Architektur

### MVVM-PatternViews (SwiftUI)  ↓ViewModels (@Observable)  ↓Services (ResetEngine, SyncEngine)  ↓Models (SwiftData: Task, Backlog)

### Kernkomponenten

Models:

- Task: SwiftData-Model mit Status (inBacklog, dailyFocus, scheduled, completed)

- Backlog: Container für Tasks mit Sortierung

- TaskStatus: Enum für den Task-Lifecycle

Services:

- ResetEngine: Verantwortlich für den 3-AM-Reset

- SyncEngine: Bidirektionale EventKit-Synchronisation

- EventKitCalendarService: Wrapper für EKEventStore

ViewModels:

- BacklogViewModel: Verwaltet Backlog-Tasks

- DailyFocusViewModel: Verwaltet Daily Focus Tasks

Views:

- BacklogView: Liste der Backlog-Tasks mit Swipe-Actions

- DailyFocusView: Tagesansicht mit Checkbox zum Abhaken

- QuickAddView: Sheet zum Erstellen neuer Tasks

Intents (Siri):

- AddTaskIntent: Task zum Backlog hinzufügen

- AddTaskTodayIntent: Task zu Daily Focus hinzufügen

- DawnyShortcuts: Siri-Phrasen Provider

------

## Benutzerflows

### Task erstellen und erledigen

1. Nutzer öffnet Backlog-Tab

1. Tippt auf "+" und gibt Task-Titel ein

1. Swipe nach links → "Heute" verschiebt Task zu Daily Focus

1. Wechsel zum Heute-Tab

1. Checkbox antippen → Task erledigt

### Automatischer Reset

1. Nutzer hat um 23:00 Uhr 3 offene Tasks in Daily Focus

1. Nutzer schließt App und schläft

1. Nutzer öffnet App am nächsten Morgen um 8:00 Uhr

1. App prüft: Letzter Reset war gestern → Reset durchführen

1. Die 3 Tasks sind jetzt im Backlog (ganz oben, mit aktuellem Datum)

### Siri-Workflow

1. "Hey Siri, füge Milch kaufen heute zu Dawny hinzu"

1. Siri: "Erledigt! 'Milch kaufen' wurde für heute hinzugefügt."

1. Task erscheint in Daily Focus

1. Task wird auch zu iOS Erinnerungen synchronisiert

------

## Technische Details

### Protokolle für Testbarkeit

- TimeProvider: Abstrahiert die Systemzeit (ermöglicht Zeit-Mocking in Tests)

- CalendarServiceProtocol: Abstrahiert EventKit (ermöglicht Mock-Kalender in Tests)

### SwiftData-Konfiguration@Modelfinal class Task {  var id: UUID  var title: String  var status: TaskStatus  var scheduledDate: Date?  var externalReminderID: String?  var sortPriority: Date  *// ...*}

### Concurrency

- Services sind @MainActor markiert für Thread-Safety mit SwiftData

- Async/await für alle Netzwerk- und Kalender-Operationen

------

## Unterschiede zu Microsoft To-Do

| Feature              | Dawny                       | Microsoft To-Do         |
| :------------------- | :-------------------------- | :---------------------- |
| Überfällige Tasks    | Existieren nicht            | Bleiben überfällig      |
| Fälligkeitsdaten     | Nur "Heute" oder nicht      | Beliebige Termine       |
| Listen               | 1 Backlog                   | Unbegrenzt              |
| Wiederkehrende Tasks | Nein                        | Ja                      |
| Subtasks             | Nein                        | Ja                      |
| Tags                 | Nein                        | Ja                      |
| Cross-Platform       | Nur iOS                     | Alle Plattformen        |
| Philosophie          | Opinionated, minimalistisch | Flexibel, feature-reich |

------

## Teststrategie

### Unit Tests (XCTest)

- TaskModelTests: Task-Methoden und Computed Properties

- BacklogModelTests: Relationships und Filter

- ResetEngineTests: Reset-Timing und Verhalten

- SyncEngineTests: Kalender-Synchronisation

### Integration Tests

- TaskLifecycleTests: Vollständiger Workflow

- PersistenceTests: SwiftData-Persistenz

### UI Tests

- Navigation zwischen Tabs

- Task-Erstellung

- Launch Performance

### Mocks

- MockTimeProvider: Kontrollierte Zeit für Tests

- MockCalendarService: Fake-Kalender ohne EventKit

- TestModelContainer: In-Memory SwiftData

------

## Dateistruktur

Dawny/

├── Sources/

│  ├── DawnyApp.swift

│  ├── Models/

│  │  ├── Task.swift

│  │  ├── Backlog.swift

│  │  └── TaskStatus.swift

│  ├── Services/

│  │  ├── ResetEngine.swift

│  │  ├── SyncEngine.swift

│  │  └── EventKitCalendarService.swift

│  ├── ViewModels/

│  │  ├── BacklogViewModel.swift

│  │  └── DailyFocusViewModel.swift

│  ├── Views/

│  │  ├── ContentView.swift

│  │  ├── BacklogView.swift

│  │  ├── DailyFocusView.swift

│  │  ├── QuickAddView.swift

│  │  └── Components/

│  ├── Intents/

│  │  ├── AddTaskIntent.swift

│  │  ├── AddTaskTodayIntent.swift

│  │  └── DawnyShortcuts.swift

│  ├── Protocols/

│  │  ├── TimeProvider.swift

│  │  └── CalendarServiceProtocol.swift

│  └── Extensions/

│    └── HapticFeedback.swift

├── DawnyTests/

│  ├── Models/

│  ├── Services/

│  ├── Integration/

│  └── Mocks/

------

## Berechtigungen

- Reminders (EventKit): Für Synchronisation mit iOS Erinnerungen

- Siri: Für Sprachbefehle

- Background Modes: Für den 3-AM-Reset (fetch, processing)

------

## Zukünftige Erweiterungen (nicht implementiert)

- Mehrere Backlogs

- Wiederkehrende Tasks

- Widget für Home Screen

- Apple Watch App

- Statistiken und Insights

- iCloud-Synchronisation
