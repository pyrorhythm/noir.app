import XCTest

final class noirUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        XCUIApplication().terminate()
    }

    func testMenuBarAgentLaunchesWithoutOnboardingWindow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--noir-ui-testing-disable-onboarding"]
        app.launch()

        let launched = app.wait(for: .runningBackground, timeout: 5) || app.state == .runningForeground
        XCTAssertTrue(launched)
        XCTAssertFalse(app.windows["Welcome to Noir"].exists)
    }
}
