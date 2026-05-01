// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

import AppIntents
import CoreSpotlight
import Foundation

@MainActor
enum EntityIndexer {

    static func reindexAll() async {
        guard let context = try? IntentDataStore.makeContext() else { return }
        if let tasks = try? IntentDataStore.allTasks(in: context) {
            let entities = tasks
                .filter { !$0.isCompleted && $0.status != .archived }
                .map(TaskAppEntity.init)
            try? await CSSearchableIndex.default().indexAppEntities(entities)
        }
        if let categories = try? IntentDataStore.allCategories(in: context) {
            let entities = categories.map(CategoryAppEntity.init)
            try? await CSSearchableIndex.default().indexAppEntities(entities)
        }
    }

    static func indexTask(_ task: Task) async {
        guard !task.isCompleted, task.status != .archived else {
            await deindexTask(id: task.id)
            return
        }
        let entity = TaskAppEntity(task: task)
        try? await CSSearchableIndex.default().indexAppEntities([entity])
    }

    static func deindexTask(id: UUID) async {
        try? await CSSearchableIndex.default().deleteAppEntities(
            identifiedBy: [id],
            ofType: TaskAppEntity.self
        )
    }
}
