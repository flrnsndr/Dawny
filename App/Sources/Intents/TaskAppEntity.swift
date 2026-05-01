// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

import AppIntents
import CoreSpotlight
import Foundation
import SwiftData

struct TaskAppEntity: AppEntity, IndexedEntity, Identifiable {
    let id: UUID
    let displayName: String
    let statusRawValue: String
    let categoryName: String?

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Task"
    static var defaultQuery = TaskEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        let subtitle = [categoryName, statusDisplayName]
            .compactMap { $0 }
            .joined(separator: " · ")
        return DisplayRepresentation(
            title: "\(displayName)",
            subtitle: LocalizedStringResource(stringLiteral: subtitle)
        )
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet()
        attributes.displayName = displayName
        attributes.contentDescription = [statusDisplayName, categoryName]
            .compactMap { $0 }
            .joined(separator: " · ")
        attributes.keywords = [statusDisplayName, categoryName].compactMap { $0 }
        return attributes
    }

    private var statusDisplayName: String {
        TaskStatus(rawValue: statusRawValue)?.displayName ?? ""
    }

    init(task: Task) {
        self.id = task.id
        self.displayName = task.title
        self.statusRawValue = task.status.rawValue
        self.categoryName = task.category?.displayName
    }
}

struct TaskEntityQuery: EntityQuery, EntityStringQuery {

    @MainActor
    func entities(for identifiers: [TaskAppEntity.ID]) async throws -> [TaskAppEntity] {
        let context = try IntentDataStore.makeContext()
        return try searchableTasks(in: context)
            .filter { identifiers.contains($0.id) }
            .map(TaskAppEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [TaskAppEntity] {
        let context = try IntentDataStore.makeContext()
        return try searchableTasks(in: context)
            .prefix(50)
            .map(TaskAppEntity.init)
    }

    @MainActor
    func entities(matching string: String) async throws -> [TaskAppEntity] {
        let context = try IntentDataStore.makeContext()
        let tasks = try searchableTasks(in: context)

        return IntentTextMatcher.bestMatches(for: string, in: tasks) { task in
            [task.title, task.category?.displayName].compactMap { $0 }
        }
        .map(TaskAppEntity.init)
    }

    @MainActor
    private func searchableTasks(in context: ModelContext) throws -> [Task] {
        try IntentDataStore.allTasks(in: context)
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
        case .dailyFocus:
            return 0
        case .scheduled:
            return 1
        case .inBacklog:
            return 2
        case .completed:
            return 3
        case .archived:
            return 4
        }
    }
}
