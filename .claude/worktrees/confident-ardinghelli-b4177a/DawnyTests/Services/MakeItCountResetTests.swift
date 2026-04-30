// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  MakeItCountResetTests.swift
//  DawnyTests
//
//  Tests für das Make it count Feature: ResetEngine archiviert non-recurring Tasks
//  nach Erreichen des Schwellwerts, recurring Tasks gehen immer zurück ins Backlog.
//

import XCTest
import SwiftData
@testable import Dawny

@MainActor
final class MakeItCountResetTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var timeProvider: MockTimeProvider!
    var calendarService: MockCalendarService!
    var syncEngine: SyncEngine!
    var resetEngine: ResetEngine!

    private var originalThreshold: Int!
    private var originalHasNewArchived: Bool!
    private var originalResetHour: Int!

    override func setUp() async throws {
        try await super.setUp()
        container = try TestModelContainer.create()
        context = container.mainContext
        timeProvider = MockTimeProvider()
        calendarService = MockCalendarService()
        syncEngine = SyncEngine(calendarService: calendarService, modelContext: context)
        resetEngine = ResetEngine(timeProvider: timeProvider, modelContext: context)
        resetEngine.syncEngine = syncEngine
        resetEngine.clearLastResetDate()

        originalThreshold = AppSettings.shared.makeItCountThreshold
        originalHasNewArchived = AppSettings.shared.hasNewArchivedTasks
        originalResetHour = AppSettings.shared.resetHour

        AppSettings.shared.resetHour = 3
        AppSettings.shared.makeItCountThreshold = 1
        AppSettings.shared.hasNewArchivedTasks = false
    }

    override func tearDown() async throws {
        AppSettings.shared.makeItCountThreshold = originalThreshold
        AppSettings.shared.hasNewArchivedTasks = originalHasNewArchived
        AppSettings.shared.resetHour = originalResetHour
        container = nil
        context = nil
        syncEngine = nil
        resetEngine = nil
        timeProvider = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func referenceDate() -> Date {
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        components.hour = 10
        return Calendar.current.date(from: components)!
    }

    private func makeRecurringCategory() -> Dawny.Category {
        let service = CategoryService(modelContext: context)
        service.initializeDefaultCategories()
        if let cat = service.getCategoriesSorted().first(where: { $0.isRecurring }) {
            return cat
        }
        let cat = Dawny.Category(categoryType: .quick, isRecurring: true)
        context.insert(cat)
        try? context.save()
        return cat
    }

    private func makeNonRecurringCategory() -> Dawny.Category {
        let service = CategoryService(modelContext: context)
        service.initializeDefaultCategories()
        if let cat = service.getCategoriesSorted().first(where: { !$0.isRecurring && !$0.isUncategorized }) {
            return cat
        }
        let cat = Dawny.Category(categoryType: .someday, isRecurring: false)
        context.insert(cat)
        try? context.save()
        return cat
    }

    // MARK: - Tests: Threshold = 1 (Standard)

    func testNonRecurringTaskArchivedAfterOneReset() async throws {
        AppSettings.shared.makeItCountThreshold = 1
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)

        await resetEngine.performReset(referenceDate: referenceDate())

        XCTAssertEqual(task.status, .archived, "Task sollte nach einem Reset archiviert sein (threshold=1)")
        XCTAssertNotNil(task.archivedAt)
        XCTAssertEqual(task.resetCount, 1)
        XCTAssertTrue(AppSettings.shared.hasNewArchivedTasks)
    }

    func testNonRecurringTaskGoesBackToBacklogBelowThreshold() async throws {
        AppSettings.shared.makeItCountThreshold = 2
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)

        await resetEngine.performReset(referenceDate: referenceDate())

        XCTAssertEqual(task.status, .inBacklog, "Task sollte bei threshold=2 nach erstem Reset ins Backlog gehen")
        XCTAssertEqual(task.resetCount, 1)
        XCTAssertFalse(AppSettings.shared.hasNewArchivedTasks)
    }

    func testNonRecurringTaskArchivedAfterReachingThreshold() async throws {
        AppSettings.shared.makeItCountThreshold = 2
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)

        // Erster Reset: ins Backlog (resetCount = 1)
        await resetEngine.performReset(referenceDate: referenceDate())
        XCTAssertEqual(task.status, .inBacklog)
        XCTAssertEqual(task.resetCount, 1)

        // Zweiter Reset: Task muss wieder in dailyFocus sein
        task.moveToDailyFocus(date: Date())
        try context.save()

        await resetEngine.performReset(referenceDate: referenceDate().addingTimeInterval(86400))
        XCTAssertEqual(task.status, .archived, "Task sollte nach threshold=2 Resets archiviert sein")
        XCTAssertEqual(task.resetCount, 2)
        XCTAssertTrue(AppSettings.shared.hasNewArchivedTasks)
    }

    // MARK: - Tests: Recurring Tasks

    func testRecurringTaskAlwaysGoesBackToBacklog() async throws {
        AppSettings.shared.makeItCountThreshold = 1
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Recurring", status: .dailyFocus, backlog: backlog)
        task.category = makeRecurringCategory()
        try context.save()

        await resetEngine.performReset(referenceDate: referenceDate())

        XCTAssertEqual(task.status, .inBacklog, "Wiederkehrender Task soll immer ins Backlog zurück")
        XCTAssertNil(task.archivedAt)
        XCTAssertFalse(AppSettings.shared.hasNewArchivedTasks)
    }

    func testRecurringTaskResetCountNotIncremented() async throws {
        AppSettings.shared.makeItCountThreshold = 1
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Recurring", status: .dailyFocus, backlog: backlog)
        task.category = makeRecurringCategory()
        try context.save()

        await resetEngine.performReset(referenceDate: referenceDate())

        XCTAssertEqual(task.resetCount, 0, "Wiederkehrender Task: resetCount darf nicht erhöht werden")
    }

    // MARK: - Tests: Mixed Tasks

    func testMixedRecurringAndNonRecurringReset() async throws {
        AppSettings.shared.makeItCountThreshold = 1
        let backlog = TestModelContainer.createBacklog(in: context)

        let recurring = TestModelContainer.createTask(in: context, title: "Recurring", status: .dailyFocus, backlog: backlog)
        recurring.category = makeRecurringCategory()

        let nonRecurring = TestModelContainer.createTask(in: context, title: "Normal", status: .dailyFocus, backlog: backlog)
        try context.save()

        await resetEngine.performReset(referenceDate: referenceDate())

        XCTAssertEqual(recurring.status, .inBacklog)
        XCTAssertEqual(nonRecurring.status, .archived)
        XCTAssertTrue(AppSettings.shared.hasNewArchivedTasks)
    }

    // MARK: - Tests: Dot Badge

    func testDotBadgeSetWhenTasksAreArchived() async throws {
        AppSettings.shared.makeItCountThreshold = 1
        AppSettings.shared.hasNewArchivedTasks = false
        let backlog = TestModelContainer.createBacklog(in: context)
        _ = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)

        await resetEngine.performReset(referenceDate: referenceDate())

        XCTAssertTrue(AppSettings.shared.hasNewArchivedTasks)
    }

    func testDotBadgeNotSetWhenNoTasksArchived() async throws {
        AppSettings.shared.makeItCountThreshold = 2
        AppSettings.shared.hasNewArchivedTasks = false
        let backlog = TestModelContainer.createBacklog(in: context)
        _ = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)

        await resetEngine.performReset(referenceDate: referenceDate())

        XCTAssertFalse(AppSettings.shared.hasNewArchivedTasks)
    }

    // MARK: - Tests: Missed Days count as single +1

    func testMissedDaysCountAsSingleReset() async throws {
        AppSettings.shared.makeItCountThreshold = 3
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)

        // Simuliere einen einzelnen Reset (auch wenn mehrere Tage verpasst wurden)
        await resetEngine.performReset(referenceDate: referenceDate())

        XCTAssertEqual(task.resetCount, 1, "Auch bei mehreren verpassten Tagen: nur +1 beim Reset")
        XCTAssertEqual(task.status, .inBacklog)
    }
}
