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
    
    func testTabNavigation() throws {
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
    
    // MARK: - Performance Tests
    
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
