// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  SyncEngineTests.swift
//  DawnyTests
//
//  Unit Tests für die SyncEngine
//

import XCTest
import SwiftData
@testable import Dawny

@MainActor
final class SyncEngineTests: XCTestCase {
    
    var container: ModelContainer!
    var context: ModelContext!
    var calendarService: MockCalendarService!
    var syncEngine: SyncEngine!

    /// Namen der pro Test angelegten UserDefaults-Suites. Das Verzeichnis der lokal
    /// erreichbaren Erinnerungen ist gerätelokaler Zustand — jedes „Gerät" im Test
    /// braucht sein eigenes, sonst weiß Gerät B von Erinnerungen, die es nie gesehen hat.
    private var suiteNames: [String] = []

    override func setUp() async throws {
        container = try TestModelContainer.create()
        context = container.mainContext
        calendarService = MockCalendarService()
        syncEngine = SyncEngine(
            calendarService: calendarService,
            modelContext: context,
            linkRegistry: makeIsolatedRegistry()
        )

        // Setze Kalender-Sync auf aktiviert für Tests
        AppSettings.shared.calendarSyncEnabled = true

        // Das Migrations-Flag liegt in den geteilten UserDefaults und überlebt sonst
        // den einzelnen Test — jeder Test startet mit einer nicht gelaufenen Migration.
        AppGroup.defaults.removeObject(forKey: SyncEngine.reminderIdentifierMigrationKey)
    }

    override func tearDown() async throws {
        // Bereinige Settings nach jedem Test
        AppSettings.shared.calendarSyncEnabled = true
        AppGroup.defaults.removeObject(forKey: SyncEngine.reminderIdentifierMigrationKey)

        for name in suiteNames {
            UserDefaults.standard.removePersistentDomain(forName: name)
        }
        suiteNames.removeAll()
    }

    /// Ein frisches, leeres Verzeichnis — entspricht einem Gerät, das noch keine
    /// Erinnerung selbst aufgelöst hat.
    private func makeIsolatedRegistry() -> ReminderLinkRegistry {
        let name = "DawnyTests.ReminderLinks.\(UUID().uuidString)"
        suiteNames.append(name)
        return ReminderLinkRegistry(defaults: UserDefaults(suiteName: name)!)
    }
    
    // MARK: - Create Reminder Tests
    
    func testSyncCreatesReminder() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test Task", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()
        
        await syncEngine.syncTaskToCalendar(task)
        
