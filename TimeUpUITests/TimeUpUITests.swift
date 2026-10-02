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
        app.buttons["join-button"].tap()

        XCTAssertTrue(app.staticTexts["ניהול הקבוצות שלך"].waitForExistence(timeout: 10))
    }

    func testInvalidGroupCodeShowsError() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Continue with Apple"].tap()
        XCTAssertTrue(app.staticTexts["הצטרפות ל-TimeUp"].waitForExistence(timeout: 10))

        fillJoinForm(app: app, name: "Test User", code: "9999")
        app.buttons["join-button"].tap()

        XCTAssertTrue(app.staticTexts["join-error"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["join-error"].label, "לא נמצאה קבוצה עם הקוד הזה.")
    }

    private func fillJoinForm(app: XCUIApplication, name: String, code: String) {
        let nameField = app.textFields["display-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10))
        nameField.tap()
        nameField.typeText(name)

        let codeField = app.textFields["group-code-field"]
        XCTAssertTrue(codeField.waitForExistence(timeout: 10))
        codeField.tap()
        XCTAssertTrue(codeField.waitForExistence(timeout: 2))
        codeField.typeText(code)

        let doneButton = app.buttons["סיום"]
        if doneButton.exists {
            doneButton.tap()
        }

        XCTAssertEqual(codeField.value as? String, code)
    }
}
