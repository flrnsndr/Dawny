// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  ArchiveViewModel.swift
//  Dawny
//
//  ViewModel für das Archiv (Make it count)
//

import Foundation
import SwiftData
import Observation

@Observable
final class ArchiveViewModel {
    // MARK: - Properties

    private let modelContext: ModelContext

    var archivedTasks: [Task] = []
    var errorMessage: String?

    var isEmpty: Bool { archivedTasks.isEmpty }

    // MARK: - Initializer

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadArchivedTasks()
    }

    // MARK: - Loading

    func loadArchivedTasks() {
        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\.archivedAt, order: .reverse)]
        )
        do {
            let all = try modelContext.fetch(descriptor)
            archivedTasks = all.filter { $0.status == .archived && !$0.isDeleted }
        } catch {
            errorMessage = String(
                localized: "error.archive.load",
                defaultValue: "Failed to load archived tasks: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Task Actions

    /// Unarchiviert einen Task zurück ins Backlog (in seine letzte Kategorie).
    /// Falls die Kategorie zwischenzeitlich gelöscht wurde, wird „Unkategorisiert" verwendet.
    func unarchiveToBacklog(taskID: UUID) {
        guard let task = task(withID: taskID) else { return }
        ensureCategoryExists(for: task)
        task.unarchiveToBacklog()
        saveAndReload()
    }

    /// Unarchiviert einen Task direkt in den Daily Focus.
    /// Falls die Kategorie zwischenzeitlich gelöscht wurde, wird „Unkategorisiert" verwendet.
    func unarchiveToDailyFocus(taskID: UUID) {
        guard let task = task(withID: taskID) else { return }
        ensureCategoryExists(for: task)
        task.unarchiveToDailyFocus(date: Date())
        saveAndReload()
    }

    /// Löscht einen archivierten Task permanent.
    func deleteTask(taskID: UUID) {
        guard let task = task(withID: taskID) else { return }
        modelContext.delete(task)
        saveAndReload()
    }

    // MARK: - Private Helpers

    private func task(withID id: UUID) -> Task? {
        var descriptor = FetchDescriptor<Task>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    /// Stellt sicher, dass der Task eine gültige Kategorie hat.
    /// Wenn die Kategorie gelöscht wurde (nil oder isDeleted), wird „Unkategorisiert" zugewiesen.
    private func ensureCategoryExists(for task: Task) {
        guard task.category == nil || task.category?.isDeleted == true else { return }
        let descriptor = FetchDescriptor<Category>()
        guard let categories = try? modelContext.fetch(descriptor) else { return }
        if let uncategorized = categories.first(where: { $0.isUncategorized && !$0.isDeleted }) {
            task.category = uncategorized
        }
    }

    private func saveAndReload() {
        do {
            try modelContext.save()
            loadArchivedTasks()
        } catch {
            errorMessage = String(
                localized: "error.archive.save",
                defaultValue: "Failed to save: \(error.localizedDescription)"
            )
        }
    }
}
