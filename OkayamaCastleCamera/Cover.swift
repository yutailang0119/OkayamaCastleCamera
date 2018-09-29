//
//  Cover.swift
//  OkayamaCastleCamera
//
//  Created by Yutaro Muta on 2018/09/28.
//  Copyright © 2018 Yutaro Muta. All rights reserved.
//

import UIKit

enum Cover {
    case normal
    case covered(image: CIImage)

    init?(index: Int) {
        switch index {
        case 0:
            self = .normal
        case 1:
            self = .covered(image: CIImage(image: #imageLiteral(resourceName: "cover1"))!)
        case 2:
            self = .covered(image: CIImage(image: #imageLiteral(resourceName: "cover2"))!)
        default:
            return nil
        }
    }

    func coveredImage(fromOriginal originalCIImage: CIImage?) -> CIImage? {
        switch self {
        case .normal:
            return originalCIImage
        case .covered(let image):
            guard let orgImage = originalCIImage else {
                return nil
            }
            let coverImage = image.resizeToSameSize(as: orgImage)
            let parameters: [String: Any] = [kCIInputImageKey: coverImage,
                                             kCIInputBackgroundImageKey: orgImage]
            let filter = CIFilter(name: "CISourceOverCompositing", parameters: parameters)!
            let outputImage = filter.outputImage
            return outputImage
        }
    }
}
