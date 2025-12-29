//
//  Backlog.swift
//  Dawn
//
//  SwiftData Model für Backlogs
//

import Foundation
import SwiftData

@Model
final class Backlog {
    // MARK: - Stored Properties
    
    /// Eindeutige ID
    var id: UUID
    
    /// Name des Backlogs
    var title: String
    
    /// Sortierungs-Index (für Multi-Backlog später)
    var orderIndex: Int
    
    /// Erstellungsdatum
    var createdAt: Date
    
    // MARK: - Relationships
    
    /// Alle Tasks in diesem Backlog
    @Relationship(deleteRule: .cascade, inverse: \Task.backlog)
    var tasks: [Task]
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        title: String,
        orderIndex: Int = 0,
        createdAt: Date = Date(),
        tasks: [Task] = []
    ) {
        self.id = id
        self.title = title
        self.orderIndex = orderIndex
        self.createdAt = createdAt
        self.tasks = tasks
    }
    
    // MARK: - Computed Properties
    
    /// Anzahl der Tasks im Backlog
    var taskCount: Int {
        tasks.filter { $0.status == .inBacklog }.count
    }
    
    /// Tasks die im Backlog sind (nicht completed/scheduled)
    var backlogTasks: [Task] {
        tasks
            .filter { $0.status == .inBacklog }
            .sorted()
    }
    
    /// Tasks die completed sind
    var completedTasks: [Task] {
        tasks
            .filter { $0.status == .completed }
            .sorted { $0.modifiedAt > $1.modifiedAt }
    }
    
    // MARK: - Methods
    
    /// Fügt einen neuen Task zum Backlog hinzu
    func addTask(title: String, notes: String? = nil) -> Task {
        let task = Task(
            title: title,
            notes: notes,
            status: .inBacklog,
            parentBacklogID: self.id
        )
        task.backlog = self
        tasks.append(task)
        return task
    }
    
    /// Entfernt einen Task aus dem Backlog
    func removeTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
    }
}

// MARK: - Comparable

extension Backlog: Comparable {
    static func < (lhs: Backlog, rhs: Backlog) -> Bool {
        lhs.orderIndex < rhs.orderIndex
    }
}
