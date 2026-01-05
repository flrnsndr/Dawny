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
        let heuteTab = app.tabBars.buttons["Heute"]
        let backlogTab = app.tabBars.buttons["Backlog"]
        
        XCTAssertTrue(heuteTab.waitForExistence(timeout: 5))
        XCTAssertTrue(backlogTab.exists)
        
        // Wechsle zu Backlog
        backlogTab.tap()
        
        // Wechsle zurück zu Heute
        heuteTab.tap()
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
        
        // Warte auf Sheet - TextField hat Placeholder "Task"
        let titleField = app.textFields["Task"]
        if titleField.waitForExistence(timeout: 3) {
            titleField.tap()
            titleField.typeText("UI Test Task")
            
            // Tippe auf Hinzufügen
            let addTaskButton = app.buttons["Hinzufügen"]
            if addTaskButton.exists && addTaskButton.isEnabled {
                addTaskButton.tap()
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

