//
//  RealtimeMaskViewController.swift
//  OkayamaCastleCamera
//
//  Created by Yutaro Muta on 2018/09/25.
//  Copyright © 2018 Yutaro Muta. All rights reserved.
//

import UIKit
import MetalKit
import AVFoundation
import Photos

final class RealtimeMaskViewController: UIViewController {

    @IBOutlet weak var mtkView: MTKView! {
        didSet {
            let device = MTLCreateSystemDefaultDevice()!
            mtkView.device = device
            mtkView.backgroundColor = .clear
            renderer = MetalRenderer(metalDevice: device, renderDestination: mtkView)
        }
    }
    @IBOutlet weak var maskSegmentedControl: UISegmentedControl! {
        didSet {
            maskSegmentedControl.selectedSegmentIndex = 0
        }
    }
    @IBOutlet weak var coverSegmentedControl: UISegmentedControl! {
        didSet {
            coverSegmentedControl.selectedSegmentIndex = 0
        }
    }
    @IBOutlet weak var backgroundPickerButton: UIButton! {
        didSet {
            backgroundPickerButton.isEnabled = false
        }
    }
    @IBOutlet weak var shutterButton: UIButton! {
        didSet {
            shutterButton.isEnabled = true
        }
    }

    private var videoCapture: VideoCapture!
    private var currentCameraType: CameraType = .front(true)
    private let serialQueue = DispatchQueue(label: "com.yutailajng0119.OkayamaCastleCamera")
    private var currentCaptureSize: CGSize = CGSize.zero {
        didSet {
            self.backgroundCIImage = backgroundCIImage?.resize(currentCaptureSize)
        }
    }

    private var renderer: MetalRenderer!

    private var backgroundCIImage: CIImage?
    private var videoImage: CIImage?
    private var maskImage: CIImage?
    private var displayedImage: CIImage?

