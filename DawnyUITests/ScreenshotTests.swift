// Dawny
// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.
// Licensed under PolyForm Noncommercial 1.0.0 — see LICENSE in the repository root.

//
//  ScreenshotTests.swift
//  DawnyUITests
//
//  Generates the three standardized App Store screenshots (Backlog, Today,
//  Archive) for both English and German. Driven by scripts/take-screenshots.sh
//  which runs both methods in a single xcodebuild invocation.
//
//  Output: /tmp/dawny-screenshots/<lang>/0{1,2,3}_{Backlog,Today,Archive}.png
//

import XCTest

final class ScreenshotTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }

    func testTakeScreenshotsEN() throws {
        try runScreenshots(
            lang: "en",
            firstArchivedSearchText: "RSVP",
            archiveSectionTitle: "Archived"
        )
    }

    func testTakeScreenshotsDE() throws {
        try runScreenshots(
            lang: "de",
            firstArchivedSearchText: "Einladung",
            archiveSectionTitle: "Archiviert"
        )
    }

    // MARK: - Test driver

    private func runScreenshots(
        lang: String,
        firstArchivedSearchText: String,
        archiveSectionTitle: String
    ) throws {
        let outputDir = "/tmp/dawny-screenshots/\(lang)"
        try FileManager.default.createDirectory(
            atPath: outputDir,
            withIntermediateDirectories: true
        )

        app = XCUIApplication()
        // Pass locale as both launchArguments (writes to UserDefaults at startup,
        // overriding any persisted AppleLanguages from a prior test run on the
        // same simulator) AND launchEnvironment (some system APIs read the env
        // before UserDefaults).
        let locale = lang == "de" ? "de_DE" : "en_US"
        app.launchArguments = [
            "--uitesting",
            "--screenshots",
            "-AppleLanguages", "(\(lang))",
            "-AppleLocale", locale
        ]
        app.launchEnvironment["AppleLanguages"] = "(\(lang))"
        app.launchEnvironment["AppleLocale"] = locale
        app.launch()

        waitForSeederToFinish()

        navigateToBacklog()
        Thread.sleep(forTimeInterval: 0.6)
        save(name: "01_Backlog", outputDir: outputDir)

        navigateToToday(lang: lang)
        Thread.sleep(forTimeInterval: 0.6)
        save(name: "02_Today", outputDir: outputDir)

        navigateToArchive()
        Thread.sleep(forTimeInterval: 0.8)
        partialSwipeRightOnFirstArchivedTask(
            matching: firstArchivedSearchText,
            sectionTitle: archiveSectionTitle
        )
        Thread.sleep(forTimeInterval: 0.5)
        save(name: "03_Archive", outputDir: outputDir)
    }

    // MARK: - Navigation

    private func waitForSeederToFinish() {
        let settings = app.buttons["ToolbarSettingsButton"]
        _ = settings.waitForExistence(timeout: 10)
    }

    private func navigateToBacklog() {
        let backlog = app.buttons["Backlog"]
        if backlog.waitForExistence(timeout: 3) {
            backlog.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    private func navigateToToday(lang: String) {
        let label = lang == "de" ? "Heute" : "Today"
        let button = app.buttons[label]
        if button.waitForExistence(timeout: 3) {
            button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    private func navigateToArchive() {
        let archive = app.buttons["ToolbarArchiveButton"]
        XCTAssertTrue(archive.waitForExistence(timeout: 5))
        archive.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    // MARK: - Swipe helpers

    /// Targets the cell containing `searchText` (a unique substring of the first
    /// archived task title) and drags it ~50% of the way across to reveal both
    /// leading swipe actions without triggering the full-swipe.
    ///
    /// Why not `app.cells.element(boundBy: 0)`: ContentView's TabPager keeps the
    /// Backlog and Today lists in the accessibility hierarchy (just translated
    /// off-screen). The first cell by index belongs to the Backlog, not the
    /// Archive.
    ///
    /// If the cell isn't found, the Archive section header is tapped once to
    /// expand it (it can render collapsed on first appearance in some launch
    /// orderings), then the search is retried.
    private func partialSwipeRightOnFirstArchivedTask(
        matching searchText: String,
        sectionTitle: String
    ) {
        let predicate = NSPredicate(format: "label CONTAINS %@", searchText)
        var cell = app.cells.containing(predicate).firstMatch

        if !cell.waitForExistence(timeout: 2) {
            let header = app.staticTexts[sectionTitle]
            if header.waitForExistence(timeout: 2) {
                header.tap()
                Thread.sleep(forTimeInterval: 0.4)
            }
            cell = app.cells.containing(predicate).firstMatch
        }

        XCTAssertTrue(
            cell.waitForExistence(timeout: 5),
            "Archive cell containing '\(searchText)' not found."
        )
        let start = cell.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5))
        let end = cell.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    // MARK: - Save

    private func save(name: String, outputDir: String) {
        let screenshot = app.screenshot()
        let url = URL(fileURLWithPath: "\(outputDir)/\(name).png")
        do {
            try screenshot.pngRepresentation.write(to: url)
        } catch {
            XCTFail("Failed to write screenshot \(name): \(error)")
        }

        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
