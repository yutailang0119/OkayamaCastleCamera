//
//  CVPixelBuffer+Utils.swift
//  OkayamaCastleCamera
//

import MetalKit

extension CVPixelBuffer {

    func binarize(cutOff: Float) {
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        for yMap in 0 ..< height {
            let rowData = CVPixelBufferGetBaseAddress(self)! + yMap * CVPixelBufferGetBytesPerRow(self)
            let data = UnsafeMutableBufferPointer<Float32>(start: rowData.assumingMemoryBound(to: Float32.self), count: width)
            for index in 0 ..< width {
                if data[index] > 0 && data[index] <= cutOff {
                    data[index] = 1.0
                } else {
                    data[index] = 0.0
                }
            }
        }
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
    }
}
