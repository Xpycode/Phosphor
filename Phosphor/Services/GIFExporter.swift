//
//  GIFExporter.swift
//  Phosphor
//
//  Created on 2025-11-06
//

import Foundation
import AppKit
import ImageIO
import UniformTypeIdentifiers

enum ExportError: LocalizedError {
    case failedToCreateDestination
    case failedToCreateImage
    case failedToFinalizeDestination
    case noImages
    case fileSizeLimitExceeded(maxBytes: Int64, actualBytes: Int64)

    var errorDescription: String? {
        switch self {
        case .failedToCreateDestination:
            return "Failed to create export destination"
        case .failedToCreateImage:
            return "Failed to process image"
        case .failedToFinalizeDestination:
            return "Failed to finalize export"
        case .noImages:
            return "No images to export"
        case let .fileSizeLimitExceeded(maxBytes, actualBytes):
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            let actual = formatter.string(fromByteCount: actualBytes)
            let max = formatter.string(fromByteCount: maxBytes)
            return "Export exceeds your size limit (\(actual) > \(max))."
        }
    }
}

struct GIFExporter {
    static func export(
        images: [ImageItem],
        to url: URL,
        frameDelay: Double,
        loopCount: Int,
        quality: Double,
        dithering: Bool,
        resizeConfiguration: ExportResizeConfiguration?,
        colorDepthLevels: Int?,
        perFrameDelays: [Double]?,
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        guard !images.isEmpty else {
            throw ExportError.noImages
        }

        // Create the destination
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.gif.identifier as CFString,
            images.count,
            nil
        ) else {
            throw ExportError.failedToCreateDestination
        }

        // Set global GIF properties
        let fileProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: loopCount
            ]
        ]
        CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)

        // Process each image
        for (index, item) in images.enumerated() {
            guard var nsImage = NSImage(contentsOf: item.url) else {
                throw ExportError.failedToCreateImage
            }

            if let resizeConfiguration = resizeConfiguration {
                nsImage = nsImage.resized(
                    to: resizeConfiguration.targetSize,
                    preservingAspectRatio: resizeConfiguration.preserveAspectRatio
                )
            }

            if let levels = colorDepthLevels, levels > 0, let reduced = ColorDepthReducer.shared.applyingPosterize(to: nsImage, levels: levels) {
                nsImage = reduced
            }

            guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                throw ExportError.failedToCreateImage
            }

            let effectiveDelay = perFrameDelays?[index] ?? (frameDelay * 1000.0)
            let delaySeconds = max(0.01, effectiveDelay / 1000.0)
            let frameProperties: [String: Any] = [
                kCGImagePropertyGIFDictionary as String: [
                    kCGImagePropertyGIFDelayTime as String: delaySeconds,
                    kCGImagePropertyGIFUnclampedDelayTime as String: delaySeconds
                ]
            ]

            CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)

            // Update progress
            let progress = Double(index + 1) / Double(images.count)
            await MainActor.run {
                progressHandler(progress)
            }
        }

        // Finalize the GIF
        guard CGImageDestinationFinalize(destination) else {
            throw ExportError.failedToFinalizeDestination
        }
    }
}

extension NSImage {
    func cgImage(forProposedRect proposedDestRect: UnsafeMutablePointer<NSRect>?, context: NSGraphicsContext?, hints: [NSImageRep.HintKey: Any]?) -> CGImage? {
        guard let imageData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: imageData) else {
            return nil
        }
        return bitmap.cgImage
    }
}
