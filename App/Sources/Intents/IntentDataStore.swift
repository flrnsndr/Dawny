// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

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

        if isStoredInMemoryOnly {
            // `.none` ist Pflicht: der Default `.automatic` würde seit dem
            // iCloud-Entitlement auch In-Memory-Stores an CloudKit koppeln.
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
            return try ModelContainer(for: schema, configurations: [config])
        }

        if let persistentContainer {
            return persistentContainer
        }

        // Das Widget darf niemals einen (verfrühten) lokalen oder Group-Store anlegen:
        // die Migration läuft ausschließlich im App-Prozess. Bis dahin: keine Daten.
        if sharedStoreURL == nil, AppGroup.isRunningInAppExtension {
            throw IntentDataStoreError.dataStoreUnavailable
        }

        let container: ModelContainer
        if shouldUseCloudKit {
            do {
                container = try ModelContainer(
                    for: schema,
                    configurations: [makeConfiguration(schema: schema, cloudKit: .private(CloudKitConfig.containerID))]
                )
            } catch {
                // Kein Entitlement, kein iCloud-Account, Container nicht erreichbar:
                // lieber lokal weiterlaufen als die App blockieren. Das Flag wird
                // zurückgesetzt, damit die Settings den echten Zustand zeigen.
                print("⚠️ CloudKit-Container nicht verfügbar, Fallback auf lokalen Store: \(error)")
                AppSettings.shared.iCloudSyncEnabled = false
                container = try ModelContainer(
                    for: schema,
                    configurations: [makeConfiguration(schema: schema, cloudKit: .none)]
                )
            }
        } else {
            container = try ModelContainer(
                for: schema,
                configurations: [makeConfiguration(schema: schema, cloudKit: .none)]
            )
        }

        persistentContainer = container
        return container
    }

    /// Baut die Store-Konfiguration. `cloudKit` entscheidet, ob derselbe Store
    /// zusätzlich an die private CloudKit-Datenbank gekoppelt wird — der Pfad
    /// bleibt in beiden Fällen identisch, ein Wechsel verschiebt also keine Daten.
    private static func makeConfiguration(
        schema: Schema,
        cloudKit: ModelConfiguration.CloudKitDatabase
    ) -> ModelConfiguration {
        if let storeURL = sharedStoreURL {
            // Geteilter Store in der App Group (App + Widget lesen denselben Container).
            return ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: cloudKit)
        }
        // Vor der Migration (oder ohne App-Group-Entitlement): Legacy-Default-Store.
        return ModelConfiguration(schema: schema, cloudKitDatabase: cloudKit)
    }

    /// URL des geteilten Stores — nur gültig, wenn die Migration gelaufen ist
    /// UND das App-Group-Entitlement vorhanden ist.
    private static var sharedStoreURL: URL? {
        guard AppGroup.isMigrated else { return nil }
        return AppGroup.storeURL
    }

    /// CloudKit-Sync läuft ausschließlich im App-Prozess: die Widget-Extension
    /// liest denselben Store lokal weiter (siehe `CloudKitConfig`).
    private static var shouldUseCloudKit: Bool {
        !AppGroup.isRunningInAppExtension && AppSettings.shared.iCloudSyncEnabled
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
        WidgetRefresher.reload()
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
        WidgetRefresher.reload()
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

        applyCompletion(to: task, in: context)
        try context.save()
        WidgetRefresher.reload()
        let completedID = task.id
        _Concurrency.Task { await EntityIndexer.deindexTask(id: completedID) }
        return task
    }

    /// Markiert einen erledigten Task wieder als offen (Heute). Löscht den
    /// evtl. beim Abschließen erzeugten wiederkehrenden Backlog-Clone.
    /// Spiegelt `DailyFocusViewModel.uncompleteTask` (ohne Kalender-Sync,
    /// der läuft App-seitig weiter über `SyncEngine`).
    @discardableResult
    static func uncompleteTask(taskID: UUID, in context: ModelContext) throws -> Task {
        guard let task = try task(withID: taskID, in: context) else {
            throw IntentDataStoreError.taskNotFound
        }
        // Bereits offen → nichts zu tun (idempotent).
        guard task.isCompleted || task.status == .completed else {
            return task
        }

        if let cloneID = task.recurringCloneID, let clone = try Self.task(withID: cloneID, in: context) {
            context.delete(clone)
        }
        task.recurringCloneID = nil
        task.isCompleted = false
        task.completedAt = nil
        task.status = .dailyFocus
        task.modifiedAt = Date()
        task.enteredBacklogAt = nil

        try context.save()
        WidgetRefresher.reload()
        let reopened = task
        _Concurrency.Task { await EntityIndexer.indexTask(reopened) }
        return task
    }

    /// Schließt einen Task ab und erzeugt für wiederkehrende Kategorien einen
    /// neuen Backlog-Clone (damit die Aufgabe morgen wieder auftaucht).
    /// Einzige Quelle dieser Logik — von App-ViewModel, Siri-Intent und Widget genutzt.
    /// Speichert NICHT; der Aufrufer ruft `save()`.
    @discardableResult
    static func applyCompletion(to task: Task, in context: ModelContext) -> Task? {
        let wasRecurring = task.isRecurring
        task.complete()
        guard wasRecurring else { return nil }

        let clone = Task(
            title: task.title,
            notes: task.notes,
            status: .inBacklog,
            parentBacklogID: task.parentBacklogID,
            sortPriority: Date(),
            category: task.category
        )
        clone.backlog = task.backlog
        if clone.backlog == nil {
            let parentID = task.parentBacklogID
            var descriptor = FetchDescriptor<Backlog>(predicate: #Predicate<Backlog> { $0.id == parentID })
            descriptor.fetchLimit = 1
            if let backlog = try? context.fetch(descriptor).first {
                clone.backlog = backlog
            }
        }
        context.insert(clone)
        task.recurringCloneID = clone.id
        return clone
    }

    static func todayTasks(in context: ModelContext) throws -> [Task] {
        try allTasks(in: context)
            .filter { $0.status == .dailyFocus && !$0.isCompleted }
            .sorted()
    }

}
