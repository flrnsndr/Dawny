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
        
        // Lade defaultCategoryType
        if let data = UserDefaults.standard.data(forKey: Keys.defaultCategoryType),
           let rawValue = try? JSONDecoder().decode(String.self, from: data),
           let categoryType = TaskCategory(rawValue: rawValue) {
            self.defaultCategoryType = categoryType
        } else {
            self.defaultCategoryType = .quick
        }
    }
    
    // MARK: - Singleton
    
    /// Shared Instance für App-weite Nutzung
    static let shared = AppSettings()
}

