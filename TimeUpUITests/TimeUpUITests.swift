import XCTest

final class TimeUpUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsLogin() {

        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(
            app.staticTexts["TimeUp"]
                .waitForExistence(timeout: 10)
        )

        XCTAssertTrue(
            app.buttons["Continue with Apple"]
                .waitForExistence(timeout: 10)
        )

        XCTAssertTrue(
            app.buttons["Continue with Google"]
                .waitForExistence(timeout: 10)
        )
    }

    func testLoginScreenDoesNotShowMemberUIBeforeAuthentication() {

        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(
            app.staticTexts["TimeUp"]
                .waitForExistence(timeout: 10)
        )

        XCTAssertFalse(
            app.tabBars.buttons["דשבורד"]
                .exists
        )

        XCTAssertFalse(
            app.tabBars.buttons["הקבוצה"]
                .exists
        )

        XCTAssertFalse(
            app.tabBars.buttons["AI"]
                .exists
        )

        XCTAssertFalse(
            app.tabBars.buttons["דירוג"]
                .exists
        )
    }
}
