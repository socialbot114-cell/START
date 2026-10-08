import XCTest

final class STARTScreenshotTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-screenshot-mode"]
        app.launch()
    }

    private func shot(_ name: String) {
        let s = app.screenshot()
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
        let back = app.buttons["Voltar"]
        if back.exists {
            back.tap()
        }
    }

    func testScreenshots() throws {
        XCTAssertTrue(app.staticTexts["Todo jogo tem uma grande história."].waitForExistence(timeout: 10))
        shot("01-home")
        XCTAssertTrue(app.buttons["mode-dice"].isHittable)
        XCTAssertTrue(app.buttons["mode-finger"].isHittable)
        XCTAssertTrue(app.buttons["mode-cards"].isHittable)
        XCTAssertTrue(app.buttons["mode-situations"].isHittable)

        app.buttons["start-title"].tap()
        XCTAssertTrue(app.staticTexts["Como vamos descobrir quem começa?"].waitForExistence(timeout: 5))
        goBackIfNeeded()

        // Dice
        app.buttons["mode-dice"].tap()
        XCTAssertTrue(app.buttons["roll-dice-button"].waitForExistence(timeout: 8))
        app.buttons["roll-dice-button"].tap()
        sleep(3)
        let resultLabel = app.descendants(matching: .any)["dice-result"]
        XCTAssertTrue(resultLabel.waitForExistence(timeout: 3))
        XCTAssertTrue(resultLabel.label.contains("4"), "Screenshot mode should settle on the expected D6 face")
        shot("02-dice")

        for sides in [4, 8, 10, 12, 20] {
            app.buttons["die-d\(sides)"].tap()
            app.buttons["roll-dice-button"].tap()
            sleep(2)
            let numericValue = Int(resultLabel.label.filter(\.isNumber)) ?? 0
            XCTAssertTrue((1...sides).contains(numericValue), "D\(sides) returned \(numericValue), outside its face range")
        }
        goBackIfNeeded()

        // Finger
        app.buttons["mode-finger"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["finger-area"].waitForExistence(timeout: 5))
        sleep(1)
        shot("03-finger")
        goBackIfNeeded()

        // Cards
        app.buttons["mode-cards"].tap()
        XCTAssertTrue(app.buttons["deal-cards-button"].waitForExistence(timeout: 5))
        app.buttons["deal-cards-button"].tap()
        sleep(1)
        XCTAssertTrue(app.descendants(matching: .any)["cards-result"].exists)
        shot("04-cards")
        goBackIfNeeded()

        // Situations
        app.buttons["mode-situations"].tap()
        XCTAssertTrue(app.buttons["confirm-situation-button"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Quem está usando óculos?"].exists)
        sleep(1)
        shot("05-situations")
    }
}
