//
//  APNGExporter.swift
//  Phosphor
//
//  Created on 2025-11-06
//

import Foundation
import AppKit
import ImageIO
import UniformTypeIdentifiers

struct APNGExporter {
    static func export(
        images: [ImageItem],
        to url: URL,
        frameDelay: Double,
        loopCount: Int,
        resizeInstruction: ResizeInstruction?,
        perFrameDelays: [Double]?,
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        guard !images.isEmpty else {
            throw ExportError.noImages
        }

        // Create the destination
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            images.count,
            nil
        ) else {
            throw ExportError.failedToCreateDestination
        }

        // Set global APNG properties
        let fileProperties: [String: Any] = [
            kCGImagePropertyPNGDictionary as String: [
                kCGImagePropertyAPNGLoopCount as String: loopCount
            ]
        ]
        CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)

        // Process each image
        for (index, item) in images.enumerated() {
            try autoreleasepool {
                guard var nsImage = NSImage.loadedNormalizingOrientation(from: item.url) else {
                    throw ExportError.failedToCreateImage
                }

                if let resizeInstruction = resizeInstruction {
                    nsImage = nsImage.resized(using: resizeInstruction)
                }

                guard let cgImage = nsImage.cgImageRespectingOrientation() else {
                    throw ExportError.failedToCreateImage
                }

                let delaySeconds: Double
                if let overrides = perFrameDelays, index < overrides.count {
                    delaySeconds = max(0.01, overrides[index] / 1000.0)
                } else {
                    delaySeconds = max(0.01, frameDelay)
                }
                let frameProperties: [String: Any] = [
                    kCGImagePropertyPNGDictionary as String: [
                        kCGImagePropertyAPNGDelayTime as String: delaySeconds
                    ]
                ]

                CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
            }

            // Update progress (outside autoreleasepool to avoid MainActor issues)
            let progress = Double(index + 1) / Double(images.count)
            await MainActor.run {
                progressHandler(progress)
            }
        }

        // Finalize the APNG
        guard CGImageDestinationFinalize(destination) else {
            throw ExportError.failedToFinalizeDestination
        }
    }
}
