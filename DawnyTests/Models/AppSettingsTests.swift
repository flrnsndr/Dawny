// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  AppSettingsTests.swift
//  DawnyTests
//
//  Unit Tests für AppSettings
//

import XCTest
@testable import Dawny

@MainActor
final class AppSettingsTests: XCTestCase {
    
    var settings: AppSettings!
    
    override func setUp() async throws {
        // Erstelle eine neue Settings-Instanz für jeden Test
        settings = AppSettings()
        
        // Setze Standardwerte für Tests
        settings.resetHour = 3
        settings.calendarSyncEnabled = true
        settings.showCompletedTasksInToday = true
    }
    
    override func tearDown() async throws {
        // Bereinige UserDefaults nach jedem Test
        UserDefaults.standard.removeObject(forKey: "DawnyResetHour")
        UserDefaults.standard.removeObject(forKey: "DawnyCalendarSyncEnabled")
        UserDefaults.standard.removeObject(forKey: "DawnyShowCompletedTasksInToday")
        settings = nil
    }
    
    // MARK: - Initialization Tests
    
    func testDefaultValues() {
        let newSettings = AppSettings()
        
        XCTAssertEqual(newSettings.resetHour, 3, "Standard Reset-Zeit sollte 3 Uhr sein")
        XCTAssertTrue(newSettings.calendarSyncEnabled, "Kalender-Sync sollte standardmäßig aktiviert sein")
        XCTAssertTrue(newSettings.showCompletedTasksInToday, "Erledigte Tasks sollten standardmäßig angezeigt werden")
    }
    
    func testLoadsFromUserDefaults() {
        // Setze Werte in UserDefaults
        UserDefaults.standard.set(5, forKey: "DawnyResetHour")
        UserDefaults.standard.set(false, forKey: "DawnyCalendarSyncEnabled")
        UserDefaults.standard.set(false, forKey: "DawnyShowCompletedTasksInToday")
        
        // Erstelle neue Settings-Instanz
        let newSettings = AppSettings()
        
        XCTAssertEqual(newSettings.resetHour, 5, "Sollte Wert aus UserDefaults laden")
        XCTAssertFalse(newSettings.calendarSyncEnabled, "Sollte Wert aus UserDefaults laden")
        XCTAssertFalse(newSettings.showCompletedTasksInToday, "Sollte Wert aus UserDefaults laden")
        
        // Bereinige
        UserDefaults.standard.removeObject(forKey: "DawnyResetHour")
        UserDefaults.standard.removeObject(forKey: "DawnyCalendarSyncEnabled")
        UserDefaults.standard.removeObject(forKey: "DawnyShowCompletedTasksInToday")
    }
    
    // MARK: - Reset Hour Tests
    
    func testResetHourPersistence() {
        settings.resetHour = 5
        
        // Prüfe dass Wert in UserDefaults gespeichert wurde
        let savedValue = UserDefaults.standard.integer(forKey: "DawnyResetHour")
        XCTAssertEqual(savedValue, 5)
        
        // Prüfe dass Property aktualisiert wurde
        XCTAssertEqual(settings.resetHour, 5)
    }
    
    func testResetHourRange() {
        // Teste verschiedene gültige Werte
        settings.resetHour = 0
        XCTAssertEqual(settings.resetHour, 0)
        
        settings.resetHour = 12
        XCTAssertEqual(settings.resetHour, 12)
        
        settings.resetHour = 23
        XCTAssertEqual(settings.resetHour, 23)
    }
    
    // MARK: - Calendar Sync Tests
    
    func testCalendarSyncEnabledPersistence() {
        settings.calendarSyncEnabled = false
        
        let savedValue = UserDefaults.standard.bool(forKey: "DawnyCalendarSyncEnabled")
        XCTAssertFalse(savedValue)
        XCTAssertFalse(settings.calendarSyncEnabled)
    }
    
    func testCalendarSyncEnabledToggle() {
        XCTAssertTrue(settings.calendarSyncEnabled)
        
        settings.calendarSyncEnabled = false
        XCTAssertFalse(settings.calendarSyncEnabled)
        
        settings.calendarSyncEnabled = true
        XCTAssertTrue(settings.calendarSyncEnabled)
    }
    
    // MARK: - Show Completed Tasks Tests
    
    func testShowCompletedTasksInTodayPersistence() {
        settings.showCompletedTasksInToday = false
        
        let savedValue = UserDefaults.standard.bool(forKey: "DawnyShowCompletedTasksInToday")
        XCTAssertFalse(savedValue)
        XCTAssertFalse(settings.showCompletedTasksInToday)
    }
    
    func testShowCompletedTasksInTodayToggle() {
        XCTAssertTrue(settings.showCompletedTasksInToday)
        
        settings.showCompletedTasksInToday = false
        XCTAssertFalse(settings.showCompletedTasksInToday)
        
        settings.showCompletedTasksInToday = true
        XCTAssertTrue(settings.showCompletedTasksInToday)
    }
    
    // MARK: - Singleton Tests
    
    func testSharedInstance() {
        let shared1 = AppSettings.shared
        let shared2 = AppSettings.shared
        
        // Sollte die gleiche Instanz sein
        XCTAssertTrue(shared1 === shared2)
    }
    
    func testSharedInstancePersistence() {
        AppSettings.shared.resetHour = 7
        
        // Neue Referenz sollte den gleichen Wert haben
        let shared = AppSettings.shared
        XCTAssertEqual(shared.resetHour, 7)
        
        // Zurücksetzen
        AppSettings.shared.resetHour = 3
    }
}

