// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  DailyFocusRecurringTests.swift
//  DawnyTests
//
//  Wiederkehrend: Complete erzeugt Backlog-Clone, Uncomplete entfernt ihn.
//

import XCTest
import SwiftData
@testable import Dawny

@MainActor
final class DailyFocusRecurringTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var syncEngine: SyncEngine!
    var resetEngine: ResetEngine!
    var timeProvider: MockTimeProvider!
    var originalCalendarEnabled: Bool!

    override func setUp() async throws {
        try await super.setUp()
        UserDefaults.standard.removeObject(
            forKey: "DawnyMigratedRecurringDefaultBeforeUncategorizedV1"
        )
        originalCalendarEnabled = AppSettings.shared.calendarSyncEnabled
        AppSettings.shared.calendarSyncEnabled = false
        timeProvider = MockTimeProvider()
        container = try TestModelContainer.create()
        context = container.mainContext
        let calendarService = MockCalendarService()
        syncEngine = SyncEngine(calendarService: calendarService, modelContext: context)
        resetEngine = ResetEngine(timeProvider: timeProvider, modelContext: context)
    }

    override func tearDown() async throws {
        AppSettings.shared.calendarSyncEnabled = originalCalendarEnabled
        container = nil
        context = nil
        syncEngine = nil
        resetEngine = nil
        timeProvider = nil
        try await super.tearDown()
    }

    private func recurringCategory() throws -> Dawny.Category {
        let service = CategoryService(modelContext: context)
        service.initializeDefaultCategories()
        let rec = try XCTUnwrap(
            service.getCategoriesSorted().first(where: { $0.isRecurring }),
            "Wiederkehrend-Default Kategorie"
        )
        return rec
    }

    func testCompleteRecurringCreatesBacklogClone() async throws {
        let vm = DailyFocusViewModel(
            modelContext: context,
            syncEngine: syncEngine,
            resetEngine: resetEngine
        )
        let recurring = try recurringCategory()
        let backlog = TestModelContainer.createBacklog(in: context, title: "B")
        let task = backlog.addTask(title: "R1")
        task.category = recurring
        let today = Calendar.current.startOfDay(for: Date())
        task.moveToDailyFocus(date: today)
        try context.save()

        await vm.completeTask(task)

        let all = try context.fetch(FetchDescriptor<Task>())
        XCTAssertEqual(all.count, 2)
        let completed = all.filter { $0.status == .completed }
        let backlogs = all.filter { $0.status == .inBacklog }
        XCTAssertEqual(completed.count, 1)
        XCTAssertEqual(completed[0].id, task.id)
        XCTAssertEqual(backlogs.count, 1)
        XCTAssertEqual(backlogs[0].title, "R1")
        XCTAssertNil(backlogs[0].externalReminderID, "Clone ohne Kalender-Reminder")
        XCTAssertEqual(task.recurringCloneID, backlogs[0].id)
    }

    func testUncompleteRecurringRemovesClone() async throws {
        let vm = DailyFocusViewModel(
            modelContext: context,
            syncEngine: syncEngine,
            resetEngine: resetEngine
        )
        let recurring = try recurringCategory()
        let backlog = TestModelContainer.createBacklog(in: context, title: "B2")
        let task = backlog.addTask(title: "R2")
        task.category = recurring
        task.moveToDailyFocus(date: Calendar.current.startOfDay(for: Date()))
        try context.save()

        await vm.completeTask(task)
        XCTAssertNotNil(task.recurringCloneID)

        await vm.uncompleteTask(task)

        let all = try context.fetch(FetchDescriptor<Task>())
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all[0].id, task.id)
        XCTAssertEqual(task.status, .dailyFocus)
        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.recurringCloneID)
    }

    func testDoubleCompleteRecurringYieldsTwoCompletedEntries() async throws {
        let vm = DailyFocusViewModel(
            modelContext: context,
            syncEngine: syncEngine,
            resetEngine: resetEngine
        )
        let recurring = try recurringCategory()
        let backlog = TestModelContainer.createBacklog(in: context, title: "B3")
        let t1 = backlog.addTask(title: "Doppelt")
        t1.category = recurring
        t1.moveToDailyFocus(date: Calendar.current.startOfDay(for: Date()))
        try context.save()

        await vm.completeTask(t1)
        var clone1 = try XCTUnwrap(try findTask(id: t1.recurringCloneID!))
        clone1.moveToDailyFocus(date: Calendar.current.startOfDay(for: Date()))
        try context.save()

        await vm.completeTask(clone1)

        let all = try context.fetch(FetchDescriptor<Task>())
        XCTAssertEqual(all.filter { $0.status == .completed }.count, 2)
        XCTAssertEqual(all.filter { $0.status == .inBacklog }.count, 1)
    }

    private func findTask(id: UUID) throws -> Task? {
        var d = FetchDescriptor<Task>(predicate: #Predicate { $0.id == id })
        d.fetchLimit = 1
        return try context.fetch(d).first
    }

    /// `Task.isRecurring` leitet von `Category.isRecurring` ab
    func testTaskIsRecurringInheritsFromCategory() throws {
        let rec = try recurringCategory()
        let backlog = TestModelContainer.createBacklog(in: context, title: "B-inherit")
        let task = backlog.addTask(title: "T")
        task.category = rec
        XCTAssertTrue(task.isRecurring)
        task.category = nil
        XCTAssertFalse(task.isRecurring)
    }
}
