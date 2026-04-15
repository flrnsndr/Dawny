//
//  DawnyUITests.swift
//  DawnyUITests
//
//  UI Tests für Dawny App
//

import XCTest

final class DawnyUITests: XCTestCase {
    
    var app: XCUIApplication!
    
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

        // Prüfe dass beide Tabs existieren
        // Note: Tests verwenden lokalisierte Strings - funktioniert mit Deutsch und Englisch
        let heuteTab = app.tabBars.buttons["Heute"]
        let todayTab = app.tabBars.buttons["Today"]
        let backlogTab = app.tabBars.buttons["Backlog"]
        
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
        let backlogTab = app.tabBars.buttons["Backlog"]
        XCTAssertTrue(backlogTab.waitForExistence(timeout: 5))
        backlogTab.tap()
        
        // Tippe auf + Button
        let addButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()
        
        // Warte auf Sheet - TextField hat Placeholder "Task" (lokalisiert)
        let titleField = app.textFields["Task"]
        if titleField.waitForExistence(timeout: 3) {
            titleField.tap()
            titleField.typeText("UI Test Task")
            
            // Tippe auf Hinzufügen/Add (lokalisiert)
            let addTaskButtonDE = app.buttons["Hinzufügen"]
            let addTaskButtonEN = app.buttons["Add"]
            if addTaskButtonDE.exists && addTaskButtonDE.isEnabled {
                addTaskButtonDE.tap()
            } else if addTaskButtonEN.exists && addTaskButtonEN.isEnabled {
                addTaskButtonEN.tap()
            }
        }
    }
    
    func testShowWelcomeFromSettingsHelpButton() throws {
        dismissWelcomeIfShown()
        
        let settingsButton = app.navigationBars.buttons["Einstellungen"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()
        
        let welcomeHelpButton = app.navigationBars.buttons["Willkommensbildschirm anzeigen"]
        XCTAssertTrue(welcomeHelpButton.waitForExistence(timeout: 3))
        welcomeHelpButton.tap()
        
        let welcomeTitle = app.staticTexts["Willkommen bei Dawny"]
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: 5))
    }
    
    // MARK: - Performance Tests
    
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
