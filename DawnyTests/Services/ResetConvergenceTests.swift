// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  ResetConvergenceTests.swift
//  DawnyTests
//
//  Sichert die Kernannahme des iCloud-Syncs ab: der nächtliche Reset ist
//  konvergent. Zwei Geräte, die denselben Zustand mit denselben Parametern
//  resetten, schreiben dieselben Werte — der CloudKit-Merge (feldweise
//  Last-Writer-Wins) führt deshalb nicht zu doppelten Effekten.
//
//  Der Test simuliert das, indem er denselben Reset zweimal auf denselben
//  Zustand anwendet und prüft, dass der zweite Lauf nichts mehr verändert.
//

import XCTest
import SwiftData
@testable import Dawny

@MainActor
final class ResetConvergenceTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var timeProvider: MockTimeProvider!
    private var resetEngine: ResetEngine!
    private var backlog: Backlog!

    private var originalThreshold: Int!
    private var originalResetHour: Int!

    /// Fixer Bezugszeitpunkt — beide „Geräte" rechnen mit demselben Wert.
    private let referenceDate = Date()

    override func setUp() async throws {
        container = try TestModelContainer.create()
        context = container.mainContext
        timeProvider = MockTimeProvider()
        resetEngine = ResetEngine(timeProvider: timeProvider, modelContext: context)
        resetEngine.clearLastResetDate()

        originalThreshold = AppSettings.shared.makeItCountThreshold
        originalResetHour = AppSettings.shared.resetHour
        AppSettings.shared.makeItCountThreshold = 3
        AppSettings.shared.resetHour = 3

        backlog = Backlog(title: "Test Backlog")
        context.insert(backlog)
        try context.save()
    }

    override func tearDown() async throws {
        AppSettings.shared.makeItCountThreshold = originalThreshold
        AppSettings.shared.resetHour = originalResetHour
        resetEngine.clearLastResetDate()
    }

    // MARK: - Snapshot

    /// Alle Felder, die der Reset schreibt. Sortiert nach `id`, damit der
    /// Vergleich unabhängig von der Fetch-Reihenfolge ist.
    private struct TaskSnapshot: Equatable {
        let id: UUID
        let status: TaskStatus
        let resetCount: Int
        let isCompleted: Bool
        let archiveReason: ArchiveReason?
        let isArchived: Bool
    }

    private func snapshot() throws -> [TaskSnapshot] {
        try context.fetch(FetchDescriptor<Task>())
            .filter { !$0.isDeleted }
            .map {
                TaskSnapshot(
                    id: $0.id,
                    status: $0.status,
                    resetCount: $0.resetCount,
                    isCompleted: $0.isCompleted,
                    archiveReason: $0.archiveReason,
                    isArchived: $0.archivedAt != nil
                )
            }
            .sorted { $0.id.uuidString < $1.id.uuidString }
    }

    // MARK: - Fixtures

    @discardableResult
    private func makeCategory(
        name: String,
        isRecurring: Bool,
        autoArchiveDays: Int? = nil
    ) -> Dawny.Category {
        let category = Dawny.Category(
            categoryType: .custom,
            name: name,
            isNameCustomized: true,
            isRecurring: isRecurring,
            autoArchiveDays: autoArchiveDays
        )
        context.insert(category)
        return category
    }

    @discardableResult
    private func makeTask(
        title: String,
        status: TaskStatus,
        category: Dawny.Category,
        resetCount: Int = 0,
        enteredBacklogAt: Date? = nil
    ) -> Task {
        let task = Task(
            title: title,
            status: status,
            parentBacklogID: backlog.id,
            scheduledDate: status == .dailyFocus ? referenceDate : nil,
            category: category
        )
        task.backlog = backlog
        task.resetCount = resetCount
        task.enteredBacklogAt = enteredBacklogAt
        context.insert(task)
        return task
    }

    /// Deckt alle vier Reset-Ausgänge gleichzeitig ab.
    private func seedMixedState() throws {
        let recurring = makeCategory(name: "Recurring", isRecurring: true)
        let normal = makeCategory(name: "Normal", isRecurring: false)
        let shortLived = makeCategory(name: "Short lived", isRecurring: false, autoArchiveDays: 1)

        makeTask(title: "Recurring in Today", status: .dailyFocus, category: recurring)
        makeTask(title: "Below threshold", status: .dailyFocus, category: normal, resetCount: 0)
        makeTask(title: "At threshold", status: .dailyFocus, category: normal, resetCount: 2)
        makeTask(title: "Completed in Today", status: .dailyFocus, category: normal)
            .complete()
        makeTask(
            title: "Stale in backlog",
            status: .inBacklog,
            category: shortLived,
            enteredBacklogAt: referenceDate.addingTimeInterval(-10 * 86_400)
        )

        try context.save()
    }

    // MARK: - Tests

    func testSecondResetOnSameStateChangesNothing() async throws {
        try seedMixedState()

        await resetEngine.performReset(referenceDate: referenceDate)
        let afterFirst = try snapshot()

        // Zweites „Gerät" wendet denselben Reset auf denselben Zustand an.
        await resetEngine.performReset(referenceDate: referenceDate)
        let afterSecond = try snapshot()

        XCTAssertEqual(afterFirst, afterSecond, "Ein zweiter Reset darf den Zustand nicht weiter verändern")
    }

    func testRecurringTaskIsNeverArchivedAcrossRepeatedResets() async throws {
        try seedMixedState()

        for _ in 0..<3 {
            await resetEngine.performReset(referenceDate: referenceDate)
        }

        let recurringTasks = try context.fetch(FetchDescriptor<Task>())
            .filter { !$0.isDeleted && $0.isRecurring }
        XCTAssertFalse(recurringTasks.isEmpty, "Fixture muss wiederkehrende Tasks enthalten")

        for task in recurringTasks {
            XCTAssertEqual(task.status, .inBacklog, "Wiederkehrende Tasks gehören nach dem Reset ins Backlog")
            XCTAssertNil(task.archivedAt, "Wiederkehrende Tasks dürfen nie archiviert werden")
            XCTAssertEqual(task.resetCount, 0, "Wiederkehrende Tasks zählen keinen resetCount hoch")
        }
    }

    func testResetCountDoesNotDoubleIncrementOnRepeatedReset() async throws {
        let normal = makeCategory(name: "Normal", isRecurring: false)
        let task = makeTask(title: "Below threshold", status: .dailyFocus, category: normal, resetCount: 0)
        try context.save()

        await resetEngine.performReset(referenceDate: referenceDate)
        XCTAssertEqual(task.resetCount, 1)

        await resetEngine.performReset(referenceDate: referenceDate)
        XCTAssertEqual(task.resetCount, 1, "Der Task liegt nicht mehr in Heute — der Zähler darf nicht erneut steigen")
    }

    func testTaskAtThresholdIsArchivedExactlyOnce() async throws {
        let normal = makeCategory(name: "Normal", isRecurring: false)
        let task = makeTask(title: "At threshold", status: .dailyFocus, category: normal, resetCount: 2)
        try context.save()

        await resetEngine.performReset(referenceDate: referenceDate)
        let archivedAt = task.archivedAt
        XCTAssertEqual(task.status, .archived)
        XCTAssertEqual(task.archiveReason, .makeItCount)
        XCTAssertNotNil(archivedAt)

        await resetEngine.performReset(referenceDate: referenceDate)
        XCTAssertEqual(task.archivedAt, archivedAt, "Der Archivierungszeitpunkt darf sich nicht verschieben")
        XCTAssertEqual(task.resetCount, 3, "Der Zähler darf beim zweiten Lauf nicht weiter steigen")
    }
}
