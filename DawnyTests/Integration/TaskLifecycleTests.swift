//
//  TaskLifecycleTests.swift
//  DawnyTests
//
//  Integration Tests für den vollständigen Task-Lifecycle
//

import XCTest
import SwiftData
@testable import Dawny

@MainActor
final class TaskLifecycleTests: XCTestCase {
    
    var container: ModelContainer!
    var context: ModelContext!
    var timeProvider: MockTimeProvider!
    var calendarService: MockCalendarService!
    var syncEngine: SyncEngine!
    var resetEngine: ResetEngine!
    
    override func setUp() async throws {
        container = try TestModelContainer.create()
        context = container.mainContext
        timeProvider = MockTimeProvider()
        calendarService = MockCalendarService()
        syncEngine = SyncEngine(calendarService: calendarService, modelContext: context)
        resetEngine = ResetEngine(timeProvider: timeProvider, modelContext: context)
        resetEngine.syncEngine = syncEngine
        resetEngine.clearLastResetDate()
    }
    
    // MARK: - Full Lifecycle Tests
    
    func testFullTaskLifecycle() async throws {
        // 1. Erstelle Backlog und Task
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = backlog.addTask(title: "Lifecycle Test Task")
        try context.save()
        
        XCTAssertEqual(task.status, .inBacklog)
        XCTAssertNil(task.externalReminderID)
        
        // 2. Verschiebe zu Daily Focus
        let today = Calendar.current.startOfDay(for: Date())
        task.moveToDailyFocus(date: today)
        try context.save()
        
        XCTAssertEqual(task.status, .dailyFocus)
        XCTAssertEqual(task.scheduledDate, today)
        
        // 3. Sync zu Kalender
        await syncEngine.syncTaskToCalendar(task)
        
        XCTAssertNotNil(task.externalReminderID)
        XCTAssertEqual(calendarService.reminders.count, 1)
        
        // 4. Task abschließen
        task.complete()
        try context.save()
        
        XCTAssertEqual(task.status, .completed)
        XCTAssertTrue(task.isCompleted)
    }
    
    func testTaskResetCycle() async throws {
        // Setup
        let day1_10am = MockTimeProvider.createDate(year: 2025, month: 1, day: 15, hour: 10)
        timeProvider.setCurrentDate(day1_10am)
        
        // 1. Erstelle Task und verschiebe zu Daily Focus
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = backlog.addTask(title: "Reset Cycle Task")
        task.moveToDailyFocus(date: Calendar.current.startOfDay(for: day1_10am))
        try context.save()
        
        // 2. Sync zu Kalender
        await syncEngine.syncTaskToCalendar(task)
        let reminderID = task.externalReminderID
        XCTAssertNotNil(reminderID)
        
        // 3. Zeit vorspulen: Nächster Tag 10:00
        let day2_10am = MockTimeProvider.createDate(year: 2025, month: 1, day: 16, hour: 10)
        timeProvider.setCurrentDate(day2_10am)
        
        // 4. Reset durchführen
        await resetEngine.performReset(referenceDate: day2_10am)
        
        XCTAssertEqual(task.status, .inBacklog)
        XCTAssertNil(task.scheduledDate)
        
        // 5. Wieder zu Daily Focus hinzufügen
        task.moveToDailyFocus(date: Calendar.current.startOfDay(for: day2_10am))
        try context.save()
        
        await syncEngine.syncTaskToCalendar(task)
        
        XCTAssertEqual(task.status, .dailyFocus)
        XCTAssertNotNil(task.externalReminderID)
    }
    
    func testMultipleTasksInDailyFocus() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        
        // Erstelle mehrere Tasks
        var tasks: [Task] = []
        for i in 1...5 {
            let task = backlog.addTask(title: "Task \(i)")
            task.moveToDailyFocus(date: Date())
            tasks.append(task)
        }
        try context.save()
        
        // Sync alle
        await syncEngine.syncAllDailyFocusTasks()
        
        XCTAssertEqual(calendarService.reminders.count, 5)
        
        // Alle sollten Reminder IDs haben
        for task in tasks {
            XCTAssertNotNil(task.externalReminderID)
        }
        
        // Schließe einige ab
        tasks[0].complete()
        tasks[2].complete()
        tasks[4].complete()
        try context.save()
        
        XCTAssertEqual(tasks.filter { $0.isCompleted }.count, 3)
        XCTAssertEqual(tasks.filter { !$0.isCompleted }.count, 2)
    }
    
    func testMoveBackToBacklog() async throws {
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = backlog.addTask(title: "Move Back Task")
        task.moveToDailyFocus(date: Date())
        try context.save()
        
        await syncEngine.syncTaskToCalendar(task)
        let reminderID = task.externalReminderID!
        
        // Zurück ins Backlog
        await syncEngine.removeTaskFromCalendar(task)
        task.resetToBacklog()
        try context.save()
        
        XCTAssertEqual(task.status, .inBacklog)
        XCTAssertNil(task.externalReminderID)
        XCTAssertNil(calendarService.reminders[reminderID])
    }
}
