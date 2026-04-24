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
    
    /// Nächste Tage
    case nextFewDays = "thisWeek"
    
    /// Nächste Wochen
    case nextFewWeeks = "thisMonth"
    
    /// Nächste Monate
    case nextFewMonths = "thisYear"
    
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
        case .nextFewDays:
            return String(localized: "category.nextFewDays.name", defaultValue: "Next couple of days")
        case .nextFewWeeks:
            return String(localized: "category.nextFewWeeks.name", defaultValue: "Next couple of weeks")
        case .nextFewMonths:
            return String(localized: "category.nextFewMonths.name", defaultValue: "Next couple of months")
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
        case .nextFewDays:
            return "calendar"
        case .nextFewWeeks:
            return "calendar.badge.clock"
        case .nextFewMonths:
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
        case .nextFewDays:
            return 1
        case .nextFewWeeks:
            return 2
        case .nextFewMonths:
            return 3
        case .someday:
            return 5
        case .uncategorized:
            return 6
        case .custom:
            return 7
        }
    }
}

