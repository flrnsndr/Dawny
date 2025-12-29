//
//  ResetEngineTests.swift
//  DawnTests
//
//  Unit Tests für die ResetEngine
//

import XCTest
import SwiftData
@testable import Dawn

@MainActor
final class ResetEngineTests: XCTestCase {
    
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
    
    // MARK: - Helper
    
    func createDate(year: Int, month: Int, day: Int, hour: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)!
    }
    
    // MARK: - Reset Timing Tests
    
    func testResetNotNeededSameDay() async throws {
        // Setup: Aktuell 10:00 Uhr
        let currentDate = createDate(year: 2025, month: 1, day: 15, hour: 10)
        timeProvider.setCurrentDate(currentDate)
        
        // Simuliere dass heute um 3:05 schon resettet wurde
        let alreadyResetAt = createDate(year: 2025, month: 1, day: 15, hour: 3)
        resetEngine.setLastResetDate(alreadyResetAt)
        
        // Erstelle einen Task im dailyFocus
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        
        // Action
        await resetEngine.checkAndPerformResetIfNeeded()
        
        // Assert: Task sollte immer noch in dailyFocus sein
        XCTAssertEqual(task.status, .dailyFocus)
    }
    
    func testResetNeededAfter3AM() async throws {
        // Setup: Aktuell 10:00 Uhr
        let currentDate = createDate(year: 2025, month: 1, day: 15, hour: 10)
        timeProvider.setCurrentDate(currentDate)
        
        // Simuliere dass gestern um 3:00 zuletzt resettet wurde
        let lastResetYesterday = createDate(year: 2025, month: 1, day: 14, hour: 3)
        resetEngine.setLastResetDate(lastResetYesterday)
        
        // Erstelle einen Task im dailyFocus
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        
        // Action
        await resetEngine.checkAndPerformResetIfNeeded()
        
        // Assert: Task sollte jetzt im Backlog sein
        XCTAssertEqual(task.status, .inBacklog)
    }
    
    func testResetMovesOnlyDailyFocusTasks() async throws {
        let currentDate = createDate(year: 2025, month: 1, day: 15, hour: 10)
        timeProvider.setCurrentDate(currentDate)
        
        // Erstelle verschiedene Tasks
        let backlog = TestModelContainer.createBacklog(in: context)
        let dailyTask = TestModelContainer.createTask(in: context, title: "Daily", status: .dailyFocus, backlog: backlog)
        let backlogTask = TestModelContainer.createTask(in: context, title: "Backlog", status: .inBacklog, backlog: backlog)
        let completedTask = TestModelContainer.createTask(in: context, title: "Completed", status: .completed, backlog: backlog)
        completedTask.isCompleted = true
        
        // Action
        await resetEngine.performReset(referenceDate: currentDate)
        
        // Assert
        XCTAssertEqual(dailyTask.status, .inBacklog, "DailyFocus Task sollte im Backlog sein")
        XCTAssertEqual(backlogTask.status, .inBacklog, "Backlog Task sollte unverändert sein")
        XCTAssertEqual(completedTask.status, .completed, "Completed Task sollte unverändert sein")
    }
    
    func testResetRemovesScheduledDate() async throws {
        let currentDate = createDate(year: 2025, month: 1, day: 15, hour: 10)
        timeProvider.setCurrentDate(currentDate)
        
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Test", status: .dailyFocus, backlog: backlog)
        task.scheduledDate = Date()
        
        await resetEngine.performReset(referenceDate: currentDate)
        
        XCTAssertNil(task.scheduledDate)
    }
    
    func testResetWithNoTasks() async throws {
        let currentDate = createDate(year: 2025, month: 1, day: 15, hour: 10)
        timeProvider.setCurrentDate(currentDate)
        
        // Sollte nicht crashen
        await resetEngine.performReset(referenceDate: currentDate)
        
        // LastResetDate sollte trotzdem gesetzt werden
        let lastReset = UserDefaults.standard.object(forKey: "DawnLastResetDate") as? Date
        XCTAssertNotNil(lastReset)
    }
    
    func testResetIgnoresCompletedDailyFocusTasks() async throws {
        let currentDate = createDate(year: 2025, month: 1, day: 15, hour: 10)
        timeProvider.setCurrentDate(currentDate)
        
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(in: context, title: "Completed Daily", status: .dailyFocus, backlog: backlog)
        task.complete() // Markiert als completed
        
        await resetEngine.performReset(referenceDate: currentDate)
        
        // Task sollte completed bleiben
        XCTAssertEqual(task.status, .completed)
        XCTAssertTrue(task.isCompleted)
    }
}
