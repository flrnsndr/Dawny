// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  TaskStatus.swift
//  Dawny
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
            return String(localized: "task.status.backlog", defaultValue: "Backlog")
        case .scheduled:
            return String(localized: "task.status.scheduled", defaultValue: "Scheduled")
        case .dailyFocus:
            return String(localized: "task.status.today", defaultValue: "Today")
        case .completed:
            return String(localized: "task.status.completed", defaultValue: "Completed")
        }
    }
    
    /// Gibt an ob der Task im Kalender synchronisiert werden soll
    var shouldSyncToCalendar: Bool {
        self == .dailyFocus
    }
}
