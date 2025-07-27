//
//  media_library_demoUITestsLaunchTests.swift
//  media-library-demoUITests
//
//  Created by haludoll on 2025/07/27.
//

import XCTest

final class media_library_demoUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // 写真ライブラリ画面が表示されるまで待機
        let scrollView = app.scrollViews.firstMatch
        _ = scrollView.waitForExistence(timeout: 10)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
