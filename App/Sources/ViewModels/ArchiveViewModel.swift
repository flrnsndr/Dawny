// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  ArchiveViewModel.swift
//  Dawny
//
//  ViewModel für das Archiv (Make it count) und die Erledigt-Historie
//

import Foundation
import SwiftData
import Observation

@Observable
final class ArchiveViewModel {
    // MARK: - Properties

    private let modelContext: ModelContext

    /// Automatisch archivierte Tasks (Make-It-Count via ResetEngine)
    var archivedTasks: [Task] = []

    /// Manuell erledigte Tasks der letzten 30 Tage
    var completedTasks: [Task] = []

    var errorMessage: String?

    var isEmpty: Bool { archivedTasks.isEmpty && completedTasks.isEmpty }

    // MARK: - Initializer

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadAll()
    }

    // MARK: - Loading

    func loadAll() {
        let descriptor = FetchDescriptor<Task>()
        do {
            let all = try modelContext.fetch(descriptor)
            let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

            archivedTasks = all
                .filter { $0.status == .archived && !$0.isDeleted }
                .sorted { ($0.archivedAt ?? .distantPast) > ($1.archivedAt ?? .distantPast) }

            completedTasks = all
                .filter {
                    $0.status == .completed
                    && !$0.isDeleted
                    && ($0.completedAt ?? .distantPast) >= cutoff
                }
                .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
        } catch {
            errorMessage = String(
                localized: "error.archive.load",
                defaultValue: "Failed to load archived tasks: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Archived Task Actions

    /// Unarchiviert einen Task zurück ins Backlog.
    func unarchiveToBacklog(taskID: UUID) {
        guard let task = task(withID: taskID) else { return }
        ensureCategoryExists(for: task)
        task.unarchiveToBacklog()
        saveAndReload()
    }

    /// Unarchiviert einen Task direkt in den Daily Focus.
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

    // MARK: - Completed Task Actions

    /// Verschiebt einen erledigten Task zurück ins Backlog.
    /// Löscht einen verknüpften Recurring-Clone, falls vorhanden.
    func moveCompletedToBacklog(taskID: UUID) {
        guard let task = task(withID: taskID) else { return }
        if let cloneID = task.recurringCloneID, let clone = self.task(withID: cloneID) {
            modelContext.delete(clone)
        }
        task.recurringCloneID = nil
        task.isCompleted = false
        task.completedAt = nil
        task.status = .inBacklog
        task.sortPriority = Date()
        task.modifiedAt = Date()
        task.enteredBacklogAt = Date()
        ensureCategoryExists(for: task)
        saveAndReload()
    }

    /// Verschiebt einen erledigten Task direkt in den Daily Focus.
    /// Löscht einen verknüpften Recurring-Clone, falls vorhanden.
    func moveCompletedToDailyFocus(taskID: UUID) {
        guard let task = task(withID: taskID) else { return }
        if let cloneID = task.recurringCloneID, let clone = self.task(withID: cloneID) {
            modelContext.delete(clone)
        }
        task.recurringCloneID = nil
        task.isCompleted = false
        task.completedAt = nil
        task.status = .dailyFocus
        task.scheduledDate = Date()
        task.modifiedAt = Date()
        task.enteredBacklogAt = nil
        ensureCategoryExists(for: task)
        saveAndReload()
    }

    /// Löscht einen erledigten Task permanent.
    func deleteCompletedTask(taskID: UUID) {
        guard let task = task(withID: taskID) else { return }
        modelContext.delete(task)
        saveAndReload()
    }

    // MARK: - Badge Clearing

    /// Markiert alle archivierten Tasks als gesehen (archiveReviewed = true).
    /// Wird aufgerufen wenn der Nutzer das Archiv verlässt.
    func markAllArchiveReviewed() {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { $0.archiveReviewed == false }
        )
        guard let unreviewed = try? modelContext.fetch(descriptor), !unreviewed.isEmpty else { return }
        for task in unreviewed {
            task.archiveReviewed = true
        }
        try? modelContext.saveAndRefreshWidgets()
    }

    // MARK: - Private Helpers

    private func task(withID id: UUID) -> Task? {
        var descriptor = FetchDescriptor<Task>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    /// Stellt sicher, dass der Task eine gültige Kategorie hat.
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
            try modelContext.saveAndRefreshWidgets()
            loadAll()
        } catch {
            errorMessage = String(
                localized: "error.archive.save",
                defaultValue: "Failed to save: \(error.localizedDescription)"
            )
        }
    }
}
