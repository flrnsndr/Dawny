//
//  MockTimeProvider.swift
//  DawnTests
//
//  Mock-Implementierung für testbare Zeit
//

import Foundation
@testable import Dawn

final class MockTimeProvider: TimeProvider {
    private var _currentDate: Date
    private var _calendar: Calendar
    
    var currentDate: Date {
        _currentDate
    }
    
    var calendar: Calendar {
        _calendar
    }
    
    init(currentDate: Date = Date(), calendar: Calendar = .current) {
        self._currentDate = currentDate
        self._calendar = calendar
    }
    
    /// Setzt die Zeit für Tests
    func setCurrentDate(_ date: Date) {
        _currentDate = date
    }
    
    /// Fügt Zeit hinzu (für Time-Travel)
    func advance(by timeInterval: TimeInterval) {
        _currentDate = _currentDate.addingTimeInterval(timeInterval)
    }
    
    /// Springt zu einem spezifischen Datum und Zeit
    func travel(to date: Date) {
        _currentDate = date
    }
    
    /// Erstellt ein Datum für Tests
    static func createDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
