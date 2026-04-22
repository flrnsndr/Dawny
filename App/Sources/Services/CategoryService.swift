// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  CategoryService.swift
//  Dawny
//
//  Service für Kategorien-Management und Initialisierung
//

import Foundation
import SwiftData

/// Strategie, wie Tasks behandelt werden, wenn der Nutzer eine Kategorie löscht.
enum CategoryDeleteStrategy {
    /// Alle Tasks der Kategorie werden mitgelöscht.
    case deleteTasks
    /// Alle Tasks werden in die "Unkategorisiert"-Kategorie verschoben.
    case moveToUncategorized
}

/// Fehler bei Edit-Operationen auf einer Kategorie.
enum CategoryEditError: LocalizedError {
    case nameEmpty
    case nameTooLong(maxLength: Int)
    case protectedFromRename
    case protectedFromIconChange
    case protectedFromDelete
    case protectedFromRecurring
    case uncategorizedMissing
    case persistence(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .nameEmpty:
            return String(
                localized: "category.rename.errorEmpty",
                defaultValue: "The name can't be empty."
            )
        case .nameTooLong(let maxLength):
            let format = String(
                localized: "category.rename.errorTooLong",
                defaultValue: "The name may be at most %lld characters."
            )
            return String(format: format, locale: .current, maxLength)
        case .protectedFromRename, .protectedFromIconChange, .protectedFromDelete, .protectedFromRecurring:
            return String(
                localized: "category.edit.errorProtected",
                defaultValue: "This category can't be modified."
            )
        case .uncategorizedMissing:
            return String(
                localized: "category.edit.errorUncategorizedMissing",
                defaultValue: "The Uncategorized category couldn't be found."
            )
        case .persistence(let underlying):
            return underlying.localizedDescription
        }
    }
}

/// Service für Kategorien-Management
final class CategoryService {
    /// Maximale Länge eines benutzerdefinierten Kategorienamens.
    static let maxNameLength = 40

    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Initialisiert die Standard-Kategorien beim ersten App-Start und
    /// legt bei Bedarf die Standard-„Wiederkehrende Aufgaben“-Kategorie an (Idempotent / Migration).
    func initializeDefaultCategories() {
        let descriptor = FetchDescriptor<Category>()
        do {
            var allCategories = try modelContext.fetch(descriptor)

            if allCategories.isEmpty {
                let types: [TaskCategory] = [.quick, .thisWeek, .thisMonth, .thisYear, .someday, .uncategorized]
                for categoryType in types {
                    let category = Category(
                        categoryType: categoryType,
                        orderIndex: categoryType.defaultOrderIndex,
                        isUncategorized: categoryType == .uncategorized
                    )
                    modelContext.insert(category)
                }
                try modelContext.save()
                allCategories = try modelContext.fetch(descriptor)
            }

            if !allCategories.contains(where: { $0.isRecurring }) {
                let nextOrderIndex = (allCategories.map(\.orderIndex).max() ?? -1) + 1
                let defaultName = String(
                    localized: "category.recurring.default.name",
                    defaultValue: "Recurring Tasks"
                )
                let recurring = Category(
                    categoryType: .custom,
                    name: defaultName,
                    iconName: "arrow.triangle.2.circlepath",
                    orderIndex: nextOrderIndex,
                    isUncategorized: false,
                    isNameCustomized: true,
                    isIconCustomized: true,
                    isRecurring: true
                )
                modelContext.insert(recurring)
                try modelContext.save()
            }
        } catch {
            print("Fehler bei Standard-Kategorien / wiederkehrender Default: \(error)")
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
            
            return categories
        } catch {
            print("Fehler beim Laden der Kategorien: \(error)")
            return []
        }
    }
    
    /// Legt eine neue benutzerdefinierte Kategorie an (erscheint nach bestehenden Einträgen, typisch unter „Unkategorisiert“).
    /// - Parameter isRecurring: Wenn `true`, passendes Default-Symbol und `isRecurring` auf dem Modell.
    func createCustom(name: String, isRecurring: Bool = false) throws -> Category {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CategoryEditError.nameEmpty
        }
        guard trimmed.count <= Self.maxNameLength else {
            throw CategoryEditError.nameTooLong(maxLength: Self.maxNameLength)
        }

        let descriptor = FetchDescriptor<Category>()
        let existing = try modelContext.fetch(descriptor)
        let nextOrderIndex = (existing.map(\.orderIndex).max() ?? -1) + 1

