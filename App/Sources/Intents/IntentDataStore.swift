// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

import Foundation
import SwiftData

enum IntentDataStoreError: LocalizedError, CustomLocalizedStringResourceConvertible {
    case categoryNotFound
    case taskNotFound
    case taskAlreadyCompleted
    case taskArchived
    case titleEmpty
    case dataStoreUnavailable

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .categoryNotFound:
            LocalizedStringResource("intent.error.categoryNotFound", defaultValue: "I couldn't find that category.")
        case .taskNotFound:
            LocalizedStringResource("intent.error.taskNotFound", defaultValue: "I couldn't find that task.")
        case .taskAlreadyCompleted:
            LocalizedStringResource("intent.error.taskAlreadyCompleted", defaultValue: "That task is already completed.")
        case .taskArchived:
            LocalizedStringResource("intent.error.taskArchived", defaultValue: "That task is archived.")
        case .titleEmpty:
            LocalizedStringResource("intent.error.titleEmpty", defaultValue: "Please provide a task title.")
        case .dataStoreUnavailable:
            LocalizedStringResource("intent.error.dataStoreUnavailable", defaultValue: "Sorry, I can't access your tasks right now. Please try again.")
        }
    }

    var errorDescription: String? {
        String(localized: localizedStringResource)
    }
}

@MainActor
enum IntentDataStore {
    private static var persistentContainer: ModelContainer?

    static func makeModelContainer(isStoredInMemoryOnly: Bool = false) throws -> ModelContainer {
        let schema = Schema([Task.self, Backlog.self, Category.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)

        if isStoredInMemoryOnly {
            return try ModelContainer(for: schema, configurations: [config])
        }

        if let persistentContainer {
            return persistentContainer
        }

        let container = try ModelContainer(for: schema, configurations: [config])
        persistentContainer = container
        return container
    }

    static func makeContext(isStoredInMemoryOnly: Bool = false) throws -> ModelContext {
        try makeModelContainer(isStoredInMemoryOnly: isStoredInMemoryOnly).mainContext
    }

    @discardableResult
    static func initializeCategories(in context: ModelContext) -> CategoryService {
        let categoryService = CategoryService(modelContext: context)
        categoryService.initializeDefaultCategories()
        return categoryService
    }

    static func findOrCreateBacklog(in context: ModelContext) throws -> Backlog {
        let descriptor = FetchDescriptor<Backlog>(
            sortBy: [SortDescriptor(\.orderIndex)]
        )

        if let existingBacklog = try context.fetch(descriptor).first {
            return existingBacklog
        }

        let backlogTitle = String(localized: "backlog.default.title", defaultValue: "Backlog")
        let newBacklog = Backlog(title: backlogTitle, orderIndex: 0)
        context.insert(newBacklog)
        try context.save()

        return newBacklog
    }

    static func allCategories(in context: ModelContext) throws -> [Category] {
        initializeCategories(in: context)
        return try context.fetch(
            FetchDescriptor<Category>(sortBy: [SortDescriptor(\.orderIndex)])
        )
    }

    static func category(withID id: UUID, in context: ModelContext) throws -> Category? {
        try allCategories(in: context).first { $0.id == id }
    }

    static func allTasks(in context: ModelContext) throws -> [Task] {
        try context.fetch(FetchDescriptor<Task>()).filter { !$0.isDeleted }
    }

    static func task(withID id: UUID, in context: ModelContext) throws -> Task? {
        try allTasks(in: context).first { $0.id == id }
    }

    static func addTask(
        title: String,
        categoryID: UUID?,
        status: TaskStatus,
        in context: ModelContext
    ) throws -> Task {
        let categoryService = initializeCategories(in: context)
        let backlog = try findOrCreateBacklog(in: context)
        let today = Calendar.current.startOfDay(for: Date())

        let task = Task(
            title: title,
            status: status,
            parentBacklogID: backlog.id,
            scheduledDate: status == .dailyFocus ? today : nil
        )
        task.backlog = backlog

        if let categoryID {
            guard let selectedCategory = try category(withID: categoryID, in: context) else {
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

    static func moveTaskToToday(taskID: UUID, in context: ModelContext) throws -> Task {
        guard let task = try task(withID: taskID, in: context) else {
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

    static func completeTask(taskID: UUID, in context: ModelContext) throws -> Task {
        guard let task = try task(withID: taskID, in: context) else {
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

    static func todayTasks(in context: ModelContext) throws -> [Task] {
        try allTasks(in: context)
            .filter { $0.status == .dailyFocus && !$0.isCompleted }
            .sorted()
    }

}
