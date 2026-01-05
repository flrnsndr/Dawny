//
//  PersistenceTests.swift
//  DawnyTests
//
//  Integration Tests für Datenpersistenz
//

import XCTest
import SwiftData
@testable import Dawny

@MainActor
final class PersistenceTests: XCTestCase {
    
    var container: ModelContainer!
    var context: ModelContext!
    
    override func setUp() async throws {
        container = try TestModelContainer.create()
        context = container.mainContext
    }
    
    // MARK: - SwiftData Persistence Tests
    
    func testTaskPersistence() throws {
        // Erstelle und speichere
        let backlog = Backlog(title: "Test Backlog")
        context.insert(backlog)
        
        let task = Task(
            title: "Persisted Task",
            notes: "Important notes",
            status: .dailyFocus,
            parentBacklogID: backlog.id,
            scheduledDate: Date(),
            externalReminderID: "reminder-123"
        )
        task.backlog = backlog
        context.insert(task)
        try context.save()
        
        let taskID = task.id
        
        // Fetch und verifiziere
        let descriptor = FetchDescriptor<Task>()
        let loadedTasks = try context.fetch(descriptor)
        
        let loadedTask = loadedTasks.first { $0.id == taskID }
        
        XCTAssertNotNil(loadedTask)
        XCTAssertEqual(loadedTask?.title, "Persisted Task")
        XCTAssertEqual(loadedTask?.notes, "Important notes")
        XCTAssertEqual(loadedTask?.status, .dailyFocus)
        XCTAssertEqual(loadedTask?.externalReminderID, "reminder-123")
    }
    
    func testBacklogTaskRelationship() throws {
        let backlog = Backlog(title: "Relationship Test")
        context.insert(backlog)
        
        _ = backlog.addTask(title: "Task 1")
        _ = backlog.addTask(title: "Task 2")
        _ = backlog.addTask(title: "Task 3")
        
        try context.save()
        
        // Fetch Backlog und prüfe Tasks
        let descriptor = FetchDescriptor<Backlog>()
        let loadedBacklogs = try context.fetch(descriptor)
        let loadedBacklog = loadedBacklogs.first { $0.title == "Relationship Test" }
        
        XCTAssertNotNil(loadedBacklog)
        XCTAssertEqual(loadedBacklog?.tasks.count, 3)
    }
    
    func testTaskStatusPersistence() throws {
        let backlog = Backlog(title: "Status Test")
        context.insert(backlog)
        
        _ = backlog.addTask(title: "InBacklog")  // Bleibt .inBacklog (default)
        let task2 = backlog.addTask(title: "DailyFocus")
        let task3 = backlog.addTask(title: "Completed")
        let task4 = backlog.addTask(title: "Scheduled")
        
        task2.status = .dailyFocus
        task3.status = .completed
        task4.status = .scheduled
        
        try context.save()
        
        // Fetch und verifiziere
        let descriptor = FetchDescriptor<Task>()
        let loadedTasks = try context.fetch(descriptor)
        
        let loadedTask1 = loadedTasks.first { $0.title == "InBacklog" }
        let loadedTask2 = loadedTasks.first { $0.title == "DailyFocus" }
        let loadedTask3 = loadedTasks.first { $0.title == "Completed" }
        let loadedTask4 = loadedTasks.first { $0.title == "Scheduled" }
        
        XCTAssertEqual(loadedTask1?.status, .inBacklog)
        XCTAssertEqual(loadedTask2?.status, .dailyFocus)
        XCTAssertEqual(loadedTask3?.status, .completed)
        XCTAssertEqual(loadedTask4?.status, .scheduled)
    }
    
    // MARK: - Edge Cases
    
    func testEmptyDatabase() throws {
        let taskDescriptor = FetchDescriptor<Task>()
        let backlogDescriptor = FetchDescriptor<Backlog>()
        
        let tasks = try context.fetch(taskDescriptor)
        let backlogs = try context.fetch(backlogDescriptor)
        
        XCTAssertTrue(tasks.isEmpty)
        XCTAssertTrue(backlogs.isEmpty)
    }
    
    func testCascadeDelete() throws {
        let backlog = Backlog(title: "To Delete")
        context.insert(backlog)
        
        _ = backlog.addTask(title: "Child Task 1")
        _ = backlog.addTask(title: "Child Task 2")
        
        try context.save()
        
        // Lösche Backlog
        context.delete(backlog)
        try context.save()
        
        // Tasks sollten auch gelöscht sein
        let taskDescriptor = FetchDescriptor<Task>()
        let remainingTasks = try context.fetch(taskDescriptor)
        
        XCTAssertTrue(remainingTasks.isEmpty)
    }
}