        let icon = isRecurring ? "arrow.triangle.2.circlepath" : TaskCategory.custom.iconName
        let category = Category(
            categoryType: .custom,
            name: trimmed,
            iconName: icon,
            orderIndex: nextOrderIndex,
            isUncategorized: false,
            isNameCustomized: true,
            isIconCustomized: true,
            isRecurring: isRecurring
        )
        modelContext.insert(category)
        try save()
        return category
    }

    /// Setzt die Eigenschaft „wiederkehrend“ auf einer Kategorie.
    func setRecurring(_ category: Category, to newValue: Bool) throws {
        guard category.canToggleRecurring else {
            throw CategoryEditError.protectedFromRecurring
        }
        if category.isRecurring == newValue { return }
        category.isRecurring = newValue
        try save()
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
    
    // MARK: - Edit Operations

    /// Benennt eine Kategorie um. Trimmt Whitespace, validiert Länge und
    /// markiert den Namen als benutzerdefiniert (für Lokalisierungs-Logik).
    @discardableResult
    func rename(_ category: Category, to newName: String) throws -> String {
        guard category.canRename else {
            throw CategoryEditError.protectedFromRename
        }

        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CategoryEditError.nameEmpty
        }
        guard trimmed.count <= Self.maxNameLength else {
            throw CategoryEditError.nameTooLong(maxLength: Self.maxNameLength)
        }

        // Wenn sich nichts geändert hat: nichts tun (vermeidet unnötige Saves
        // und unnötiges Setzen von isNameCustomized).
        if category.isNameCustomized && category.name == trimmed {
            return trimmed
        }

        category.name = trimmed
        category.isNameCustomized = true

        try save()
        return trimmed
    }

    /// Setzt das Symbol einer Kategorie und markiert es als benutzerdefiniert.
    func updateIcon(_ category: Category, to symbolName: String) throws {
        guard category.canChangeIcon else {
            throw CategoryEditError.protectedFromIconChange
        }

        let trimmed = symbolName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            // Leeres Symbol fällt zurück auf Default → wir entfernen die Custom-Markierung.
            category.isIconCustomized = false
            try save()
            return
        }

        category.iconName = trimmed
        category.isIconCustomized = true

        try save()
    }

    /// Löscht eine Kategorie nach gewählter Strategie.
    /// - `.deleteTasks`: alle zugehörigen Tasks (auch bereits abgeschlossene/gescheduelte)
    ///   werden vor dem Entfernen der Kategorie explizit gelöscht.
    /// - `.moveToUncategorized`: alle Tasks werden in die "Unkategorisiert"-Kategorie umgehängt.
    /// Setzt zusätzlich `AppSettings.defaultCategoryType` auf einen sinnvollen Fallback,
    /// falls die gelöschte Kategorie als Standard markiert war.
    func delete(_ category: Category, strategy: CategoryDeleteStrategy) throws {
        guard category.canDelete else {
            throw CategoryEditError.protectedFromDelete
        }

        switch strategy {
        case .deleteTasks:
            // Snapshot, weil wir während der Iteration aus der Relationship löschen.
            let tasksToDelete = category.tasks
            for task in tasksToDelete {
                modelContext.delete(task)
            }

        case .moveToUncategorized:
            guard let uncategorized = getUncategorizedCategory() else {
                throw CategoryEditError.uncategorizedMissing
            }
            // Snapshot wegen Inverse-Relationship-Mutation während der Iteration.
            let tasksToMove = category.tasks
            for task in tasksToMove {
                task.category = uncategorized
                task.modifiedAt = Date()
            }
        }

        // Default-Fallback: zeigt AppSettings noch auf den gerade gelöschten Typ?
        // Dann auf .quick (die einzige garantiert nicht löschbare User-Kategorie) zurücksetzen.
        let settings = AppSettings.shared
        if settings.defaultCategoryType == category.categoryType {
            settings.defaultCategoryType = .quick
        }

        modelContext.delete(category)
        try save()
    }

    // MARK: - Private Helpers

    private func save() throws {
        do {
            try modelContext.save()
        } catch {
            throw CategoryEditError.persistence(underlying: error)
        }
    }

    /// Migriert alle Tasks ohne Kategorie zur "Unkategorisiert"-Kategorie
    func migrateUncategorizedTasks() {
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
            
            for task in tasksWithoutCategory {
                task.category = uncategorizedCategory
            }
            
            if !tasksWithoutCategory.isEmpty {
                try modelContext.save()
            }
        } catch {
            print("Fehler beim Migrieren der Tasks: \(error)")
        }
    }
}

