//
//  TimeProvider.swift
//  Dawn
//
//  Protocol für testbare Zeit-Abhängigkeiten
//

import Foundation

/// Protokoll zur Abstraktion der Zeitabfrage
/// Ermöglicht Time-Travel in Tests durch Mock-Implementierung
protocol TimeProvider {
    /// Gibt die aktuelle Zeit zurück
    var currentDate: Date { get }
    
    /// Gibt das aktuelle Calendar-Objekt zurück
    var calendar: Calendar { get }
}

/// Standard-Implementierung die die echte Systemzeit verwendet
final class SystemTimeProvider: TimeProvider {
    var currentDate: Date {
        Date()
    }
    
    var calendar: Calendar {
        Calendar.current
    }
}
