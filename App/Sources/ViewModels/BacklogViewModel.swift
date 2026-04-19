//
//  BacklogViewModel.swift
//  Dawny
//
//  ViewModel für Backlog-Management
//

import Foundation
import SwiftData
import Observation

/// Steuert die Sortier-Position neu angelegter Tasks innerhalb der Kategorie bzw. der flachen Liste.
enum TaskPlacement: Sendable {
    /// Bestehendes Verhalten: `sortPriority` bleibt beim Default → erscheint oben in der Liste.
    case topOfCategory
    /// Unter bestehende Einträge (Quick-Entry).
    case bottomOfCategory
}

@Observable
final class BacklogViewModel {
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let syncEngine: SyncEngine
    private let categoryService: CategoryService
    
    var backlogs: [Backlog] = []
    var currentBacklog: Backlog?
    var isLoading = false
    var errorMessage: String?
    var categories: [Category] = []
    
    // MARK: - Initializer
    
    init(modelContext: ModelContext, syncEngine: SyncEngine) {
        self.modelContext = modelContext
        self.syncEngine = syncEngine
        self.categoryService = CategoryService(modelContext: modelContext)
        loadBacklogs()
        initializeCategories()
    }
    
    // MARK: - Backlog Management
    
    /// Lädt alle Backlogs
    func loadBacklogs() {
        let descriptor = FetchDescriptor<Backlog>(
            sortBy: [SortDescriptor(\.orderIndex)]
        )
        
        do {
            backlogs = try modelContext.fetch(descriptor)
            
            // Setze ersten Backlog als current falls keiner gesetzt
            if currentBacklog == nil {
                currentBacklog = backlogs.first
            }
            
            // Falls keine Backlogs existieren, erstelle Default-Backlog
            if backlogs.isEmpty {
                createDefaultBacklog()
            }
        } catch {
            let format = String(
                localized: "error.backlog.load_backlogs",
                defaultValue: "Failed to load backlogs: %@"
            )
            errorMessage = String(format: format, error.localizedDescription)
        }
    }
    
    /// Erstellt einen neuen Backlog
    func createBacklog(title: String) {
        let backlog = Backlog(
            title: title,
            orderIndex: backlogs.count
        )
        
        modelContext.insert(backlog)
        
        do {
            try modelContext.save()
            backlogs.append(backlog)
            
            if currentBacklog == nil {
                currentBacklog = backlog
            }
        } catch {
            let format = String(
                localized: "error.backlog.create_backlog",
                defaultValue: "Failed to create backlog: %@"
            )
            errorMessage = String(format: format, error.localizedDescription)
        }
    }
    
    /// Erstellt den Default-Backlog beim ersten Start
    private func createDefaultBacklog() {
        createBacklog(title: String(localized: "backlog.default.title", defaultValue: "Backlog"))
    }
    
    /// Löscht einen Backlog
    func deleteBacklog(_ backlog: Backlog) {
        modelContext.delete(backlog)
        
        do {
            try modelContext.save()
            loadBacklogs()
        } catch {
            let format = String(
                localized: "error.backlog.delete_backlog",
                defaultValue: "Failed to delete backlog: %@"
            )
            errorMessage = String(format: format, error.localizedDescription)
        }
    }
    
    // MARK: - Task Management
    
    /// Fügt einen neuen Task zum aktuellen Backlog hinzu
    /// - Parameter category: Wenn gesetzt und Kategorien aktiv sind, wird diese Kategorie verwendet; sonst die Standard-Kategorie aus den Einstellungen.
    @discardableResult
    func addTask(
        title: String,
        notes: String? = nil,
        category: Category? = nil,
        placement: TaskPlacement = .topOfCategory
    ) -> Task? {
        guard let backlog = currentBacklog else {
            errorMessage = String(
                localized: "error.backlog.none_selected",
                defaultValue: "No backlog selected"
            )
            return nil
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return nil }

        let task = backlog.addTask(title: trimmedTitle, notes: notes)
        
        // Wenn Kategorien aktiviert sind, weise Standard-Kategorie zu
        let settings = AppSettings.shared
        
        if settings.showCategories {
            // Stelle sicher, dass Kategorien initialisiert sind
            categoryService.initializeDefaultCategories()
            
            if let chosen = category {
                task.category = chosen
            } else if let defaultCategory = categoryService.getCategory(type: settings.defaultCategoryType) {
                task.category = defaultCategory
            }
        }

        if placement == .bottomOfCategory {
            applyBottomPlacement(for: task, in: backlog)
        }
        
        do {
            try modelContext.save()
            return task
        } catch {
            let format = String(
                localized: "error.backlog.create_task",
                defaultValue: "Failed to create task: %@"
            )
            errorMessage = String(format: format, error.localizedDescription)
            return nil
        }
    }