        XCTAssertEqual(calendarService.createCallCount, 1)
        XCTAssertNotNil(task.externalReminderID)
        XCTAssertEqual(calendarService.reminders.count, 1)
    }
    
    func testSyncDoesNotCreateReminderForBacklogTask() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test Task", status: .inBacklog, backlog: backlog)
        
        await syncEngine.syncTaskToCalendar(task)
        
        XCTAssertEqual(calendarService.createCallCount, 0)
        XCTAssertNil(task.externalReminderID)
    }
    
    // MARK: - Update Reminder Tests
    
    func testSyncUpdatesReminder() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Original Title", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()
        
        // Erstelle initial
        await syncEngine.syncTaskToCalendar(task)
        let reminderID = task.externalReminderID!
        
        // Ändere Task
        task.title = "Updated Title"
        
        // Sync nochmal
        await syncEngine.syncTaskToCalendar(task)
        
        XCTAssertEqual(calendarService.updateCallCount, 1)
        XCTAssertEqual(task.externalReminderID, reminderID)
    }
    
    // MARK: - Remove Reminder Tests
    
    func testSyncRemovesReminder() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()
        
        // Erstelle Reminder
        await syncEngine.syncTaskToCalendar(task)
        let reminderID = task.externalReminderID!
        XCTAssertNotNil(calendarService.reminders[reminderID])
        
        // Entferne Reminder
        await syncEngine.removeTaskFromCalendar(task)
        
        XCTAssertEqual(calendarService.deleteCallCount, 1)
        XCTAssertNil(calendarService.reminders[reminderID])
        XCTAssertNil(task.externalReminderID)
    }

    /// Ein Gerät ohne Reminders-Integration darf die Verknüpfung nicht anfassen.
    /// Bei aktivem iCloud-Sync würde das Lösen sonst zum verknüpfenden Gerät
    /// zurücksyncen und dessen echte Erinnerung verwaisen lassen.
    func testRemoveIsNoOpWhileCalendarSyncIsDisabled() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()

        await syncEngine.syncTaskToCalendar(task)
        let reminderID = task.externalReminderID
        XCTAssertNotNil(reminderID)

        AppSettings.shared.calendarSyncEnabled = false
        await syncEngine.removeTaskFromCalendar(task)

        XCTAssertEqual(calendarService.deleteCallCount, 0, "Ohne Reminders-Integration darf EventKit nicht angefasst werden")
        XCTAssertEqual(task.externalReminderID, reminderID, "Die Verknüpfung muss erhalten bleiben")
    }


    // MARK: - Sync All Tests
    
    func testSyncAllDailyFocusTasks() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task1 = TestModelContainer.createTask(in: context, title: "Task 1", status: .dailyFocus, backlog: backlog)
        let task2 = TestModelContainer.createTask(in: context, title: "Task 2", status: .dailyFocus, backlog: backlog)
        let task3 = TestModelContainer.createTask(in: context, title: "Backlog Task", status: .inBacklog, backlog: backlog)
        
        task1.scheduledDate = Date()
        task2.scheduledDate = Date()
        
        await syncEngine.syncAllDailyFocusTasks()
        
        XCTAssertEqual(calendarService.createCallCount, 2)
        XCTAssertNotNil(task1.externalReminderID)
        XCTAssertNotNil(task2.externalReminderID)
        XCTAssertNil(task3.externalReminderID)
    }
    
    // MARK: - Error Handling Tests
    
    func testSyncHandlesErrors() async throws {
        calendarService.shouldFailOperations = true
        
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()
        
        // Sollte nicht crashen
        await syncEngine.syncTaskToCalendar(task)
        
        XCTAssertNil(task.externalReminderID)
    }
    
    // MARK: - Edge Cases
    
    func testRemoveWithoutReminderID() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        
        // Sollte nicht crashen
        await syncEngine.removeTaskFromCalendar(task)
        
        XCTAssertEqual(calendarService.deleteCallCount, 0)
    }
    
    // MARK: - Settings Tests
    
    func testSyncRespectsCalendarSyncEnabled() async throws {
        // Deaktiviere Kalender-Sync
        AppSettings.shared.calendarSyncEnabled = false
        
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test Task", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()
        
        // Versuche zu synchronisieren
        await syncEngine.syncTaskToCalendar(task)
        
        // Sollte nicht synchronisiert werden
        XCTAssertEqual(calendarService.createCallCount, 0)
        XCTAssertNil(task.externalReminderID)
    }
    
    func testSyncAllRespectsCalendarSyncEnabled() async throws {
        // Deaktiviere Kalender-Sync
        AppSettings.shared.calendarSyncEnabled = false

        let backlog = TestModelContainer.createBacklog(in: context)
        let task1 = TestModelContainer.createTask(in: context, title: "Task 1", status: .dailyFocus, backlog: backlog)
        let task2 = TestModelContainer.createTask(in: context, title: "Task 2", status: .dailyFocus, backlog: backlog)

        task1.scheduledDate = Date()
        task2.scheduledDate = Date()

        // Versuche alle zu synchronisieren
        await syncEngine.syncAllDailyFocusTasks()

        // Sollte nicht synchronisiert werden
        XCTAssertEqual(calendarService.createCallCount, 0)
        XCTAssertNil(task1.externalReminderID)
        XCTAssertNil(task2.externalReminderID)
    }

    // MARK: - UI Refresh Notification Tests

    /// Wird in Reminders eine verknüpfte Aufgabe abgehakt, muss `syncNow()` ein
    /// `.dawnyDidSyncFromCalendar`-Signal posten, damit die ViewModels neu laden.
    func testSyncFromCalendarPostsNotificationWhenReminderChanged() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()

        await syncEngine.syncTaskToCalendar(task)
        let reminderID = try XCTUnwrap(task.externalReminderID)

        // Simuliere "in Reminders abgehakt": Reminder ist completed und neuer als der Task.
        task.modifiedAt = Date(timeIntervalSinceNow: -60)
        let existing = try XCTUnwrap(calendarService.reminders[reminderID])
        calendarService.reminders[reminderID] = CalendarReminder(
            id: existing.id,
            title: existing.title,
            notes: existing.notes,
            isCompleted: true,
            dueDate: existing.dueDate,
            modificationDate: Date(timeIntervalSinceNow: 60)
        )

        let expectation = XCTNSNotificationExpectation(name: .dawnyDidSyncFromCalendar)
        await syncEngine.syncNow()
        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertTrue(task.isCompleted)
    }

    /// Ohne tatsächliche Änderung im Kalender darf kein Refresh-Signal gepostet werden
    /// (verhindert unnötige Reloads / Refresh-Stürme).
    func testSyncFromCalendarDoesNotPostNotificationWhenNothingChanged() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()

        await syncEngine.syncTaskToCalendar(task)

        let expectation = XCTNSNotificationExpectation(name: .dawnyDidSyncFromCalendar)
        expectation.isInverted = true
        await syncEngine.syncNow()
        await fulfillment(of: [expectation], timeout: 0.5)
    }

    // MARK: - Sync Toggle Tests

    /// Der Kern des gemeldeten Fehlers: Wer den Sync einschaltet, während schon
    /// Aufgaben in Heute liegen, hat den Moment verpasst, in dem eine Erinnerung
    /// entstanden wäre. Das Nachziehen holt genau diese Aufgaben ein.
    func testBackfillAfterEnablingCreatesRemindersForExistingDailyFocusTasks() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let first = TestModelContainer.createTask(in: context, title: "Erste", status: .dailyFocus, backlog: backlog)
        first.scheduledDate = Date()
        let second = TestModelContainer.createTask(in: context, title: "Zweite", status: .dailyFocus, backlog: backlog)
        second.scheduledDate = Date()
        let backlogTask = TestModelContainer.createTask(in: context, title: "Im Backlog", status: .inBacklog, backlog: backlog)

        await syncEngine.backfillAfterEnabling()

        XCTAssertEqual(calendarService.createCallCount, 2)
        XCTAssertNotNil(first.externalReminderID)
        XCTAssertNotNil(second.externalReminderID)
        XCTAssertNil(backlogTask.externalReminderID)
    }

    /// Beim Ausschalten steht `calendarSyncEnabled` bereits auf `false`. Das Aufräumen
    /// muss trotzdem laufen, sonst bleiben verwaiste Erinnerungen zurück, die Dawny
    /// danach nie wieder anfasst.
    func testTeardownAfterDisablingRemovesRemindersEvenWhenSyncIsOff() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()

        await syncEngine.syncTaskToCalendar(task)
        XCTAssertEqual(calendarService.reminders.count, 1)

        AppSettings.shared.calendarSyncEnabled = false
        await syncEngine.teardownAfterDisabling()

        XCTAssertEqual(calendarService.deleteCallCount, 1)
        XCTAssertTrue(calendarService.reminders.isEmpty)
        XCTAssertNil(task.externalReminderID)
    }

    /// Auch eine inzwischen erledigte Aufgabe kann noch eine Erinnerung tragen.
    /// Das Aufräumen darf sich deshalb nicht auf `.dailyFocus` beschränken.
    func testTeardownAfterDisablingRemovesRemindersOfCompletedTasks() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()

        await syncEngine.syncTaskToCalendar(task)
        task.complete()
        XCTAssertNotNil(task.externalReminderID)

        AppSettings.shared.calendarSyncEnabled = false
        await syncEngine.teardownAfterDisabling()

        XCTAssertTrue(calendarService.reminders.isEmpty)
        XCTAssertNil(task.externalReminderID)
    }

    // MARK: - Error Surfacing Tests

    /// Vorher landeten Kalender-Fehler nur in einem `print`, der Nutzer sah nie,
    /// dass das Anlegen einer Erinnerung fehlgeschlagen ist.
    func testFailedSyncSurfacesErrorMessage() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()
        calendarService.shouldFailOperations = true

        await syncEngine.syncTaskToCalendar(task)

        XCTAssertNotNil(syncEngine.lastErrorMessage)

        syncEngine.clearError()
        XCTAssertNil(syncEngine.lastErrorMessage)
    }

    func testSuccessfulSyncLeavesNoErrorMessage() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()

        await syncEngine.syncTaskToCalendar(task)

        XCTAssertNil(syncEngine.lastErrorMessage)
    }

    // MARK: - Reminder-Identifier-Migration

    /// Kern der Umstellung: Eine Verknüpfung aus der Zeit der gerätelokalen ID wird
    /// auf die geräteübergreifend stabile ID gehoben.
    func testMigrationRewritesLegacyIdentifierToStableID() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()

        let stableID = try await calendarService.createReminder(title: "Test", notes: nil, dueDate: Date())
        calendarService.registerLegacyIdentifier("local-only-id", for: stableID)
        task.externalReminderID = "local-only-id"

        await syncEngine.migrateReminderIdentifiersIfNeeded()

        XCTAssertEqual(task.externalReminderID, stableID)
    }

    /// Eine ID, die dieses Gerät nicht auflösen kann, gehört einem anderen Gerät oder
    /// einer gelöschten Erinnerung. Die Migration lässt sie in Ruhe — das verknüpfende
    /// Gerät schreibt sie selbst um, gelöschte räumt der reguläre Sync ab.
    func testMigrationKeepsUnresolvableLinkUntouched() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        task.externalReminderID = "id-vom-anderen-geraet"

        await syncEngine.migrateReminderIdentifiersIfNeeded()

        XCTAssertEqual(task.externalReminderID, "id-vom-anderen-geraet")
    }

    /// Das Flag liegt in den geteilten UserDefaults: Nach einem erfolgreichen Durchlauf
    /// fasst die Migration nichts mehr an.
    func testMigrationRunsOnlyOnce() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)

        await syncEngine.migrateReminderIdentifiersIfNeeded()
        XCTAssertTrue(AppGroup.defaults.bool(forKey: SyncEngine.reminderIdentifierMigrationKey))

        let stableID = try await calendarService.createReminder(title: "Test", notes: nil, dueDate: Date())
        calendarService.registerLegacyIdentifier("local-only-id", for: stableID)
        task.externalReminderID = "local-only-id"
        calendarService.stableIdentifierCallCount = 0

        await syncEngine.migrateReminderIdentifiersIfNeeded()

        XCTAssertEqual(calendarService.stableIdentifierCallCount, 0)
        XCTAssertEqual(task.externalReminderID, "local-only-id")
    }

    /// Scheitert der Zugriff auf EventKit — etwa ohne erteilte Berechtigung —, darf das
    /// Flag nicht gesetzt werden, sonst bleibt die Verknüpfung für immer gerätelokal.
    func testMigrationRetriesAfterFailure() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)

        let stableID = try await calendarService.createReminder(title: "Test", notes: nil, dueDate: Date())
        calendarService.registerLegacyIdentifier("local-only-id", for: stableID)
        task.externalReminderID = "local-only-id"

        calendarService.shouldFailOperations = true
        await syncEngine.migrateReminderIdentifiersIfNeeded()

        XCTAssertFalse(AppGroup.defaults.bool(forKey: SyncEngine.reminderIdentifierMigrationKey))
        XCTAssertEqual(task.externalReminderID, "local-only-id")

        calendarService.shouldFailOperations = false
        await syncEngine.migrateReminderIdentifiersIfNeeded()

        XCTAssertEqual(task.externalReminderID, stableID)
    }

    /// Bis die Migration läuft, muss der normale Sync mit der Alt-ID weiterarbeiten:
    /// EventKit löst die gerätelokale ID auf dem verknüpfenden Gerät weiterhin auf.
    func testSyncStillResolvesLegacyIdentifier() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Neuer Titel", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()

        let stableID = try await calendarService.createReminder(title: "Alter Titel", notes: nil, dueDate: Date())
        calendarService.registerLegacyIdentifier("local-only-id", for: stableID)
        task.externalReminderID = "local-only-id"
        calendarService.createCallCount = 0

        await syncEngine.syncTaskToCalendar(task)

        XCTAssertEqual(calendarService.createCallCount, 0, "Keine zweite Erinnerung für dieselbe Aufgabe")
        XCTAssertEqual(calendarService.updateCallCount, 1)
        XCTAssertEqual(calendarService.reminders[stableID]?.title, "Neuer Titel")
    }

    /// Der eigentliche Fehler: Vor der Umstellung fand ein Zweitgerät zur mitgesyncten
    /// ID keine Erinnerung und legte eine zweite an. Mit der stabilen ID greift es auf
    /// dieselbe zu. Das zweite Gerät wird durch einen eigenen Context bei geteiltem
    /// Kalender abgebildet — genau so sieht iCloud für beide Geräte aus.
    func testSecondDeviceUpdatesTheSameReminderInsteadOfCreatingADuplicate() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()

        await syncEngine.syncTaskToCalendar(task)
        let stableID = try XCTUnwrap(task.externalReminderID)

        // Gerät B: eigener Store, dieselbe Aufgabe samt mitgesyncter Verknüpfung.
        let secondContainer = try TestModelContainer.create()
        let secondContext = secondContainer.mainContext
        let secondEngine = SyncEngine(calendarService: calendarService, modelContext: secondContext)
        let secondBacklog = TestModelContainer.createBacklog(in: secondContext)
        let secondTask = TestModelContainer.createTask(in: secondContext, title: "Test", status: .dailyFocus, backlog: secondBacklog)
        secondTask.scheduledDate = Date()
        secondTask.externalReminderID = stableID

        calendarService.createCallCount = 0
        await secondEngine.syncTaskToCalendar(secondTask)

        XCTAssertEqual(calendarService.createCallCount, 0)
        XCTAssertEqual(calendarService.reminders.count, 1, "Beide Geräte zeigen auf dieselbe Erinnerung")

        // Abhaken auf Gerät B trifft die Erinnerung, die Gerät A angelegt hat.
        await secondEngine.removeTaskFromCalendar(secondTask)
        XCTAssertTrue(calendarService.reminders.isEmpty)
    }

    // MARK: - Nicht auflösbare Verknüpfungen anderer Geräte

    /// Der gemeldete Fehler: Gerät B importiert eine Aufgabe samt Verknüpfung, kann die
    /// Erinnerung dahinter aber nicht auflösen. Vorher las der Sync das als „in Reminders
    /// gelöscht" und räumte die Aufgabe aus Heute — auf beiden Geräten.
    func testSyncKeepsTaskInTodayWhenReminderBelongsToAnotherDevice() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()
        task.externalReminderID = "id-vom-anderen-geraet"

        await syncEngine.syncNow()

        XCTAssertEqual(task.status, .dailyFocus, "Die Aufgabe muss in Heute bleiben")
        XCTAssertEqual(task.externalReminderID, "id-vom-anderen-geraet", "Die Verknüpfung gehört Gerät A")
    }

    /// Und es darf auch kein Refresh-Signal geben: Ohne Änderung an den Daten gibt es
    /// nichts nachzuladen.
    func testSyncPostsNoNotificationForAnUnresolvableForeignLink() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()
        task.externalReminderID = "id-vom-anderen-geraet"

        let expectation = XCTNSNotificationExpectation(name: .dawnyDidSyncFromCalendar)
        expectation.isInverted = true
        await syncEngine.syncNow()
        await fulfillment(of: [expectation], timeout: 0.5)
    }

    /// Die Gegenprobe: Auf dem verknüpfenden Gerät bleibt das bisherige Verhalten. Wer
    /// die Erinnerung in Reminders löscht, bekommt die Aufgabe zurück ins Backlog.
    func testSyncMovesTaskToBacklogWhenTheOwnReminderWasDeleted() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()

        // Dieses Gerät legt die Erinnerung selbst an und kennt sie damit.
        await syncEngine.syncTaskToCalendar(task)
        let reminderID = try XCTUnwrap(task.externalReminderID)

        // In der Erinnerungen-App gelöscht.
        calendarService.reminders.removeValue(forKey: reminderID)

        await syncEngine.syncNow()

        XCTAssertEqual(task.status, .inBacklog)
        XCTAssertNil(task.externalReminderID)
    }

    /// Zweiter Schadenspfad derselben Ursache: Beim Reset läuft `deleteReminder` für eine
    /// fremde ID stillschweigend ins Leere, das Lösen der Verknüpfung aber nicht — und das
    /// Lösen synct zurück und lässt die echte Erinnerung auf Gerät A verwaisen. Der
    /// `calendarSyncEnabled`-Guard greift hier nicht, weil die Integration im
    /// Auslieferungszustand auf jedem Gerät an ist.
    func testRemoveKeepsTheLinkWhenTheReminderBelongsToAnotherDevice() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()
        task.externalReminderID = "id-vom-anderen-geraet"

        XCTAssertTrue(AppSettings.shared.calendarSyncEnabled)
        await syncEngine.removeTaskFromCalendar(task)

        XCTAssertEqual(calendarService.deleteCallCount, 0)
        XCTAssertEqual(task.externalReminderID, "id-vom-anderen-geraet", "Die Verknüpfung gehört Gerät A")
    }

    /// Erster Lauf nach dem Update: Das Verzeichnis ist noch leer, die Verknüpfungen
    /// stammen aber von diesem Gerät. Ein direkter Abruf entscheidet, damit das Aufräumen
    /// nicht für Bestandsnutzer stehen bleibt.
    func testRemoveStillWorksForAnUnregisteredButReachableReminder() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()

        // Verknüpfung wie aus der Zeit vor dem Update: Erinnerung vorhanden, Verzeichnis leer.
        let reminderID = try await calendarService.createReminder(title: "Test", notes: nil, dueDate: Date())
        task.externalReminderID = reminderID

        await syncEngine.removeTaskFromCalendar(task)

        XCTAssertEqual(calendarService.deleteCallCount, 1)
        XCTAssertNil(task.externalReminderID)
    }

    /// Dritter Schadenspfad: Eine fremde Verknüpfung lässt `updateReminder` scheitern.
    /// Das ist auf einem Zweitgerät der Normalfall und darf weder ein Fehler-Banner
    /// zeigen noch eine zweite Erinnerung für dieselbe Aufgabe anlegen.
    func testForeignLinkNeitherShowsAnErrorNorCreatesADuplicate() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()
        task.externalReminderID = "id-vom-anderen-geraet"

        await syncEngine.syncTaskToCalendar(task)

        XCTAssertNil(syncEngine.lastErrorMessage)
        XCTAssertEqual(calendarService.createCallCount, 0)
        XCTAssertEqual(task.externalReminderID, "id-vom-anderen-geraet")
    }

    /// Auch das Abräumen beim Ausschalten der Integration darf fremde Verknüpfungen
    /// nicht lösen — sonst verwaist die Erinnerung auf dem Gerät, das sie hält.
    func testTeardownKeepsLinksOfAnotherDevice() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let own = TestModelContainer.createTask(in: context, title: "Eigen", status: .dailyFocus, backlog: backlog)
        own.scheduledDate = Date()
        await syncEngine.syncTaskToCalendar(own)

        let foreign = TestModelContainer.createTask(in: context, title: "Fremd", status: .dailyFocus, backlog: backlog)
        foreign.scheduledDate = Date()
        foreign.externalReminderID = "id-vom-anderen-geraet"

        AppSettings.shared.calendarSyncEnabled = false
        await syncEngine.teardownAfterDisabling()

        XCTAssertNil(own.externalReminderID, "Die eigene Erinnerung wird abgeräumt")
        XCTAssertEqual(foreign.externalReminderID, "id-vom-anderen-geraet", "Die fremde bleibt unangetastet")
    }

    /// Der Ablauf aus dem Fehlerbericht, end to end und über zwei Geräte. Gerät B hat
    /// einen eigenen Store, ein eigenes Verzeichnis und einen eigenen EventKit-Zugang,
    /// der die Erinnerung von Gerät A nicht auflöst — genau der Fall, in dem die
    /// Tagesplanung vorher verloren ging.
    func testForeignReminderDoesNotWipeTodayOnEitherDevice() async throws {
        // Gerät A: Aufgabe in Heute, Erinnerung angelegt.
        let backlog = TestModelContainer.createBacklog(in: context)
        let taskOnA = TestModelContainer.createTask(in: context, title: "Steuer", status: .dailyFocus, backlog: backlog)
        taskOnA.scheduledDate = Date()
        await syncEngine.syncTaskToCalendar(taskOnA)
        let reminderID = try XCTUnwrap(taskOnA.externalReminderID)

        // Gerät B: importiert Aufgabe samt Verknüpfung, erreicht die Erinnerung aber nicht.
        let calendarOnB = MockCalendarService()
        let containerOnB = try TestModelContainer.create()
        let contextOnB = containerOnB.mainContext
        let engineOnB = SyncEngine(
            calendarService: calendarOnB,
            modelContext: contextOnB,
            linkRegistry: makeIsolatedRegistry()
        )
        let backlogOnB = TestModelContainer.createBacklog(in: contextOnB)
        let taskOnB = TestModelContainer.createTask(in: contextOnB, title: "Steuer", status: .dailyFocus, backlog: backlogOnB)
        taskOnB.scheduledDate = Date()
        taskOnB.externalReminderID = reminderID

        await engineOnB.syncNow()

        XCTAssertEqual(taskOnB.status, .dailyFocus, "Gerät B darf die Aufgabe nicht aus Heute räumen")
        XCTAssertEqual(taskOnB.externalReminderID, reminderID, "und die Verknüpfung nicht lösen")

        // Auf Gerät A ändert sich ebenfalls nichts — die Erinnerung existiert weiterhin.
        await syncEngine.syncNow()
        XCTAssertEqual(taskOnA.status, .dailyFocus)
        XCTAssertEqual(calendarOnB.reminders.count, 0)
        XCTAssertEqual(calendarService.reminders.count, 1)
    }
}
