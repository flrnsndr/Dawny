// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  AppSettings.swift
//  Dawny
//
//  App-Einstellungen mit UserDefaults-Persistenz
//

import Foundation
import Observation

/// Verwaltet App-Einstellungen mit UserDefaults-Persistenz
@Observable
final class AppSettings {
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let resetHour = "DawnyResetHour"
        static let calendarSyncEnabled = "DawnyCalendarSyncEnabled"
        static let showCompletedTasksInToday = "DawnyShowCompletedTasksInToday"
        static let showCategories = "DawnyShowCategories"
        static let defaultCategoryType = "DawnyDefaultCategoryType"
        static let hasSeenWelcome = "DawnyHasSeenWelcome"
        static let makeItCountThreshold = "DawnyMakeItCountThreshold"
        static let hasNewArchivedTasks = "DawnyHasNewArchivedTasks"
        static let appLaunchCount = "DawnyAppLaunchCount"
        static let totalResetEventCount = "DawnyTotalResetEventCount"
        static let lastReviewPromptDate = "DawnyLastReviewPromptDate"
    }
    
    // MARK: - Properties
    
    /// Reset-Zeit in Stunden (0-23)
    var resetHour: Int {
        didSet {
            UserDefaults.standard.set(resetHour, forKey: Keys.resetHour)
        }
    }
    
    /// Kalender-Synchronisation aktiviert
    var calendarSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(calendarSyncEnabled, forKey: Keys.calendarSyncEnabled)
        }
    }
    
    /// Erledigte Tasks im Heute-Tab anzeigen
    var showCompletedTasksInToday: Bool {
        didSet {
            UserDefaults.standard.set(showCompletedTasksInToday, forKey: Keys.showCompletedTasksInToday)
        }
    }
    
    /// Kategorien im Backlog anzeigen
    var showCategories: Bool {
        didSet {
            UserDefaults.standard.set(showCategories, forKey: Keys.showCategories)
        }
    }
    
    /// Welcome Screen wurde bereits angezeigt
    var hasSeenWelcome: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenWelcome, forKey: Keys.hasSeenWelcome)
        }
    }

    /// Anzahl der fehlgeschlagenen Resets, bevor ein Task archiviert wird (1–7, Standard: 1)
    var makeItCountThreshold: Int {
        didSet {
            UserDefaults.standard.set(makeItCountThreshold, forKey: Keys.makeItCountThreshold)
        }
    }

    /// Zeigt an ob beim letzten Reset neue Tasks ins Archiv verschoben wurden (Dot-Badge)
    var hasNewArchivedTasks: Bool {
        didSet {
            UserDefaults.standard.set(hasNewArchivedTasks, forKey: Keys.hasNewArchivedTasks)
        }
    }
    
    /// Anzahl der App-Starts (für Review-Prompt-Eligibility)
    var appLaunchCount: Int {
        didSet {
            UserDefaults.standard.set(appLaunchCount, forKey: Keys.appLaunchCount)
        }
    }

    /// Anzahl abgeschlossener Reset-Events (für Review-Prompt-Eligibility)
    var totalResetEventCount: Int {
        didSet {
            UserDefaults.standard.set(totalResetEventCount, forKey: Keys.totalResetEventCount)
        }
    }

    /// Datum des letzten Review-Prompts (Rate-Limiting)
    var lastReviewPromptDate: Date? {
        didSet {
            UserDefaults.standard.set(lastReviewPromptDate, forKey: Keys.lastReviewPromptDate)
        }
    }

    /// Standard-Kategorie für neue Tasks (wenn Kategorien aktiviert)
    var defaultCategoryType: TaskCategory {
        didSet {
            if let encoded = try? JSONEncoder().encode(defaultCategoryType.rawValue) {
                UserDefaults.standard.set(encoded, forKey: Keys.defaultCategoryType)
            }
        }
    }
    
    // MARK: - Initializer
    
    init() {
        // Lade Werte aus UserDefaults oder verwende Defaults
        self.resetHour = UserDefaults.standard.object(forKey: Keys.resetHour) as? Int ?? 3
        self.calendarSyncEnabled = UserDefaults.standard.object(forKey: Keys.calendarSyncEnabled) as? Bool ?? true
        self.showCompletedTasksInToday = UserDefaults.standard.object(forKey: Keys.showCompletedTasksInToday) as? Bool ?? true
        self.showCategories = UserDefaults.standard.object(forKey: Keys.showCategories) as? Bool ?? true
        self.hasSeenWelcome = UserDefaults.standard.bool(forKey: Keys.hasSeenWelcome)
        self.makeItCountThreshold = UserDefaults.standard.object(forKey: Keys.makeItCountThreshold) as? Int ?? 1
        self.hasNewArchivedTasks = UserDefaults.standard.bool(forKey: Keys.hasNewArchivedTasks)
        self.appLaunchCount = UserDefaults.standard.object(forKey: Keys.appLaunchCount) as? Int ?? 0
        self.totalResetEventCount = UserDefaults.standard.object(forKey: Keys.totalResetEventCount) as? Int ?? 0
        self.lastReviewPromptDate = UserDefaults.standard.object(forKey: Keys.lastReviewPromptDate) as? Date
        
        // Lade defaultCategoryType
        if let data = UserDefaults.standard.data(forKey: Keys.defaultCategoryType),
           let rawValue = try? JSONDecoder().decode(String.self, from: data),
           let categoryType = TaskCategory(rawValue: rawValue) {
            self.defaultCategoryType = categoryType
        } else {
            self.defaultCategoryType = .quick
        }
    }
    
    // MARK: - Computed

    /// True wenn alle Bedingungen für den Review-Prompt erfüllt sind
    var isEligibleForReviewPrompt: Bool {
        guard appLaunchCount >= 5, totalResetEventCount >= 2 else { return false }
        if let last = lastReviewPromptDate {
            return Date().timeIntervalSince(last) >= 60 * 60 * 24 * 60
        }
        return true
    }

    // MARK: - Singleton

    /// Shared Instance für App-weite Nutzung
    static let shared = AppSettings()
}

