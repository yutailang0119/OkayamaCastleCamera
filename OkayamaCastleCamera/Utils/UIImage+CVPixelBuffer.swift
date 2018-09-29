//
//  UIImage+CVPixelBuffer.swift
//  OkayamaCastleCamera
//

import UIKit

extension UIImage {
    convenience init?(pixelBuffer: CVPixelBuffer) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let pixelBufferWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let pixelBufferHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let imageRect:CGRect = CGRect(x: 0, y: 0, width: pixelBufferWidth, height: pixelBufferHeight)
        let ciContext = CIContext.init()
        guard let cgImage = ciContext.createCGImage(ciImage, from: imageRect) else {
            return nil
        }
        self.init(cgImage: cgImage)
    }
}
