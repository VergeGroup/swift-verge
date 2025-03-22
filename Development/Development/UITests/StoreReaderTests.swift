import XCTest

final class StoreReaderTests: XCTestCase {
  
  var app: XCUIApplication!
  
  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launch()
  }
  
  override func tearDownWithError() throws {
    app = nil
  }
  
  func testA_up() {
    
    let app = XCUIApplication()
    app.collectionViews.buttons[
      "StoreReader"
    ]
      .tap()
    
    app.buttons["A Up"].tap()
    
    XCTAssertTrue(app.staticTexts["A Value: 1"].exists)
    XCTAssertTrue(app.staticTexts["B Value: 1"].exists)
    
  }
  
  func test_sync() {
    
    let app = XCUIApplication()
    app.collectionViews.buttons[
      "StoreReader"
    ]
      .tap()
    app.buttons["A.1"].tap()
    
    app.buttons["A.1.a: 0"].tap()
    
    XCTAssertTrue(app.buttons["A.1.a: 1"].exists)
    
    app.buttons["B.1"].tap()
    
    XCTAssertTrue(app.buttons["B.1.a: 1"].exists)
    
    app.buttons["B.1.a: 1"].tap()
    
    XCTAssertTrue(app.buttons["A.1.a: 2"].exists)
    XCTAssertTrue(app.buttons["B.1.a: 2"].exists)
    
    
  }
}
