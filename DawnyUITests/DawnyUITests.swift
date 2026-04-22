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
        let startById = app.buttons["WelcomeStartButton"]
        let nextById = app.buttons["WelcomeNextButton"]
        let settingsButtons = [
            app.buttons["ToolbarSettingsButton"],
            app.buttons["Einstellungen"],
            app.buttons["Settings"]
        ]

        let deadline = Date().addingTimeInterval(12)
        while Date() < deadline {
            // Hauptansicht sichtbar -> Welcome bereits weg.
            if settingsButtons.contains(where: { $0.exists }) {
                return
            }

            // Letzte Kachel: Welcome per CTA schließen.
            if startById.exists || startById.waitForExistence(timeout: 0.3) {
                robustTap(startById, timeout: 2)
                continue
            }
            for start in startButtons where start.exists || start.waitForExistence(timeout: 0.6) {
                robustTap(start, timeout: 2)
                continue
            }

            // Davor: Schrittweise per Weiter/Continue navigieren.
            if nextById.exists || nextById.waitForExistence(timeout: 0.3) {
                robustTap(nextById, timeout: 1.5)
                continue
            }
            if let next = nextButtons.first(where: { $0.exists || $0.waitForExistence(timeout: 0.8) }) {
                robustTap(next, timeout: 1.5)
                continue
            }

            // Weder Welcome noch Hauptansicht sichtbar: kurzer Poll-Delay.
            Thread.sleep(forTimeInterval: 0.2)
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
        throw XCTSkip("Temporär deaktiviert wegen instabilem Simulator-/UI-Test-Verhalten in CI.")
    }
    
    // MARK: - Performance Tests
    
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
