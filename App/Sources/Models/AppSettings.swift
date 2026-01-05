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
        static let defaultCategory = "DawnyDefaultCategory"
        static let collapsedCategories = "DawnyCollapsedCategories"
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
    
    /// Standard-Kategorie für neue Tasks (wenn Kategorien aktiviert sind)
    var defaultCategory: TaskCategory {
        didSet {
            UserDefaults.standard.set(defaultCategory.rawValue, forKey: Keys.defaultCategory)
        }
    }
    
    /// Set der eingeklappten Kategorien
    var collapsedCategories: Set<TaskCategory> {
        didSet {
            let rawValues = collapsedCategories.map { $0.rawValue }
            UserDefaults.standard.set(rawValues, forKey: Keys.collapsedCategories)
        }
    }
    
    // MARK: - Initializer
    
    init() {
        // Lade Werte aus UserDefaults oder verwende Defaults
        self.resetHour = UserDefaults.standard.object(forKey: Keys.resetHour) as? Int ?? 3
        self.calendarSyncEnabled = UserDefaults.standard.object(forKey: Keys.calendarSyncEnabled) as? Bool ?? true
        self.showCompletedTasksInToday = UserDefaults.standard.object(forKey: Keys.showCompletedTasksInToday) as? Bool ?? true
        self.showCategories = UserDefaults.standard.object(forKey: Keys.showCategories) as? Bool ?? true
        
        // Lade Default-Kategorie
        if let rawValue = UserDefaults.standard.string(forKey: Keys.defaultCategory),
           let category = TaskCategory(rawValue: rawValue) {
            self.defaultCategory = category
        } else {
            self.defaultCategory = .someday
        }
        
        // Lade eingeklappte Kategorien
        if let rawValues = UserDefaults.standard.array(forKey: Keys.collapsedCategories) as? [String] {
            self.collapsedCategories = Set(rawValues.compactMap { TaskCategory(rawValue: $0) })
        } else {
            self.collapsedCategories = []
        }
    }
    
    // MARK: - Singleton
    
    /// Shared Instance für App-weite Nutzung
    static let shared = AppSettings()
    
    // MARK: - Category Helpers
    
    /// Prüft ob eine Kategorie eingeklappt ist
    func isCategoryCollapsed(_ category: TaskCategory) -> Bool {
        collapsedCategories.contains(category)
    }
    
    /// Toggled den Einklapp-Zustand einer Kategorie
    func toggleCategoryCollapsed(_ category: TaskCategory) {
        if collapsedCategories.contains(category) {
            collapsedCategories.remove(category)
        } else {
            collapsedCategories.insert(category)
        }
    }
}

