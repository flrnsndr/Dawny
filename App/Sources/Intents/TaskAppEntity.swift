// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

import AppIntents
import Foundation
import SwiftData

struct TaskAppEntity: AppEntity, Identifiable {
    let id: UUID
    let displayName: String
    let statusRawValue: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Task"
    static var defaultQuery = TaskEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(displayName)",
            subtitle: "\(statusDisplayName)"
        )
    }

    private var statusDisplayName: String {
        TaskStatus(rawValue: statusRawValue)?.displayName ?? ""
    }

    init(task: Task) {
        self.id = task.id
        self.displayName = task.title
        self.statusRawValue = task.status.rawValue
    }
}

struct TaskEntityQuery: EntityQuery, EntityStringQuery {
    func entities(for identifiers: [TaskAppEntity.ID]) async throws -> [TaskAppEntity] {
        let context = try await IntentDataStore.makeContext()
        return try await searchableTasks(in: context)
            .filter { identifiers.contains($0.id) }
            .map(TaskAppEntity.init)
    }

    func suggestedEntities() async throws -> [TaskAppEntity] {
        let context = try await IntentDataStore.makeContext()
        return try await searchableTasks(in: context)
            .prefix(20)
            .map(TaskAppEntity.init)
    }

    func entities(matching string: String) async throws -> [TaskAppEntity] {
        let context = try await IntentDataStore.makeContext()
        let tasks = try await searchableTasks(in: context)

        return IntentTextMatcher.bestMatches(for: string, in: tasks) { task in
            [task.title]
        }
        .map(TaskAppEntity.init)
    }

    private func searchableTasks(in context: ModelContext) async throws -> [Task] {
        try await IntentDataStore.allTasks(in: context)
            .filter { task in
                !task.isCompleted && task.status != .completed && task.status != .archived
            }
            .sorted { lhs, rhs in
                if lhs.status != rhs.status {
                    return lhs.status.siriSortRank < rhs.status.siriSortRank
                }
                return lhs < rhs
            }
    }
}

private extension TaskStatus {
    nonisolated var siriSortRank: Int {
        switch self {
        case .inBacklog:
            return 0
        case .dailyFocus:
            return 1
        case .scheduled:
            return 2
        case .completed:
            return 3
        case .archived:
            return 4
        }
    }
}
