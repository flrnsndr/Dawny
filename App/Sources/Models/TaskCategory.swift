//
//  TaskCategory.swift
//  Dawny
//
//  Enum für Backlog-Kategorien
//

import Foundation

/// Kategorien für Tasks im Backlog
enum TaskCategory: String, Codable, CaseIterable, Identifiable {
    case uncategorized = "uncategorized"
    case quickWin = "quickWin"
    case thisWeek = "thisWeek"
    case thisMonth = "thisMonth"
    case thisYear = "thisYear"
    case someday = "someday"
    
    var id: String { rawValue }
    
    // MARK: - Display Properties
    
    /// Lokalisierter Anzeigename der Kategorie
    var displayName: String {
        switch self {
        case .uncategorized:
            return String(localized: "category.uncategorized", defaultValue: "Unkategorisiert")
        case .quickWin:
            return String(localized: "category.quickWin", defaultValue: "Schnell erledigen")
        case .thisWeek:
            return String(localized: "category.thisWeek", defaultValue: "Diese Woche")
        case .thisMonth:
            return String(localized: "category.thisMonth", defaultValue: "Diesen Monat")
        case .thisYear:
            return String(localized: "category.thisYear", defaultValue: "Dieses Jahr")
        case .someday:
            return String(localized: "category.someday", defaultValue: "Irgendwann")
        }
    }
    
    /// SF Symbol Icon für die Kategorie
    var icon: String {
        switch self {
        case .uncategorized:
            return "questionmark.folder"
        case .quickWin:
            return "bolt.fill"
        case .thisWeek:
            return "calendar.badge.clock"
        case .thisMonth:
            return "calendar"
        case .thisYear:
            return "calendar.badge.plus"
        case .someday:
            return "cloud"
        }
    }
    
    /// Alias für icon (Kompatibilität mit Category Model)
    var iconName: String { icon }
    
    /// Sortierreihenfolge der Kategorien (niedrigere Werte = weiter oben)
    var sortOrder: Int {
        switch self {
        case .uncategorized: return 0
        case .quickWin: return 1
        case .thisWeek: return 2
        case .thisMonth: return 3
        case .thisYear: return 4
        case .someday: return 5
        }
    }
    
    /// Alias für sortOrder (Kompatibilität mit Category Model)
    var defaultOrderIndex: Int { sortOrder }
    
    // MARK: - Helper Methods
    
    /// Alle Kategorien außer "Unkategorisiert" (für Picker in Settings)
    static var selectableCategories: [TaskCategory] {
        allCases.filter { $0 != .uncategorized }
    }
    
    /// Alle Kategorien sortiert nach Reihenfolge
    static var sorted: [TaskCategory] {
        allCases.sorted { $0.sortOrder < $1.sortOrder }
    }
}

// MARK: - Comparable

extension TaskCategory: Comparable {
    static func < (lhs: TaskCategory, rhs: TaskCategory) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

