import XCTest

final class DocketUITests: XCTestCase {
    private var interruptionMonitorToken: NSObjectProtocol?

    override func setUpWithError() throws {
        continueAfterFailure = false
        interruptionMonitorToken = addUIInterruptionMonitor(withDescription: "System alert dismissal") { alert in
            for label in ["Allow", "OK", "Don't Allow", "Cancel"] {
                let button = alert.buttons[label]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            return false
        }
    }

    override func tearDownWithError() throws {
        if let token = interruptionMonitorToken {
            removeUIInterruptionMonitor(token)
        }
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        return app
    }

    func testHomeShowsSeedItemsAndGauge() throws {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["Pencils (box of 12)"].waitForExistence(timeout: 12))
        let gauge = app.descendants(matching: .any).matching(identifier: "supplyHealthGauge").firstMatch
        XCTAssertTrue(gauge.waitForExistence(timeout: 12), "Supply health gauge did not appear")
    }

    func testMarkUsedDecrementsRemaining() throws {
        let app = launchApp()
        let markUsedButton = app.buttons["markUsedButton_Glue Sticks"]
        XCTAssertTrue(markUsedButton.waitForExistence(timeout: 12))
        markUsedButton.tap()

        XCTAssertTrue(app.staticTexts["4 left"].waitForExistence(timeout: 12), "Remaining count did not decrement")
    }

    func testRestockIncreasesRemaining() throws {
        let app = launchApp()
        let restockButton = app.buttons["restockButton_Glue Sticks"]
        XCTAssertTrue(restockButton.waitForExistence(timeout: 12))
        restockButton.tap()

        let countField = app.textFields["restockCountField"]
        XCTAssertTrue(countField.waitForExistence(timeout: 12))
        countField.tap()
        countField.doubleTap()

        app.buttons["saveRestockButton"].tap()

        XCTAssertTrue(app.staticTexts["Docket"].waitForExistence(timeout: 12))
    }

    func testAddItemFromHome() throws {
        let app = launchApp()
        let addButton = app.buttons["addItemButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 12))
        addButton.tap()

        let nameField = app.textFields["itemNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 12))
        nameField.tap()
        nameField.typeText("Markers")

        app.buttons["saveItemButton"].tap()

        XCTAssertTrue(app.staticTexts["Markers"].waitForExistence(timeout: 12), "New item did not appear")
    }

    func testDeleteItemViaForm() throws {
        let app = launchApp()
        let notebooksText = app.staticTexts["Notebooks"]
        XCTAssertTrue(notebooksText.waitForExistence(timeout: 12))
        notebooksText.tap()

        app.buttons["deleteItemButton"].tap()

        XCTAssertFalse(app.staticTexts["Notebooks"].waitForExistence(timeout: 6), "Item was not deleted")
    }

    func testFreeLimitTriggersPaywallAtSixthItem() throws {
        let app = launchApp()
        // Seed has 3 items, free limit is 5 — add 2 more to hit the limit.
        for name in ["Tape", "Folders"] {
            let addButton = app.buttons["addItemButton"]
            XCTAssertTrue(addButton.waitForExistence(timeout: 12))
            addButton.tap()
            let nameField = app.textFields["itemNameField"]
            XCTAssertTrue(nameField.waitForExistence(timeout: 12))
            nameField.tap()
            nameField.typeText(name)
            app.buttons["saveItemButton"].tap()
            XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 12))
        }

        let addButton = app.buttons["addItemButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 12))
        addButton.tap()
        XCTAssertTrue(app.staticTexts["Docket Pro"].waitForExistence(timeout: 12), "Paywall did not appear after hitting the free item limit")
    }

    func testSettingsKeyboardDismissOnTap() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()

        let toggle = app.switches["lowStockAlertsToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 12))
        toggle.tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
    }

    func testItemFormDismissesKeyboardOnOutsideTap() throws {
        let app = launchApp()
        let addButton = app.buttons["addItemButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 12))
        addButton.tap()

        let nameField = app.textFields["itemNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 12))
        nameField.tap()
        nameField.typeText("Rulers")

        app.staticTexts["Category (e.g. Writing)"].tap()
        XCTAssertFalse(app.keyboards.element.exists, "Keyboard did not dismiss on tap-outside")
    }
}
