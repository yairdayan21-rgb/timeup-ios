import XCTest

final class TimeUpUITests: XCTestCase {
    func testAllowScreenTime() throws {
        let app = XCUIApplication()
        app.launch()

        let connect = app.buttons["Connect Screen Time"]
        XCTAssertTrue(connect.waitForExistence(timeout: 10))
        connect.tap()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        let continueButton = springboard.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 10))
        continueButton.tap()

        let allowButton = springboard.buttons["Allow with Passcode"]
        XCTAssertTrue(allowButton.waitForExistence(timeout: 10))
        allowButton.tap()

        sleep(5)
    }
}
