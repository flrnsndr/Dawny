//
//  CategoryService.swift
//  Dawny
//
//  Service für Kategorien-Management und Initialisierung
//

import Foundation
import SwiftData

/// Service für Kategorien-Management
final class CategoryService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Initialisiert die Standard-Kategorien beim ersten App-Start
    func initializeDefaultCategories() {
        // Prüfe ob bereits Kategorien existieren
        let descriptor = FetchDescriptor<Category>()
        do {
            let existingCategories = try modelContext.fetch(descriptor)
            
            if !existingCategories.isEmpty {
                // Kategorien existieren bereits
                return
            }
        } catch {
            // Fehler beim Laden - versuche trotzdem zu erstellen
            print("Fehler beim Laden der Kategorien: \(error)")
        }
        
        // Erstelle alle Standard-Kategorien
        let categories: [TaskCategory] = [.quickWin, .thisWeek, .thisMonth, .thisYear, .someday, .uncategorized]
        
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
        } catch {
            print("Fehler beim Speichern der Standard-Kategorien: \(error)")
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
            return try modelContext.fetch(descriptor)
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
        // SwiftData Predicates unterstützen weder == nil für Relationships
        // noch Enum-Vergleiche (wie .status == .inBacklog),
        // daher laden wir alle Tasks und filtern in Swift
        let descriptor = FetchDescriptor<Task>()
        
        do {
            let allTasks = try modelContext.fetch(descriptor)
            let tasksWithoutCategory = allTasks.filter { 
                $0.status == .inBacklog && $0.category == nil 
            }
            
            for task in tasksWithoutCategory {
                task.category = .uncategorized
            }
            
            if !tasksWithoutCategory.isEmpty {
                try modelContext.save()
            }
        } catch {
            print("Fehler beim Migrieren der Tasks: \(error)")
        }
    }
}
