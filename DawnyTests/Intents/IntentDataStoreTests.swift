// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

import SwiftData
import XCTest
@testable import Dawny

@MainActor
final class IntentDataStoreTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var categoryService: CategoryService!

    override func setUp() async throws {
        UserDefaults.standard.removeObject(forKey: "DawnyMigratedRecurringDefaultBeforeUncategorizedV1")
        UserDefaults.standard.removeObject(forKey: "DawnyMigratedRecurringDefaultBeforeSomedayV2")

        container = try TestModelContainer.create()
        context = container.mainContext
        categoryService = IntentDataStore.initializeCategories(in: context)
    }

    override func tearDown() async throws {
        categoryService = nil
        context = nil
        container = nil
    }

    func testAddTaskWithoutCategoryUsesUncategorized() throws {
        let task = try IntentDataStore.addTask(
            title: "Briefkasten leeren",
            categoryID: nil,
            status: .inBacklog,
            in: context
        )

        XCTAssertEqual(task.title, "Briefkasten leeren")
        XCTAssertEqual(task.status, .inBacklog)
        XCTAssertTrue(task.category?.isUncategorized == true)
    }

    func testAddTaskWithCustomCategory() throws {
        let category = try categoryService.createCustom(name: "Haushalt")

        let task = try IntentDataStore.addTask(
            title: "Briefkasten leeren",
            categoryID: category.id,
            status: .inBacklog,
            in: context
        )

        XCTAssertEqual(task.category?.id, category.id)
        XCTAssertEqual(task.category?.displayName, "Haushalt")
    }

    func testAddTaskForTodaySetsDailyFocusDate() throws {
        let task = try IntentDataStore.addTask(
            title: "Einkaufen",
            categoryID: nil,
            status: .dailyFocus,
            in: context
        )

        XCTAssertEqual(task.status, .dailyFocus)
        XCTAssertNotNil(task.scheduledDate)
        XCTAssertTrue(Calendar.current.isDateInToday(try XCTUnwrap(task.scheduledDate)))
    }

    func testMoveTaskToToday() throws {
        let task = try IntentDataStore.addTask(
            title: "Briefkasten leeren",
            categoryID: nil,
            status: .inBacklog,
            in: context
        )

        let movedTask = try IntentDataStore.moveTaskToToday(taskID: task.id, in: context)

        XCTAssertEqual(movedTask.status, .dailyFocus)
        XCTAssertNotNil(movedTask.scheduledDate)
        XCTAssertTrue(Calendar.current.isDateInToday(try XCTUnwrap(movedTask.scheduledDate)))
    }

    func testCompleteTask() throws {
        let task = try IntentDataStore.addTask(
            title: "Briefkasten leeren",
            categoryID: nil,
            status: .dailyFocus,
            in: context
        )

        let completedTask = try IntentDataStore.completeTask(taskID: task.id, in: context)

        XCTAssertTrue(completedTask.isCompleted)
        XCTAssertEqual(completedTask.status, .completed)
    }

    func testTodayTasksOnlyReturnsOpenDailyFocusTasks() throws {
        _ = try IntentDataStore.addTask(title: "Backlog", categoryID: nil, status: .inBacklog, in: context)
        _ = try IntentDataStore.addTask(title: "Heute", categoryID: nil, status: .dailyFocus, in: context)
        let completed = try IntentDataStore.addTask(title: "Fertig", categoryID: nil, status: .dailyFocus, in: context)
        _ = try IntentDataStore.completeTask(taskID: completed.id, in: context)

        let todayTasks = try IntentDataStore.todayTasks(in: context)

        XCTAssertEqual(todayTasks.map(\.title), ["Heute"])
    }
}
