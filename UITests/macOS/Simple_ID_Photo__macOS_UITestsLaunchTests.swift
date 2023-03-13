//
//  Simple_ID_Photo__macOS_UITestsLaunchTests.swift
//  Simple-ID-Photo (macOS)UITests
//  
//  Created by TakashiUshikoshi on 2023/03/14
//  
//

import XCTest

final class Simple_ID_Photo__macOS_UITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
