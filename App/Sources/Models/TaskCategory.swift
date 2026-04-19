// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

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
            return String(localized: "category.quick.name", defaultValue: "Quick")
        case .thisWeek:
            return String(localized: "category.thisWeek.name", defaultValue: "This Week")
        case .thisMonth:
            return String(localized: "category.thisMonth.name", defaultValue: "This Month")
        case .thisYear:
            return String(localized: "category.thisYear.name", defaultValue: "This Year")
        case .someday:
            return String(localized: "category.someday.name", defaultValue: "Someday")
        case .uncategorized:
            return String(localized: "category.uncategorized.name", defaultValue: "Uncategorized")
        case .custom:
            return String(localized: "category.custom.name", defaultValue: "New category")
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

