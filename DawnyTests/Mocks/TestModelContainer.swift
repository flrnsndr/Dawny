//
//  TestModelContainer.swift
//  DawnyTests
//
//  In-Memory SwiftData Container für Tests
//

import Foundation
import SwiftData
@testable import Dawny

/// Factory für Test-ModelContainer mit In-Memory Storage
@MainActor
enum TestModelContainer {
    /// Erstellt einen neuen In-Memory ModelContainer für Tests
    static func create() throws -> ModelContainer {
        let schema = Schema([
            Task.self,
            Backlog.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
    
    /// Erstellt einen ModelContext aus einem neuen Container
    static func createContext() throws -> ModelContext {
        let container = try create()
        return container.mainContext
    }
    
    /// Erstellt einen Test-Backlog mit optionalen Tasks
    static func createBacklog(
        in context: ModelContext,
        title: String = "Test Backlog",
        taskTitles: [String] = []
    ) -> Backlog {
        let backlog = Backlog(title: title)
        context.insert(backlog)
        
        for taskTitle in taskTitles {
            _ = backlog.addTask(title: taskTitle)
        }
        
        try? context.save()
        return backlog
    }
    
    /// Erstellt einen Test-Task
    static func createTask(
        in context: ModelContext,
        title: String = "Test Task",
        status: TaskStatus = .inBacklog,
        backlog: Backlog
    ) -> Task {
        let task = Task(
            title: title,
            status: status,
            parentBacklogID: backlog.id
        )
        task.backlog = backlog
        context.insert(task)
        
        try? context.save()
        return task
    }
}

