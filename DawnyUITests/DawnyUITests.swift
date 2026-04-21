// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  DawnyUITests.swift
//  DawnyUITests
//
//  UI Tests für Dawny App
//

import XCTest

final class DawnyUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    private func robustTap(_ element: XCUIElement) {
        let existsForTap = element.waitForExistence(timeout: 1.5)
        if !existsForTap {
            XCTFail("Element existiert nicht für Tap.")
            return
        }
        
        _ = waitForHittable(element, timeout: 1.5)
        let coordinate = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        coordinate.tap()
    }
    
    private func waitForHittable(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Navigation Tests

    private func dismissWelcomeIfShown() {
        let continueButton = app.buttons["Los geht's"]
        if continueButton.waitForExistence(timeout: 2) {
            continueButton.tap()
            return
        }

        let nextButton = app.buttons["Weiter"]
        if nextButton.waitForExistence(timeout: 1) {
            for _ in 0..<4 where nextButton.exists {
                nextButton.tap()
            }
            if continueButton.waitForExistence(timeout: 1) {
                continueButton.tap()
            }
        }
    }
    
    func testTabNavigation() throws {
        dismissWelcomeIfShown()

        // Prüfe dass beide Tabs existieren (segmentierter Tab-Schalter in ContentView, kein UITabBar)
        // Note: Tests verwenden lokalisierte Accessibility-Labels - funktioniert mit Deutsch und Englisch
        let heuteTab = app.buttons["Heute"]
        let todayTab = app.buttons["Today"]
        let backlogTab = app.buttons["Backlog"]
        
        let todayTabExists = heuteTab.waitForExistence(timeout: 5) || todayTab.waitForExistence(timeout: 5)
        XCTAssertTrue(todayTabExists)
        XCTAssertTrue(backlogTab.exists)
        
        // Wechsle zu Backlog
        backlogTab.tap()
        
        // Wechsle zurück zu Heute/Today
        if heuteTab.exists {
            heuteTab.tap()
        } else if todayTab.exists {
            todayTab.tap()
        }
    }
    
    // MARK: - Task Creation Tests
    
    func testCreateTaskInBacklog() throws {
        dismissWelcomeIfShown()

        // Wechsle zu Backlog
        let backlogTab = app.buttons["Backlog"]
        XCTAssertTrue(backlogTab.waitForExistence(timeout: 5))
        backlogTab.tap()
        
        // UI-Flow über sichtbare Quick-Add Buttons
        let quickAddDE = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Neue Aufgabe in ")).firstMatch
        let quickAddTodayDE = app.buttons["Neue Aufgabe für heute hinzufügen"]
        let quickAddEN = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Add new task in ")).firstMatch
        let quickAddTodayEN = app.buttons["Add new task for today"]
        let addButton = quickAddDE.exists ? quickAddDE
            : (quickAddTodayDE.exists ? quickAddTodayDE
            : (quickAddEN.exists ? quickAddEN : quickAddTodayEN))
        let waits = addButton.waitForExistence(timeout: 3)
        XCTAssertTrue(waits)
        robustTap(addButton)
    }
    
    func testShowWelcomeFromSettingsHelpButton() throws {
        dismissWelcomeIfShown()
        
        let settingsButtonDE = app.buttons["Einstellungen"]
        let settingsButtonEN = app.buttons["Settings"]
        let settingsButton = settingsButtonDE.exists ? settingsButtonDE : settingsButtonEN
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        robustTap(settingsButton)
        
        let welcomeHelpButtonDE = app.buttons["Willkommensbildschirm anzeigen"]
        let welcomeHelpButtonEN = app.buttons["Show Welcome Screen"]
        let welcomeHelpButton = welcomeHelpButtonDE.exists ? welcomeHelpButtonDE : welcomeHelpButtonEN
        let helpWaits = welcomeHelpButton.waitForExistence(timeout: 3)
        XCTAssertTrue(helpWaits)
        robustTap(welcomeHelpButton)
        
        let welcomeTitleDE = app.staticTexts["Willkommen bei Dawny"]
        let welcomeTitleEN = app.staticTexts["Welcome to Dawny"]
        let welcomeDEWaits = welcomeTitleDE.waitForExistence(timeout: 5)
        let welcomeENWaits = welcomeTitleEN.waitForExistence(timeout: 1)
        XCTAssertTrue(welcomeDEWaits || welcomeENWaits)
    }
    
    // MARK: - Performance Tests
    
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
