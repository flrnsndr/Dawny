//
//  TaskStatus.swift
//  Dawn
//
//  Task Status Enum
//

import Foundation

/// Status eines Tasks im System-Lebenszyklus
enum TaskStatus: String, Codable, CaseIterable {
    /// Task ist im Backlog und wartet auf Planung
    case inBacklog
    
    /// Task ist für einen zukünftigen Tag geplant
    case scheduled
    
    /// Task ist für heute im Daily Focus
    case dailyFocus
    
    /// Task wurde abgeschlossen
    case completed
    
    var displayName: String {
        switch self {
        case .inBacklog:
            return "Backlog"
        case .scheduled:
            return "Geplant"
        case .dailyFocus:
            return "Heute"
        case .completed:
            return "Erledigt"
        }
    }
    
    /// Gibt an ob der Task im Kalender synchronisiert werden soll
    var shouldSyncToCalendar: Bool {
        self == .dailyFocus
    }
}
