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

        // Frame properties
        let frameProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFDelayTime as String: frameDelay,
                kCGImagePropertyGIFUnclampedDelayTime as String: frameDelay
            ]
        ]

        // Process each image
        for (index, item) in images.enumerated() {
            guard let nsImage = NSImage(contentsOf: item.url),
                  let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                throw ExportError.failedToCreateImage
            }

            // Add frame to GIF
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
