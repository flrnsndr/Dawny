// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  TabSelectionLogicTests.swift
//  DawnyTests
//
//  Tests für die Tab-Selektions-Logik beim App-Start
//

import XCTest
import SwiftData
@testable import Dawny

@MainActor
final class TabSelectionLogicTests: XCTestCase {
    
    var container: ModelContainer!
    var context: ModelContext!
    
    override func setUp() async throws {
        container = try TestModelContainer.create()
        context = container.mainContext
    }
    
    // MARK: - Helper
    
    /// Repliziert die shouldShowTodayTab Logik aus ContentView für Tests
    private func shouldShowTodayTab() -> Bool {
        // Fetch alle Tasks und filtere im Speicher
        // (SwiftData unterstützt keine computed properties in Predicates)
        let descriptor = FetchDescriptor<Task>()
        
        do {
            let allTasks = try context.fetch(descriptor)
            
            // Prüfe auf dailyFocus Tasks (offene Tasks für heute)
            let hasDailyFocusTasks = allTasks.contains { $0.status == .dailyFocus }
            
            // TODO: Wenn Feature "erledigte Tasks im Heute-Tab" implementiert ist,
            // hier auch completedToday Tasks prüfen
            
            return hasDailyFocusTasks
        } catch {
            return false
        }
    }
    
    // MARK: - Tests
    
    func testShouldShowTodayTab_EmptyDatabase() async throws {
        // Keine Tasks vorhanden
        XCTAssertFalse(shouldShowTodayTab())
    }
    
    func testShouldShowTodayTab_WithDailyFocusTasks() async throws {
        // Erstelle einen Backlog und einen DailyFocus Task
        let backlog = TestModelContainer.createBacklog(in: context)
        let task = TestModelContainer.createTask(
            in: context,
            title: "Daily Task",
            status: .dailyFocus,
            backlog: backlog
        )
        task.scheduledDate = Calendar.current.startOfDay(for: Date())
        try context.save()
        
        XCTAssertTrue(shouldShowTodayTab())
    }
    
    func testShouldShowTodayTab_WithCompletedTodayTasks() async throws {
        // Erstelle einen Backlog und einen heute erledigten Task
        // HINWEIS: Completed Tasks triggern NICHT mehr den Today-Tab,
        // bis das Feature "erledigte Tasks im Heute-Tab" implementiert ist
        let backlog = TestModelContainer.createBacklog(in: context)
        let today = Calendar.current.startOfDay(for: Date())
        
        let task = TestModelContainer.createTask(
            in: context,
            title: "Completed Today",
            status: .completed,
            backlog: backlog
        )
        task.scheduledDate = today
        task.isCompleted = true
        try context.save()
        
        XCTAssertFalse(shouldShowTodayTab())
    }
    
    func testShouldShowTodayTab_NoRelevantTasks() async throws {
        // Erstelle nur Backlog-Tasks (keine DailyFocus, keine Completed)
        let backlog = TestModelContainer.createBacklog(in: context)
        _ = TestModelContainer.createTask(
            in: context,
            title: "Backlog Task 1",
            status: .inBacklog,
            backlog: backlog
        )
        _ = TestModelContainer.createTask(
            in: context,
            title: "Backlog Task 2",
            status: .inBacklog,
            backlog: backlog
        )
        try context.save()
        
        XCTAssertFalse(shouldShowTodayTab())
    }
    
    func testShouldShowTodayTab_CompletedYesterday() async throws {
        // Erstelle einen gestern erledigten Task - sollte NICHT den Heute-Tab triggern
        let backlog = TestModelContainer.createBacklog(in: context)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        
        let task = TestModelContainer.createTask(
            in: context,
            title: "Completed Yesterday",
            status: .completed,
            backlog: backlog
        )
        task.scheduledDate = Calendar.current.startOfDay(for: yesterday)
        task.isCompleted = true
        try context.save()
        
        XCTAssertFalse(shouldShowTodayTab())
    }
    
    func testShouldShowTodayTab_MixedStatuses() async throws {
        // Erstelle gemischte Tasks - einer ist DailyFocus
        let backlog = TestModelContainer.createBacklog(in: context)
        
        _ = TestModelContainer.createTask(
            in: context,
            title: "Backlog Task",
            status: .inBacklog,
            backlog: backlog
        )
        
        let dailyTask = TestModelContainer.createTask(
            in: context,
            title: "Daily Task",
            status: .dailyFocus,
            backlog: backlog
        )
        dailyTask.scheduledDate = Calendar.current.startOfDay(for: Date())
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let completedTask = TestModelContainer.createTask(
            in: context,
            title: "Old Completed",
            status: .completed,
            backlog: backlog
        )
        completedTask.scheduledDate = Calendar.current.startOfDay(for: yesterday)
        completedTask.isCompleted = true
        
        try context.save()
        
        XCTAssertTrue(shouldShowTodayTab())
    }
    
    func testShouldShowTodayTab_CompletedWithoutScheduledDate() async throws {
        // Completed Task ohne scheduledDate - sollte NICHT den Heute-Tab triggern
        let backlog = TestModelContainer.createBacklog(in: context)
        
        let task = TestModelContainer.createTask(
            in: context,
            title: "Completed No Date",
            status: .completed,
            backlog: backlog
        )
        task.scheduledDate = nil
        task.isCompleted = true
        try context.save()
        
        XCTAssertFalse(shouldShowTodayTab())
    }
}

