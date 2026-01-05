//
//  CategoryService.swift
//  Dawny
//
//  Service für Kategorien-Management und Initialisierung
//

import Foundation
import SwiftData

// #region agent log helper
extension CategoryService {
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

/// Service für Kategorien-Management
final class CategoryService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Initialisiert die Standard-Kategorien beim ersten App-Start
    func initializeDefaultCategories() {
        // #region agent log
        writeLog(["location": "CategoryService.swift:20", "message": "initializeDefaultCategories called", "data": [:], "timestamp": Int(Date().timeIntervalSince1970 * 1000), "sessionId": "debug-session", "runId": "run1", "hypothesisId": "A"])
        // #endregion
        
        // Prüfe ob bereits Kategorien existieren
        let descriptor = FetchDescriptor<Category>()
        do {
            let existingCategories = try modelContext.fetch(descriptor)
            
            // #region agent log
            writeLog(["location": "CategoryService.swift:27", "message": "Existing categories count", "data": ["count": existingCategories.count, "categories": existingCategories.map { ["id": $0.id.uuidString, "type": $0.categoryType.rawValue, "name": $0.name] }], "timestamp": Int(Date().timeIntervalSince1970 * 1000), "sessionId": "debug-session", "runId": "run1", "hypothesisId": "A"])
            // #endregion
            
            if !existingCategories.isEmpty {
                // Kategorien existieren bereits
                return
            }
        } catch {
            // Fehler beim Laden - versuche trotzdem zu erstellen
            print("Fehler beim Laden der Kategorien: \(error)")
        }
        
        // Erstelle alle Standard-Kategorien
        let categories: [TaskCategory] = [.quick, .thisWeek, .thisMonth, .thisYear, .someday, .uncategorized]
        
        // #region agent log
        writeLog(["location": "CategoryService.swift:37", "message": "Creating categories", "data": ["count": categories.count, "types": categories.map { $0.rawValue }], "timestamp": Int(Date().timeIntervalSince1970 * 1000), "sessionId": "debug-session", "runId": "run1", "hypothesisId": "A"])
        // #endregion
        
        for categoryType in categories {
            let category = Category(
                categoryType: categoryType,
                orderIndex: categoryType.defaultOrderIndex,
                isUncategorized: categoryType == .uncategorized
            )
            modelContext.insert(category)
        }
        
        // Speichere die Kategorien
        do {
            try modelContext.save()
            
            // #region agent log
            writeLog(["location": "CategoryService.swift:51", "message": "Categories saved successfully", "data": [:], "timestamp": Int(Date().timeIntervalSince1970 * 1000), "sessionId": "debug-session", "runId": "run1", "hypothesisId": "A"])
            // #endregion
        } catch {
            print("Fehler beim Speichern der Standard-Kategorien: \(error)")
            
            // #region agent log
            writeLog(["location": "CategoryService.swift:54", "message": "Failed to save categories", "data": ["error": error.localizedDescription], "timestamp": Int(Date().timeIntervalSince1970 * 1000), "sessionId": "debug-session", "runId": "run1", "hypothesisId": "A"])
            // #endregion
        }
    }
    
    /// Gibt die "Unkategorisiert"-Kategorie zurück
    func getUncategorizedCategory() -> Category? {
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.isUncategorized == true }
        )
        
        do {
            let categories = try modelContext.fetch(descriptor)
            return categories.first
        } catch {
            print("Fehler beim Laden der Unkategorisiert-Kategorie: \(error)")
            return nil
        }
    }
    
    /// Gibt alle Kategorien nach orderIndex sortiert zurück
    func getCategoriesSorted() -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.orderIndex)]
        )
        
        do {
            let categories = try modelContext.fetch(descriptor)
            
            // #region agent log
            writeLog(["location": "CategoryService.swift:76", "message": "getCategoriesSorted result", "data": ["count": categories.count, "categories": categories.map { ["id": $0.id.uuidString, "type": $0.categoryType.rawValue, "name": $0.name, "orderIndex": $0.orderIndex] }], "timestamp": Int(Date().timeIntervalSince1970 * 1000), "sessionId": "debug-session", "runId": "run1", "hypothesisId": "B"])
            // #endregion
            
            return categories
        } catch {
            print("Fehler beim Laden der Kategorien: \(error)")
            return []
        }
    }
    
    /// Gibt eine Kategorie nach Typ zurück
    func getCategory(type: TaskCategory) -> Category? {
        // SwiftData Predicates unterstützen keine Enum-Vergleiche,
        // daher laden wir alle Kategorien und filtern in Swift
        let descriptor = FetchDescriptor<Category>()
        
        do {
            let allCategories = try modelContext.fetch(descriptor)
            return allCategories.first { $0.categoryType == type }
        } catch {
            print("Fehler beim Laden der Kategorie: \(error)")
            return nil
        }
    }
    
    /// Migriert alle Tasks ohne Kategorie zur "Unkategorisiert"-Kategorie
    func migrateUncategorizedTasks() {
        // #region agent log
        writeLog(["location": "CategoryService.swift:143", "message": "migrateUncategorizedTasks called", "data": [:], "timestamp": Int(Date().timeIntervalSince1970 * 1000), "sessionId": "debug-session", "runId": "post-fix", "hypothesisId": "E"])
        // #endregion
        
        guard let uncategorizedCategory = getUncategorizedCategory() else {
            print("Unkategorisiert-Kategorie nicht gefunden")
            return
        }
        
        // SwiftData Predicates unterstützen weder == nil für Relationships
        // noch Enum-Vergleiche (wie .status == .inBacklog),
        // daher laden wir alle Tasks und filtern in Swift
        let descriptor = FetchDescriptor<Task>()
        
        do {
            let allTasks = try modelContext.fetch(descriptor)
            let tasksWithoutCategory = allTasks.filter { 
                $0.status == .inBacklog && $0.category == nil 
            }
            
            // #region agent log
            writeLog(["location": "CategoryService.swift:160", "message": "Migration found tasks", "data": ["allTasksCount": allTasks.count, "tasksWithoutCategoryCount": tasksWithoutCategory.count, "tasksWithoutCategory": tasksWithoutCategory.map { ["id": $0.id.uuidString, "title": $0.title, "status": $0.status.rawValue] }], "timestamp": Int(Date().timeIntervalSince1970 * 1000), "sessionId": "debug-session", "runId": "post-fix", "hypothesisId": "E"])
            // #endregion
            
            for task in tasksWithoutCategory {
                task.category = uncategorizedCategory
            }
            
            if !tasksWithoutCategory.isEmpty {
                try modelContext.save()
                
                // #region agent log
                writeLog(["location": "CategoryService.swift:168", "message": "Migration completed", "data": ["migratedCount": tasksWithoutCategory.count], "timestamp": Int(Date().timeIntervalSince1970 * 1000), "sessionId": "debug-session", "runId": "post-fix", "hypothesisId": "E"])
                // #endregion
            }
        } catch {
            print("Fehler beim Migrieren der Tasks: \(error)")
        }
    }
}

