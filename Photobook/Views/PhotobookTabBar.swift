//
//  PhotobookTabBar.swift
//  Photobook
//
//  Created by Jaime Landazuri on 10/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class PhotobookTabBar: UITabBar {
    
    var effectView: UIVisualEffectView?
    var tabChangeObserver: NSKeyValueObservation?
    
    var isBackgroundHidden:Bool = false {
        didSet {
            effectView?.alpha = isBackgroundHidden ? 0 : 1
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        effectView?.frame = bounds
    }
    
    func setup() {
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        self.effectView = effectView
        
        effectView.backgroundColor = UIColor(white: 1.0, alpha: 0.75)
        insertSubview(effectView, at: 0)
        backgroundImage = UIImage(color: .clear)
        shadowImage = UIImage()
        
        tabChangeObserver = observe(\.selectedItem, options: [.new,.old], changeHandler: { tabBar, change in
            guard let oldValue = change.oldValue,
                let newValueTitle = tabBar.selectedItem?.title,
                newValueTitle != oldValue?.title
                else { return }
            Analytics.shared.trackAction(Analytics.ActionName.photoSourceSelected, [Analytics.PropertyNames.photoSourceName: newValueTitle])
        })
    }
    
}
