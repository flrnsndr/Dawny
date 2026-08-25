// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  CloudDeduplicatorTests.swift
//  DawnyTests
//
//  Deckt die Reparatur doppelt geseedeter Objekte nach einem CloudKit-Import ab.
//

import XCTest
import SwiftData
@testable import Dawny

@MainActor
final class CloudDeduplicatorTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() async throws {
        container = try TestModelContainer.create()
        context = container.mainContext
    }

    // MARK: - Helpers

    private func makeBacklog(title: String, createdAt: Date) -> Backlog {
        let backlog = Backlog(title: title, createdAt: createdAt)
        context.insert(backlog)
        return backlog
    }

    @discardableResult
    private func makeTask(title: String, in backlog: Backlog, category: Dawny.Category? = nil) -> Task {
        let task = Task(title: title, parentBacklogID: backlog.id, category: category)
        task.backlog = backlog
        context.insert(task)
        return task
    }

    private func makeCategory(
        type: TaskCategory,
        createdAt: Date,
        name: String? = nil,
        isNameCustomized: Bool = false,
        isIconCustomized: Bool = false,
        isRecurring: Bool = false,
        autoArchiveDays: Int? = nil
    ) -> Dawny.Category {
        let category = Dawny.Category(
            categoryType: type,
            name: name,
            orderIndex: 0,
            isUncategorized: type == .uncategorized,
            isNameCustomized: isNameCustomized,
            isIconCustomized: isIconCustomized,
            isRecurring: isRecurring,
            autoArchiveDays: autoArchiveDays,
            createdAt: createdAt
        )
        context.insert(category)
        return category
    }

    private func fetchBacklogs() throws -> [Backlog] {
        try context.fetch(FetchDescriptor<Backlog>()).filter { !$0.isDeleted }
    }

    private func fetchCategories() throws -> [Dawny.Category] {
        try context.fetch(FetchDescriptor<Dawny.Category>()).filter { !$0.isDeleted }
    }

    // MARK: - Backlogs

    func testDuplicateBacklogsAreMergedIntoOldest() throws {
        let older = makeBacklog(title: "Erstes", createdAt: Date(timeIntervalSince1970: 1_000))
        let newer = makeBacklog(title: "Zweites", createdAt: Date(timeIntervalSince1970: 2_000))
        makeTask(title: "A", in: older)
        makeTask(title: "B", in: newer)
        makeTask(title: "C", in: newer)
        try context.save()

        let changed = try CloudDeduplicator.dedupe(in: context)

        XCTAssertTrue(changed)
        let backlogs = try fetchBacklogs()
        XCTAssertEqual(backlogs.count, 1)
        XCTAssertEqual(backlogs.first?.id, older.id, "Das ältere Backlog gewinnt")

        let tasks = try context.fetch(FetchDescriptor<Task>()).filter { !$0.isDeleted }
        XCTAssertEqual(tasks.count, 3, "Kein Task darf beim Zusammenführen verloren gehen")
        for task in tasks {
            XCTAssertEqual(task.parentBacklogID, older.id)
            XCTAssertEqual(task.backlog?.id, older.id)
        }
    }

    // MARK: - Built-in categories

    func testDuplicateBuiltInCategoriesAreMerged() throws {
        let older = makeCategory(type: .quick, createdAt: Date(timeIntervalSince1970: 1_000))
        let newer = makeCategory(type: .quick, createdAt: Date(timeIntervalSince1970: 2_000))
        let backlog = makeBacklog(title: "B", createdAt: Date(timeIntervalSince1970: 500))
        makeTask(title: "A", in: backlog, category: older)
        makeTask(title: "B", in: backlog, category: newer)
        try context.save()

        try CloudDeduplicator.dedupe(in: context)

        let quickCategories = try fetchCategories().filter { $0.categoryType == .quick }
        XCTAssertEqual(quickCategories.count, 1)
        XCTAssertEqual(quickCategories.first?.id, older.id)
        XCTAssertEqual((quickCategories.first?.tasks ?? []).filter { !$0.isDeleted }.count, 2)
    }

    func testCustomizationOfLoserIsPreservedOnUncustomizedWinner() throws {
        let winner = makeCategory(type: .someday, createdAt: Date(timeIntervalSince1970: 1_000))
        _ = makeCategory(
            type: .someday,
            createdAt: Date(timeIntervalSince1970: 2_000),
            name: "Irgendwann mal",
            isNameCustomized: true,
            isIconCustomized: true,
            autoArchiveDays: 42
        )
        try context.save()

        try CloudDeduplicator.dedupe(in: context)

        let categories = try fetchCategories().filter { $0.categoryType == .someday }
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(winner.name, "Irgendwann mal")
        XCTAssertTrue(winner.isNameCustomized)
        XCTAssertTrue(winner.isIconCustomized)
        XCTAssertEqual(winner.autoArchiveDays, 42)
    }

    func testWinnerKeepsItsOwnCustomization() throws {
        let winner = makeCategory(
            type: .nextFewDays,
            createdAt: Date(timeIntervalSince1970: 1_000),
            name: "Gewinner",
            isNameCustomized: true
        )
        _ = makeCategory(
            type: .nextFewDays,
            createdAt: Date(timeIntervalSince1970: 2_000),
            name: "Verlierer",
            isNameCustomized: true
        )
        try context.save()

        try CloudDeduplicator.dedupe(in: context)

        XCTAssertEqual(winner.name, "Gewinner")
    }

    // MARK: - Default recurring category

    func testDuplicateDefaultRecurringCategoriesAreMerged() throws {
        let defaultName = String(
            localized: "category.recurring.default.name",
            defaultValue: "Recurring Tasks"
        )
        let older = makeCategory(
            type: .custom,
            createdAt: Date(timeIntervalSince1970: 1_000),
            name: defaultName,
            isRecurring: true
        )
        _ = makeCategory(
            type: .custom,
            createdAt: Date(timeIntervalSince1970: 2_000),
            name: defaultName,
            isRecurring: true
        )
        try context.save()

        try CloudDeduplicator.dedupe(in: context)

        let recurring = try fetchCategories().filter { $0.isRecurring }
        XCTAssertEqual(recurring.count, 1)
        XCTAssertEqual(recurring.first?.id, older.id)
    }

    func testUserCreatedCategoriesAreNeverMerged() throws {
        _ = makeCategory(
            type: .custom,
            createdAt: Date(timeIntervalSince1970: 1_000),
            name: "Garten",
            isNameCustomized: true
        )
        _ = makeCategory(
            type: .custom,
            createdAt: Date(timeIntervalSince1970: 2_000),
            name: "Garten",
            isNameCustomized: true
        )
        try context.save()

        let changed = try CloudDeduplicator.dedupe(in: context)

        XCTAssertFalse(changed, "Gleichnamige Custom-Kategorien sind zwei echte Kategorien")
        XCTAssertEqual(try fetchCategories().count, 2)
    }

    // MARK: - Idempotence

    func testSecondRunChangesNothing() throws {
        _ = makeBacklog(title: "A", createdAt: Date(timeIntervalSince1970: 1_000))
        _ = makeBacklog(title: "B", createdAt: Date(timeIntervalSince1970: 2_000))
        _ = makeCategory(type: .quick, createdAt: Date(timeIntervalSince1970: 1_000))
        _ = makeCategory(type: .quick, createdAt: Date(timeIntervalSince1970: 2_000))
        try context.save()

        XCTAssertTrue(try CloudDeduplicator.dedupe(in: context))
        XCTAssertFalse(try CloudDeduplicator.dedupe(in: context), "Ein zweiter Lauf darf nichts mehr ändern")
    }

    func testCleanStoreIsUntouched() throws {
        let backlog = makeBacklog(title: "A", createdAt: Date(timeIntervalSince1970: 1_000))
        let category = makeCategory(type: .quick, createdAt: Date(timeIntervalSince1970: 1_000))
        makeTask(title: "A", in: backlog, category: category)
        try context.save()

        XCTAssertFalse(try CloudDeduplicator.dedupe(in: context))
        XCTAssertEqual(try fetchBacklogs().count, 1)
        XCTAssertEqual(try fetchCategories().count, 1)
    }
}
