//
//  PositionAnchor.swift
//  Phosphor
//
//  Created on 2026-01-31
//

import Foundation

/// Position presets for the 3x3 anchor grid
enum PositionAnchor: CaseIterable, Equatable {
    case topLeft, topCenter, topRight
    case middleLeft, center, middleRight
    case bottomLeft, bottomCenter, bottomRight

    var description: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topCenter: return "Top Center"
        case .topRight: return "Top Right"
        case .middleLeft: return "Middle Left"
        case .center: return "Center"
        case .middleRight: return "Middle Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomCenter: return "Bottom Center"
        case .bottomRight: return "Bottom Right"
        }
    }

    /// Calculate offset to position image at anchor on canvas
    /// Uses canvas-relative positioning - offset is bounded to keep image visible
    func offset(
        imageSize: CGSize,
        canvasSize: CGSize,
        scale: Double
    ) -> (x: CGFloat, y: CGFloat) {
        let scaledImage = CGSize(
            width: imageSize.width * scale / 100,
            height: imageSize.height * scale / 100
        )

        // Calculate the maximum useful offset in each direction
        // This is how far we can move before the image edge reaches the opposite canvas edge
        let maxOffsetX = max(0, (scaledImage.width - canvasSize.width) / 2)
        let maxOffsetY = max(0, (scaledImage.height - canvasSize.height) / 2)

        // For images smaller than canvas, use canvas-based offset to position within
        let smallImageOffsetX = max(0, (canvasSize.width - scaledImage.width) / 2)
        let smallImageOffsetY = max(0, (canvasSize.height - scaledImage.height) / 2)

        // Use the appropriate offset based on whether image is larger or smaller than canvas
        let useX = scaledImage.width > canvasSize.width ? maxOffsetX : smallImageOffsetX
        let useY = scaledImage.height > canvasSize.height ? maxOffsetY : smallImageOffsetY

        // SwiftUI offset: positive X moves view RIGHT, positive Y moves view DOWN
        // To show TOP-LEFT of image: move image RIGHT and DOWN → (+X, +Y)
        // To show BOTTOM-RIGHT of image: move image LEFT and UP → (-X, -Y)
        switch self {
        case .topLeft:
            return (useX, useY)
        case .topCenter:
            return (0, useY)
        case .topRight:
            return (-useX, useY)
        case .middleLeft:
            return (useX, 0)
        case .center:
            return (0, 0)
        case .middleRight:
            return (-useX, 0)
        case .bottomLeft:
            return (useX, -useY)
        case .bottomCenter:
            return (0, -useY)
        case .bottomRight:
            return (-useX, -useY)
        }
    }

    /// Detect which anchor is closest to the given offset
    static func detect(
        offsetX: CGFloat,
        offsetY: CGFloat,
        imageSize: CGSize,
        canvasSize: CGSize,
        scale: Double
    ) -> PositionAnchor? {
        // Use a relative tolerance based on canvas size
        let tolerance: CGFloat = min(canvasSize.width, canvasSize.height) * 0.02

        for anchor in PositionAnchor.allCases {
            let expected = anchor.offset(imageSize: imageSize, canvasSize: canvasSize, scale: scale)
            let dx = abs(offsetX - expected.x)
            let dy = abs(offsetY - expected.y)

            if dx < tolerance && dy < tolerance {
                return anchor
            }
        }

        return nil
    }
}
