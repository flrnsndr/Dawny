// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  ArchiveViewModelTests.swift
//  DawnyTests
//
//  Tests für ArchiveViewModel: Unarchivierung, Kategorie-Edge-Case, Löschen.
//

import XCTest
import SwiftData
@testable import Dawny

@MainActor
final class ArchiveViewModelTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var viewModel: ArchiveViewModel!

    override func setUp() async throws {
        try await super.setUp()
        container = try TestModelContainer.create()
        context = container.mainContext
        viewModel = ArchiveViewModel(modelContext: context)
    }

    override func tearDown() async throws {
        container = nil
        context = nil
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func makeArchivedTask(title: String = "Archived", category: Dawny.Category? = nil) -> Task {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: title, backlog: backlog)
        task.category = category
        task.archive()
        try? context.save()
        return task
    }

    private func makeCategory(type: TaskCategory = .someday) -> Dawny.Category {
        let service = CategoryService(modelContext: context)
        service.initializeDefaultCategories()
        if let cat = service.getCategoriesSorted().first(where: { $0.categoryType == type }) {
            return cat
        }
        let cat = Dawny.Category(categoryType: type)
        context.insert(cat)
        try? context.save()
        return cat
    }

    private func makeUncategorized() -> Dawny.Category {
        let service = CategoryService(modelContext: context)
        service.initializeDefaultCategories()
        return service.getCategoriesSorted().first(where: { $0.isUncategorized })!
    }

    // MARK: - Load Tests

    func testLoadArchivedTasksReturnsOnlyArchivedTasks() throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let archived = TestModelContainer.createTask(in: context, title: "Archived", backlog: backlog)
        archived.archive()
        _ = TestModelContainer.createTask(in: context, title: "Normal", status: .inBacklog, backlog: backlog)
        try context.save()

        viewModel.loadArchivedTasks()

        XCTAssertEqual(viewModel.archivedTasks.count, 1)
        XCTAssertEqual(viewModel.archivedTasks.first?.title, "Archived")
    }

    func testEmptyWhenNoArchivedTasks() throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        _ = TestModelContainer.createTask(in: context, title: "Normal", status: .inBacklog, backlog: backlog)
        try context.save()

        viewModel.loadArchivedTasks()

        XCTAssertTrue(viewModel.isEmpty)
    }

    // MARK: - Unarchive to Backlog

    func testUnarchiveToBacklogSetsStatusInBacklog() throws {
        let task = makeArchivedTask()

        viewModel.unarchiveToBacklog(taskID: task.id)

        XCTAssertEqual(task.status, .inBacklog)
    }

    func testUnarchiveToBacklogResetsResetCount() throws {
        let task = makeArchivedTask()
        task.resetCount = 5
        try context.save()

        viewModel.unarchiveToBacklog(taskID: task.id)

        XCTAssertEqual(task.resetCount, 0, "resetCount muss bei Unarchivierung auf 0 gesetzt werden")
    }

    func testUnarchiveToBacklogClearsArchivedAt() throws {
        let task = makeArchivedTask()

        viewModel.unarchiveToBacklog(taskID: task.id)

        XCTAssertNil(task.archivedAt)
    }

    func testUnarchiveToBacklogPreservesCategory() throws {
        let category = makeCategory()
        let task = makeArchivedTask(category: category)

        viewModel.unarchiveToBacklog(taskID: task.id)

        XCTAssertEqual(task.category?.id, category.id, "Kategorie muss nach Unarchivierung erhalten bleiben")
    }

    func testUnarchiveToBacklogRemovesFromArchivedList() throws {
        let task = makeArchivedTask()
        viewModel.loadArchivedTasks()
        XCTAssertEqual(viewModel.archivedTasks.count, 1)

        viewModel.unarchiveToBacklog(taskID: task.id)

        XCTAssertEqual(viewModel.archivedTasks.count, 0)
    }

    // MARK: - Unarchive to Daily Focus

    func testUnarchiveToDailyFocusSetsStatusDailyFocus() throws {
        let task = makeArchivedTask()

        viewModel.unarchiveToDailyFocus(taskID: task.id)

        XCTAssertEqual(task.status, .dailyFocus)
    }

    func testUnarchiveToDailyFocusResetsResetCount() throws {
        let task = makeArchivedTask()
        task.resetCount = 3
        try context.save()

        viewModel.unarchiveToDailyFocus(taskID: task.id)

        XCTAssertEqual(task.resetCount, 0)
    }

    func testUnarchiveToDailyFocusSetsScheduledDate() throws {
        let task = makeArchivedTask()

        viewModel.unarchiveToDailyFocus(taskID: task.id)

        XCTAssertNotNil(task.scheduledDate, "scheduledDate muss gesetzt sein wenn Task in DailyFocus")
    }

    // MARK: - Category Edge Case: Category deleted

    func testUnarchiveToBacklogAssignsUncategorizedWhenCategoryDeleted() throws {
        let category = makeCategory()
        let uncategorized = makeUncategorized()
        let task = makeArchivedTask(category: category)

        // Kategorie löschen
        context.delete(category)
        try context.save()

        viewModel.unarchiveToBacklog(taskID: task.id)

        XCTAssertEqual(
            task.category?.id,
            uncategorized.id,
            "Gelöschte Kategorie: Task soll in 'Unkategorisiert' landen"
        )
    }

    func testUnarchiveToDailyFocusAssignsUncategorizedWhenCategoryDeleted() throws {
        let category = makeCategory()
        let uncategorized = makeUncategorized()
        let task = makeArchivedTask(category: category)

        context.delete(category)
        try context.save()

        viewModel.unarchiveToDailyFocus(taskID: task.id)

        XCTAssertEqual(task.category?.id, uncategorized.id)
    }

    // MARK: - Delete

    func testDeleteTaskPermanentlyDeletesTask() throws {
        let task = makeArchivedTask()
        viewModel.loadArchivedTasks()
        XCTAssertEqual(viewModel.archivedTasks.count, 1)

        viewModel.deleteTask(taskID: task.id)

        viewModel.loadArchivedTasks()
        XCTAssertEqual(viewModel.archivedTasks.count, 0)

        let all = try context.fetch(FetchDescriptor<Task>())
        XCTAssertTrue(all.isEmpty, "Task muss permanent gelöscht worden sein")
    }
}
