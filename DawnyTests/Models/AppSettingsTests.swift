// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

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
        AppGroup.defaults.removeObject(forKey: "DawnyResetHour")
        AppGroup.defaults.removeObject(forKey: "DawnyCalendarSyncEnabled")
        AppGroup.defaults.removeObject(forKey: "DawnyShowCompletedTasksInToday")
        AppGroup.defaults.removeObject(forKey: AppSettings.Keys.iCloudSyncEnabled)
        AppGroup.defaults.removeObject(forKey: AppSettings.Keys.hasSeenICloudSyncIntro)
        settings = nil
    }
    
    // MARK: - Initialization Tests
    
    func testDefaultValues() {
        let newSettings = AppSettings()
        
        XCTAssertEqual(newSettings.resetHour, 3, "Standard Reset-Zeit sollte 3 Uhr sein")
        XCTAssertTrue(newSettings.calendarSyncEnabled, "Kalender-Sync sollte standardmäßig aktiviert sein")
        XCTAssertTrue(newSettings.showCompletedTasksInToday, "Erledigte Tasks sollten standardmäßig angezeigt werden")
    }

    /// Der Sync bleibt aus, bis der Nutzer den einmaligen Hinweis bestätigt hat.
    /// Sonst würde ein Update ungefragt zwei Gerätestände zusammenführen.
    func testICloudSyncIsDisabledUntilTheUserOptsIn() {
        AppGroup.defaults.removeObject(forKey: AppSettings.Keys.iCloudSyncEnabled)
        AppGroup.defaults.removeObject(forKey: AppSettings.Keys.hasSeenICloudSyncIntro)

        let fresh = AppSettings()

        XCTAssertFalse(fresh.iCloudSyncEnabled, "Ohne Zustimmung darf der Sync nicht laufen")
        XCTAssertFalse(fresh.hasSeenICloudSyncIntro, "Der Hinweis gilt erst nach dem Bestätigen als gesehen")
    }

    /// Ein einmal gesetztes Opt-out muss den Neustart überleben.
    func testICloudSyncOptOutIsPersisted() {
        AppGroup.defaults.set(false, forKey: AppSettings.Keys.iCloudSyncEnabled)
        defer { AppGroup.defaults.removeObject(forKey: AppSettings.Keys.iCloudSyncEnabled) }

        XCTAssertFalse(AppSettings().iCloudSyncEnabled, "Ein abgeschaltetes Opt-out darf nicht zurückspringen")
    }

    /// Zustimmung im Hinweis: Sync an, Hinweis erledigt, beides übersteht den Neustart.
    func testOptInFromIntroEnablesSyncPersistently() {
        AppGroup.defaults.removeObject(forKey: AppSettings.Keys.iCloudSyncEnabled)
        AppGroup.defaults.removeObject(forKey: AppSettings.Keys.hasSeenICloudSyncIntro)

        let previous = (AppSettings.shared.iCloudSyncEnabled, AppSettings.shared.hasSeenICloudSyncIntro)
        defer {
            AppSettings.shared.iCloudSyncEnabled = previous.0
            AppSettings.shared.hasSeenICloudSyncIntro = previous.1
        }

        ICloudSyncOptIn.apply(true)

        let afterRelaunch = AppSettings()
        XCTAssertTrue(afterRelaunch.iCloudSyncEnabled, "Nach dem Okay soll der Sync beim nächsten Start greifen")
        XCTAssertTrue(afterRelaunch.hasSeenICloudSyncIntro, "Der Hinweis darf nicht erneut erscheinen")
    }

    /// Ablehnung im Hinweis: Sync bleibt aus, der Hinweis kommt trotzdem nicht wieder.
    func testOptOutFromIntroKeepsSyncOffButMarksIntroSeen() {
        AppGroup.defaults.removeObject(forKey: AppSettings.Keys.iCloudSyncEnabled)
        AppGroup.defaults.removeObject(forKey: AppSettings.Keys.hasSeenICloudSyncIntro)

        let previous = (AppSettings.shared.iCloudSyncEnabled, AppSettings.shared.hasSeenICloudSyncIntro)
        defer {
            AppSettings.shared.iCloudSyncEnabled = previous.0
            AppSettings.shared.hasSeenICloudSyncIntro = previous.1
        }

        ICloudSyncOptIn.apply(false)

        let afterRelaunch = AppSettings()
        XCTAssertFalse(afterRelaunch.iCloudSyncEnabled, "Ein abgelehnter Sync darf nicht doch anspringen")
        XCTAssertTrue(afterRelaunch.hasSeenICloudSyncIntro, "Auch die Ablehnung ist eine Entscheidung")
    }
    
    func testLoadsFromUserDefaults() {
        // Setze Werte in UserDefaults
        AppGroup.defaults.set(5, forKey: "DawnyResetHour")
        AppGroup.defaults.set(false, forKey: "DawnyCalendarSyncEnabled")
        AppGroup.defaults.set(false, forKey: "DawnyShowCompletedTasksInToday")
        
        // Erstelle neue Settings-Instanz
        let newSettings = AppSettings()
        
        XCTAssertEqual(newSettings.resetHour, 5, "Sollte Wert aus UserDefaults laden")
        XCTAssertFalse(newSettings.calendarSyncEnabled, "Sollte Wert aus UserDefaults laden")
        XCTAssertFalse(newSettings.showCompletedTasksInToday, "Sollte Wert aus UserDefaults laden")
        
        // Bereinige
        AppGroup.defaults.removeObject(forKey: "DawnyResetHour")
        AppGroup.defaults.removeObject(forKey: "DawnyCalendarSyncEnabled")
        AppGroup.defaults.removeObject(forKey: "DawnyShowCompletedTasksInToday")
    }
    
    // MARK: - Reset Hour Tests
    
    func testResetHourPersistence() {
        settings.resetHour = 5
        
        // Prüfe dass Wert in UserDefaults gespeichert wurde
        let savedValue = AppGroup.defaults.integer(forKey: "DawnyResetHour")
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
        
        let savedValue = AppGroup.defaults.bool(forKey: "DawnyCalendarSyncEnabled")
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
        
        let savedValue = AppGroup.defaults.bool(forKey: "DawnyShowCompletedTasksInToday")
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

