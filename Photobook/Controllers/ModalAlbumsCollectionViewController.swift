//
//  ModalAlbumsCollectionViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 09/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

protocol AssetCollectorAddingDelegate: class {
    func didFinishAdding(assets: [Asset]?)
}

class ModalAlbumsCollectionViewController: UIViewController {

    private struct Constants {
        static let topMargin: CGFloat = 10.0
        static let borderCornerRadius: CGFloat = 10.0
        static let velocityToTriggerSwipe: CGFloat = 50.0
        static let velocityForFastDismissal: CGFloat = 1000.0
        static let screenThresholdToDismiss: CGFloat = 3.0 // A third of the height
    }
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var containerViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerViewHeightConstraint: NSLayoutConstraint!
    
    private var rootNavigationController: UINavigationController!
    private var downwardArrowButton: UIButton!
    private var hasAppliedMask = false
    
    var collectorMode: AssetCollectorMode = .adding
    var albumManager: AlbumManager?
    weak var addingDelegate: AssetCollectorAddingDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        containerViewBottomConstraint.constant = view.bounds.height
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 11.0, *) {
            containerViewHeightConstraint.constant = view.bounds.height - Constants.topMargin - view.safeAreaInsets.top
        } else {
            containerViewHeightConstraint.constant = view.bounds.height - Constants.topMargin
        }
        containerViewBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.backgroundColor = UIColor(white: 0.0, alpha: 0.6)
            self.view.layoutIfNeeded()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !hasAppliedMask {
            let rect = CGRect(x: 0.0, y: 0.0, width: view.bounds.width, height: view.bounds.height * 1.1)
            let cornerRadii = CGSize(width: Constants.borderCornerRadius, height: Constants.borderCornerRadius)
            let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft, .topRight], cornerRadii: cornerRadii).cgPath
            let maskLayer = CAShapeLayer()
            maskLayer.fillColor = UIColor.white.cgColor
            maskLayer.frame = rect
            maskLayer.path = path
            containerView.layer.mask = maskLayer
            
            hasAppliedMask = true
        }
        downwardArrowButton.center = CGPoint(x: view.center.x, y: 20.0)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AlbumsCollectionSegue" {
            rootNavigationController = segue.destination as! UINavigationController
            rootNavigationController.delegate = self
            
            let navigationBar = rootNavigationController.navigationBar as! PhotobookNavigationBar
            navigationBar.willShowPrompt = true
            
            downwardArrowButton = UIButton(type: .custom)
            downwardArrowButton.setImage(UIImage(named: "Drag-down-arrow"), for: .normal)
            downwardArrowButton.setTitleColor(.black, for: .normal)
            downwardArrowButton.sizeToFit()
            downwardArrowButton.addTarget(self, action: #selector(didTapOnArrowButton(_:)), for: .touchUpInside)
            navigationBar.addSubview(downwardArrowButton)
            
            let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPanOnNavigationBar(_:)))
            navigationBar.addGestureRecognizer(panGestureRecognizer)

            let albumsCollectionViewController = rootNavigationController.viewControllers.first as! AlbumsCollectionViewController
            albumsCollectionViewController.albumManager = albumManager
            albumsCollectionViewController.collectorMode = collectorMode
            albumsCollectionViewController.addingDelegate = self
        }
    }
    
    @IBAction private func didSwipeOnNavigationBar(_ gesture: UISwipeGestureRecognizer) {
        animateContainerViewOffScreen()
    }
    
    @IBAction private func didPanOnNavigationBar(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .changed:
            let deltaY = gesture.translation(in: view).y
            if deltaY <= 0.0 {
                containerViewBottomConstraint.constant = Constants.topMargin
                return
            }
            containerViewBottomConstraint.constant = Constants.topMargin + deltaY
        case .ended:
            let deltaY = gesture.translation(in: view).y
            let velocityY = gesture.velocity(in: view).y
            
            let belowThreshold = deltaY >= view.bounds.height / Constants.screenThresholdToDismiss
            if  belowThreshold || velocityY > Constants.velocityToTriggerSwipe {
                let duration = belowThreshold || velocityY > Constants.velocityForFastDismissal ? 0.2 : 0.4
                animateContainerViewOffScreen(duration: duration)
                return
            }
            containerViewBottomConstraint.constant = Constants.topMargin
            UIView.animate(withDuration: 0.1, delay: 0.0, options: [.beginFromCurrentState, .curveEaseOut], animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        default:
            break
        }
    }
    
    private func animateContainerViewOffScreen(duration: TimeInterval = 0.4, adding assets: [Asset]? = nil) {
        containerViewBottomConstraint.constant = view.bounds.height
        UIView.animate(withDuration: duration, delay: 0.0, options: [.beginFromCurrentState, .curveEaseOut], animations: {
            self.view.backgroundColor = .clear
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.addingDelegate?.didFinishAdding(assets: assets)
        })
    }
    
    @IBAction private func didTapOnArrowButton(_ sender: UIButton) {
        animateContainerViewOffScreen()
    }
}

extension ModalAlbumsCollectionViewController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        viewController.navigationItem.prompt = " "
    }
}

extension ModalAlbumsCollectionViewController: AssetCollectorAddingDelegate {
    
    func didFinishAdding(assets: [Asset]?) {
        animateContainerViewOffScreen(adding: assets)
    }
}