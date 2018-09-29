//
//  AssetsPickerController.swift
//  OkayamaCastleCamera
//
//  Created by Yutaro Muta on 2018/09/26.
//  Copyright © 2018 Yutaro Muta. All rights reserved.
//

import UIKit
import Photos

final class AssetsPickerController: UIViewController {

    private let cellIdentifier = "AssetCell"
    private let collectionViewEdgeInset: CGFloat = 2
    private let assetsInRow: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 4 : 8
    private let cachingImageManager = PHCachingImageManager()
    private var adjustCellSize = CGSize.zero
    private var assets: [PHAsset] = [] {
        willSet {
            cachingImageManager.stopCachingImagesForAllAssets()
        }

        didSet {
            cachingImageManager.startCachingImages(for: self.assets, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.aspectFill, options: nil)
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.register(UINib(nibName: cellIdentifier, bundle: nil), forCellWithReuseIdentifier: cellIdentifier)
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.scrollDirection = UICollectionView.ScrollDirection.vertical

            collectionView?.collectionViewLayout = flowLayout
            collectionView?.backgroundColor = UIColor.white

            let scale = UIScreen.main.scale
            let cellSize = flowLayout.itemSize
            self.adjustCellSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
        }
    }

    private var albumType: AlbumType?
    private var completionHandler: ((PHAsset) -> Void)?

    static func make(with albumType: AlbumType, completion completionHandler: @escaping (PHAsset) -> Void) -> AssetsPickerController {
        let controller = UIStoryboard(name: "AssetsPicker", bundle: nil).instantiateViewController(withIdentifier: "AssetsPickerController") as! AssetsPickerController
        controller.albumType = albumType
        controller.completionHandler = completionHandler
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        func loadAssets() {
            assets = albumType?.assets ?? []
        }

        func showAlert() {
            let alertController = UIAlertController(title: "Could not get a image", message: "Please allow access to Photo Library", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }

        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ status in
                switch status {
                case .authorized:
                    loadAssets()
                case .notDetermined,.restricted, .denied:
                    showAlert()
                }
            })
        case .restricted, .denied:
            showAlert()
        case .authorized:
            loadAssets()
        }
    }

    @IBAction func tappedCancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

extension AssetsPickerController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
        guard let assetCell = cell as? AssetCell else {
            fatalError()
        }
        let asset = assets[indexPath.row]
        cachingImageManager.requestImage(for: asset, targetSize: adjustCellSize, contentMode: PHImageContentMode.aspectFill, options: nil, resultHandler: { (image: UIImage?, info :[AnyHashable: Any]?) -> Void in
            assetCell.configure(image)
        })
        return assetCell
    }
}

extension AssetsPickerController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = assets[indexPath.row]
        dismiss(animated: true) {
            self.completionHandler?(asset)
        }
    }
}

extension AssetsPickerController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let a = (self.view.frame.size.width - assetsInRow * 1 - 2 * collectionViewEdgeInset) / assetsInRow
        return CGSize(width: a, height: a)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: collectionViewEdgeInset, left: collectionViewEdgeInset, bottom: collectionViewEdgeInset, right: collectionViewEdgeInset)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
}
