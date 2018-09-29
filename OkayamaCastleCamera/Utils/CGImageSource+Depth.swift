//
//  CGImageSource+Depth.swift
//  OkayamaCastleCamera
//

import AVFoundation

extension CGImageSource {

    private var portraitEffectsMatteDataInfo: [String : AnyObject]? {
        return CGImageSourceCopyAuxiliaryDataInfoAtIndex(self, 0, kCGImageAuxiliaryDataTypePortraitEffectsMatte) as? [String : AnyObject]
    }

    func getMatteData() -> AVPortraitEffectsMatte? {
        if let info = portraitEffectsMatteDataInfo {
            return try? AVPortraitEffectsMatte(fromDictionaryRepresentation: info)
        }
        return nil
    }

}
