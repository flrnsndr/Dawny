// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

import Foundation
import SwiftData

@MainActor
protocol TaskDataStoring: Sendable {
    func allTasks() throws -> [Task]
    func allCategories() throws -> [Category]
    func task(withID id: UUID) throws -> Task?
    func category(withID id: UUID) throws -> Category?
    func addTask(title: String, categoryID: UUID?, status: TaskStatus) throws -> Task
    func moveTaskToToday(taskID: UUID) throws -> Task
    func completeTask(taskID: UUID) throws -> Task
    func todayTasks() throws -> [Task]
}

@MainActor
final class TaskDataStore: TaskDataStoring {
    private let container: ModelContainer

    nonisolated init(container: ModelContainer) {
        self.container = container
    }

    private var context: ModelContext { container.mainContext }

    func allTasks() throws -> [Task] {
        try context.fetch(FetchDescriptor<Task>()).filter { !$0.isDeleted }
    }

    func allCategories() throws -> [Category] {
        initializeCategories()
        return try context.fetch(
            FetchDescriptor<Category>(sortBy: [SortDescriptor(\.orderIndex)])
        )
    }

    func task(withID id: UUID) throws -> Task? {
        try allTasks().first { $0.id == id }
    }

    func category(withID id: UUID) throws -> Category? {
        try allCategories().first { $0.id == id }
    }

    func addTask(title: String, categoryID: UUID?, status: TaskStatus) throws -> Task {
        let categoryService = initializeCategories()
        let backlog = try findOrCreateBacklog()
        let today = Calendar.current.startOfDay(for: Date())

        let task = Task(
            title: title,
            status: status,
            parentBacklogID: backlog.id,
            scheduledDate: status == .dailyFocus ? today : nil
        )
        task.backlog = backlog

        if let categoryID {
            guard let selectedCategory = try category(withID: categoryID) else {
                throw IntentDataStoreError.categoryNotFound
            }
            task.category = selectedCategory
        } else {
            task.category = categoryService.getUncategorizedCategory()
        }

        context.insert(task)
        try context.save()
        let indexTarget = task
        _Concurrency.Task { await EntityIndexer.indexTask(indexTarget) }
        return task
    }

    func moveTaskToToday(taskID: UUID) throws -> Task {
        guard let task = try task(withID: taskID) else {
            throw IntentDataStoreError.taskNotFound
        }
        guard task.status != .archived else {
            throw IntentDataStoreError.taskArchived
        }
        guard !task.isCompleted && task.status != .completed else {
            throw IntentDataStoreError.taskAlreadyCompleted
        }

        task.moveToDailyFocus(date: Calendar.current.startOfDay(for: Date()))
        try context.save()
        let indexTarget = task
        _Concurrency.Task { await EntityIndexer.indexTask(indexTarget) }
        return task
    }

    func completeTask(taskID: UUID) throws -> Task {
        guard let task = try task(withID: taskID) else {
            throw IntentDataStoreError.taskNotFound
        }
        guard task.status != .archived else {
            throw IntentDataStoreError.taskArchived
        }
        guard !task.isCompleted && task.status != .completed else {
            throw IntentDataStoreError.taskAlreadyCompleted
        }

        task.complete()
        try context.save()
        let taskID = task.id
        _Concurrency.Task { await EntityIndexer.deindexTask(id: taskID) }
        return task
    }

    func todayTasks() throws -> [Task] {
        try allTasks()
            .filter { $0.status == .dailyFocus && !$0.isCompleted }
            .sorted()
    }

    // MARK: - Private

    @discardableResult
    private func initializeCategories() -> CategoryService {
        let categoryService = CategoryService(modelContext: context)
        categoryService.initializeDefaultCategories()
        return categoryService
    }

    private func findOrCreateBacklog() throws -> Backlog {
        let descriptor = FetchDescriptor<Backlog>(
            sortBy: [SortDescriptor(\.orderIndex)]
        )

        if let existing = try context.fetch(descriptor).first {
            return existing
        }

        let title = String(localized: "backlog.default.title", defaultValue: "Backlog")
        let backlog = Backlog(title: title, orderIndex: 0)
        context.insert(backlog)
        try context.save()
        return backlog
    }
}
