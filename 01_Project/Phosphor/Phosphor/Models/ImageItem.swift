//
//  ImageItem.swift
//  Phosphor
//
//  Created on 2025-11-06
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import CoreGraphics

struct ImageItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let thumbnail: NSImage?
    let resolution: CGSize
    let fileSize: Int64
    let modificationDate: Date
    var isMuted: Bool = false

    /// Per-frame transform (rotation, scale, position)
    var transform: FrameTransform = .identity

    /// Per-frame delay override in milliseconds.
    /// nil indicates frame inherits global FPS; non-nil enables per-frame timing.
    var customDelay: Double? = nil

    var fileName: String {
        url.lastPathComponent
    }

    var fileSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var resolutionString: String {
        "\(Int(resolution.width)) × \(Int(resolution.height))"
    }

    var aspectRatioValue: Double? {
        guard resolution.height > 0 else { return nil }
        return Double(resolution.width / resolution.height)
    }

    var aspectRatioLabel: String {
        guard resolution.width > 0, resolution.height > 0 else { return "—" }
        let widthInt = max(Int(resolution.width.rounded()), 1)
        let heightInt = max(Int(resolution.height.rounded()), 1)
        let divisor = gcd(widthInt, heightInt)
        let simplifiedWidth = widthInt / divisor
        let simplifiedHeight = heightInt / divisor
        return "\(simplifiedWidth):\(simplifiedHeight)"
    }

    static let supportedContentTypes: [UTType] = {
        var types: [UTType] = [.jpeg, .png, .gif, .tiff, .bmp]

        if #available(macOS 11.0, *) {
            types.append(contentsOf: [.heic, .heif])
        }

        if let webp = UTType("org.webmproject.webp") {
            types.append(webp)
        }

        if let tga = UTType("com.truevision.tga-image") {
            types.append(tga)
        }

        return types
    }()

    static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
        lhs.id == rhs.id
    }

    static func from(url: URL) -> ImageItem? {
        guard isSupported(url: url) else { return nil }

        return autoreleasepool {
            guard let image = NSImage.loadedNormalizingOrientation(from: url) else { return nil }

            // Get file attributes
            var fileSize: Int64 = 0
            var modificationDate = Date()

            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {
                fileSize = attributes[.size] as? Int64 ?? 0
                modificationDate = attributes[.modificationDate] as? Date ?? Date()
            }

            // Get image resolution
            let resolution = image.size

            // Create thumbnail sized to match the list canvas (no upscaling later)
            let thumbnailSize = CGSize(width: 120, height: 72)
            let thumbnail = image.resized(to: thumbnailSize)

            return ImageItem(
                url: url,
                thumbnail: thumbnail,
                resolution: resolution,
                fileSize: fileSize,
                modificationDate: modificationDate,
                isMuted: false
            )
        }
    }
}

extension NSImage {
    static func loadedNormalizingOrientation(from url: URL) -> NSImage? {
        return autoreleasepool {
            guard let original = NSImage(contentsOf: url) else { return nil }

            // Use CGImage-based approach to avoid lockFocus memory leaks
            guard let cgImage = original.cgImageRespectingOrientation() else { return nil }

            let size = CGSize(width: cgImage.width, height: cgImage.height)
            let image = NSImage(cgImage: cgImage, size: size)

            return image
        }
    }

    func resized(
        to targetSize: CGSize,
        preservingAspectRatio: Bool = true
    ) -> NSImage {
        guard let sourceCGImage = cgImageRespectingOrientation() else {
            return self
        }

        let clampedSize = CGSize(
            width: max(targetSize.width, 1),
            height: max(targetSize.height, 1)
        )

        let resolvedSize: CGSize
        if preservingAspectRatio {
            let widthRatio = clampedSize.width / size.width
            let heightRatio = clampedSize.height / size.height
            let ratio = min(widthRatio, heightRatio)
            resolvedSize = CGSize(
                width: max(size.width * ratio, 1),
                height: max(size.height * ratio, 1)
            )
        } else {
            resolvedSize = clampedSize
        }

        let pixelWidth = max(Int(resolvedSize.width.rounded()), 1)
        let pixelHeight = max(Int(resolvedSize.height.rounded()), 1)
        let finalSize = CGSize(width: CGFloat(pixelWidth), height: CGFloat(pixelHeight))

        let colorSpace = sourceCGImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return self
        }

        context.interpolationQuality = .high
        context.draw(sourceCGImage, in: CGRect(origin: .zero, size: finalSize))

        guard let scaledCGImage = context.makeImage() else {
            return self
        }

