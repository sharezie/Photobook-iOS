//
//  PhotosAsset.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

class PhotosAsset: Asset {
    
    var photosAsset: PHAsset
    
    var identifier: String{
        return photosAsset.localIdentifier
    }
    
    init(_ asset: PHAsset){
        photosAsset = asset
    }
    
    func uneditedImage(size: CGSize, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        
        let imageSize = CGSize(width: size.width * UIScreen.main.usableScreenScale(), height: size.height * UIScreen.main.usableScreenScale())
        PHImageManager.default().requestImage(for: photosAsset, targetSize: imageSize, contentMode: .aspectFill, options: options) { (image, _) in
            completionHandler(image, nil)
        }
    }
    
}