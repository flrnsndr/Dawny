// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  ExternalStoreWriteTests.swift
//  DawnyTests
//
//  Externe Schreibvorgänge auf denselben Store: kommt eine Aufgabe an,
//  ohne dass die App neu gestartet werden muss?
//

import SwiftData
import XCTest
@testable import Dawny

/// Reproduziert den Zwei-Geräte-Fund lokal, ohne iCloud.
///
/// Der Fehler lautete: eine importierte Aufgabe liegt nachweislich im Store, die
/// Backlog-Liste zeigt sie trotzdem erst nach einem Kaltstart. Ursache ist nicht
/// CloudKit im Besonderen, sondern jeder Schreibvorgang von außen — und davon hat
/// Dawny mehrere: den CloudKit-Import (derselbe Container, anderer Kontext) sowie
/// Widget-Extension und App-Intents (eigener Prozess, eigener Container). Beide
/// Wege lassen sich hier in Millisekunden nachstellen statt in Minuten.
///
/// Was die Tests unten zeigen: die **Daten** sind nach einem `loadBacklogs()`
/// aktuell, das Problem ist die fehlende **Benachrichtigung** an SwiftUI.
@MainActor
final class ExternalStoreWriteTests: XCTestCase {

    private var storeURL: URL!
    private var appContainer: ModelContainer!
    private var foreignContainer: ModelContainer!
    private var appContext: ModelContext!
    /// Fremder Prozess (Widget, App-Intents): eigener Container, eigener Koordinator.
    private var foreignProcessContext: ModelContext!
    /// CloudKit-Import: **derselbe** Container, nur ein anderer Kontext.
    private var importContext: ModelContext!
    private var syncEngine: SyncEngine!
    private var viewModel: BacklogViewModel!
    private var observer: CloudSyncObserver!

    override func setUp() async throws {
        storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("DawnyExternalWrite-\(UUID().uuidString).store")

        appContainer = try TestModelContainer.createOnDisk(at: storeURL)
        foreignContainer = try TestModelContainer.createOnDisk(at: storeURL)
        appContext = appContainer.mainContext
        foreignProcessContext = foreignContainer.mainContext
        importContext = ModelContext(appContainer)

        syncEngine = SyncEngine(calendarService: MockCalendarService(), modelContext: appContext)
        viewModel = BacklogViewModel(modelContext: appContext, syncEngine: syncEngine)
        observer = CloudSyncObserver(modelContext: appContext)
    }

    override func tearDown() async throws {
        observer = nil
        viewModel = nil
        syncEngine = nil
        appContext = nil
        foreignProcessContext = nil
        importContext = nil
        appContainer = nil
        foreignContainer = nil
        TestModelContainer.removeStore(at: storeURL)
        storeURL = nil
    }

    // MARK: - Helpers

    /// Legt eine Aufgabe im gemeinsamen Store an, aber über einen *fremden* Kontext.
    private func writeTask(title: String, toBacklogWithID id: UUID, through context: ModelContext) throws {
        let backlog = try XCTUnwrap(fetchBacklog(id, in: context))
        _ = backlog.addTask(title: title)
        try context.save()
    }

