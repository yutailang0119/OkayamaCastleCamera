//
//  PHContentEditingInput+Utils.swift
//  OkayamaCastleCamera
//

import Photos

extension PHAsset {

    func requestColorImage(handler: @escaping (UIImage?) -> Void) {
        PHImageManager.default().requestImage(for: self, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.aspectFit, options: nil) { (image, info) in
            handler(image)
        }
    }

}

extension PHContentEditingInput {

    func createImageSource() -> CGImageSource {
        guard let url = fullSizeImageURL else { fatalError() }
        return CGImageSourceCreateWithURL(url as CFURL, nil)!
    }
}