    /// Legt einen Task in der Quick-Kategorie an und verschiebt ihn nach Heute (Kalender-Sync inkl.).
    @discardableResult
    func addTaskToTodayQuickEntry(title: String) async -> Task? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        categoryService.initializeDefaultCategories()
        let quickCategory = categoryService.getCategory(type: .quick)

        guard let task = addTask(
            title: trimmed,
            notes: nil,
            category: quickCategory,
            placement: .bottomOfCategory
        ) else { return nil }

        await moveTaskToDailyFocus(task)
        placeTaskAtBottomOfTodayOpenList(task)
        return task
    }

    private func applyBottomPlacement(for task: Task, in backlog: Backlog) {
        let settings = AppSettings.shared
        let others: [Task]
        if settings.showCategories {
            let categoryId = task.category?.id
            others = backlog.backlogTasks.filter { $0.id != task.id && $0.category?.id == categoryId }
        } else {
            others = backlog.backlogTasks.filter { $0.id != task.id }
        }
        let minPriority = others.map(\.sortPriority).min() ?? Date()
        task.sortPriority = minPriority.addingTimeInterval(-0.001)
    }

    private func placeTaskAtBottomOfTodayOpenList(_ task: Task) {
        do {
            let descriptor = FetchDescriptor<Task>()
            let allTasks = try modelContext.fetch(descriptor)
            let others = allTasks.filter { $0.status == .dailyFocus && !$0.isCompleted && $0.id != task.id }
            let minPriority = others.map(\.sortPriority).min() ?? Date()
            task.sortPriority = minPriority.addingTimeInterval(-0.001)
            try modelContext.save()
        } catch {
            let format = String(
                localized: "error.backlog.sort_today_tasks",
                defaultValue: "Failed to reorder Today: %@"
            )
            errorMessage = String(format: format, error.localizedDescription)
        }
    }
    
    /// Löscht einen Task
    func deleteTask(_ task: Task) async {
        // Falls Task im Kalender, entfernen
        if task.isSyncedToCalendar {
            await syncEngine.removeTaskFromCalendar(task)
        }
        
        modelContext.delete(task)
        
        do {
            try modelContext.save()
        } catch {
            let format = String(
                localized: "error.backlog.delete_task",
                defaultValue: "Failed to delete task: %@"
            )
            errorMessage = String(format: format, error.localizedDescription)
        }
    }
    
    /// Markiert einen Task als abgeschlossen
    func completeTask(_ task: Task) async {
        task.complete()
        
        // Sync zu Kalender falls verbunden
        if task.isSyncedToCalendar {
            await syncEngine.syncTaskToCalendar(task)
        }
        
        do {
            try modelContext.save()
        } catch {
            let format = String(
                localized: "error.backlog.complete_task",
                defaultValue: "Failed to complete task: %@"
            )
            errorMessage = String(format: format, error.localizedDescription)
        }
    }
    
    /// Verschiebt einen Task zu Daily Focus
    func moveTaskToDailyFocus(_ task: Task) async {
        let today = Calendar.current.startOfDay(for: Date())
        task.moveToDailyFocus(date: today)
        
        // Sync zu Kalender
        await syncEngine.syncTaskToCalendar(task)
        
        do {
            try modelContext.save()
            // Aktualisiere Backlog-Liste damit der Task verschwindet
            loadBacklogs()
        } catch {
            let format = String(
                localized: "error.backlog.move_task",
                defaultValue: "Failed to move task: %@"
            )
            errorMessage = String(format: format, error.localizedDescription)
        }
    }
    
    /// Aktualisiert einen Task
    func updateTask(_ task: Task, title: String, notes: String?) async {
        task.title = title
        task.notes = notes
        task.modifiedAt = Date()
        
        // Sync zu Kalender falls verbunden
        if task.isSyncedToCalendar {
            await syncEngine.syncTaskToCalendar(task)
        }
        
        do {
            try modelContext.save()
        } catch {
            let format = String(
                localized: "error.backlog.update_task",
                defaultValue: "Failed to update task: %@"
            )
            errorMessage = String(format: format, error.localizedDescription)
        }
    }
    
    /// Verschiebt Task zurück ins Backlog
    func moveTaskToBacklog(_ task: Task) async {
        // Entferne aus Kalender falls synchronisiert
        if task.isSyncedToCalendar {
            await syncEngine.removeTaskFromCalendar(task)
        }
        
        task.resetToBacklog()
        
        do {
            try modelContext.save()
        } catch {
            let format = String(
                localized: "error.backlog.move_to_backlog",
                defaultValue: "Failed to move task to backlog: %@"
            )
            errorMessage = String(format: format, error.localizedDescription)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Alle Tasks im aktuellen Backlog
    var backlogTasks: [Task] {
        currentBacklog?.backlogTasks ?? []
    }
    
    /// Anzahl der Tasks im Backlog
    var taskCount: Int {
        currentBacklog?.taskCount ?? 0
    }
    
    // MARK: - Category Management
    
    /// Initialisiert Kategorien beim ersten Start
    private func initializeCategories() {
        categoryService.initializeDefaultCategories()
        loadCategories()
    }
    
    /// Lädt alle Kategorien
    func loadCategories() {
        categories = categoryService.getCategoriesSorted()
    }
    
    /// Tasks nach Kategorie gruppiert (Key: Category ID)
    var groupedTasks: [UUID: [Task]] {
        guard let backlog = currentBacklog else { return [:] }
        
        var grouped: [UUID: [Task]] = [:]
        
        // Gruppiere Tasks nach Kategorie
        for task in backlog.backlogTasks {
            if let category = task.category {
                let categoryId = category.id
                if grouped[categoryId] == nil {
                    grouped[categoryId] = []
                }
                grouped[categoryId]?.append(task)
            } else {
                // Tasks ohne Kategorie → "Unkategorisiert"
                if let uncategorized = categoryService.getUncategorizedCategory() {
                    let categoryId = uncategorized.id
                    if grouped[categoryId] == nil {
                        grouped[categoryId] = []
                    }
                    grouped[categoryId]?.append(task)
                }
            }
        }
        
        // Sortiere Tasks innerhalb jeder Kategorie
        for (categoryId, tasks) in grouped {
            grouped[categoryId] = tasks.sorted()
        }
        
        return grouped
    }
    
    /// Verschiebt einen Task in eine andere Kategorie
    /// - Parameter placeAtTopOfCategory: Wenn `true`, wird `sortPriority` gesetzt, damit der Task oben in der Zielkategorie erscheint (z. B. Drag & Drop auf den Header).
    func moveTaskToCategory(_ task: Task, category: Category?, placeAtTopOfCategory: Bool = false) {
        task.category = category
        if placeAtTopOfCategory {
            task.sortPriority = Date()
        }
        task.modifiedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            let format = String(
                localized: "error.backlog.move_task_category",
                defaultValue: "Failed to change task category: %@"
            )
            errorMessage = String(format: format, error.localizedDescription)
        }
    }

    /// Lädt einen Task anhand seiner ID (z. B. nach Drag & Drop).
    func task(withID id: UUID) -> Task? {
        var descriptor = FetchDescriptor<Task>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }
    
    /// Gibt Tasks einer bestimmten Kategorie zurück
    func getTasksForCategory(_ category: Category) -> [Task] {
        guard let backlog = currentBacklog else { return [] }
        return backlog.backlogTasks.filter { $0.category?.id == category.id }
    }
    
    /// Gibt Tasks ohne Kategorie zurück
    func getUncategorizedTasks() -> [Task] {
        guard let backlog = currentBacklog else { return [] }
        return backlog.backlogTasks.filter { $0.category == nil }
    }
    
    /// Migriert alle Tasks ohne Kategorie zur "Unkategorisiert"-Kategorie
    func migrateUncategorizedTasksIfNeeded() {
        categoryService.migrateUncategorizedTasks()
    }

    // MARK: - Category Editing

    /// Benennt eine Kategorie um. Setzt `errorMessage`, wenn die Validierung fehlschlägt.
    /// - Returns: `true` bei Erfolg, sonst `false`.
    @discardableResult
    func renameCategory(_ category: Category, to newName: String) -> Bool {
        do {
            try categoryService.rename(category, to: newName)
            loadCategories()
            return true
        } catch let error as CategoryEditError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Aktualisiert das Symbol einer Kategorie.
    /// - Returns: `true` bei Erfolg, sonst `false`.
    @discardableResult
    func updateCategoryIcon(_ category: Category, to symbolName: String) -> Bool {
        do {
            try categoryService.updateIcon(category, to: symbolName)
            loadCategories()
            return true
        } catch let error as CategoryEditError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Löscht eine Kategorie nach gewählter Strategie.
    /// - Returns: `true` bei Erfolg, sonst `false`.
    @discardableResult
    func deleteCategory(_ category: Category, strategy: CategoryDeleteStrategy) -> Bool {
        do {
            try categoryService.delete(category, strategy: strategy)
            loadCategories()
            return true
        } catch let error as CategoryEditError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Legt eine neue benutzerdefinierte Kategorie an.
    @discardableResult
    func createCategory(name: String) -> Category? {
        do {
            let category = try categoryService.createCustom(name: name)
            loadCategories()
            HapticFeedback.success()
            return category
        } catch let error as CategoryEditError {
            errorMessage = error.errorDescription
            return nil
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    /// Verschiebt Tasks innerhalb einer Kategorie (Drag & Drop)
    func moveTasksWithinCategory(category: Category, from source: IndexSet, to destination: Int) {
        guard let backlog = currentBacklog else { return }
        
        var tasks = backlog.backlogTasks.filter { $0.category?.id == category.id }
        tasks.sort()
        
        guard !source.isEmpty else { return }
        
        var itemsToMove: [Task] = []
        let sortedIndices = source.sorted(by: >)
        for index in sortedIndices {
            itemsToMove.insert(tasks.remove(at: index), at: 0)
        }
        
        let maxSourceIndex = sortedIndices.last!
        let insertIndex = destination > maxSourceIndex ? destination - itemsToMove.count : destination
        
        for (index, item) in itemsToMove.enumerated() {
            tasks.insert(item, at: insertIndex + index)
        }
        
        let now = Date()
        for (index, task) in tasks.enumerated() {
            task.sortPriority = now.addingTimeInterval(Double(-index))
            task.modifiedAt = Date()
        }
        
        do {
            try modelContext.save()
            HapticFeedback.light()
        } catch {
            let format = String(
                localized: "error.backlog.reorder_tasks",
                defaultValue: "Failed to reorder tasks: %@"
            )
            errorMessage = String(format: format, error.localizedDescription)
        }
    }
    
    /// Verschiebt Tasks in der unkategorisierten Ansicht (Drag & Drop)
    func moveTasks(from source: IndexSet, to destination: Int) {
        guard let backlog = currentBacklog else { return }
        
        var tasks = backlog.backlogTasks
        tasks.sort()
        
        guard !source.isEmpty else { return }
        
        var itemsToMove: [Task] = []
        let sortedIndices = source.sorted(by: >)
        for index in sortedIndices {
            itemsToMove.insert(tasks.remove(at: index), at: 0)
        }
        
        let maxSourceIndex = sortedIndices.last!
        let insertIndex = destination > maxSourceIndex ? destination - itemsToMove.count : destination
        
        for (index, item) in itemsToMove.enumerated() {
            tasks.insert(item, at: insertIndex + index)
        }
        
        let now = Date()
        for (index, task) in tasks.enumerated() {
            task.sortPriority = now.addingTimeInterval(Double(-index))
            task.modifiedAt = Date()
        }
        
        do {
            try modelContext.save()
            HapticFeedback.light()
        } catch {
            let format = String(
                localized: "error.backlog.reorder_tasks",
                defaultValue: "Failed to reorder tasks: %@"
            )
            errorMessage = String(format: format, error.localizedDescription)
        }
    }

    /// Legt Testelemente im Backlog an (für manuelles UI-Testing).
    func addDebugTestItems(settings: AppSettings) {
        loadCategories()
        let assignableCategories = categories
            .sorted()
            .filter { $0.categoryType != .uncategorized }

        var counter = 1

        // In jeder Kategorie 3-4 Backlog-Tasks erzeugen.
        for category in assignableCategories {
            let countPerCategory = Int.random(in: 3...4)
            for index in 1...countPerCategory {
                addTask(
                    title: "Testtask \(counter) \(category.displayName) #\(index)",
                    category: category
                )
                counter += 1
            }
        }

        // Zusätzlich 2-3 Tasks direkt in den Heute-Tab legen.
        let todayCount = Int.random(in: 2...3)
        let todayDate = Calendar.current.startOfDay(for: Date())
        let todayCategory = assignableCategories.first(where: { $0.categoryType == .quick }) ?? assignableCategories.first

        for index in 1...todayCount {
            if let task = addTask(
                title: "Testtask Heute \(counter) #\(index)",
                category: todayCategory
            ) {
                task.moveToDailyFocus(date: todayDate)
                do {
                    try modelContext.save()
                } catch {
                    let format = String(
                        localized: "error.backlog.debug_today_test_tasks",
                        defaultValue: "Failed to create test tasks: %@"
                    )
                    errorMessage = String(format: format, error.localizedDescription)
                    return
                }
            }
            counter += 1
        }
    }
}
