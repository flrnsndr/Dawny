// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  BacklogModelTests.swift
//  DawnyTests
//
//  Unit Tests für das Backlog Model
//

import XCTest
import SwiftData
@testable import Dawny

@MainActor
final class BacklogModelTests: XCTestCase {
    
    var container: ModelContainer!
    var context: ModelContext!
    
    override func setUp() async throws {
        container = try TestModelContainer.create()
        context = container.mainContext
    }
    
    // MARK: - Creation Tests
    
    func testBacklogCreation() throws {
        let backlog = Backlog(title: "Test Backlog")
        
        XCTAssertEqual(backlog.title, "Test Backlog")
        XCTAssertEqual(backlog.orderIndex, 0)
        XCTAssertTrue(backlog.tasks.isEmpty)
    }
    
    // MARK: - AddTask Tests
    
    func testAddTask() throws {
        let backlog = Backlog(title: "Test")
        context.insert(backlog)
        
        let task = backlog.addTask(title: "New Task")
        
        XCTAssertEqual(task.title, "New Task")
        XCTAssertEqual(task.status, .inBacklog)
        XCTAssertEqual(task.parentBacklogID, backlog.id)
    }
    
    func testAddTaskWithNotes() throws {
        let backlog = Backlog(title: "Test")
        context.insert(backlog)
        
        let task = backlog.addTask(title: "Task with Notes", notes: "Some notes")
        
        XCTAssertEqual(task.notes, "Some notes")
    }
    
    // MARK: - Computed Properties Tests
    
    func testBacklogTasksFilter() throws {
        let backlog = Backlog(title: "Test")
        context.insert(backlog)
        
        let task1 = backlog.addTask(title: "Backlog Task")
        let task2 = backlog.addTask(title: "Daily Task")
        let task3 = backlog.addTask(title: "Completed Task")
        
        task2.status = .dailyFocus
        task3.status = .completed
        
        let backlogTasks = backlog.backlogTasks
        
        // Nur task1 sollte in backlogTasks sein
        XCTAssertEqual(backlogTasks.count, 1)
        XCTAssertEqual(backlogTasks.first?.id, task1.id)
    }
    
    func testTaskCount() throws {
        let backlog = Backlog(title: "Test")
        context.insert(backlog)
        
        _ = backlog.addTask(title: "Task 1")
        _ = backlog.addTask(title: "Task 2")
        let dailyTask = backlog.addTask(title: "Daily Task")
        dailyTask.status = .dailyFocus
        
        XCTAssertEqual(backlog.taskCount, 2)
    }
    
    // MARK: - Edge Cases
    
    func testEmptyBacklog() throws {
        let backlog = Backlog(title: "Empty")
        
        XCTAssertEqual(backlog.taskCount, 0)
        XCTAssertTrue(backlog.backlogTasks.isEmpty)
    }
}
