//
//  TaskCategory.swift
//  Dawny
//
//  Enum für Backlog-Kategorien
//

import Foundation

/// Kategorien für Backlog-Tasks
enum TaskCategory: String, Codable, CaseIterable {
    /// Schnell erledigen
    case quick
    
    /// Diese Woche
    case thisWeek
    
    /// Diesen Monat
    case thisMonth
    
    /// Dieses Jahr
    case thisYear
    
    /// Irgendwann
    case someday
    
    /// Unkategorisiert (speziell)
    case uncategorized

    /// Benutzerdefinierte Kategorie (mehrfach anlegbar; Anzeige aus `Category.name` / `iconName`)
    case custom
    
    /// Lokalisierter Display-Name
    var displayName: String {
        switch self {
        case .quick:
            return String(localized: "category.quick.name", defaultValue: "Schnell erledigen")
        case .thisWeek:
            return String(localized: "category.thisWeek.name", defaultValue: "Diese Woche")
        case .thisMonth:
            return String(localized: "category.thisMonth.name", defaultValue: "Diesen Monat")
        case .thisYear:
            return String(localized: "category.thisYear.name", defaultValue: "Dieses Jahr")
        case .someday:
            return String(localized: "category.someday.name", defaultValue: "Irgendwann")
        case .uncategorized:
            return String(localized: "category.uncategorized.name", defaultValue: "Unkategorisiert")
        case .custom:
            return String(localized: "category.custom.name", defaultValue: "Neue Kategorie")
        }
    }
    
    /// SF Symbol Icon-Name
    var iconName: String {
        switch self {
        case .quick:
            return "bolt.fill"
        case .thisWeek:
            return "calendar"
        case .thisMonth:
            return "calendar.badge.clock"
        case .thisYear:
            return "calendar.badge.exclamationmark"
        case .someday:
            return "infinity"
        case .uncategorized:
            return "tag"
        case .custom:
            return "tag"
        }
    }
    
    /// Standard-Reihenfolge-Index (für initiale Sortierung)
    var defaultOrderIndex: Int {
        switch self {
        case .quick:
            return 0
        case .thisWeek:
            return 1
        case .thisMonth:
            return 2
        case .thisYear:
            return 3
        case .someday:
            return 4
        case .uncategorized:
            return 5
        case .custom:
            return 6
        }
    }
}

