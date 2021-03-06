//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import XCTest
@testable import Photobook_App

class FacebookAlbumManagerTests: XCTestCase {
    
    var facebookAlbumManager: FacebookAlbumManager!
    var facebookApiManager: FacebookApiManagerMock!
    
    override func setUp() {
        super.setUp()
        
        facebookAlbumManager = FacebookAlbumManager()
        facebookApiManager = FacebookApiManagerMock()
        facebookAlbumManager.facebookManager = facebookApiManager
    }
    
    func testLoadAssets_shouldFailWithoutATokenKey() {
        facebookAlbumManager.loadAlbums { error in XCTAssertNotNil(error) }
    }

    func testLoadAlbums_shouldCallCompletionIfThereAreAlbumsAlreadyLoaded() {
        facebookApiManager.accessToken = "ClownKey"
        var called = false
        
        let album = PhotosAlbum(PHAssetCollectionMock())
        facebookAlbumManager.albums = [album]
        facebookAlbumManager.loadAlbums { error in
            called = true
            XCTAssertNil(error)
        }
        XCTAssertTrue(called)
    }
    
    func testLoadAlbums_shouldReturnErrorIfApiFails() {
        facebookApiManager.accessToken = "ClownKey"
        facebookApiManager.error = ErrorMock()
        facebookAlbumManager.loadAlbums { error in XCTAssertNotNil(error) }
    }
    
    func testLoadAlbums_shouldReturnErrorIfResultIsNil() {
        facebookApiManager.accessToken = "ClownKey"
        facebookAlbumManager.loadAlbums { error in XCTAssertNotNil(error) }
    }
    
    func testLoadAlbums_shouldReturnErrorIfResultIsNotDictionary() {
        facebookApiManager.accessToken = "ClownKey"
        facebookApiManager.result = ["An array", "With strings"]
        facebookAlbumManager.loadAlbums { error in XCTAssertNotNil(error) }
    }
    
    func testLoadAssets_shouldNotParseImageDataWithoutRequiredFields() {
        facebookApiManager.accessToken = "ClownKey"
        let testData = ["data": [
            ["id": "1", "name": "Clown Photos", "cover_photo": ["id": "cover_1"]],
            ["id": "2", "name": "Massive Fiesta", "count": 3, "cover_photo": ["id": "cover_2"]],
            ["id": "3", "count": 1, "cover_photo": ["id": "cover_3"]],
            ["name": "Friday Clowning", "count": 1, "cover_photo": ["id": "cover_4"]],
            ["id": "5", "name": "Friday Clowning", "count": 1 ],
            ["id": "6", "name": "Friday Clowning", "count": 1, "cover_photo": ["id": "cover_6"]],
            ]]
        
        // Should only parse 2 & 6
        facebookApiManager.result = testData
        facebookAlbumManager.loadAlbums { (error) in
            XCTAssertEqual(self.facebookAlbumManager.albums.count, 2)
            XCTAssertTrue(self.facebookAlbumManager.albums.contains { $0.identifier == "2"})
            XCTAssertTrue(self.facebookAlbumManager.albums.contains { $0.identifier == "6"})
        }
    }
    
    func testLoadNextBatchOfAlbums_shouldDoNothingIfThereIsNoMoreAlbumsToRequest() {
        facebookApiManager.accessToken = "ClownKey"
        let testData = ["data": [
            ["id": "1", "name": "Thursday Clowning", "count": 1, "images": [["source": testUrlString, "width": 700, "height": 500]], "cover_photo": ["id": "cover_1"]],
            ]]
        facebookApiManager.result = testData

        var called: Bool = false
        facebookAlbumManager.loadNextBatchOfAlbums { _ in called = true }
        
        XCTAssertFalse(called)
    }
    
    func testLoadNextBatchOfAlbums_shouldPerformRequestWithProvidedNextUrl() {
        facebookApiManager.accessToken = "ClownKey"
        var testData: [String: Any] = [
            "paging": ["next": "clown1", "cursors": ["after" : "clown2"]],
            "data": [
            ["id": "1", "name": "Thursday Clowning", "count": 1, "images": [["source": testUrlString, "width": 700, "height": 500]], "cover_photo": ["id": "cover_1"]],
            ]]
 
        facebookApiManager.result = testData
        facebookAlbumManager.loadAlbums { _ in }
        XCTAssertTrue(facebookAlbumManager.hasMoreAlbumsToLoad)
        
        testData["paging"] = nil
        facebookApiManager.result = testData
        facebookAlbumManager.loadNextBatchOfAlbums { _ in }
        XCTAssertTrue(facebookApiManager.lastPath != nil && facebookApiManager.lastPath!.contains("clown2"))
        XCTAssertFalse(facebookAlbumManager.hasMoreAlbumsToLoad)
    }
}
