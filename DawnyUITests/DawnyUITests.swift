// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

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
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            return
        }
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func coordinateTap(_ element: XCUIElement, timeout: TimeInterval = 2) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element existiert nicht für Tap.")
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    /// Pollt statt `XCTNSPredicateExpectation` auf `hittable`: Ein Element mit ungültigem
    /// Frame (z. B. ein Tab-Bar-Button mitten in der Animation) lässt XCTest die
    /// Hittability-Prüfung des Predicates mit einem Testfehler abbrechen, statt `false`
    /// zu liefern. Der Frame-Check überspringt solche Zwischenzustände.
    private func waitForHittable(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if element.exists, element.frame.size != .zero, element.isHittable { return true }
            Thread.sleep(forTimeInterval: 0.1)
        } while Date() < deadline
        return false
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
        let scroll = app.scrollViews.firstMatch
        if scroll.waitForExistence(timeout: 0.5) { return scroll }
        return app
    }

    /// Sucht einen antippbaren Quick-Add-Button und scrollt bei Bedarf in der Backlog-Liste.
    private func tapVisibleQuickAddInBacklog() {
        let prefixes = ["Neue Aufgabe in ", "Add new task in "]
        // Die Task-Tabelle ist unter `--uitesting` leer, der Button ist ohne Scrollen sichtbar.
        // Die Runden bleiben als Reserve für den Fall, dass doch Inhalt vorhanden ist.
        for _ in 0..<4 {
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
        // Sprache deterministisch auf Englisch zwingen. launchEnvironment allein
        // genügt nicht — die System-Sprache (hier: Deutsch) setzt sich sonst durch.
        // Erst die `-AppleLanguages`/`-AppleLocale` launchArguments schreiben den
        // Override beim Start in UserDefaults (gleicher Ansatz wie ScreenshotTests).
        app.launchArguments = [
            "--uitesting",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
        app.launchEnvironment["AppleLanguages"] = "(en)"
        app.launchEnvironment["AppleLocale"] = "en_US"
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Launch Helper

    /// Wartet, bis die Hauptansicht steht.
    /// Mit `--uitesting` setzt `UITestSupport` `hasSeenWelcome` vor, der Welcome-Cover
    /// erscheint also gar nicht mehr. Das Wegtippen bleibt nur als Sicherheitsnetz.
    private func waitForMainUI() {
        let settingsButton = app.buttons["ToolbarSettingsButton"]
        let startButton = app.buttons["WelcomeStartButton"]
        let nextButton = app.buttons["WelcomeNextButton"]

        let deadline = Date().addingTimeInterval(15)
        while Date() < deadline {
            if settingsButton.exists { return }
            if startButton.exists { robustTap(startButton, timeout: 2); continue }
            if nextButton.exists { robustTap(nextButton, timeout: 2); continue }
            Thread.sleep(forTimeInterval: 0.2)
        }
        XCTFail("Hauptansicht ist nach dem Start nicht erschienen.")
    }

    // MARK: - Navigation

    /// Sucht den Tab-Button via lokalisiertem Label oder deutschem Fallback.
    private func tabButton(en: String, de: String) -> XCUIElement {
        let enButton = app.buttons[en]
        if enButton.waitForExistence(timeout: 2) { return enButton }
        let deButton = app.buttons[de]
        if deButton.waitForExistence(timeout: 2) { return deButton }
        return enButton
    }

    func testTabNavigation() throws {
        waitForMainUI()

        let archiveTab = app.buttons["ToolbarArchiveButton"]
        XCTAssertTrue(archiveTab.waitForExistence(timeout: 5))

        let backlogTab = tabButton(en: "Backlog", de: "Backlog")
        XCTAssertTrue(backlogTab.waitForExistence(timeout: 5), "Backlog-Tab nicht gefunden.")
        robustTap(backlogTab)

        let todayTab = tabButton(en: "Today", de: "Heute")
        XCTAssertTrue(todayTab.waitForExistence(timeout: 5), "Today-Tab nicht gefunden.")
        robustTap(todayTab)

        robustTap(archiveTab)
    }

    // MARK: - Task Creation

    func testCreateTaskInBacklog() throws {
        waitForMainUI()

        let backlogTab = app.buttons["Backlog"]
        XCTAssertTrue(backlogTab.waitForExistence(timeout: 5))
        robustTap(backlogTab)

        tapVisibleQuickAddInBacklog()
    }

    /// Standard-Kategorie „Recurring Tasks" (EN) erscheint im Backlog (laut Default-`initializeDefaultCategories`).
    func testRecurringDefaultCategoryVisibleInBacklog() throws {
        waitForMainUI()

        let backlogTab = tabButton(en: "Backlog", de: "Backlog")
        XCTAssertTrue(backlogTab.waitForExistence(timeout: 5))
        robustTap(backlogTab)

        // Suche über mehrere Element-Typen, weil SwiftUI-Section-Header je nach Konfiguration
        // mal als staticText, mal als otherElement im Tree landen. Die Liste startet unter
        // `--uitesting` leer, deshalb reichen wenige Scroll-Etappen als Reserve.
        let host = scrollHostForBacklog()
        for _ in 0..<6 {
            if app.staticTexts["Recurring Tasks"].firstMatch.exists { return }
            if app.otherElements["Recurring Tasks"].firstMatch.exists { return }
            if app.descendants(matching: .any).matching(identifier: "Recurring Tasks").firstMatch.exists { return }
            host.swipeUp()
        }
        XCTFail("Kategorie 'Recurring Tasks' nicht sichtbar")
    }

    // MARK: - Settings Flow

    /// Belegt, dass das Settings-Sheet präsentiert ist. Die Make-it-count-Pille liegt
    /// im ersten Abschnitt des Forms und ist damit ohne Scrollen im Tree.
    private func settingsSheetIsPresented(timeout: TimeInterval) -> Bool {
        let marker = app.descendants(matching: .any)
            .matching(identifier: "SettingsMakeItCountThreshold")
            .firstMatch
        if marker.waitForExistence(timeout: timeout) { return true }
        return app.buttons["SettingsShowWelcomeButton"].exists
    }


    func testShowWelcomeFromSettingsHelpButton() throws {
        waitForMainUI()

        let settingsButton = app.buttons["ToolbarSettingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        robustTap(settingsButton)

        // Präsentation prüfen, bevor gescrollt wird. Ohne Sheet liefen sonst zehn
        // wirkungslose Drags auf dem Hauptscreen und der Test scheiterte erst danach
        // mit einer irreführenden Meldung.
        XCTAssertTrue(settingsSheetIsPresented(timeout: 5), "Settings-Sheet wurde nach dem Tap nicht präsentiert.")

        let showWelcomeButton = app.buttons["SettingsShowWelcomeButton"]
        if !showWelcomeButton.waitForExistence(timeout: 2) {
            // Das Settings-`Form` wird von einer UICollectionView getragen, nicht von
            // einem `scrollView`, ein swipeUp auf `app.scrollViews` scrollt deshalb nichts.
            // Stattdessen per Koordinaten im Fenster nach oben ziehen. Bewusst nicht
            // relativ zum Collection-View: bei präsentiertem Sheet bleiben die drei
            // Tab-Seiten der ContentView im Baum, und `app.collectionViews.firstMatch`
            // liefert die Seite bei x = -440, also einen Startpunkt außerhalb des Schirms.
            for _ in 0..<4 {
                if showWelcomeButton.exists && showWelcomeButton.isHittable { break }
                let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
                let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
                start.press(forDuration: 0.05, thenDragTo: end)
            }
        }
        XCTAssertTrue(showWelcomeButton.waitForExistence(timeout: 3), "Show-Welcome-Button im Settings-Sheet nicht gefunden.")
        robustTap(showWelcomeButton)

        let welcomeAppeared = app.buttons["WelcomeStartButton"].waitForExistence(timeout: 5)
            || app.buttons["WelcomeNextButton"].waitForExistence(timeout: 5)
        XCTAssertTrue(welcomeAppeared, "Welcome-Screen wurde nicht angezeigt nach Tap auf Settings-Button.")
    }

    // MARK: - Performance

    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
