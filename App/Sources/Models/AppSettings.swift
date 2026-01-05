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
    
    // MARK: - Initializer
    
    init() {
        // Lade Werte aus UserDefaults oder verwende Defaults
        self.resetHour = UserDefaults.standard.object(forKey: Keys.resetHour) as? Int ?? 3
        self.calendarSyncEnabled = UserDefaults.standard.object(forKey: Keys.calendarSyncEnabled) as? Bool ?? true
        self.showCompletedTasksInToday = UserDefaults.standard.object(forKey: Keys.showCompletedTasksInToday) as? Bool ?? true
    }
    
    // MARK: - Singleton
    
    /// Shared Instance für App-weite Nutzung
    static let shared = AppSettings()
}

