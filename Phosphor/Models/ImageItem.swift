//
//  ImageItem.swift
//  Phosphor
//
//  Created on 2025-11-06
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ImageItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let thumbnail: NSImage?
    let resolution: CGSize
    let fileSize: Int64
    let modificationDate: Date

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

        return types
    }()

    static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
        lhs.id == rhs.id
    }

    static func from(url: URL) -> ImageItem? {
        guard isSupported(url: url) else { return nil }
        guard let image = NSImage(contentsOf: url) else { return nil }

        // Get file attributes
        var fileSize: Int64 = 0
        var modificationDate = Date()

        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {
            fileSize = attributes[.size] as? Int64 ?? 0
            modificationDate = attributes[.modificationDate] as? Date ?? Date()
        }

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
            modificationDate: modificationDate
        )
    }
}

extension NSImage {
    func resized(to newSize: CGSize) -> NSImage {
        let ratio = min(newSize.width / size.width, newSize.height / size.height)
        let targetSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()

        let rect = NSRect(origin: .zero, size: targetSize)
        draw(in: rect, from: NSRect(origin: .zero, size: size), operation: .copy, fraction: 1.0)

        newImage.unlockFocus()
        return newImage
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