    /// Löscht eine Aufgabe über einen fremden Kontext — der Gegenfall zum Anlegen.
    private func deleteTaskExternally(title: String, through context: ModelContext) throws {
        let descriptor = FetchDescriptor<Task>(predicate: #Predicate { $0.title == title })
        let task = try XCTUnwrap(context.fetch(descriptor).first)
        context.delete(task)
        try context.save()
    }

    private func fetchBacklog(_ id: UUID, in context: ModelContext) throws -> Backlog? {
        var descriptor = FetchDescriptor<Backlog>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Der `BacklogViewModel` legt beim Start selbst ein Default-Backlog an.
    private func currentBacklogID() throws -> UUID {
        try XCTUnwrap(viewModel.currentBacklog?.id)
    }

    /// Führt `body` aus und meldet, ob die Observation dabei eine Änderung an der
    /// Backlog-Liste gemeldet hat — also ob SwiftUI neu zeichnen würde.
    private func observationFires(during body: () -> Void) -> Bool {
        var fired = false
        withObservationTracking {
            _ = viewModel.backlogTasks
        } onChange: {
            fired = true
        }
        body()
        return fired
    }

    // MARK: - Datenweg

    /// Der Datenweg ist in Ordnung: ein Fetch frischt die Beziehung mit auf, egal ob
    /// von außen angelegt oder gelöscht wurde. Der Kaltstart war also nie nötig, um
    /// überhaupt an die Daten zu kommen.
    func testExternalWritesReachTheListAfterALoad() throws {
        let backlogID = try currentBacklogID()

        try writeTask(title: "Aus dem Import", toBacklogWithID: backlogID, through: importContext)
        try writeTask(title: "Aus dem Widget", toBacklogWithID: backlogID, through: foreignProcessContext)
        viewModel.loadBacklogs()

        XCTAssertEqual(
            Set(viewModel.backlogTasks.map(\.title)),
            ["Aus dem Import", "Aus dem Widget"]
        )

        try deleteTaskExternally(title: "Aus dem Widget", through: importContext)
        viewModel.loadBacklogs()

        XCTAssertEqual(viewModel.backlogTasks.map(\.title), ["Aus dem Import"])
    }

    /// Der Refresh des Observers darf den Datenweg nicht verschlechtern.
    func testHandleRemoteChangesKeepsTheListCurrent() async throws {
        let backlogID = try currentBacklogID()

        try writeTask(title: "Von außen", toBacklogWithID: backlogID, through: importContext)

        await observer.handleRemoteChanges()
        viewModel.loadBacklogs()

        XCTAssertEqual(viewModel.backlogTasks.map(\.title), ["Von außen"])
        XCTAssertEqual(viewModel.taskCount, 1)
    }

    /// Noch nicht gespeicherte Eingaben dürfen der Auffrischung nicht zum Opfer
    /// fallen: `refreshContextFromStore()` sichert sie vorher.
    func testUnsavedLocalEditSurvivesTheRefresh() async throws {
        let backlogID = try currentBacklogID()
        viewModel.addTask(title: "Lokal getippt")

        try writeTask(title: "Von außen", toBacklogWithID: backlogID, through: importContext)

        await observer.handleRemoteChanges()
        viewModel.loadBacklogs()

        XCTAssertEqual(
            Set(viewModel.backlogTasks.map(\.title)),
            ["Lokal getippt", "Von außen"]
        )
    }

    // MARK: - Anzeigeweg

    /// Der eigentliche Regressionstest. Aktuelle Daten allein nützen nichts, wenn
    /// SwiftUI nichts davon erfährt — dann bleibt die alte Liste am Bildschirm stehen.
    func testLoadBacklogsNotifiesObserversAfterAnExternalWrite() throws {
        let backlogID = try currentBacklogID()
        try writeTask(title: "Von außen", toBacklogWithID: backlogID, through: importContext)

        let didNotify = observationFires { viewModel.loadBacklogs() }

        XCTAssertTrue(
            didNotify,
            "Ohne Benachrichtigung bleibt die Liste am Bildschirm stehen, obwohl die Daten stimmen."
        )
    }

    /// Hält fest, warum es dafür `reloadCount` braucht: die naheliegende Lösung,
    /// `currentBacklog` einfach neu zuzuweisen, meldet nichts. Observation vergleicht
    /// die Identität und schluckt die Zuweisung desselben Objekts. Genau daran ist
    /// der erste Versuch gescheitert.
    func testAssigningTheSameBacklogDoesNotNotify() throws {
        let unchanged = viewModel.currentBacklog

        let didNotifyOnSameObject = observationFires { viewModel.currentBacklog = unchanged }
        XCTAssertFalse(didNotifyOnSameObject)

        // Gegenprobe, damit klar ist, dass die Beobachtung überhaupt anschlägt.
        let didNotifyOnRealChange = observationFires { viewModel.currentBacklog = nil }
        XCTAssertTrue(didNotifyOnRealChange)
    }
}
