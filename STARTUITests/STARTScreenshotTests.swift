import XCTest

final class STARTScreenshotTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-screenshot-mode"]
        app.launch()
    }

    private func goBackIfNeeded() {
        let back = app.buttons["Voltar"]
        if back.exists {
            back.tap()
        }
    }

    func testFirstLaunchOnboarding() throws {
        app.terminate()
        app.launchArguments = ["-ui-testing", "-reset-onboarding"]
        app.launch()

        XCTAssertTrue(app.staticTexts["A primeira vez é no acaso."].waitForExistence(timeout: 10))
        app.buttons["onboarding-next"].tap()
        XCTAssertTrue(app.staticTexts["Escolham juntos."].waitForExistence(timeout: 3))
        app.buttons["onboarding-next"].tap()
        XCTAssertTrue(app.buttons["onboarding-start"].waitForExistence(timeout: 3))
        app.buttons["onboarding-start"].tap()
        XCTAssertTrue(app.staticTexts["Todo jogo tem uma grande história."].waitForExistence(timeout: 5))
    }

    func testMVPInteractions() throws {
        XCTAssertTrue(app.staticTexts["Todo jogo tem uma grande história."].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["mode-dice"].isHittable)
        XCTAssertTrue(app.buttons["mode-finger"].isHittable)
        XCTAssertTrue(app.buttons["mode-cards"].isHittable)
        XCTAssertTrue(app.buttons["mode-situations"].isHittable)

        app.buttons["Editar jogadores"].tap()
        let effectsToggle = app.descendants(matching: .any)["effects-toggle"]
        XCTAssertTrue(effectsToggle.waitForExistence(timeout: 5))
        effectsToggle.tap()
        effectsToggle.tap()
        app.buttons["Concluir"].tap()

        app.buttons["start-title"].tap()
        XCTAssertTrue(app.staticTexts["Como vamos descobrir quem começa?"].waitForExistence(timeout: 5))
        goBackIfNeeded()

        // Dice
        app.buttons["mode-dice"].tap()
        XCTAssertTrue(app.buttons["roll-dice-button"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["die-d4"].isHittable, "The first die option should be visible without scrolling")
        XCTAssertTrue(app.buttons["die-d20"].isHittable, "The last die option should be visible without scrolling")
        XCTAssertTrue(app.buttons["roll-dice-button"].isHittable, "The roll action should be visible without scrolling")
        app.buttons["roll-dice-button"].tap()
        sleep(3)
        let resultLabel = app.descendants(matching: .any)["dice-result"]
        XCTAssertTrue(resultLabel.waitForExistence(timeout: 3))
        XCTAssertTrue(resultLabel.label.contains("4"), "Screenshot mode should settle on the expected D6 face")
        for sides in [4, 8, 10, 12, 20] {
            app.buttons["die-d\(sides)"].tap()
            app.buttons["roll-dice-button"].tap()
            sleep(3)
            let numericValue = Int(resultLabel.label.filter(\.isNumber)) ?? 0
            XCTAssertTrue((1...sides).contains(numericValue), "D\(sides) returned \(numericValue), outside its face range")
        }
        goBackIfNeeded()

        // Finger
        app.buttons["mode-finger"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["finger-area"].waitForExistence(timeout: 5))
        sleep(1)
        goBackIfNeeded()

        // Cards
        app.buttons["mode-cards"].tap()
        XCTAssertTrue(app.buttons["deal-cards-button"].waitForExistence(timeout: 5))
        for style in ["classic", "casino", "vintage", "classic"] {
            let styleButton = app.buttons["card-style-\(style)"]
            XCTAssertTrue(styleButton.isHittable, "The \(style) deck style should be visible")
            styleButton.tap()
        }
        app.buttons["deal-cards-button"].tap()
        sleep(1)
        XCTAssertTrue(app.descendants(matching: .any)["cards-result"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["dealt-card-3"].waitForExistence(timeout: 3))
        goBackIfNeeded()

        // Situations
        app.buttons["mode-situations"].tap()
        XCTAssertTrue(app.buttons["confirm-situation-button"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Quem está usando óculos?"].exists)
        sleep(1)
    }
}
