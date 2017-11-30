//
//  AssetPickerCollectionViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 10/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class AssetPickerCollectionViewController: UICollectionViewController {

    @IBOutlet weak var selectAllButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    private let marginBetweenImages: CGFloat = 1
    private let numberOfCellsPerRow: CGFloat = 4 //CGFloat because it's used in size calculations
    private var previousPreheatRect = CGRect.zero
    var selectedAssetsManager: SelectedAssetsManager?
    
    var albumManager: AlbumManager?
    var album: Album! {
        didSet{
            self.title = album.localizedName
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resetCachedAssets()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        if album.assets.count == 0{
            self.album.loadAssets(completionHandler: { (_) in
                self.collectionView?.reloadData()
                self.postAlbumLoadSetup()
            })
        }
        else{
            postAlbumLoadSetup()
        }
        
        calcAndSetCellSize()
        
        if traitCollection.forceTouchCapability == .available{
            registerForPreviewing(with: self, sourceView: collectionView!)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateCachedAssets()
    }
    
    @IBAction func unwindToThisView(withUnwindSegue unwindSegue: UIStoryboardSegue) {}

    @IBAction func selectAllButtonTapped(_ sender: UIBarButtonItem) {
        if selectedAssetsManager?.count(for: album) == album.assets.count {
            selectedAssetsManager?.deselectAllAssets(for: album)
        }
        else {
            selectedAssetsManager?.selectAllAssets(for: album)
        }
        
        updateSelectAllButtonTitle()
        collectionView?.reloadData()
    }
    
    func postAlbumLoadSetup() {
        activityIndicator.stopAnimating()
        
        // Hide "Select All" if current album has too many photos
        if selectedAssetsManager?.willSelectingAllExceedTotalAllowed(for: album) ?? false{
            selectAllButton.title = nil
            return
        }
        
        updateSelectAllButtonTitle()
    }
    
    func updateSelectAllButtonTitle() {
        if selectedAssetsManager?.count(for: album) == self.album.assets.count {
            selectAllButton.title = NSLocalizedString("ImagePicker/Button/DeselectAll", value: "Deselect All", comment: "Button title for de-selecting all selected photos")
        }
        else{
            selectAllButton.title = NSLocalizedString("ImagePicker/Button/SelectAll", value: "Select All", comment: "Button title for selecting all selected photos")
        }
    }
    
    func calcAndSetCellSize() {
        guard let collectionView = collectionView else { return }
        var usableSpace = collectionView.frame.size.width;
        usableSpace -= (numberOfCellsPerRow - 1.0) * marginBetweenImages
        let cellWidth = usableSpace / numberOfCellsPerRow
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = CGSize(width: cellWidth, height: cellWidth)
    }
    
    // MARK: UIScrollView
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
    // MARK: Asset Caching
    
    fileprivate func resetCachedAssets() {
        albumManager?.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    
    fileprivate func updateCachedAssets() {
        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil else { return }
        
        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in album.assets[indexPath.item] }
        let removedAssets = removedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in album.assets[indexPath.item] }
        
        // Update the assets the PHCachingImageManager is caching.
        let thumbnailSize = (collectionView?.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize ?? .zero
        albumManager?.startCachingImages(for: addedAssets,
                                        targetSize: thumbnailSize)
        albumManager?.stopCachingImages(for: removedAssets,
                                       targetSize: thumbnailSize)
        
        // Store the preheat rect to compare against in the future.
        previousPreheatRect = preheatRect
    }
    
    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
    
}

extension AssetPickerCollectionViewController {
    //MARK: - UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return album.assets.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AssetPickerCollectionViewCell", for: indexPath) as? AssetPickerCollectionViewCell else { return UICollectionViewCell() }
        
        let asset = album.assets[indexPath.item]
        cell.assetId = asset.identifier
        
        let selected = selectedAssetsManager?.isSelected(asset, for: album) ?? false
        cell.selectedStatusImageView.image = selected ? UIImage(named: "Tick") : UIImage(named: "Tick-empty")
        
        let size = (self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize ?? .zero
        asset.image(size: size, completionHandler: {(image, _) in
            guard cell.assetId == asset.identifier else { return }
            cell.imageView.image = image
        })
        
        return cell
    }
    
}

extension AssetPickerCollectionViewController {
    //MARK: - UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = album.assets[indexPath.item]
        
        // TODO: Use result to present alert that we have selected the maximum amount of photos
        _ = selectedAssetsManager?.toggleSelected(asset, for: album)
        
        collectionView.reloadItems(at: [indexPath])
        
        updateSelectAllButtonTitle()
    }
    
}

extension AssetPickerCollectionViewController: UIViewControllerPreviewingDelegate{
    // MARK: - UIViewControllerPreviewingDelegate
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let collectionView = collectionView,
            let indexPath = collectionView.indexPathForItem(at: location),
            let cell = collectionView.cellForItem(at: indexPath) as? AssetPickerCollectionViewCell,
            let thumbnailImage = cell.imageView.image,
            let fullScreenImageViewController = storyboard?.instantiateViewController(withIdentifier: "FullScreenImageViewController") as? FullScreenImageViewController
            else { return nil }
        
        previewingContext.sourceRect = cell.convert(cell.contentView.frame, to: collectionView)
        
        fullScreenImageViewController.asset = album.assets[indexPath.item]
        fullScreenImageViewController.album = album
        fullScreenImageViewController.selectedAssetsManager = selectedAssetsManager
        fullScreenImageViewController.delegate = self
        fullScreenImageViewController.providesPresentationContextTransitionStyle = true
        fullScreenImageViewController.definesPresentationContext = true
        fullScreenImageViewController.modalPresentationStyle = .overCurrentContext
        
        // Use the cell's image to calculate the image's aspect ratio
        fullScreenImageViewController.preferredContentSize = CGSize(width: view.frame.size.width, height: view.frame.size.width * (thumbnailImage.size.height / thumbnailImage.size.width) - 1) // -1 because otherwise a black line can be seen above the image
        
        return fullScreenImageViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let fullScreenImageViewController = viewControllerToCommit as? FullScreenImageViewController else { return }
        fullScreenImageViewController.prepareForPop()
        fullScreenImageViewController.modalPresentationCapturesStatusBarAppearance = true
        
        tabBarController?.present(viewControllerToCommit, animated: true, completion: nil)
    }
    
}

extension AssetPickerCollectionViewController: FullScreenImageViewControllerDelegate{
    func previewDidUpdate(asset: Asset) {
        guard let index = album.assets.index(where: { (selectedAsset) in
            return selectedAsset.identifier == asset.identifier
        }),
            index != NSNotFound
            else { return }
        
        collectionView?.reloadItems(at: [IndexPath(item: index, section: 0)])
    }
    
    func sourceView(for asset:Asset) -> UIView?{
        guard let index = album.assets.index(where: { (selectedAsset) in
            return selectedAsset.identifier == asset.identifier
        }),
            index != NSNotFound,
        let cell = collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? AssetPickerCollectionViewCell
            else { return nil }
        
        return cell.imageView
        
    }
}

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}