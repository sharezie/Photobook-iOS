//
//  PhotoBookCollectionViewCell.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 21/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class PhotoBookCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var bookView: UIView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var leftPageView: PhotoBookPageView!
    @IBOutlet weak var rightPageView: PhotoBookPageView?
    @IBOutlet weak var bookWidthConstraint: NSLayoutConstraint!
    @IBOutlet var pageAspectRatioConstraint: NSLayoutConstraint!
    
    /* This hidden view is here only to set the aspect ratio of the page,
     because if the aspect ratio constraint is set to one of the non-hidden views,
     the automatic sizing of the cells doesn't work. I don't know why, it might be a bug
     in autolayout.
     */
    @IBOutlet weak var aspectRatioHelperView: UIView!
}