        return NSImage(cgImage: scaledCGImage, size: finalSize)
    }

    func resized(using instruction: ResizeInstruction) -> NSImage {
        switch instruction {
        case let .scale(percent):
            let factor = max(percent, 1) / 100.0
            let targetSize = CGSize(
                width: max(size.width * factor, 1),
                height: max(size.height * factor, 1)
            )
            return resized(to: targetSize, preservingAspectRatio: false)
        case let .fill(targetSize):
            return resizedToFill(targetSize: targetSize)
        case let .fit(targetSize, backgroundColor):
            return resizedToFit(targetSize: targetSize, backgroundColor: backgroundColor)
        }
    }

    private func resizedToFill(targetSize: CGSize) -> NSImage {
        let targetWidth = max(targetSize.width, 1)
        let targetHeight = max(targetSize.height, 1)
        let finalTarget = CGSize(width: targetWidth, height: targetHeight)

        let scale = max(
            finalTarget.width / size.width,
            finalTarget.height / size.height
        )

        let drawSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )

        let drawOrigin = CGPoint(
            x: (finalTarget.width - drawSize.width) / 2.0,
            y: (finalTarget.height - drawSize.height) / 2.0
        )

        let image = NSImage(size: finalTarget)
        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        self.draw(
            in: CGRect(origin: drawOrigin, size: drawSize),
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0
        )
        image.unlockFocus()
        return image
    }

    /// Scales image to fit inside target dimensions (letterbox).
    /// Empty space is filled with the specified background color.
    private func resizedToFit(targetSize: CGSize, backgroundColor: NSColor) -> NSImage {
        let targetWidth = max(targetSize.width, 1)
        let targetHeight = max(targetSize.height, 1)
        let finalTarget = CGSize(width: targetWidth, height: targetHeight)

        // Scale to fit inside target (letterbox)
        let scale = min(
            finalTarget.width / size.width,
            finalTarget.height / size.height
        )

        let drawSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )

        let drawOrigin = CGPoint(
            x: (finalTarget.width - drawSize.width) / 2.0,
            y: (finalTarget.height - drawSize.height) / 2.0
        )

        // Create output at exact target size
        let image = NSImage(size: finalTarget)
        image.lockFocus()

        // Fill background (for GIF transparency handling)
        backgroundColor.setFill()
        NSRect(origin: .zero, size: finalTarget).fill()

        // Draw scaled image centered
        NSGraphicsContext.current?.imageInterpolation = .high
        self.draw(
            in: CGRect(origin: drawOrigin, size: drawSize),
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0
        )
        image.unlockFocus()
        return image
    }

    /// Samples the top-left pixel to detect background color for auto-detect feature.
    func dominantCornerColor() -> NSColor {
        guard let cgImage = cgImageRespectingOrientation(),
              let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return .white
        }

        // Sample top-left pixel (first 4 bytes: RGBA or BGRA depending on format)
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        guard bytesPerPixel >= 3 else { return .white }

        let r = CGFloat(bytes[0]) / 255.0
        let g = CGFloat(bytes[1]) / 255.0
        let b = CGFloat(bytes[2]) / 255.0

        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }

    /// Apply per-frame transform and return transformed image on canvas
    func applying(transform: FrameTransform, canvasSize: CGSize) -> NSImage {
        guard !transform.isIdentity else { return self }
        
        let rotated = self.rotated(by: transform.rotation)
        
        let scaleFactor = transform.scale / 100.0
        let scaledSize = CGSize(
            width: rotated.size.width * scaleFactor,
            height: rotated.size.height * scaleFactor
        )
        let scaled = rotated.resized(to: scaledSize, preservingAspectRatio: false)
        
        let canvas = NSImage(size: canvasSize)
        canvas.lockFocus()
        
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: canvasSize).fill()
        
        let drawOrigin = CGPoint(
            x: (canvasSize.width - scaledSize.width) / 2 + transform.offsetX,
            y: (canvasSize.height - scaledSize.height) / 2 + transform.offsetY
        )
        
        scaled.draw(
            in: CGRect(origin: drawOrigin, size: scaledSize),
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0
        )
        
        canvas.unlockFocus()
        return canvas
    }
    
    /// Rotate image by degrees (0, 90, 180, 270)
    func rotated(by degrees: Int) -> NSImage {
        guard degrees != 0 else { return self }
        
        let radians = CGFloat(degrees) * .pi / 180
        let newSize: CGSize
        
        if degrees == 90 || degrees == 270 {
            newSize = CGSize(width: size.height, height: size.width)
        } else {
            newSize = size
        }
        
        let rotatedImage = NSImage(size: newSize)
        rotatedImage.lockFocus()
        
        let transform = NSAffineTransform()
        transform.translateX(by: newSize.width / 2, yBy: newSize.height / 2)
        transform.rotate(byRadians: radians)
        transform.translateX(by: -size.width / 2, yBy: -size.height / 2)
        transform.concat()
        
        self.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 1.0)
        
        rotatedImage.unlockFocus()
        return rotatedImage
    }
}

extension ImageItem {
    static func isSupported(url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension.lowercased()) else {
            return false
        }

        if type.conforms(to: .rawImage) {
            return false
        }

        return supportedContentTypes.contains { type.conforms(to: $0) }
    }
}

extension NSImage {
    func cgImageRespectingOrientation() -> CGImage? {
        guard
            let tiffData = tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            return nil
        }
        return bitmap.cgImage
    }
}

private func gcd(_ a: Int, _ b: Int) -> Int {
    var x = abs(a)
    var y = abs(b)
    while y != 0 {
        let remainder = x % y
        x = y
        y = remainder
    }
    return max(x, 1)
}
