import XCTest

final class TimeUpUITests: XCTestCase {
    func testLaunchShowsLogin() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["TimeUp"].waitForExistence(timeout: 10))
        XCTAssertTrue(
            app.buttons["Continue with Apple"].waitForExistence(timeout: 10)
        )
        XCTAssertTrue(
            app.buttons["Continue with Google"].waitForExistence(timeout: 10)
        )
    }

    func testJoinFlowAcceptsAdminDemoCode() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Continue with Apple"].tap()

        XCTAssertTrue(
            app.staticTexts["הצטרפות ל-TimeUp"].waitForExistence(timeout: 10)
        )

        app.textFields["השם שלך"].tap()
        app.textFields["השם שלך"].typeText("Test User")

        app.textFields["קוד קבוצה"].tap()
        app.textFields["קוד קבוצה"].typeText("0000")

        app.buttons["המשך"].tap()

        XCTAssertTrue(
            app.staticTexts["ניהול הקבוצות שלך"].waitForExistence(timeout: 10)
        )
    }

    func testInvalidGroupCodeShowsError() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Continue with Apple"].tap()

        app.textFields["השם שלך"].tap()
        app.textFields["השם שלך"].typeText("Test User")

        app.textFields["קוד קבוצה"].tap()
        app.textFields["קוד קבוצה"].typeText("9999")

        app.buttons["המשך"].tap()

        XCTAssertTrue(
            app.staticTexts["לא נמצאה קבוצה עם הקוד הזה."].waitForExistence(timeout: 10)
        )
    }
}
