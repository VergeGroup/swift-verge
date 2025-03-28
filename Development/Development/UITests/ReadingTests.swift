import XCTest

final class ReadingTests: XCTestCase {

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
      "@Reading"
    ]
    .tap()

    app.buttons["A Up"].tap()

    XCTAssertTrue(app.staticTexts["A Value: 1"].exists)
    XCTAssertTrue(app.staticTexts["B Value: 1"].exists)

  }

  func test_sync() {

    let app = XCUIApplication()
    app.collectionViews.buttons[
      "@Reading"
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
  
  func test_binding_reading() {
        
    let app = XCUIApplication()
    app.collectionViews/*@START_MENU_TOKEN@*/.buttons["Binding @Reading"]/*[[".cells.buttons[\"Binding @Reading\"]",".buttons[\"Binding @Reading\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    app.buttons["Increment"].tap()
    
    XCTAssertTrue(app.staticTexts["1"].exists)
    
  }
  
  func test_binding_storeReader() {
    
    let app = XCUIApplication()
    app.collectionViews.buttons["Binding StoreReader"].tap()
    app.buttons["Increment"].tap()
    
    XCTAssertTrue(app.staticTexts["1"].exists)
    
  }
}
