//
//  PhotobookPreviewTests.swift
//  SDK DemoUITests
//
//  Created by Konstadinos Karayannis on 25/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest

class PhotobookPreviewTests: PhotobookUITest {
    
    func testSizeChange() {
        automation.goToPhotobookReview()
        
        let titleButton = automation.app.buttons["titleButton"]
        let originalTitle = titleButton.label
            
        titleButton.tap()
        
        let sizeButton = automation.app.sheets.buttons.matching(NSPredicate(format: "label != \"Cancel\" && label != \"\(originalTitle)\"")).firstMatch
        sizeButton.tap()
        
        XCTAssertNotEqual(titleButton.label, originalTitle)
    }
    
    func testEnterTextOnSpine() {
        automation.goToPhotobookReview()
        
        let spineLabel = automation.app.staticTexts["spineLabel"]
        XCTAssertTrue(spineLabel.label.isEmpty, "The spine label should be empty at the beginning")
        
        let spineButton = automation.app.collectionViews/*@START_MENU_TOKEN@*/.otherElements["spineButton"]/*[[".cells",".otherElements[\"Spine\"]",".otherElements[\"spineButton\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        spineButton.tap()
        
        let spineTextField = automation.app.textFields["spineTextField"]
        spineTextField.typeText("The Story of the Grand Clown Fiesta\n")
        
        XCTAssertTrue(spineButton.isHittable, "Did not return to Photobook preview")
        XCTAssertEqual(spineLabel.label, "The Story of the Grand Clown Fiesta")
    }
    
    func testRearrange() {
        automation.goToPhotobookReview()
        
        automation.app.buttons["titleButton"].tap()
        automation.app.sheets.buttons.matching(NSPredicate(format: "label CONTAINS \"Landscape\"")).firstMatch.tap()
        
        automation.app.navigationBars.firstMatch.buttons["Rearrange"].tap()
        
        automation.app.collectionViews.otherElements["Pages 2 and 3"].tap()
        automation.app.menuItems["Copy"].tap()
        
        wait(0.5) // Wait for the menu to animate away
        
        automation.app.collectionViews.otherElements["Pages 2 and 3"].tap()
        automation.app.menuItems["Paste"].tap()
        
        wait(0.5) // Wait for the insertion animation
        
        let pages2_3Screenshot = automation.app.collectionViews.otherElements["Pages 2 and 3"].screenshot().image
        let pages4_5Screenshot = automation.app.collectionViews.otherElements["Pages 4 and 5"].screenshot().image
        XCTAssertTrue(1 == 2)
        
    }
    
    
    
}
