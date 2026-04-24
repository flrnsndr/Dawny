// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  BacklogViewModelPlacementTests.swift
//  DawnyTests
//
//  Unit Tests für TaskPlacement / Quick-Entry-Sortierung im BacklogViewModel.
//

import XCTest
import SwiftData
@testable import Dawny

@MainActor
final class BacklogViewModelPlacementTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var calendarService: MockCalendarService!
    var syncEngine: SyncEngine!
    var viewModel: BacklogViewModel!

    private var originalShowCategories: Bool!

    override func setUp() async throws {
        container = try TestModelContainer.create()
        context = container.mainContext
        calendarService = MockCalendarService()
        syncEngine = SyncEngine(calendarService: calendarService, modelContext: context)
        viewModel = BacklogViewModel(modelContext: context, syncEngine: syncEngine)

        let categoryService = CategoryService(modelContext: context)
        categoryService.initializeDefaultCategories()

        originalShowCategories = AppSettings.shared.showCategories
        AppSettings.shared.showCategories = true
    }

    override func tearDown() async throws {
        AppSettings.shared.showCategories = originalShowCategories
        viewModel = nil
        syncEngine = nil
        calendarService = nil
        context = nil
        container = nil
    }

    private func category(_ type: TaskCategory) throws -> Dawny.Category {
        let service = CategoryService(modelContext: context)
        return try XCTUnwrap(service.getCategory(type: type))
    }

    /// `sorted()` der Backlog-Tasks: höhere `sortPriority` steht weiter oben.
    private func backlogOrderTitles(backlog: Backlog) -> [String] {
        backlog.backlogTasks.sorted().map(\.title)
    }

    func testAddTask_bottomPlacement_appendsAtEndOfCategory() throws {
        let backlog = try XCTUnwrap(viewModel.currentBacklog)
        let cat = try category(.nextFewDays)

        let base = Date()
        let t1 = backlog.addTask(title: "Zuerst")
        t1.category = cat
        t1.sortPriority = base.addingTimeInterval(200)

        let t2 = backlog.addTask(title: "Zweites")
        t2.category = cat
        t2.sortPriority = base.addingTimeInterval(100)

        try context.save()

        let newTask = try XCTUnwrap(
            viewModel.addTask(title: "Neu unten", category: cat, placement: .bottomOfCategory)
        )
        XCTAssertEqual(newTask.title, "Neu unten")

        let order = backlogOrderTitles(backlog: backlog)
        XCTAssertEqual(order, ["Zuerst", "Zweites", "Neu unten"])
        XCTAssert(newTask.sortPriority < t2.sortPriority)
    }

    func testAddTask_whitespaceOnly_returnsNil() {
        XCTAssertNil(viewModel.addTask(title: "   \n\t", category: nil, placement: .bottomOfCategory))
    }

    func testAddTask_sequential_bottom_createsDistinctTasks() throws {
        let backlog = try XCTUnwrap(viewModel.currentBacklog)
        let cat = try category(.quick)

        for i in 1...3 {
            _ = viewModel.addTask(title: "Task \(i)", category: cat, placement: .bottomOfCategory)
        }

        XCTAssertEqual(backlog.backlogTasks.count, 3)
        let titles = Set(backlog.backlogTasks.map(\.title))
        XCTAssertEqual(titles, ["Task 1", "Task 2", "Task 3"])
    }
}
