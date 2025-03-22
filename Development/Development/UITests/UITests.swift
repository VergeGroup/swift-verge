import XCTest

final class UITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testNavigationToBookReading() throws {
        // @Readingのリンクが存在することを確認
        let readingLink = app.staticTexts["@Reading"]
        XCTAssertTrue(readingLink.exists)
        
        // リンクをタップ
        readingLink.tap()
        
        // 基本的なUI要素の存在確認
        XCTAssertTrue(app.buttons["New"].exists)
        XCTAssertTrue(app.buttons["Up Outer"].exists)
        XCTAssertTrue(app.staticTexts["Using Store holding"].exists)
        XCTAssertTrue(app.staticTexts["Using Store passed"].exists)
        
        // 値の更新テスト
        let upButton = app.buttons["A Up"]
        XCTAssertTrue(upButton.exists)
        
        // 初期値の確認
        XCTAssertTrue(app.staticTexts["A Value: 0"].exists)
        XCTAssertTrue(app.staticTexts["B Value: 0"].exists)
        
        // 値を更新
        upButton.tap()
        
        // 更新後の値の確認
        XCTAssertTrue(app.staticTexts["A Value: 1"].exists)
        XCTAssertTrue(app.staticTexts["B Value: 1"].exists)
        
        app.buttons["A,1"].tap()
                             
        app.buttons["A : 1"].tap()
      
      XCTAssertTrue(app.buttons["In A : 0"].exists)
      
        // Bセクションのテスト
        let b1Button = app.buttons["B,1"]
        XCTAssertTrue(b1Button.exists)
        b1Button.tap()
        
        // Bの値を更新
        let bButton = app.buttons["B : 0"]
        bButton.tap()
    }
  
  func testA_up() {
        
    let app = XCUIApplication()
    app.collectionViews/*@START_MENU_TOKEN@*/.buttons["@Reading"]/*[[".cells.buttons[\"@Reading\"]",".buttons[\"@Reading\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

    app.buttons["A Up"].tap()
   
    XCTAssertTrue(app.staticTexts["A Value: 1"].exists)
    XCTAssertTrue(app.staticTexts["B Value: 1"].exists)
    
  }
  
  func test_sync() {
        
    let app = XCUIApplication()
    app.collectionViews/*@START_MENU_TOKEN@*/.buttons["@Reading"]/*[[".cells.buttons[\"@Reading\"]",".buttons[\"@Reading\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    app.buttons["A.1"].tap()
        
    app.buttons["A.1.a: 0"].tap()
    
    XCTAssertTrue(app.buttons["A.1.a: 1"].exists)
    
    app.buttons["B.1"].tap()

    XCTAssertTrue(app.buttons["B.1.a: 1"].exists)

    
  }
}
