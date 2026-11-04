// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  TaskArchiveBadgeTests.swift
//  DawnyTests
//
//  Tests für Task.isNewInArchive(since:) — die Watermark-Logik der Archiv-Row-Dots.
//

import XCTest
import SwiftData
@testable import Dawny

@MainActor
final class TaskArchiveBadgeTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        try await super.setUp()
        container = try TestModelContainer.create()
        context = container.mainContext
    }

    override func tearDown() async throws {
        container = nil
        context = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    /// Erstellt einen archivierten Task mit explizitem Grund und Archivierungszeitpunkt.
    private func makeArchived(reason: ArchiveReason?, archivedAt: Date?) -> Task {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Task", backlog: backlog)
        task.archiveReason = reason
        task.archivedAt = archivedAt
        try? context.save()
        return task
    }

    // MARK: - Dot sichtbar (true)

    func testMakeItCountArchivedAfterVisitShowsDot() throws {
        let visit = Date()
        let task = makeArchived(reason: .makeItCount, archivedAt: visit.addingTimeInterval(60))

        XCTAssertTrue(task.isNewInArchive(since: visit))
    }

    func testAutoTidyArchivedAfterVisitShowsDot() throws {
        let visit = Date()
        let task = makeArchived(reason: .autoTidy, archivedAt: visit.addingTimeInterval(60))

        XCTAssertTrue(task.isNewInArchive(since: visit))
    }

    // MARK: - Kein Dot (false)

    func testArchivedBeforeVisitShowsNoDot() throws {
        let visit = Date()
        let task = makeArchived(reason: .makeItCount, archivedAt: visit.addingTimeInterval(-60))

        XCTAssertFalse(task.isNewInArchive(since: visit))
    }

    func testArchivedExactlyAtVisitShowsNoDot() throws {
        let visit = Date()
        let task = makeArchived(reason: .makeItCount, archivedAt: visit)

        // Strikt größer: Gleichstand zählt als bereits gesehen.
        XCTAssertFalse(task.isNewInArchive(since: visit))
    }

    func testManualArchiveNeverShowsDot() throws {
        let visit = Date()
        let task = makeArchived(reason: .manual, archivedAt: visit.addingTimeInterval(60))

        XCTAssertFalse(task.isNewInArchive(since: visit))
    }

    func testMissingReasonShowsNoDot() throws {
        let visit = Date()
        let task = makeArchived(reason: nil, archivedAt: visit.addingTimeInterval(60))

        XCTAssertFalse(task.isNewInArchive(since: visit))
    }

    func testMissingArchivedAtShowsNoDot() throws {
        let visit = Date()
        let task = makeArchived(reason: .makeItCount, archivedAt: nil)

        XCTAssertFalse(task.isNewInArchive(since: visit))
    }
}