    override func viewDidLoad() {
        super.viewDidLoad()

        videoCapture = VideoCapture(cameraType: currentCameraType,
                                    preferredSpec: nil,
                                    previewContainer: nil)

        videoCapture.syncedDataBufferHandler = { [weak self] videoPixelBuffer, depthData, face in
            guard let strongSelf = self else { return }

            strongSelf.videoImage = CIImage(cvPixelBuffer: videoPixelBuffer)

            let videoWidth = CVPixelBufferGetWidth(videoPixelBuffer)
            let videoHeight = CVPixelBufferGetHeight(videoPixelBuffer)

            let captureSize = CGSize(width: videoWidth, height: videoHeight)
            guard strongSelf.currentCaptureSize == captureSize else {
                strongSelf.currentCaptureSize = captureSize
                return
            }

            DispatchQueue.main.async(execute: {
                strongSelf.serialQueue.async {
                    guard let depthPixelBuffer = depthData?.depthDataMap else { return }
                    strongSelf.processBuffer(videoPixelBuffer: videoPixelBuffer, depthPixelBuffer: depthPixelBuffer, face: face)
                }
            })
        }

        videoCapture.setDepthFilterEnabled(true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mtkView.delegate = self
        videoCapture?.startCapture()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoCapture?.resizePreview()
    }

    override func viewWillDisappear(_ animated: Bool) {
        videoCapture?.imageBufferHandler = nil
        videoCapture?.stopCapture()
        mtkView.delegate = nil
        super.viewWillDisappear(animated)
    }

    @IBAction func selectedMask(_ sender: UISegmentedControl) {
        let isBlened = sender.selectedSegmentIndex == 2
        backgroundPickerButton.isEnabled = isBlened
    }

    @IBAction func tappedSwitchCamera(_ sender: UIBarButtonItem) {
        switch currentCameraType {
        case .back:
            currentCameraType = .front(true)
        case .front:
            currentCameraType = .back(true)
        }
        videoCapture.changeCamera(with: currentCameraType)
    }

    @IBAction func filterSwitched(_ sender: UISwitch) {
        videoCapture.setDepthFilterEnabled(sender.isOn)
    }

    @IBAction func tappedSelectBackground(_ sender: UIButton) {
        let picker = AssetsPickerController.make(with: .all) { asset in
            asset.requestColorImage { image in
                self.backgroundCIImage = image?.adjustedCIImage(targetSize: self.currentCaptureSize)
            }
        }
        present(picker, animated: true, completion: nil)
    }

    @IBAction func tappedShutter(_ sender: UIButton) {
        guard let displayedImage = displayedImage else {
            return
        }
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(displayedImage, from: displayedImage.extent) else {
            fatalError()
        }
        let image = UIImage(cgImage: cgImage)
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(didFinishSaveImage(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc func didFinishSaveImage(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeMutableRawPointer) {
        let title = error != nil ? "Saving failed" : "Saved!!!"
        UIAlertController.showAlert(title: title, message: nil, on: self)
    }

}

extension RealtimeMaskViewController {
    private func readDepth(from depthPixelBuffer: CVPixelBuffer, at position: CGPoint, scaleFactor: CGFloat) -> Float {
        let pixelX = Int((position.x * scaleFactor).rounded())
        let pixelY = Int((position.y * scaleFactor).rounded())

        CVPixelBufferLockBaseAddress(depthPixelBuffer, .readOnly)

        let rowData = CVPixelBufferGetBaseAddress(depthPixelBuffer)! + pixelY * CVPixelBufferGetBytesPerRow(depthPixelBuffer)
        let faceCenterDepth = rowData.assumingMemoryBound(to: Float32.self)[pixelX]
        CVPixelBufferUnlockBaseAddress(depthPixelBuffer, .readOnly)

        return faceCenterDepth
    }

    func processBuffer(videoPixelBuffer: CVPixelBuffer, depthPixelBuffer: CVPixelBuffer, face: AVMetadataObject?) {
        let videoWidth = CVPixelBufferGetWidth(videoPixelBuffer)
        let depthWidth = CVPixelBufferGetWidth(depthPixelBuffer)

        var depthCutOff: Float = 1.0
        if let face = face {
            let faceCenter = CGPoint(x: face.bounds.midX, y: face.bounds.midY)
            let scaleFactor = CGFloat(depthWidth) / CGFloat(videoWidth)
            let faceCenterDepth = readDepth(from: depthPixelBuffer, at: faceCenter, scaleFactor: scaleFactor)
            depthCutOff = faceCenterDepth + 0.25
        }

        // 二値化
        // Convert depth map in-place: every pixel above cutoff is converted to 1. otherwise it's 0
        depthPixelBuffer.binarize(cutOff: depthCutOff)

        // Create the mask from that pixel buffer.
        let depthImage = CIImage(cvPixelBuffer: depthPixelBuffer, options: [:])

        // Smooth edges to create an alpha matte, then upscale it to the RGB resolution.
        let alphaUpscaleFactor = Float(CVPixelBufferGetWidth(videoPixelBuffer)) / Float(depthWidth)

        self.maskImage = depthImage.applyingFilter("CIBicubicScaleTransform", parameters: ["inputScale": alphaUpscaleFactor])
    }
}

extension RealtimeMaskViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }

    func draw(in view: MTKView) {
        guard let maskType = MaskType(rawValue: maskSegmentedControl.selectedSegmentIndex),
            let cover = Cover(index: coverSegmentedControl.selectedSegmentIndex) else {
            fatalError()
        }
        let maskedImage = maskType.maskedImage(fromInput: videoImage, maskImage: maskImage, backgroundCIImage: backgroundCIImage)
        guard let coveredImage = cover.coveredImage(fromOriginal: maskedImage) else {
            return
        }
        displayedImage = coveredImage
        renderer.update(with: coveredImage)
    }
}

extension RealtimeMaskViewController {
    private enum MaskType: Int {
        case original = 0
        case clipped
        case blended

        func maskedImage(fromInput inputImage: CIImage?, maskImage: CIImage?, backgroundCIImage: CIImage?) -> CIImage? {
            switch self {
            case .original:
                return inputImage
            case .clipped:
                guard let image = inputImage,
                    let maskImage = maskImage else {
                        return nil
                }

                let parameters: [String: Any] = [kCIInputMaskImageKey: maskImage]

                let outputImage = image.applyingFilter("CIBlendWithMask", parameters: parameters)
                return outputImage
            case .blended:
                guard let image = inputImage,
                    let maskImage = maskImage else {
                        return nil
                }

                var parameters: [String: Any] = [kCIInputMaskImageKey: maskImage]
                parameters[kCIInputBackgroundImageKey] = backgroundCIImage

                let outputImage = image.applyingFilter("CIBlendWithMask", parameters: parameters)
                return outputImage
            }
        }
    }
}
