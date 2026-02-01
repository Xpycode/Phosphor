//
//  WebPExporter.swift
//  Phosphor
//
//  Created on 2026-01-31
//

import Foundation
import AppKit
import webp

struct WebPExporter {
    static func export(
        images: [ImageItem],
        to url: URL,
        frameDelay: Double,
        loopCount: Int,
        quality: Double,
        resizeInstruction: ResizeInstruction?,
        perFrameDelays: [Double]?,
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        guard !images.isEmpty else {
            throw ExportError.noImages
        }

        // Load first image to determine canvas size
        guard let firstNSImage = NSImage.loadedNormalizingOrientation(from: images[0].url) else {
            throw ExportError.failedToCreateImage
        }

        // Apply resize to get final canvas dimensions
        let firstProcessed: NSImage
        if let resizeInstruction = resizeInstruction {
            firstProcessed = firstNSImage.resized(using: resizeInstruction)
        } else {
            firstProcessed = firstNSImage
        }

        let width = Int(firstProcessed.size.width)
        let height = Int(firstProcessed.size.height)

        // Create animated WebP encoder
        // Quality: convert 0.0-1.0 to 0-100
        let webpQuality = Float(max(0, min(1, quality)) * 100)
        let encoder = WebPAnimatedEncoder()
        try encoder.create(
            config: .preset(.picture, quality: webpQuality),
            width: width,
            height: height
        )

        // Process each image
        for (index, item) in images.enumerated() {
            try autoreleasepool {
                guard var nsImage = NSImage.loadedNormalizingOrientation(from: item.url) else {
                    throw ExportError.failedToCreateImage
                }

                if !item.transform.isIdentity {
                    let canvasSize = resizeInstruction?.targetSize ?? nsImage.size
                    nsImage = nsImage.applying(transform: item.transform, canvasSize: canvasSize)
                }

                if let resizeInstruction = resizeInstruction {
                    nsImage = nsImage.resized(using: resizeInstruction)
                }

                // Calculate frame duration in milliseconds
                let delaySeconds: Double
                if let overrides = perFrameDelays, index < overrides.count {
                    delaySeconds = max(0.01, overrides[index] / 1000.0)
                } else {
                    delaySeconds = max(0.01, frameDelay)
                }
                let durationMs = Int(delaySeconds * 1000)

                // Add frame to encoder
                try encoder.addImage(image: nsImage, duration: durationMs)
            }

            // Update progress
            let progress = Double(index + 1) / Double(images.count)
            await MainActor.run {
                progressHandler(progress)
            }
        }

        // Encode and write to file
        let data = try encoder.encode(loopCount: loopCount)
        try data.write(to: url)
    }
}
