//
//  CIImage+Utils.swift
//  OkayamaCastleCamera
//

import CoreImage

extension CIImage {
    func resizeToSameSize(as anotherImage: CIImage) -> CIImage {
        let size = anotherImage.extent.size
        return resize(size)
    }

    func createCGImage() -> CGImage {
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(self, from: extent) else { fatalError() }
        return cgImage
    }
}

extension CIImage {
    func resize(_ size: CGSize) -> CIImage {
        let originalSize = extent.size
        let transform = CGAffineTransform(scaleX: size.width / originalSize.width, y: size.height / originalSize.height)
        return transformed(by: transform)
    }
}
