import XCTest

final class STARTScreenshotTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
    }

    private func shot(_ name: String) {
        let s = XCUIScreen.main.screenshot()
        let a = XCTAttachment(screenshot: s)
        a.name = name
        a.lifetime = .keepAlways
        add(a)
        // Also persist to /tmp on the runner Mac (UI tests execute on the host),
        // so CI can upload them without parsing .xcresult.
        do {
            let dir = URL(fileURLWithPath: "/tmp/start-shots", isDirectory: true)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try s.pngRepresentation.write(to: dir.appendingPathComponent("\(name).png"))
        } catch {
            print("shot save failed: \(error)")
        }
    }

    private func goBackIfNeeded() {
        let back = app.navigationBars.buttons.element(boundBy: 0)
        if back.exists {
            back.tap()
        }
    }

    func testScreenshots() throws {
        XCTAssertTrue(app.staticTexts["START"].waitForExistence(timeout: 10))
        shot("01-home")

        // Dice
        app.buttons["mode-dice"].tap()
        XCTAssertTrue(app.buttons["roll-dice-button"].waitForExistence(timeout: 5))
        app.buttons["roll-dice-button"].tap()
        sleep(2)
        shot("02-dice")
        goBackIfNeeded()

        // Finger
        app.buttons["mode-finger"].tap()
        XCTAssertTrue(app.otherElements["finger-area"].waitForExistence(timeout: 5))
        sleep(1)
        shot("03-finger")
        goBackIfNeeded()

        // Cards
        app.buttons["mode-cards"].tap()
        XCTAssertTrue(app.buttons["deal-cards-button"].waitForExistence(timeout: 5))
        sleep(1)
        shot("04-cards")
        goBackIfNeeded()

        // Situations
        app.buttons["mode-situations"].tap()
        XCTAssertTrue(app.buttons["next-situation-button"].waitForExistence(timeout: 5))
        app.buttons["next-situation-button"].tap()
        sleep(1)
        shot("05-situations")
    }
}
