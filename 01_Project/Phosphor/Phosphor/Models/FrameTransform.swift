//
//  FrameTransform.swift
//  Phosphor
//
//  Created on 2026-01-31
//

import Foundation

/// Per-frame transform settings for rotation, scale, and position
struct FrameTransform: Equatable, Codable {
    /// Rotation in degrees (0, 90, 180, 270 only)
    var rotation: Int = 0

    /// Scale percentage (50-200%)
    var scale: Double = 100

    /// Horizontal offset from center in pixels
    var offsetX: CGFloat = 0

    /// Vertical offset from center in pixels
    var offsetY: CGFloat = 0

    /// Identity transform with no modifications
    static let identity = FrameTransform()

    /// Valid scale range
    static let scaleRange: ClosedRange<Double> = 50...200

    /// Whether this transform has any effect
    var isIdentity: Bool {
        rotation == 0 && scale == 100 && offsetX == 0 && offsetY == 0
    }

    /// Rotate 90 degrees clockwise
    mutating func rotate90Clockwise() {
        rotation = (rotation + 90) % 360
    }

    /// Rotate 90 degrees counter-clockwise
    mutating func rotate90CounterClockwise() {
        rotation = (rotation - 90 + 360) % 360
    }

    /// Rotate 180 degrees
    mutating func rotate180() {
        rotation = (rotation + 180) % 360
    }

    /// Reset to identity transform
    mutating func reset() {
        self = .identity
    }
}
