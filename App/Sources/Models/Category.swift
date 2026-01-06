//
//  Category.swift
//  Dawny
//
//  SwiftData Model für Backlog-Kategorien
//

import Foundation
import SwiftData

@Model
final class Category {
    // MARK: - Stored Properties
    
    /// Eindeutige ID
    var id: UUID
    
    /// Kategorie-Typ (Enum)
    var categoryType: TaskCategory
    
    /// Name der Kategorie (lokalisiert, kann überschrieben werden)
    var name: String
    
    /// SF Symbol Icon-Name
    var iconName: String
    
    /// Sortierungs-Index (für konfigurierbare Reihenfolge)
    var orderIndex: Int
    
    /// Flag ob dies die "Unkategorisiert"-Kategorie ist
    var isUncategorized: Bool
    
    /// Erstellungsdatum
    var createdAt: Date
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        categoryType: TaskCategory,
        name: String? = nil,
        iconName: String? = nil,
        orderIndex: Int? = nil,
        isUncategorized: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.categoryType = categoryType
        self.name = name ?? categoryType.displayName
        self.iconName = iconName ?? categoryType.iconName
        self.orderIndex = orderIndex ?? categoryType.defaultOrderIndex
        self.isUncategorized = isUncategorized || (categoryType == .uncategorized)
        self.createdAt = createdAt
    }
}

// MARK: - Equatable

extension Category: Equatable {
    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Comparable

extension Category: Comparable {
    static func < (lhs: Category, rhs: Category) -> Bool {
        // Primär nach orderIndex
        if lhs.orderIndex != rhs.orderIndex {
            return lhs.orderIndex < rhs.orderIndex
        }
        // Sekundär nach Erstellungsdatum
        return lhs.createdAt < rhs.createdAt
    }
}


