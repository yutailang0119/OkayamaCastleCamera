//
//  PortraitMatteViewController.swift
//  OkayamaCastleCamera
//
//  Created by Yutaro Muta on 2018/09/25.
//  Copyright © 2018 Yutaro Muta. All rights reserved.
//

import UIKit
import Photos
import CoreImage

final class PortraitMatteViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var matteSegmentedControl: UISegmentedControl! {
        didSet {
            matteSegmentedControl.selectedSegmentIndex = 0
            matteSegmentedControl.isEnabled = false
        }
    }
    @IBOutlet weak var coverSegmentedControl: UISegmentedControl! {
        didSet {
            coverSegmentedControl.selectedSegmentIndex = 0
            coverSegmentedControl.isEnabled = false
        }
    }
    @IBOutlet weak var backgroundPickerButton: UIButton! {
        didSet {
            backgroundPickerButton.isEnabled = false
        }
    }
    @IBOutlet weak var shutterButton: UIButton! {
        didSet {
            shutterButton.isEnabled = false
        }
    }

    private var image: UIImage? {
        didSet {
            shutterButton.isEnabled = image != nil
            update()
        }
    }
    private var backgroundImage: UIImage? {
        didSet {
            update()
        }
    }
    private var imageSource: CGImageSource? {
        didSet {
            let isEnabled = imageSource != nil
            DispatchQueue.main.async(execute: {
                self.matteSegmentedControl.isEnabled = isEnabled
                self.coverSegmentedControl.isEnabled = isEnabled
            })
        }
    }
    private var mattePixelBuffer: CVPixelBuffer?

    private func loadAsset(_ asset: PHAsset) {
        asset.requestColorImage { image in
            self.image = image
        }
        asset.requestContentEditingInput(with: nil) { contentEditingInput, info in
            self.imageSource = contentEditingInput?.createImageSource()
            self.getPortraitMatte()
        }
    }

    private func drawImage(_ image: UIImage?) {
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }

    private func getPortraitMatte() {
        mattePixelBuffer = imageSource?.getMatteData()?.mattingImage
    }

    private func update() {
        guard let matteType = MatteType(rawValue: matteSegmentedControl.selectedSegmentIndex),
            let cover = Cover(index: coverSegmentedControl.selectedSegmentIndex) else {
                fatalError()
        }

        guard let matteImage = matteType.matteImage(fromOriginal: image, mattePixelBuffer: mattePixelBuffer, backgroundImage: backgroundImage) else {
            UIAlertController.showAlert(title: "No Portrait Matte",
                                        message: "This picture doesn't have portrait matte info. Plaease take a picture of a HUMAN with PORTRAIT mode.",
                                        on: self)
            return
        }
        guard let coveredImage = cover.coveredImage(fromOriginal: matteImage) else {
            return
        }
        drawImage(UIImage(ciImage: coveredImage))

    }

    // MARK: - Actions

    @IBAction func selectedMaskType(_ sender: UISegmentedControl) {
        let isBlened = sender.selectedSegmentIndex == 2
        backgroundPickerButton.isEnabled = isBlened
        update()
    }

    @IBAction func selectedCover(_ sender: UISegmentedControl) {
        update()
    }

    @IBAction func tappedBackgroundPiccker(_ sender: UIButton) {
        let picker = AssetsPickerController.make(with: .all) { asset in
            asset.requestColorImage { backgroundImage in
                self.backgroundImage = backgroundImage
            }
        }
        present(picker, animated: true, completion: nil)
    }

    @IBAction func tappedShutter(_ sender: UIButton) {
        guard let displayedImage = imageView.image,
         let ciImage = displayedImage.ciImage else {
            return
        }
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            fatalError()
        }
        let image = UIImage(cgImage: cgImage)
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(didFinishSaveImage(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc func didFinishSaveImage(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeMutableRawPointer) {
        let title = error != nil ? "Saving failed" : "Saved!!!"
        UIAlertController.showAlert(title: title, message: nil, on: self)
    }

    @IBAction func tappedPortraitPiccker(_ sender: UIButton) {
        let picker = AssetsPickerController.make(with: .depth) { asset in
            self.matteSegmentedControl.selectedSegmentIndex = 0
            self.loadAsset(asset)
        }
        present(picker, animated: true, completion: nil)
    }
}

extension PortraitMatteViewController {
    private enum MatteType: Int {
        case original = 0
        case matte
        case blended

        func matteImage(fromOriginal originalImage: UIImage?, mattePixelBuffer: CVPixelBuffer?, backgroundImage: UIImage?) -> CIImage? {
            switch self {
            case .original:
                return originalImage?.cgImage.flatMap { CIImage(cgImage: $0) }
            case .matte:
                guard let cgOriginalImage = originalImage?.cgImage,
                    let matte = mattePixelBuffer else {
                        return nil
                }
                let orgImage = CIImage(cgImage: cgOriginalImage)
                let maskImage = CIImage(cvPixelBuffer: matte).resizeToSameSize(as: orgImage)
                let parameters: [String: Any] = [kCIInputImageKey: orgImage,
                                                 kCIInputMaskImageKey: maskImage,]
                let filter = CIFilter(name: "CIBlendWithMask", parameters: parameters)!
                return filter.outputImage
            case .blended:
                guard let cgOriginalImage = originalImage?.cgImage,
                    let matte = mattePixelBuffer else {
                        return nil
                }
                let orgImage = CIImage(cgImage: cgOriginalImage)
                let maskImage = CIImage(cvPixelBuffer: matte).resizeToSameSize(as: orgImage)
                var parameters: [String: Any] = [kCIInputImageKey: orgImage,
                                                 kCIInputMaskImageKey: maskImage,]
                parameters[kCIInputBackgroundImageKey] = backgroundImage.flatMap({ CIImage(image: $0) })?.resizeToSameSize(as: orgImage)
                let filter = CIFilter(name: "CIBlendWithMask", parameters: parameters)!
                return filter.outputImage
            }
        }
    }

}
