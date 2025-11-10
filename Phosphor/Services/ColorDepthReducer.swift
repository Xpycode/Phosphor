//
//  ColorDepthReducer.swift
//  Phosphor
//
//  Created on 2025-11-07
//

import AppKit
import CoreImage

struct ColorDepthReducer {
    static let shared = ColorDepthReducer()

    private let context = CIContext(options: [
        .cacheIntermediates: true
    ])

    func applyingPosterize(to image: NSImage, levels: Int) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let ciImage = CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIColorPosterize") else {
            return nil
        }

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(Double(levels), forKey: "inputLevels")

        guard
            let output = filter.outputImage,
            let resultCGImage = context.createCGImage(output, from: output.extent)
        else {
            return nil
        }

        return NSImage(cgImage: resultCGImage, size: image.size)
    }
}
