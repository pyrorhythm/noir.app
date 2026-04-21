import XCTest

final class noirUITestsLaunchTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        XCUIApplication().terminate()
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--noir-ui-testing-disable-onboarding"]
        app.launch()

        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 5) || app.state == .runningForeground)
    }
}
