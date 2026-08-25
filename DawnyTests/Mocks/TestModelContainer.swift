// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

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
            Backlog.self,
            Category.self
        ])
        
        // `.none` ist Pflicht: der Default `.automatic` koppelt seit dem
        // iCloud-Entitlement auch In-Memory-Stores an CloudKit, was das
        // Laden des Containers scheitern lässt.
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        
        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
    
    /// Erstellt einen ModelContainer auf einer **Datei**, damit sich zwei Container
    /// denselben Store teilen können. Genau das passiert im Betrieb: CloudKit, die
    /// Widget-Extension und die App-Intents schreiben aus einem anderen Koordinator
    /// in denselben App-Group-Store.
    ///
    /// Auch hier ist `cloudKitDatabase: .none` Pflicht (siehe `create()`).
    static func createOnDisk(at url: URL) throws -> ModelContainer {
        let schema = Schema([
            Task.self,
            Backlog.self,
            Category.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            url: url,
            cloudKitDatabase: .none
        )

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }

    /// Räumt eine mit `createOnDisk(at:)` erzeugte Store-Datei samt WAL-Begleitern weg.
    static func removeStore(at url: URL) {
        for suffix in ["", "-wal", "-shm"] {
            let path = url.path + suffix
            try? FileManager.default.removeItem(atPath: path)
        }
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

