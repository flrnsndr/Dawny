// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  WelcomeFlowUITests.swift
//  DawnyUITests
//
//  UI-Tests für den Welcome-Flow der Erstinstallation.
//

import XCTest

/// Deckt den Onboarding-Flow ab, den die übrigen UI-Tests überspringen: den
/// iCloud-Schalter auf der vorletzten Seite, das Blättern und den Wisch, der den
/// Flow auf der letzten Seite schließt.
///
/// Startet die App mit `--welcome-flow`: `UITestSupport` setzt den Zustand einer
/// Neuinstallation (Welcome ungesehen, Sync-Hinweis offen, Sync aus), damit der
/// Welcome-Cover erscheint und der Schalter auf der iCloud-Seite vorbelegt „an" ist.
final class WelcomeFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    private var nextButton: XCUIElement { app.buttons["WelcomeNextButton"] }
    private var startButton: XCUIElement { app.buttons["WelcomeStartButton"] }
    private var syncToggle: XCUIElement { app.switches["ICloudSyncIntroToggle"] }
    private var syncHint: XCUIElement { app.staticTexts["ICloudSyncIntroHint"] }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--welcome-flow",
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

    // MARK: - Tests

    /// Der Schalter auf der iCloud-Seite lässt sich mit einem normalen Tap umlegen,
    /// und zwar in beide Richtungen.
    func testICloudToggleOnWelcomePageReactsToTap() throws {
        advanceToICloudSyncPage()

        XCTAssertEqual(syncToggle.value as? String, "1", "Der Schalter soll vorbelegt „an“ sein.")
        XCTAssertTrue(syncHint.waitForExistence(timeout: 3), "Der Hinweistext fehlt auf der iCloud-Seite.")
        let hintWhenOn = syncHint.label

        tapSyncToggle()

        XCTAssertTrue(
            waitForValue(syncToggle, equals: "0"),
            "Ein Tap hat den Schalter nicht ausgeschaltet. Wert: \(String(describing: syncToggle.value))"
        )
        // Der Hinweistext hängt am Schalterzustand. Der Wechsel belegt, dass nicht nur
        // die Switch-Optik umgesprungen ist, sondern die Bindung wirklich gegriffen hat.
        // Die genaue Formulierung liegt in `Localizable.xcstrings` und darf sich ändern.
        XCTAssertTrue(
            waitForLabelChange(syncHint, from: hintWhenOn),
            "Der Hinweistext soll auf den Aus-Zustand wechseln. War: \(syncHint.label)"
        )
        let hintWhenOff = syncHint.label
        XCTAssertTrue(
            hintWhenOff.localizedCaseInsensitiveContains("settings"),
            "Bei ausgeschaltetem Sync soll der Hinweis auf die Einstellungen verweisen. War: \(hintWhenOff)"
        )

        tapSyncToggle()

        XCTAssertTrue(
            waitForValue(syncToggle, equals: "1"),
            "Der Schalter soll sich auch wieder einschalten lassen. Wert: \(String(describing: syncToggle.value))"
        )
        XCTAssertTrue(
            waitForLabelChange(syncHint, from: hintWhenOff),
            "Der Hinweistext soll zurück auf den An-Zustand wechseln. War: \(syncHint.label)"
        )
    }

    /// Blättern bleibt Blättern: Ein Wisch nach links auf der iCloud-Seite führt zur
    /// letzten Seite und schließt den Flow nicht vorzeitig.
    func testSwipeOnICloudPageTurnsThePageInsteadOfClosingTheFlow() throws {
        advanceToICloudSyncPage()

        swipeLeftAcrossPage()

        // Der „Get started"-Button gibt es nur auf der letzten Seite. Dass er da ist,
        // belegt beides: geblättert wurde, geschlossen wurde nicht.
        XCTAssertTrue(
            startButton.waitForExistence(timeout: 5),
            "Der Wisch soll auf die letzte Seite blättern und den Flow offen lassen."
        )
    }

    /// Ein Wisch nach links auf der letzten Seite schließt den Flow.
    func testSwipeOnLastPageFinishesTheFlow() throws {
        advanceToLastPage()

        swipeLeftAcrossPage()

        XCTAssertTrue(
            waitForDisappearance(startButton, timeout: 8),
            "Der Wisch auf der letzten Seite soll den Welcome-Flow schließen."
        )
        XCTAssertTrue(
            app.buttons["ToolbarSettingsButton"].waitForExistence(timeout: 5),
            "Nach dem Schließen soll die Hauptansicht sichtbar sein."
        )
    }

    // MARK: - Navigation

    /// Blättert per „Continue" bis zur iCloud-Seite.
    ///
    /// Die Seiten des `TabView` bleiben alle gemountet, `exists` allein sagt also
    /// nichts über die sichtbare Seite aus. Deshalb ist `isHittable` das Kriterium.
    private func advanceToICloudSyncPage() {
        XCTAssertTrue(nextButton.waitForExistence(timeout: 15), "Der Welcome-Flow ist nicht erschienen.")

        for _ in 0..<12 {
            if syncToggle.exists && syncToggle.isHittable { return }
            guard nextButton.exists else { break }
            tapNext()
        }

        XCTAssertTrue(
            syncToggle.exists && syncToggle.isHittable,
            "Die iCloud-Seite mit dem Sync-Schalter wurde nicht erreicht."
        )
    }

    private func advanceToLastPage() {
        XCTAssertTrue(nextButton.waitForExistence(timeout: 15), "Der Welcome-Flow ist nicht erschienen.")

        for _ in 0..<12 {
            if startButton.exists { return }
            guard nextButton.exists else { break }
            tapNext()
        }

        XCTAssertTrue(startButton.exists, "Die letzte Welcome-Seite wurde nicht erreicht.")
    }

    private func tapNext() {
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3), "Der „Continue“-Button fehlt.")
        // Koordinaten-Tap wie in `DawnyUITests.robustTap`: ein Element mit noch
        // ungültigem Frame lässt `tap()` sonst mit einem Testfehler abbrechen.
        nextButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        // Der Seitenwechsel ist mit 0,3 s animiert. Ohne die kurze Pause landet der
        // nächste Tap mitten in der Animation und wird verschluckt.
        Thread.sleep(forTimeInterval: 0.4)
    }

    // MARK: - Gesten

    /// Tippt auf den Schalter. Der Druckpunkt liegt am hinteren Rand, dort sitzt er.
    private func tapSyncToggle() {
        syncToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
            .tap()
    }

    /// Wischt quer über den Seitenbereich, deutlich über den 48 pt, die
    /// `closeOnLastPageSwipeGesture` verlangt.
    private func swipeLeftAcrossPage() {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.45))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.45))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    // MARK: - Warten

    private func waitForValue(
        _ element: XCUIElement,
        equals expected: String,
        timeout: TimeInterval = 3
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if element.exists, element.value as? String == expected { return true }
            Thread.sleep(forTimeInterval: 0.1)
        } while Date() < deadline
        return false
    }

    private func waitForDisappearance(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if !element.exists { return true }
            Thread.sleep(forTimeInterval: 0.1)
        } while Date() < deadline
        return false
    }

    private func waitForLabelChange(
        _ element: XCUIElement,
        from previous: String,
        timeout: TimeInterval = 3
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if element.exists, element.label != previous { return true }
            Thread.sleep(forTimeInterval: 0.1)
        } while Date() < deadline
        return false
    }
}
