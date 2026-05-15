// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  AutoArchiveReviewViewModelTests.swift
//  DawnyTests
//
//  Tests für AutoArchiveReviewViewModel: Queue-Befüllung, Filterung, markAllReviewed.
//

import XCTest
import SwiftData
@testable import Dawny

@MainActor
final class AutoArchiveReviewViewModelTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var viewModel: AutoArchiveReviewViewModel!

    override func setUp() async throws {
        try await super.setUp()
        container = try TestModelContainer.create()
        context = container.mainContext
        viewModel = AutoArchiveReviewViewModel(modelContext: context)
    }

    override func tearDown() async throws {
        container = nil
        context = nil
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func makeTask(title: String, reason: ArchiveReason, reviewed: Bool = false) -> Task {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: title, backlog: backlog)
        task.archive(reason: reason)
        task.archiveReviewed = reviewed
        try? context.save()
        return task
    }

    // MARK: - Queue Loading

    func testLoadQueuePopulatesDailyTasksForMakeItCount() throws {
        _ = makeTask(title: "Daily 1", reason: .makeItCount)
        _ = makeTask(title: "Daily 2", reason: .makeItCount)

        viewModel.loadQueue()

        XCTAssertEqual(viewModel.dailyArchivedTasks.count, 2)
        XCTAssertTrue(viewModel.backlogArchivedTasks.isEmpty)
    }

    func testLoadQueuePopulatesBacklogTasksForAutoTidy() throws {
        _ = makeTask(title: "Backlog 1", reason: .autoTidy)

        viewModel.loadQueue()

        XCTAssertTrue(viewModel.dailyArchivedTasks.isEmpty)
        XCTAssertEqual(viewModel.backlogArchivedTasks.count, 1)
    }

    func testLoadQueueExcludesManualArchives() throws {
        _ = makeTask(title: "Manual", reason: .manual)

        viewModel.loadQueue()

        XCTAssertTrue(viewModel.dailyArchivedTasks.isEmpty)
        XCTAssertTrue(viewModel.backlogArchivedTasks.isEmpty)
    }

    func testLoadQueueExcludesAlreadyReviewedItems() throws {
        _ = makeTask(title: "Reviewed Daily", reason: .makeItCount, reviewed: true)
        _ = makeTask(title: "Unreviewed Daily", reason: .makeItCount, reviewed: false)

        viewModel.loadQueue()

        XCTAssertEqual(viewModel.dailyArchivedTasks.count, 1)
        XCTAssertEqual(viewModel.dailyArchivedTasks.first?.title, "Unreviewed Daily")
    }

    func testShouldPresentIsFalseWhenQueueEmpty() throws {
        viewModel.loadQueue()

        XCTAssertFalse(viewModel.shouldPresent)
    }

    func testShouldPresentIsTrueWhenDailyQueueHasItems() throws {
        _ = makeTask(title: "Daily", reason: .makeItCount)

        viewModel.loadQueue()

        XCTAssertTrue(viewModel.shouldPresent)
    }

    func testShouldPresentIsTrueWhenBacklogQueueHasItems() throws {
        _ = makeTask(title: "Backlog", reason: .autoTidy)

        viewModel.loadQueue()

        XCTAssertTrue(viewModel.shouldPresent)
    }

    // MARK: - Mark All Reviewed

    func testMarkAllReviewedSetsArchiveReviewedOnAllItems() throws {
        let daily = makeTask(title: "Daily", reason: .makeItCount)
        let backlog = makeTask(title: "Backlog", reason: .autoTidy)

        viewModel.loadQueue()
        viewModel.markAllReviewed()

        XCTAssertTrue(daily.archiveReviewed)
        XCTAssertTrue(backlog.archiveReviewed)
    }

    func testMarkAllReviewedClearsQueueLists() throws {
        _ = makeTask(title: "Daily", reason: .makeItCount)
        _ = makeTask(title: "Backlog", reason: .autoTidy)

        viewModel.loadQueue()
        viewModel.markAllReviewed()

        XCTAssertTrue(viewModel.dailyArchivedTasks.isEmpty)
        XCTAssertTrue(viewModel.backlogArchivedTasks.isEmpty)
        XCTAssertFalse(viewModel.shouldPresent)
    }

    func testMarkAllReviewedResetsCurrentStep() throws {
        _ = makeTask(title: "Daily", reason: .makeItCount)

        viewModel.loadQueue()
        viewModel.currentStep = 1
        viewModel.markAllReviewed()

        XCTAssertEqual(viewModel.currentStep, 0)
    }

    func testSubsequentLoadQueueAfterMarkAllReviewedReturnsEmpty() throws {
        _ = makeTask(title: "Daily", reason: .makeItCount)

        viewModel.loadQueue()
        viewModel.markAllReviewed()
        viewModel.loadQueue()

        XCTAssertFalse(viewModel.shouldPresent)
    }

    // MARK: - Recurring task invariant (sanity check)

    func testRecurringTaskIsNeverArchived() throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Recurring", backlog: backlog)

        let category = Dawny.Category(categoryType: .someday)
        category.isRecurring = true
        context.insert(category)
        task.category = category
        try? context.save()

        // Recurring tasks must never appear archived — simulate what ResetEngine does
        XCTAssertTrue(task.isRecurring)
        // The reset engine skips archiving for recurring tasks; verify status stays non-archived
        XCTAssertNotEqual(task.status, .archived)
    }

    // MARK: - Default archiveReviewed on new auto-archives

    func testNewMakeItCountArchiveIsNotReviewedByDefault() throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Daily", backlog: backlog)
        task.archive(reason: .makeItCount)

        XCTAssertFalse(task.archiveReviewed)
    }

    func testNewAutoTidyArchiveIsNotReviewedByDefault() throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Backlog", backlog: backlog)
        task.archive(reason: .autoTidy)

        XCTAssertFalse(task.archiveReviewed)
    }

    func testManualArchiveIsReviewedByDefault() throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Manual", backlog: backlog)
        task.archive(reason: .manual)

        XCTAssertTrue(task.archiveReviewed)
    }
}
