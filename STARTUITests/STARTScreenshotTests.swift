import XCTest

final class STARTScreenshotTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-screenshot-mode", "-reset-local-data"]
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
        app.launchArguments = ["-ui-testing", "-reset-onboarding", "-reset-local-data"]
        app.launch()

        XCTAssertTrue(app.staticTexts["A primeira vez é no acaso."].waitForExistence(timeout: 10))
        app.buttons["onboarding-next"].tap()
        XCTAssertTrue(app.staticTexts["Escolham juntos."].waitForExistence(timeout: 3))
        app.buttons["onboarding-next"].tap()
        XCTAssertTrue(app.buttons["onboarding-start"].waitForExistence(timeout: 3))
        app.buttons["onboarding-start"].tap()
        XCTAssertTrue(app.staticTexts["Todo jogo tem uma grande história."].waitForExistence(timeout: 5))
    }

    func testDiceGalleryCaptureResults() throws {
        let captures: [(sides: Int, result: Int)] = [(4, 3), (6, 5), (8, 7), (10, 8), (12, 9), (20, 17)]
        app.terminate()

        for capture in captures {
            app.launchArguments = ["-ui-testing", "-screenshot-mode", "-capture-die-\(capture.sides)"]
            app.launch()
            let result = app.descendants(matching: .any)["dice-result"]
            XCTAssertTrue(result.waitForExistence(timeout: 5), "D\(capture.sides) capture should show its result")
            XCTAssertEqual(Int(result.label), capture.result, "D\(capture.sides) capture should use its stable face")
            app.terminate()
        }
    }

    func testRouletteTemplatesCanBeInstalledAndSpun() throws {
        app.buttons["home-wheels"].tap()
        XCTAssertTrue(app.staticTexts["Roletas da mesa"].waitForExistence(timeout: 5))

        let templateTab = app.segmentedControls["wheel-library-picker"].buttons["Templates"]
        XCTAssertTrue(templateTab.waitForExistence(timeout: 3))
        templateTab.tap()
        let installArnak = app.buttons["install-template-arnak-leaders"]
        XCTAssertTrue(installArnak.waitForExistence(timeout: 3))
        installArnak.tap()

        app.segmentedControls["wheel-library-picker"].buttons["Minhas roletas"].tap()
        let arnakWheel = app.staticTexts["Líderes da expedição"]
        XCTAssertTrue(arnakWheel.waitForExistence(timeout: 3))
        arnakWheel.tap()

        let spinButton = app.buttons["spin-wheel"]
        XCTAssertTrue(spinButton.waitForExistence(timeout: 3))
        spinButton.tap()
        XCTAssertTrue(app.staticTexts["wheel-selected-result"].waitForExistence(timeout: 8))
    }

    func testCustomWheelPersistsAfterRelaunch() throws {
        app.buttons["home-wheels"].tap()
        app.buttons["create-wheel"].tap()
        let titleField = app.textFields["wheel-title-field"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 3))
        titleField.tap()
        titleField.typeText("Noite de jogos")
        app.buttons["save-wheel"].tap()
        XCTAssertTrue(app.staticTexts["Noite de jogos"].waitForExistence(timeout: 5))

        app.terminate()
        app.launchArguments = ["-ui-testing", "-screenshot-mode"]
        app.launch()
        app.buttons["home-wheels"].tap()
        XCTAssertTrue(app.staticTexts["Noite de jogos"].waitForExistence(timeout: 5))
    }

    func testLiveMatchUpdatesLocalRankingAndHistory() throws {
        app.buttons["home-matches"].tap()
        XCTAssertTrue(app.buttons["new-match"].waitForExistence(timeout: 5))
        app.buttons["new-match"].tap()
        let arnakOption = app.buttons["match-game-option-arnak"]
        XCTAssertTrue(arnakOption.waitForExistence(timeout: 5))
        app.scrollViews["match-game-picker"].swipeLeft()
        arnakOption.tap()
        let startMatch = app.buttons["start-match"]
        if !startMatch.isHittable { app.swipeUp() }
        startMatch.tap()

        let scoreButton = app.buttons["score-plus-0"]
        XCTAssertTrue(scoreButton.waitForExistence(timeout: 5))
        scoreButton.tap()
        app.buttons["toggle-turn-timer"].tap()
        XCTAssertTrue(app.staticTexts["turn-timer-value"].waitForExistence(timeout: 3))

        app.terminate()
        app.launchArguments = ["-ui-testing", "-screenshot-mode"]
        app.launch()
        app.buttons["home-matches"].tap()
        let liveMatchRow = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "live-match-")).firstMatch
        XCTAssertTrue(liveMatchRow.waitForExistence(timeout: 5))
        liveMatchRow.tap()
        XCTAssertEqual(app.staticTexts["score-value-0"].label, "1")
        XCTAssertNotEqual(app.staticTexts["turn-timer-value"].label, "--:--")

        let finishMatch = app.buttons["finish-match"]
        if !finishMatch.isHittable { app.swipeUp() }
        finishMatch.tap()
        XCTAssertTrue(app.buttons["confirm-match-result"].waitForExistence(timeout: 3))
        app.buttons["confirm-match-result"].tap()
        XCTAssertTrue(app.staticTexts["PARTIDA ENCERRADA"].waitForExistence(timeout: 5))

        app.buttons["view-match-ranking"].tap()
        XCTAssertTrue(app.staticTexts["ARNAK"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Ana"].exists)
        XCTAssertTrue(app.staticTexts["1·0·0"].exists, "The completed result should count as one win")

        app.terminate()
        app.launchArguments = ["-ui-testing", "-screenshot-mode"]
        app.launch()
        app.buttons["home-matches"].tap()
        app.segmentedControls["match-center-picker"].buttons["Histórico"].tap()
        XCTAssertTrue(app.staticTexts["Arnak"].waitForExistence(timeout: 5))
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
        app.buttons["open-full-deck"].tap()
        XCTAssertTrue(app.staticTexts["52 cartas"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["ESPADAS"].exists)
        app.buttons["close-full-deck"].tap()
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
