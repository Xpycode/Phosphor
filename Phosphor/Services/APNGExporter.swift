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
        resizeConfiguration: ExportResizeConfiguration?,
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

        // Frame properties
        let frameProperties: [String: Any] = [
            kCGImagePropertyPNGDictionary as String: [
                kCGImagePropertyAPNGDelayTime as String: frameDelay
            ]
        ]

        // Process each image
        for (index, item) in images.enumerated() {
            try autoreleasepool {
                guard var nsImage = NSImage(contentsOf: item.url) else {
                    throw ExportError.failedToCreateImage
                }

                if let resizeConfiguration = resizeConfiguration {
                    nsImage = nsImage.resized(
                        to: resizeConfiguration.targetSize,
                        preservingAspectRatio: resizeConfiguration.preserveAspectRatio
                    )
                }

                guard let cgImage = nsImage.tiffCGImage else {
                    throw ExportError.failedToCreateImage
                }

                // Add frame to APNG
                CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
            }

            // Update progress
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
