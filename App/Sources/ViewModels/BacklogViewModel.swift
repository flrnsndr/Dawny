//
//  BacklogViewModel.swift
//  Dawny
//
//  ViewModel für Backlog-Management
//

import Foundation
import SwiftData
import Observation

// #region agent log helper
extension BacklogViewModel {
    private func writeLog(_ data: [String: Any]) {
        let logPath = "/Users/florianschneider/Git/Dawny/.cursor/debug.log"
        guard let logData = try? JSONSerialization.data(withJSONObject: data),
              let logString = String(data: logData, encoding: .utf8) else { return }
        if !FileManager.default.fileExists(atPath: logPath) {
            FileManager.default.createFile(atPath: logPath, contents: nil, attributes: nil)
        }
        guard let fileHandle = FileHandle(forWritingAtPath: logPath) else { return }
        fileHandle.seekToEndOfFile()
        fileHandle.write((logString + "\n").data(using: .utf8) ?? Data())
        fileHandle.closeFile()
    }
}
// #endregion

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
            errorMessage = "Fehler beim Laden der Backlogs: \(error.localizedDescription)"
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
            errorMessage = "Fehler beim Erstellen des Backlogs: \(error.localizedDescription)"
        }
    }
    
    /// Erstellt den Default-Backlog beim ersten Start
    private func createDefaultBacklog() {
        createBacklog(title: "Backlog")
    }
    
    /// Löscht einen Backlog
    func deleteBacklog(_ backlog: Backlog) {
        modelContext.delete(backlog)
        
        do {
            try modelContext.save()
            loadBacklogs()
        } catch {
            errorMessage = "Fehler beim Löschen des Backlogs: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Task Management
    
    /// Fügt einen neuen Task zum aktuellen Backlog hinzu
    /// - Parameter category: Wenn gesetzt und Kategorien aktiv sind, wird diese Kategorie verwendet; sonst die Standard-Kategorie aus den Einstellungen.
    func addTask(title: String, notes: String? = nil, category: Category? = nil) {
        guard let backlog = currentBacklog else {
            errorMessage = "Kein Backlog ausgewählt"
            return
        }
        
        let task = backlog.addTask(title: title, notes: notes)
        
        // #region agent log
        writeLog(["location": "BacklogViewModel.swift:125", "message": "addTask called", "data": ["title": title, "taskId": task.id.uuidString], "timestamp": Int(Date().timeIntervalSince1970 * 1000), "sessionId": "debug-session", "runId": "post-fix", "hypothesisId": "A"])
        // #endregion
        
        // Wenn Kategorien aktiviert sind, weise Standard-Kategorie zu
        let settings = AppSettings.shared
        
        // #region agent log
        writeLog(["location": "BacklogViewModel.swift:130", "message": "Settings check", "data": ["showCategories": settings.showCategories, "defaultCategoryType": settings.defaultCategoryType.rawValue], "timestamp": Int(Date().timeIntervalSince1970 * 1000), "sessionId": "debug-session", "runId": "post-fix", "hypothesisId": "B"])
        // #endregion
        
        if settings.showCategories {
            // Stelle sicher, dass Kategorien initialisiert sind
            categoryService.initializeDefaultCategories()
            
            if let chosen = category {
                task.category = chosen
                
                // #region agent log
                writeLog(["location": "BacklogViewModel.swift:137", "message": "Category assigned", "data": ["categoryId": chosen.id.uuidString, "categoryType": chosen.categoryType.rawValue, "categoryName": chosen.name], "timestamp": Int(Date().timeIntervalSince1970 * 1000), "sessionId": "debug-session", "runId": "post-fix", "hypothesisId": "C"])
                // #endregion
            } else if let defaultCategory = categoryService.getCategory(type: settings.defaultCategoryType) {
                task.category = defaultCategory
                
                // #region agent log
                writeLog(["location": "BacklogViewModel.swift:137", "message": "Category assigned", "data": ["categoryId": defaultCategory.id.uuidString, "categoryType": defaultCategory.categoryType.rawValue, "categoryName": defaultCategory.name], "timestamp": Int(Date().timeIntervalSince1970 * 1000), "sessionId": "debug-session", "runId": "post-fix", "hypothesisId": "C"])
                // #endregion
            } else {
                // #region agent log
                writeLog(["location": "BacklogViewModel.swift:140", "message": "Default category not found", "data": ["requestedType": settings.defaultCategoryType.rawValue], "timestamp": Int(Date().timeIntervalSince1970 * 1000), "sessionId": "debug-session", "runId": "post-fix", "hypothesisId": "C"])
                // #endregion
            }
        }
        
        do {
            try modelContext.save()
            
            // #region agent log
            writeLog(["location": "BacklogViewModel.swift:148", "message": "Task saved", "data": ["taskId": task.id.uuidString, "categoryId": task.category?.id.uuidString ?? "nil", "categoryType": task.category?.categoryType.rawValue ?? "nil"], "timestamp": Int(Date().timeIntervalSince1970 * 1000), "sessionId": "debug-session", "runId": "post-fix", "hypothesisId": "D"])
            // #endregion
        } catch {
            errorMessage = "Fehler beim Erstellen des Tasks: \(error.localizedDescription)"
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
            errorMessage = "Fehler beim Löschen des Tasks: \(error.localizedDescription)"
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
            errorMessage = "Fehler beim Abschließen des Tasks: \(error.localizedDescription)"
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
            errorMessage = "Fehler beim Verschieben des Tasks: \(error.localizedDescription)"
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
            errorMessage = "Fehler beim Aktualisieren des Tasks: \(error.localizedDescription)"
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
            errorMessage = "Fehler beim Verschieben des Tasks: \(error.localizedDescription)"
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
        
        // #region agent log
        writeLog(["location": "BacklogViewModel.swift:231", "message": "loadCategories result", "data": ["count": categories.count, "categories": categories.map { ["id": $0.id.uuidString, "type": $0.categoryType.rawValue, "name": $0.name] }], "timestamp": Int(Date().timeIntervalSince1970 * 1000), "sessionId": "debug-session", "runId": "run1", "hypothesisId": "B"])
        // #endregion
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
    func moveTaskToCategory(_ task: Task, category: Category?) {
        task.category = category
        task.modifiedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Fehler beim Verschieben des Tasks: \(error.localizedDescription)"
        }
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
    
    /// Verschiebt Tasks innerhalb einer Kategorie (Drag & Drop)
    func moveTasksWithinCategory(category: Category, from source: IndexSet, to destination: Int) {
        guard let backlog = currentBacklog else { return }
        
        // Hole alle Tasks dieser Kategorie
        var tasks = backlog.backlogTasks.filter { $0.category?.id == category.id }
        tasks.sort()
        
        // Verschiebe Tasks (manuelle Implementierung ohne SwiftUI)
        guard !source.isEmpty else { return }
        
        var itemsToMove: [Task] = []
        let sortedIndices = source.sorted(by: >)
        for index in sortedIndices {
            itemsToMove.insert(tasks.remove(at: index), at: 0)
        }
        
        // Berechne Insert-Index: Wenn destination nach den entfernten Indizes liegt, 
        // muss destination um die Anzahl der entfernten Elemente reduziert werden
        let maxSourceIndex = sortedIndices.last!
        let insertIndex = destination > maxSourceIndex ? destination - itemsToMove.count : destination
        
        for (index, item) in itemsToMove.enumerated() {
            tasks.insert(item, at: insertIndex + index)
        }
        
        // Aktualisiere sortPriority basierend auf neuer Reihenfolge
        let now = Date()
        for (index, task) in tasks.enumerated() {
            task.sortPriority = now.addingTimeInterval(Double(-index))
            task.modifiedAt = Date()
        }
        
        do {
            try modelContext.save()
            HapticFeedback.light()
        } catch {
            errorMessage = "Fehler beim Sortieren der Tasks: \(error.localizedDescription)"
        }
    }
    
    /// Verschiebt Tasks in der unkategorisierten Ansicht (Drag & Drop)
    func moveTasks(from source: IndexSet, to destination: Int) {
        guard let backlog = currentBacklog else { return }
        
        var tasks = backlog.backlogTasks
        tasks.sort()
        
        // Verschiebe Tasks (manuelle Implementierung ohne SwiftUI)
        guard !source.isEmpty else { return }
        
        var itemsToMove: [Task] = []
        let sortedIndices = source.sorted(by: >)
        for index in sortedIndices {
            itemsToMove.insert(tasks.remove(at: index), at: 0)
        }
        
        // Berechne Insert-Index: Wenn destination nach den entfernten Indizes liegt, 
        // muss destination um die Anzahl der entfernten Elemente reduziert werden
        let maxSourceIndex = sortedIndices.last!
        let insertIndex = destination > maxSourceIndex ? destination - itemsToMove.count : destination
        
        for (index, item) in itemsToMove.enumerated() {
            tasks.insert(item, at: insertIndex + index)
        }
        
        // Aktualisiere sortPriority basierend auf neuer Reihenfolge
        let now = Date()
        for (index, task) in tasks.enumerated() {
            task.sortPriority = now.addingTimeInterval(Double(-index))
            task.modifiedAt = Date()
        }
        
        do {
            try modelContext.save()
            HapticFeedback.light()
        } catch {
            errorMessage = "Fehler beim Sortieren der Tasks: \(error.localizedDescription)"
        }
    }
}
