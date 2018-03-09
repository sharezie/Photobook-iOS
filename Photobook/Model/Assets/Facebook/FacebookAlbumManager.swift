//
//  FacebookAlbumManager.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 02/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class FacebookAlbumManager {
    
    private struct Constants {
        static let pageSize = 100
        static let graphPath = "me/albums?limit=\(pageSize)&fields=id,name,count,cover_photo"
        static let serviceName = "Facebook"
    }
    
    var albums =  [Album]()
    let title = NSLocalizedString("Albums/Facebook/Title", value: "Facebook Albums", comment: "Facebook Albums screen title")
    
    private var after: String?
    
    func fetchAlbums(graphPath: String, completionHandler: ((Error?) -> Void)?) {
        guard let token = FBSDKAccessToken.current() else {
            completionHandler?(ErrorMessage(message: CommonLocalizedStrings.serviceAccessError(serviceName: Constants.serviceName)))
            return
        }
        
        let graphRequest = FBSDKGraphRequest(graphPath: graphPath, parameters: [:])
        _ = graphRequest?.start(completionHandler: { [weak welf = self] _, result, error in
            if let error = error {
                // Not worth showing an error if one of the later pagination requests fail
                guard self.albums.isEmpty else { return }
                completionHandler?(ErrorUtils.genericRetryErrorMessage(message: error.localizedDescription, action: {
                    welf?.fetchAlbums(graphPath: graphPath, completionHandler: completionHandler)
                }))
                return
            }
            
            guard let result = (result as? [String: Any]), let data = result["data"] as? [[String: Any]]
                else {
                    // Not worth showing an error if one of the later pagination requests fail
                    guard self.albums.isEmpty else { return }
                    completionHandler?(ErrorMessage(message: CommonLocalizedStrings.serviceAccessError(serviceName: Constants.serviceName)))
                    return
            }
            
            var albumAdditions = [AlbumAddition]()
            for album in data {
                guard let albumId = album["id"] as? String,
                let photoCount = album["count"] as? Int,
                let name = album["name"] as? String,
                let coverPhoto = (album["cover_photo"] as? [String: Any])?["id"] as? String,
                let coverPhotoUrl = URL(string: "https://graph.facebook.com/\(coverPhoto)/picture?access_token=\(token.tokenString!)")
                    else { continue }
                
                if let stelf = welf {
                    let newAlbum = FacebookAlbum(identifier: albumId, localizedName: name, numberOfAssets: photoCount, coverPhotoUrl: coverPhotoUrl)
                    albumAdditions.append(AlbumAddition(album: newAlbum, index: stelf.albums.count))
                    stelf.albums.append(newAlbum)
                }
            }
            
            // Get the next page cursor
            if let paging = result["paging"] as? [String: Any],
            paging["next"] != nil,
            let cursors = paging["cursors"] as? [String: Any],
                let after = cursors["after"] as? String {
                self.after = after
            }
            
            // Call the completion handler only on the first request, subsequent requests will update the album
            if let completionHandler = completionHandler {
                completionHandler(nil)
            } else {
                NotificationCenter.default.post(name: AssetsNotificationName.albumsWereAdded, object: albumAdditions)
            }
            
        })
    }

}

extension FacebookAlbumManager: AlbumManager {
    
    func loadAlbums(completionHandler: ((Error?) -> Void)?) {
        guard albums.isEmpty else { completionHandler?(nil); return }
        
        fetchAlbums(graphPath: Constants.graphPath, completionHandler: completionHandler)
    }
    
    func loadNextBatchOfAlbums() {
        guard let after = after else { return }
        self.after = nil
        let graphPath = Constants.graphPath + "&after=\(after)"
        fetchAlbums(graphPath: graphPath, completionHandler: nil)
    }
    
    var hasMoreAlbumsToLoad: Bool {
        return after != nil
    }
    
    func stopCachingImagesForAllAssets() { }
    func startCachingImages(for assets: [Asset], targetSize: CGSize) { }
    func stopCachingImages(for assets: [Asset], targetSize: CGSize) { }
}