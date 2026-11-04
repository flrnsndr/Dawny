// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  ICloudSyncIntroUITests.swift
//  DawnyUITests
//
//  UI-Tests für den einmaligen iCloud-Sync-Hinweis nach dem Update.
//

import XCTest

/// Startet die App mit `--icloud-intro`: das Sheet wird eingeschaltet und der
/// Ausgangszustand gesetzt (Welcome gesehen, Hinweis offen, Sync aus), damit der
/// Test unabhängig davon läuft, was frühere Läufe auf dem Simulator hinterlassen haben.
final class ICloudSyncIntroUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--icloud-intro",
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

    /// Der Hinweis erscheint mit vorab aktiviertem Schalter, und „Okay" führt zurück in die App.
    func testIntroAppearsWithSyncPreEnabledAndConfirmDismissesIt() throws {
        let confirmButton = app.buttons["ICloudSyncIntroConfirmButton"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 10), "Der Sync-Hinweis wurde nicht angezeigt.")

        let toggle = app.switches["ICloudSyncIntroToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3), "Der Sync-Schalter fehlt im Hinweis.")
        XCTAssertEqual(toggle.value as? String, "1", "Der Schalter soll vorab aktiviert sein.")

        confirmButton.tap()

        XCTAssertTrue(
            app.buttons["ToolbarSettingsButton"].waitForExistence(timeout: 5),
            "Nach dem Okay soll die App sichtbar sein."
        )
        XCTAssertFalse(confirmButton.exists, "Der Hinweis soll nach dem Okay geschlossen sein.")
    }

    /// Schalter aus: der Hinweistext verweist auf die Einstellungen.
    func testTurningSyncOffPointsAtTheSettings() throws {
        let toggle = app.switches["ICloudSyncIntroToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10), "Der Sync-Schalter fehlt im Hinweis.")

        let hint = app.staticTexts["ICloudSyncIntroHint"]
        XCTAssertTrue(hint.waitForExistence(timeout: 3), "Der Hinweistext fehlt.")
        let enabledHint = hint.label

        toggle.tap()

        XCTAssertEqual(toggle.value as? String, "0", "Der Schalter soll sich ausschalten lassen.")
        // Der Text hängt am Schalterzustand, deshalb reicht der Wechsel als Signal —
        // die genaue Formulierung liegt in `Localizable.xcstrings` und darf sich ändern.
        XCTAssertNotEqual(hint.label, enabledHint, "Der Hinweistext soll auf den Aus-Zustand wechseln.")
        XCTAssertTrue(
            hint.label.localizedCaseInsensitiveContains("settings"),
            "Bei ausgeschaltetem Sync soll der Hinweis auf die Einstellungen verweisen. War: \(hint.label)"
        )

        app.buttons["ICloudSyncIntroConfirmButton"].tap()

        XCTAssertTrue(
            app.buttons["ToolbarSettingsButton"].waitForExistence(timeout: 5),
            "Nach dem Okay soll die App sichtbar sein."
        )
    }
}
