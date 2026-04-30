// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  TaskModelTests.swift
//  DawnyTests
//
//  Unit Tests für das Task Model
//

import XCTest
import SwiftData
@testable import Dawny

final class TaskModelTests: XCTestCase {
    
    // MARK: - Creation Tests
    
    func testTaskCreation() throws {
        let backlogID = UUID()
        let task = Task(title: "Test Task", parentBacklogID: backlogID)
        
        XCTAssertEqual(task.title, "Test Task")
        XCTAssertEqual(task.status, .inBacklog)
        XCTAssertFalse(task.isCompleted)
        XCTAssertEqual(task.parentBacklogID, backlogID)
        XCTAssertNil(task.scheduledDate)
        XCTAssertNil(task.externalReminderID)
        XCTAssertNil(task.notes)
    }
    
    func testTaskCreationWithAllParameters() throws {
        let backlogID = UUID()
        let scheduledDate = Date()
        let reminderID = "reminder-123"
        
        let task = Task(
            title: "Full Task",
            notes: "Some notes",
            status: .dailyFocus,
            parentBacklogID: backlogID,
            scheduledDate: scheduledDate,
            externalReminderID: reminderID
        )
        
        XCTAssertEqual(task.title, "Full Task")
        XCTAssertEqual(task.notes, "Some notes")
        XCTAssertEqual(task.status, .dailyFocus)
        XCTAssertEqual(task.scheduledDate, scheduledDate)
        XCTAssertEqual(task.externalReminderID, reminderID)
    }
    
    // MARK: - Complete Tests
    
    func testComplete() throws {
        let task = Task(title: "Test", parentBacklogID: UUID())
        task.status = .dailyFocus
        
        task.complete()
        
        XCTAssertTrue(task.isCompleted)
        XCTAssertEqual(task.status, .completed)
    }
    
    // MARK: - Reset to Backlog Tests
    
    func testResetToBacklog() throws {
        let task = Task(title: "Test", parentBacklogID: UUID())
        task.status = .dailyFocus
        task.scheduledDate = Date()
        
        task.resetToBacklog()
        
        XCTAssertEqual(task.status, .inBacklog)
        XCTAssertNil(task.scheduledDate)
    }
    
    // MARK: - Move to Daily Focus Tests
    
    func testMoveToDailyFocus() throws {
        let task = Task(title: "Test", parentBacklogID: UUID())
        let today = Calendar.current.startOfDay(for: Date())
        
        task.moveToDailyFocus(date: today)
        
        XCTAssertEqual(task.status, .dailyFocus)
        XCTAssertEqual(task.scheduledDate, today)
    }
    
    // MARK: - Needs Reset Tests
    
    func testNeedsResetTrue() throws {
        let task = Task(title: "Test", parentBacklogID: UUID())
        task.status = .dailyFocus
        task.isCompleted = false
        
        XCTAssertTrue(task.needsReset)
    }
    
    func testNeedsResetFalseWhenCompleted() throws {
        let task = Task(title: "Test", parentBacklogID: UUID())
        task.status = .dailyFocus
        task.complete()
        
        XCTAssertFalse(task.needsReset)
    }
    
    func testNeedsResetFalseWhenInBacklog() throws {
        let task = Task(title: "Test", parentBacklogID: UUID())
        task.status = .inBacklog
        
        XCTAssertFalse(task.needsReset)
    }
    
    // MARK: - Calendar Sync Tests
    
    func testShouldSyncToCalendar() throws {
        let task = Task(title: "Test", parentBacklogID: UUID())
        
        task.status = .inBacklog
        XCTAssertFalse(task.shouldSyncToCalendar)
        
        task.status = .dailyFocus
        XCTAssertTrue(task.shouldSyncToCalendar)
        
        task.status = .completed
        XCTAssertFalse(task.shouldSyncToCalendar)
    }
    
    func testIsSyncedToCalendar() throws {
        let task = Task(title: "Test", parentBacklogID: UUID())
        
        XCTAssertFalse(task.isSyncedToCalendar)
        
        task.externalReminderID = "reminder-123"
        XCTAssertTrue(task.isSyncedToCalendar)
        
        task.unlinkFromCalendar()
        XCTAssertFalse(task.isSyncedToCalendar)
    }
    
    // MARK: - Link/Unlink Calendar Tests
    
    func testLinkToCalendar() throws {
        let task = Task(title: "Test", parentBacklogID: UUID())
        
        task.linkToCalendar(reminderID: "reminder-456")
        
        XCTAssertEqual(task.externalReminderID, "reminder-456")
    }
    
    func testUnlinkFromCalendar() throws {
        let task = Task(title: "Test", parentBacklogID: UUID())
        task.externalReminderID = "reminder-123"
        
        task.unlinkFromCalendar()
        
        XCTAssertNil(task.externalReminderID)
    }
    
    // MARK: - Schedule Tests
    
    func testScheduleFor() throws {
        let task = Task(title: "Test", parentBacklogID: UUID())
        let futureDate = Date(timeIntervalSinceNow: 86400 * 7)
        
        task.scheduleFor(date: futureDate)
        
        XCTAssertEqual(task.status, .scheduled)
        XCTAssertEqual(task.scheduledDate, futureDate)
    }

}
