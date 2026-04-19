// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  CategoryServiceTests.swift
//  DawnyTests
//
//  Unit Tests für die Kategorie-Edit-Operationen im CategoryService.
//

import XCTest
import SwiftData
@testable import Dawny

@MainActor
final class CategoryServiceTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var service: CategoryService!

    /// Default-Typ-Wert vor dem Test, um nach jedem Test wiederherzustellen.
    private var originalDefaultCategoryType: TaskCategory!

    override func setUp() async throws {
        container = try TestModelContainer.create()
        context = container.mainContext
        service = CategoryService(modelContext: context)
        service.initializeDefaultCategories()

        originalDefaultCategoryType = AppSettings.shared.defaultCategoryType
    }

    override func tearDown() async throws {
        AppSettings.shared.defaultCategoryType = originalDefaultCategoryType
        container = nil
        context = nil
        service = nil
    }

    // MARK: - Helpers

    private func category(_ type: TaskCategory) throws -> Dawny.Category {
        let cat = service.getCategory(type: type)
        return try XCTUnwrap(cat, "Erwartete Kategorie \(type) nicht gefunden")
    }

    private func makeBacklog() -> Backlog {
        TestModelContainer.createBacklog(in: context, title: "Test Backlog")
    }

    @discardableResult
    private func makeTask(in backlog: Backlog, category: Dawny.Category, title: String = "T") -> Task {
        let task = TestModelContainer.createTask(
            in: context,
            title: title,
            status: .inBacklog,
            backlog: backlog
        )
        task.category = category
        try? context.save()
        return task
    }

    // MARK: - Rename

    func testRenameTrimsWhitespaceAndMarksCustomized() throws {
        let cat = try category(.thisWeek)
        XCTAssertFalse(cat.isNameCustomized)

        try service.rename(cat, to: "  Wichtig  ")

        XCTAssertEqual(cat.name, "Wichtig")
        XCTAssertTrue(cat.isNameCustomized)
        XCTAssertEqual(cat.displayName, "Wichtig")
    }

    func testRenameEmptyThrows() throws {
        let cat = try category(.thisWeek)

        XCTAssertThrowsError(try service.rename(cat, to: "   ")) { error in
            guard case CategoryEditError.nameEmpty = error else {
                return XCTFail("Erwartet .nameEmpty, war \(error)")
            }
        }
        XCTAssertFalse(cat.isNameCustomized)
    }

    func testRenameTooLongThrows() throws {
        let cat = try category(.thisWeek)
        let tooLong = String(repeating: "x", count: CategoryService.maxNameLength + 1)

        XCTAssertThrowsError(try service.rename(cat, to: tooLong)) { error in
            guard case CategoryEditError.nameTooLong = error else {
                return XCTFail("Erwartet .nameTooLong, war \(error)")
            }
        }
    }

    func testRenameUncategorizedThrowsProtected() throws {
        let cat = try category(.uncategorized)

        XCTAssertThrowsError(try service.rename(cat, to: "Andere")) { error in
            guard case CategoryEditError.protectedFromRename = error else {
                return XCTFail("Erwartet .protectedFromRename, war \(error)")
            }
        }
    }

    func testRenameQuickIsAllowed() throws {
        // .quick darf umbenannt werden, nur Löschen ist gesperrt.
        let cat = try category(.quick)

        try service.rename(cat, to: "Sofort")

        XCTAssertEqual(cat.displayName, "Sofort")
        XCTAssertTrue(cat.isNameCustomized)
    }

    // MARK: - Update Icon

    func testUpdateIconMarksCustomized() throws {
        let cat = try category(.thisWeek)
        XCTAssertFalse(cat.isIconCustomized)

        try service.updateIcon(cat, to: "star.fill")

        XCTAssertEqual(cat.iconName, "star.fill")
        XCTAssertTrue(cat.isIconCustomized)
        XCTAssertEqual(cat.displayIconName, "star.fill")
    }

    func testUpdateIconEmptyResetsCustomFlag() throws {
        let cat = try category(.thisWeek)
        try service.updateIcon(cat, to: "star.fill")
        XCTAssertTrue(cat.isIconCustomized)

        try service.updateIcon(cat, to: "")

        XCTAssertFalse(cat.isIconCustomized)
        // Display fällt auf Default zurück
        XCTAssertEqual(cat.displayIconName, TaskCategory.thisWeek.iconName)
    }

    func testUpdateIconUncategorizedThrowsProtected() throws {
        let cat = try category(.uncategorized)

        XCTAssertThrowsError(try service.updateIcon(cat, to: "star.fill")) { error in
            guard case CategoryEditError.protectedFromIconChange = error else {
                return XCTFail("Erwartet .protectedFromIconChange, war \(error)")
            }
        }
    }

    // MARK: - Delete

    func testDeleteWithStrategyDeleteTasksRemovesTasks() throws {
        let backlog = makeBacklog()
        let cat = try category(.thisMonth)
        makeTask(in: backlog, category: cat, title: "A")
        makeTask(in: backlog, category: cat, title: "B")

        try service.delete(cat, strategy: .deleteTasks)

        // Kategorie weg
        let remaining = service.getCategoriesSorted()
        XCTAssertNil(remaining.first { $0.categoryType == .thisMonth })

        // Tasks weg
        let allTasks = try context.fetch(FetchDescriptor<Task>())
        XCTAssertTrue(allTasks.isEmpty, "Tasks sollten mitgelöscht sein")
    }

    func testDeleteWithStrategyMoveMovesTasksToUncategorized() throws {
        let backlog = makeBacklog()
        let cat = try category(.thisMonth)
        let uncat = try category(.uncategorized)
        makeTask(in: backlog, category: cat, title: "A")
        makeTask(in: backlog, category: cat, title: "B")

        try service.delete(cat, strategy: .moveToUncategorized)

        // Kategorie weg
        XCTAssertNil(service.getCategory(type: .thisMonth))

        // Tasks existieren weiterhin und gehören jetzt zu Uncategorized
        let allTasks = try context.fetch(FetchDescriptor<Task>())
        XCTAssertEqual(allTasks.count, 2)
        for task in allTasks {
            XCTAssertEqual(task.category?.id, uncat.id)
        }
    }

    func testDeleteUncategorizedThrowsProtected() throws {
        let cat = try category(.uncategorized)

        XCTAssertThrowsError(try service.delete(cat, strategy: .moveToUncategorized)) { error in
            guard case CategoryEditError.protectedFromDelete = error else {
                return XCTFail("Erwartet .protectedFromDelete, war \(error)")
            }
        }
    }

    func testDeleteQuickThrowsProtected() throws {
        let cat = try category(.quick)

        XCTAssertThrowsError(try service.delete(cat, strategy: .moveToUncategorized)) { error in
            guard case CategoryEditError.protectedFromDelete = error else {
                return XCTFail("Erwartet .protectedFromDelete, war \(error)")
            }
        }
    }

    func testDeleteResetsDefaultCategoryFallback() throws {
        AppSettings.shared.defaultCategoryType = .thisYear
        let cat = try category(.thisYear)

        try service.delete(cat, strategy: .moveToUncategorized)

        // Fallback ist .quick (immer existent, da nicht löschbar)
        XCTAssertEqual(AppSettings.shared.defaultCategoryType, .quick)
    }

    func testDeleteDoesNotChangeDefaultIfDifferentCategory() throws {
        AppSettings.shared.defaultCategoryType = .thisWeek
        let cat = try category(.thisMonth)

        try service.delete(cat, strategy: .moveToUncategorized)

        XCTAssertEqual(AppSettings.shared.defaultCategoryType, .thisWeek)
    }

    // MARK: - Display Properties

    func testDisplayNameFallsBackToLocalizedDefault() throws {
        let cat = try category(.someday)
        XCTAssertEqual(cat.displayName, TaskCategory.someday.displayName)
    }

    func testDisplayIconFallsBackToLocalizedDefault() throws {
        let cat = try category(.someday)
        XCTAssertEqual(cat.displayIconName, TaskCategory.someday.iconName)
    }

    // MARK: - Capability Flags

    func testCapabilityFlags() throws {
        let uncat = try category(.uncategorized)
        XCTAssertFalse(uncat.canRename)
        XCTAssertFalse(uncat.canChangeIcon)
        XCTAssertFalse(uncat.canDelete)
        XCTAssertFalse(uncat.hasAnyEditCapability)

        let quick = try category(.quick)
        XCTAssertTrue(quick.canRename)
        XCTAssertTrue(quick.canChangeIcon)
        XCTAssertFalse(quick.canDelete)
        XCTAssertTrue(quick.hasAnyEditCapability)

        let week = try category(.thisWeek)
        XCTAssertTrue(week.canRename)
        XCTAssertTrue(week.canChangeIcon)
        XCTAssertTrue(week.canDelete)
        XCTAssertTrue(week.hasAnyEditCapability)
    }
}
