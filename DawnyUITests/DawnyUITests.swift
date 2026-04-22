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
    
    private func robustTap(_ element: XCUIElement, timeout: TimeInterval = 5) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element existiert nicht für Tap.")
        if !waitForHittable(element, timeout: timeout) {
            // Fallback für kleine Geräte/Übergangsanimationen:
            // Ein koordinatenbasierter Tap funktioniert oft trotzdem zuverlässig.
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            return
        }
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func coordinateTap(_ element: XCUIElement, timeout: TimeInterval = 2) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element existiert nicht für Tap.")
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }
    
    private func waitForHittable(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// SwiftUI-Listen: `firstMatch` kann ein off-screen Eintrag sein (`exists` ja, `hittable` nein).
    private func firstHittableButton(in query: XCUIElementQuery, maxElements: Int = 40) -> XCUIElement? {
        let n = min(query.count, maxElements)
        for i in 0..<n {
            let el = query.element(boundBy: i)
            guard el.exists else { continue }
            if el.isHittable { return el }
        }
        return nil
    }

    private func firstExistingButton(in query: XCUIElementQuery, maxElements: Int = 40) -> XCUIElement? {
        let n = min(query.count, maxElements)
        for i in 0..<n {
            let el = query.element(boundBy: i)
            if el.exists { return el }
        }
        return nil
    }

    private func scrollHostForBacklog() -> XCUIElement {
        let table = app.tables.firstMatch
        if table.waitForExistence(timeout: 0.5) { return table }
        let collection = app.collectionViews.firstMatch
        if collection.waitForExistence(timeout: 0.5) { return collection }
        return app
    }

    /// Sucht einen antippbaren Quick-Add-Button und scrollt bei Bedarf in der Backlog-Liste.
    private func tapVisibleQuickAddInBacklog() {
        let prefixes = ["Neue Aufgabe in ", "Add new task in "]
        for _ in 0..<14 {
            var fallbackCandidate: XCUIElement?
            for prefix in prefixes {
                let q = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix))
                if let hit = firstHittableButton(in: q) {
                    robustTap(hit)
                    return
                }
                if fallbackCandidate == nil, let existing = firstExistingButton(in: q) {
                    fallbackCandidate = existing
                }
            }
            if let fallbackCandidate {
                robustTap(fallbackCandidate)
                return
            }
            let host = scrollHostForBacklog()
            XCTAssertTrue(host.exists)
            host.swipeUp()
        }
        XCTFail("Kein antippbarer Quick-Add-Button nach Scroll-Versuchen gefunden.")
    }
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        // Stabilisiert Label-basierte UI-Tests über verschiedene Simulator-Geräte hinweg.
        app.launchEnvironment["AppleLanguages"] = "(en)"
        app.launchEnvironment["AppleLocale"] = "en_US"
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Navigation Tests

    private func dismissWelcomeIfShown() {
        let startButtons = [app.buttons["Los geht's"], app.buttons["Get started"]]
        let nextButtons = [app.buttons["Weiter"], app.buttons["Continue"]]
        for _ in 0..<10 {
            // Letzte Kachel: Welcome per CTA schließen.
            for start in startButtons where start.exists || start.waitForExistence(timeout: 0.6) {
                coordinateTap(start, timeout: 2)
                return
            }

            // Davor: Schrittweise per Weiter/Continue navigieren.
            if let next = nextButtons.first(where: { $0.exists || $0.waitForExistence(timeout: 0.8) }) {
                coordinateTap(next, timeout: 1.5)
                continue
            }

            // Weder Continue noch Start sichtbar -> Welcome vermutlich nicht präsent.
            return
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

        // Quick-Entry: nicht `firstMatch` — kann off-screen sein; erst sichtbaren Eintrag wählen / scrollen.
        tapVisibleQuickAddInBacklog()
    }
    
    func testShowWelcomeFromSettingsHelpButton() throws {
        dismissWelcomeIfShown()
        
        let settingsById = app.buttons["ToolbarSettingsButton"]
        let settingsButtonDE = app.buttons["Einstellungen"]
        let settingsButtonEN = app.buttons["Settings"]
        let settingsButton: XCUIElement
        // Label zuerst: vermeidet XCTest-Probleme mit „ungültigem Aktivierungspunkt“ beim Identifier-Match.
        if settingsButtonDE.waitForExistence(timeout: 2) {
            settingsButton = settingsButtonDE
        } else if settingsButtonEN.waitForExistence(timeout: 5) {
            settingsButton = settingsButtonEN
        } else if settingsById.waitForExistence(timeout: 2) {
            settingsButton = settingsById
        } else {
            XCTFail("Weder Einstellungen/Settings noch ToolbarSettingsButton gefunden.")
            return
        }
        let settingsDoneDE = app.buttons["Fertig"]
        let settingsDoneEN = app.buttons["Done"]
        var openedSettings = false
        for attempt in 0..<4 {
            // Bei kleinen Geräten kann ein residualer Welcome-Overlay taps schlucken.
            dismissWelcomeIfShown()
            robustTap(settingsButton)
            if settingsDoneDE.waitForExistence(timeout: 1.5) || settingsDoneEN.waitForExistence(timeout: 1.5) {
                openedSettings = true
                break
            }

            // Letzter Fallback: fester Tap oben links auf die Gear-Position.
            if attempt == 3 {
                let topLeftGearArea = app.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.06))
                topLeftGearArea.tap()
                if settingsDoneDE.waitForExistence(timeout: 1.5) || settingsDoneEN.waitForExistence(timeout: 1.5) {
                    openedSettings = true
                    break
                }
            }
        }
        XCTAssertTrue(openedSettings, "Settings-Sheet konnte nicht geöffnet werden.")
        
        let welcomeHelpButtonById = app.buttons["SettingsShowWelcomeButton"]
        let welcomeHelpButtonDE = app.buttons["Willkommensbildschirm anzeigen"]
        let welcomeHelpButton: XCUIElement
        if welcomeHelpButtonById.waitForExistence(timeout: 3) {
            welcomeHelpButton = welcomeHelpButtonById
        } else if welcomeHelpButtonDE.waitForExistence(timeout: 2) {
            welcomeHelpButton = welcomeHelpButtonDE
        } else {
            let welcomeHelpButtonEN = app.buttons["Show welcome screen"]
            XCTAssertTrue(welcomeHelpButtonEN.waitForExistence(timeout: 2), "Welcome-Help-Button nicht gefunden.")
            welcomeHelpButton = welcomeHelpButtonEN
        }
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
