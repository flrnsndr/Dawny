// Dawny
// Copyright (c) 2025-2026 Florian Schneider
// Licensed under the MIT License — see LICENSE in the repository root.

//
//  DawnyUITestsLaunchTests.swift
//  DawnyUITests
//
//  Created by Dev on 08.05.26.
//

import XCTest

final class DawnyUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app
        // XCUIAutomation Documentation
        // https://developer.apple.com/documentation/xcuiautomation

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
