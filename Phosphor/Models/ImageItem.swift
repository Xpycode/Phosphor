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
import AVFoundation

struct ImageItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let thumbnail: NSImage?
    let resolution: CGSize
    let fileSize: Int64
    let modificationDate: Date
    let isVideo: Bool
    let duration: Double?

    var fileName: String {
        url.lastPathComponent
    }

    var fileSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var resolutionString: String {
        "\(Int(resolution.width)) × \(Int(resolution.height))"
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

        // Add video formats
        types.append(contentsOf: [
            .movie,
            .video,
            .mpeg4Movie,
            .quickTimeMovie,
            .mpeg2Video,
            .appleProtectedMPEG4Video
        ])

        return types
    }()

    static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
        lhs.id == rhs.id
    }

    static func from(url: URL) -> ImageItem? {
        guard isSupported(url: url) else { return nil }

        // Get file attributes
        var fileSize: Int64 = 0
        var modificationDate = Date()

        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {
            fileSize = attributes[.size] as? Int64 ?? 0
            modificationDate = attributes[.modificationDate] as? Date ?? Date()
        }

        // Check if this is a video file
        if isVideoFile(url: url) {
            return fromVideo(url: url, fileSize: fileSize, modificationDate: modificationDate)
        } else {
            return fromImage(url: url, fileSize: fileSize, modificationDate: modificationDate)
        }
    }

    private static func isVideoFile(url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension.lowercased()) else {
            return false
        }
        return type.conforms(to: .movie) || type.conforms(to: .video)
    }

    private static func fromImage(url: URL, fileSize: Int64, modificationDate: Date) -> ImageItem? {
        guard let image = NSImage(contentsOf: url) else { return nil }

        // Get image resolution
        let resolution = image.size

        // Create thumbnail
        let thumbnailSize = CGSize(width: 60, height: 60)
        let thumbnail = image.resized(to: thumbnailSize)

        return ImageItem(
            url: url,
            thumbnail: thumbnail,
            resolution: resolution,
            fileSize: fileSize,
            modificationDate: modificationDate,
            isVideo: false,
            duration: nil
        )
    }

    private static func fromVideo(url: URL, fileSize: Int64, modificationDate: Date) -> ImageItem? {
        let asset = AVAsset(url: url)

        // Get video duration
        let duration = asset.duration.seconds

        // Get video resolution
        guard let videoTrack = asset.tracks(withMediaType: .video).first else { return nil }
        let size = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        let resolution = CGSize(width: abs(size.width), height: abs(size.height))

        // Generate thumbnail
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero

        var thumbnail: NSImage?
        do {
            let cgImage = try imageGenerator.copyCGImage(at: CMTime(seconds: 0, preferredTimescale: 600), actualTime: nil)
            let nsImage = NSImage(cgImage: cgImage, size: resolution)
            let thumbnailSize = CGSize(width: 60, height: 60)
            thumbnail = nsImage.resized(to: thumbnailSize)
        } catch {
            // If thumbnail generation fails, use nil
            thumbnail = nil
        }

        return ImageItem(
            url: url,
            thumbnail: thumbnail,
            resolution: resolution,
            fileSize: fileSize,
            modificationDate: modificationDate,
            isVideo: true,
            duration: duration
        )
    }
}

extension NSImage {
    func resized(
        to targetSize: CGSize,
        preservingAspectRatio: Bool = true
    ) -> NSImage {
        guard let sourceCGImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
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
