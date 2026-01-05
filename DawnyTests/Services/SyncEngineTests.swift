//
//  SyncEngineTests.swift
//  DawnyTests
//
//  Unit Tests für die SyncEngine
//

import XCTest
import SwiftData
@testable import Dawny

@MainActor
final class SyncEngineTests: XCTestCase {
    
    var container: ModelContainer!
    var context: ModelContext!
    var calendarService: MockCalendarService!
    var syncEngine: SyncEngine!
    
    override func setUp() async throws {
        container = try TestModelContainer.create()
        context = container.mainContext
        calendarService = MockCalendarService()
        syncEngine = SyncEngine(calendarService: calendarService, modelContext: context)
        
        // Setze Kalender-Sync auf aktiviert für Tests
        AppSettings.shared.calendarSyncEnabled = true
    }
    
    override func tearDown() async throws {
        // Bereinige Settings nach jedem Test
        AppSettings.shared.calendarSyncEnabled = true
    }
    
    // MARK: - Create Reminder Tests
    
    func testSyncCreatesReminder() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test Task", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()
        
        await syncEngine.syncTaskToCalendar(task)
        
        XCTAssertEqual(calendarService.createCallCount, 1)
        XCTAssertNotNil(task.externalReminderID)
        XCTAssertEqual(calendarService.reminders.count, 1)
    }
    
    func testSyncDoesNotCreateReminderForBacklogTask() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test Task", status: .inBacklog, backlog: backlog)
        
        await syncEngine.syncTaskToCalendar(task)
        
        XCTAssertEqual(calendarService.createCallCount, 0)
        XCTAssertNil(task.externalReminderID)
    }
    
    // MARK: - Update Reminder Tests
    
    func testSyncUpdatesReminder() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Original Title", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()
        
        // Erstelle initial
        await syncEngine.syncTaskToCalendar(task)
        let reminderID = task.externalReminderID!
        
        // Ändere Task
        task.title = "Updated Title"
        
        // Sync nochmal
        await syncEngine.syncTaskToCalendar(task)
        
        XCTAssertEqual(calendarService.updateCallCount, 1)
        XCTAssertEqual(task.externalReminderID, reminderID)
    }
    
    // MARK: - Remove Reminder Tests
    
    func testSyncRemovesReminder() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()
        
        // Erstelle Reminder
        await syncEngine.syncTaskToCalendar(task)
        let reminderID = task.externalReminderID!
        XCTAssertNotNil(calendarService.reminders[reminderID])
        
        // Entferne Reminder
        await syncEngine.removeTaskFromCalendar(task)
        
        XCTAssertEqual(calendarService.deleteCallCount, 1)
        XCTAssertNil(calendarService.reminders[reminderID])
        XCTAssertNil(task.externalReminderID)
    }
    
    // MARK: - Sync All Tests
    
    func testSyncAllDailyFocusTasks() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task1 = TestModelContainer.createTask(in: context, title: "Task 1", status: .dailyFocus, backlog: backlog)
        let task2 = TestModelContainer.createTask(in: context, title: "Task 2", status: .dailyFocus, backlog: backlog)
        let task3 = TestModelContainer.createTask(in: context, title: "Backlog Task", status: .inBacklog, backlog: backlog)
        
        task1.scheduledDate = Date()
        task2.scheduledDate = Date()
        
        await syncEngine.syncAllDailyFocusTasks()
        
        XCTAssertEqual(calendarService.createCallCount, 2)
        XCTAssertNotNil(task1.externalReminderID)
        XCTAssertNotNil(task2.externalReminderID)
        XCTAssertNil(task3.externalReminderID)
    }
    
    // MARK: - Error Handling Tests
    
    func testSyncHandlesErrors() async throws {
        calendarService.shouldFailOperations = true
        
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()
        
        // Sollte nicht crashen
        await syncEngine.syncTaskToCalendar(task)
        
        XCTAssertNil(task.externalReminderID)
    }
    
    // MARK: - Edge Cases
    
    func testRemoveWithoutReminderID() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        
        // Sollte nicht crashen
        await syncEngine.removeTaskFromCalendar(task)
        
        XCTAssertEqual(calendarService.deleteCallCount, 0)
    }
    
    // MARK: - Settings Tests
    
    func testSyncRespectsCalendarSyncEnabled() async throws {
        // Deaktiviere Kalender-Sync
        AppSettings.shared.calendarSyncEnabled = false
        
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test Task", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()
        
        // Versuche zu synchronisieren
        await syncEngine.syncTaskToCalendar(task)
        
        // Sollte nicht synchronisiert werden
        XCTAssertEqual(calendarService.createCallCount, 0)
        XCTAssertNil(task.externalReminderID)
    }
    
    func testSyncAllRespectsCalendarSyncEnabled() async throws {
        // Deaktiviere Kalender-Sync
        AppSettings.shared.calendarSyncEnabled = false
        
        let backlog = TestModelContainer.createBacklog(in: context)
        let task1 = TestModelContainer.createTask(in: context, title: "Task 1", status: .dailyFocus, backlog: backlog)
        let task2 = TestModelContainer.createTask(in: context, title: "Task 2", status: .dailyFocus, backlog: backlog)
        
        task1.scheduledDate = Date()
        task2.scheduledDate = Date()
        
        // Versuche alle zu synchronisieren
        await syncEngine.syncAllDailyFocusTasks()
        
        // Sollte nicht synchronisiert werden
        XCTAssertEqual(calendarService.createCallCount, 0)
        XCTAssertNil(task1.externalReminderID)
        XCTAssertNil(task2.externalReminderID)
    }
}
