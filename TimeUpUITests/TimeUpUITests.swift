import XCTest

final class TimeUpUITests: XCTestCase {
    func testLaunchShowsLogin() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["TimeUp"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Continue with Apple"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Continue with Google"].waitForExistence(timeout: 10))
    }

    func testJoinFlowAcceptsAdminDemoCode() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Continue with Apple"].tap()
        XCTAssertTrue(app.staticTexts["הצטרפות ל-TimeUp"].waitForExistence(timeout: 10))

        fillJoinForm(app: app, name: "Test User", code: "0000")
        let joinButton = app.buttons["join-button"]
        XCTAssertTrue(joinButton.waitForExistence(timeout: 10))
        XCTAssertTrue(joinButton.isEnabled)
        joinButton.tap()

        XCTAssertTrue(app.staticTexts["ניהול הקבוצות שלך"].waitForExistence(timeout: 10))
    }

    func testInvalidGroupCodeShowsError() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Continue with Apple"].tap()
        XCTAssertTrue(app.staticTexts["הצטרפות ל-TimeUp"].waitForExistence(timeout: 10))

        fillJoinForm(app: app, name: "Test User", code: "9999")
        let joinButton = app.buttons["join-button"]
        XCTAssertTrue(joinButton.waitForExistence(timeout: 10))
        XCTAssertTrue(joinButton.isEnabled)
        joinButton.tap()

        let error = app.staticTexts["join-error"]
        XCTAssertTrue(error.waitForExistence(timeout: 10))
        XCTAssertEqual(error.label, "לא נמצאה קבוצה עם הקוד הזה.")
    }

    private func fillJoinForm(app: XCUIApplication, name: String, code: String) {
        let nameField = app.textFields["display-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10))
        nameField.tap()
        nameField.typeText(name)
        XCTAssertEqual(nameField.value as? String, name)

        let codeField = app.textFields["group-code-field"]
        XCTAssertTrue(codeField.waitForExistence(timeout: 10))
        codeField.tap()
        XCTAssertTrue(codeField.hasKeyboardFocus)
        codeField.typeText(code)
        XCTAssertEqual(codeField.value as? String, code)

        app.keyboards.buttons["סיום"].tapIfExists()
        app.keyboards.buttons["Done"].tapIfExists()
    }
}

private extension XCUIElement {
    func tapIfExists() {
        if exists && isHittable {
            tap()
        }
    }
}
