// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  MakeItCountDailyFocusTests.swift
//  DawnyTests
//
//  Tests dass manuelles Zurücklegen von Heute → Backlog den resetCount auf 0 setzt.
//

import XCTest
import SwiftData
@testable import Dawny

@MainActor
final class MakeItCountDailyFocusTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var syncEngine: SyncEngine!
    var resetEngine: ResetEngine!
    var timeProvider: MockTimeProvider!
    var originalCalendarEnabled: Bool!

    override func setUp() async throws {
        try await super.setUp()
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

    func testManualRemoveFromDailyFocusResetsCounter() async throws {
        let vm = DailyFocusViewModel(
            modelContext: context,
            syncEngine: syncEngine,
            resetEngine: resetEngine
        )
        let backlog = TestModelContainer.createBacklog(in: context, title: "B")
        let task = TestModelContainer.createTask(in: context, title: "Task", status: .dailyFocus, backlog: backlog)

        // Simuliere dass der Task bereits 2 Mal nicht erledigt wurde
        task.resetCount = 2
        try context.save()

        await vm.removeFromDailyFocus(task)

        XCTAssertEqual(task.resetCount, 0, "Manuelles Zurücklegen soll resetCount auf 0 setzen")
        XCTAssertEqual(task.status, .inBacklog)
    }

    func testManualRemoveDoesNotArchiveTask() async throws {
        let vm = DailyFocusViewModel(
            modelContext: context,
            syncEngine: syncEngine,
            resetEngine: resetEngine
        )
        let backlog = TestModelContainer.createBacklog(in: context, title: "B")
        let task = TestModelContainer.createTask(in: context, title: "Task", status: .dailyFocus, backlog: backlog)
        task.resetCount = 99
        try context.save()

        await vm.removeFromDailyFocus(task)

        XCTAssertNotEqual(task.status, .archived, "Manuelles Zurücklegen darf nicht archivieren")
        XCTAssertEqual(task.status, .inBacklog)
    }
}
