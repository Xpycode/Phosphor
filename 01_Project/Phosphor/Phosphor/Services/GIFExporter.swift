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
import CoreImage

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
        resizeInstruction: ResizeInstruction?,
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

                let paletteLevels = colorDepthLevels ?? 0
                if paletteLevels > 0, let reduced = ColorDepthReducer.shared.applyingPosterize(to: nsImage, levels: paletteLevels) {
                    nsImage = reduced
                }

                if dithering, paletteLevels > 0, let dithered = nsImage.applyingDither(intensity: GIFExporter.defaultDitherIntensity) {
                    nsImage = dithered
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
                let gifFrameProperties: [String: Any] = [
                    kCGImagePropertyGIFDelayTime as String: delaySeconds,
                    kCGImagePropertyGIFUnclampedDelayTime as String: delaySeconds
                ]

                let frameProperties: [String: Any] = [
                    kCGImageDestinationLossyCompressionQuality as String: max(0.0, min(1.0, quality)),
                    kCGImagePropertyGIFDictionary as String: gifFrameProperties
                ]

                CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
            }

            // Update progress (outside autoreleasepool to avoid MainActor issues)
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

private let gifExporterCIContext = CIContext(options: [.cacheIntermediates: true])
private extension GIFExporter {
    static let defaultDitherIntensity = 0.2
}

extension NSImage {
    func applyingDither(intensity: Double) -> NSImage? {
        guard let cgImage = cgImageRespectingOrientation() else {
            return nil
        }

        let ciImage = CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIDither") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(intensity, forKey: "inputIntensity")

        guard
            let output = filter.outputImage,
            let resultCGImage = gifExporterCIContext.createCGImage(output, from: output.extent)
        else {
            return nil
        }

        return NSImage(cgImage: resultCGImage, size: size)
    }
}
