# Salvaged Code from Previous Implementation

**Date:** 2025-11-13
**Source:** Commits up to `3faf94e` (6-pane workspace implementation)

This directory contains code that is potentially reusable when rebuilding the app from scratch.

## ⚠️ Important Notes

- **NOT TESTED** - Export code hasn't been verified to work end-to-end
- Use this as reference only
- Review carefully before integrating into new codebase
- May need modifications to work with new architecture

---

## 📁 Directory Structure

```
SALVAGED_CODE/
├── Services/           Export functionality
├── Models/             Data models
├── Utilities/          Helper functions and extensions
└── README.md          This file
```

---

## 🔧 Services/

### GIFExporter.swift (159 lines)
**Purpose:** Export sequence of images to animated GIF

**Features:**
- Async/await implementation
- Per-frame delay support
- Quality settings (0.0 - 1.0)
- Dithering with CoreImage CIDither filter
- Color depth reduction integration
- Loop count support (0 = infinite)
- Progress callbacks
- File size checking
- Orientation normalization

**Dependencies:**
- `ImageItem` model
- `ResizeInstruction` enum (from ExportSettings)
- `ColorDepthReducer` service
- `ExportError` enum

**Usage Pattern:**
```swift
try await GIFExporter.export(
    images: [ImageItem],
    to: URL,
    frameDelay: Double,        // seconds per frame
    loopCount: Int,            // 0 = infinite
    quality: Double,           // 0.0 - 1.0
    dithering: Bool,
    resizeInstruction: ResizeInstruction?,
    colorDepthLevels: Int?,    // for posterization
    perFrameDelays: [Double]?, // optional per-frame timing
    progressHandler: (Double) -> Void
)
```

**Key Functions:**
- Main export function (async)
- Automatic orientation correction
- EXIF-aware image loading
- Memory-efficient autoreleasepool usage

---

### APNGExporter.swift (88 lines)
**Purpose:** Export sequence of images to animated PNG (APNG)

**Features:**
- Async/await implementation
- Per-frame delay support
- Loop count support
- Resize support
- Progress callbacks
- Orientation normalization

**Dependencies:**
- `ImageItem` model
- `ResizeInstruction` enum
- `ExportError` enum

**Usage Pattern:**
```swift
try await APNGExporter.export(
    images: [ImageItem],
    to: URL,
    frameDelay: Double,
    loopCount: Int,
    resizeInstruction: ResizeInstruction?,
    perFrameDelays: [Double]?,
    progressHandler: (Double) -> Void
)
```

**Note:** APNG doesn't support quality settings like GIF/WebP

---

### ColorDepthReducer.swift (~100 lines)
**Purpose:** Reduce color depth for GIF optimization using CoreImage

**Features:**
- Singleton pattern (thread-safe)
- CIColorPosterize filter wrapper
- Reduces colors to specified levels (2-30 recommended)
- Used before GIF export to optimize file size

**Usage Pattern:**
```swift
let reduced = ColorDepthReducer.shared.applyingPosterize(
    to: NSImage,
    levels: Int  // e.g., 16 for 16^3 = 4096 colors
)
```

**Why it exists:** GIF files use a 256-color palette. Reducing colors before export can significantly reduce file size and improve encoding efficiency.

---

### WebPExporter.swift (30 lines)
**Status:** ⚠️ STUBBED OUT - NOT IMPLEMENTED

**Purpose:** Export sequence to WebP format

**Current Implementation:**
```swift
static func export(...) async throws {
    // TODO: Implement WebP export using libwebp
    print("WebP export not yet implemented")
    throw ExportError.failedToCreateDestination
}
```

**To Implement:** Would need libwebp integration via Swift Package or C bridging

---

## 📦 Models/

### ImageItem.swift (120 lines)
**Purpose:** Represents a single image file with metadata

**Properties:**
```swift
let id: UUID
let url: URL
let fileName: String
let fileSize: Int64
let resolution: CGSize
let modificationDate: Date
var thumbnail: NSImage?
```

**Computed Properties:**
- `resolutionString` - "1920×1080"
- `fileSizeString` - "2.4 MB"
- `aspectRatioValue` - Width/height ratio
- `aspectRatioLabel` - "16:9", "4:3", etc.

**Key Features:**
- Lazy thumbnail generation
- EXIF orientation handling
- File format detection
- Aspect ratio calculations

**Static Properties:**
```swift
static var supportedContentTypes: [UTType]
// Includes: JPEG, PNG, GIF, TIFF, BMP, HEIC, WebP
```

**Important Methods:**
```swift
static func loadedNormalizingOrientation(from: URL) -> NSImage?
extension NSImage.cgImageRespectingOrientation() -> CGImage?
extension NSImage.resized(using: ResizeInstruction) -> NSImage
```

**Note:** Thumbnail generation happens on main thread - may want to optimize this

---

### ExportSettings.swift (267 lines)
**Purpose:** All settings for export configuration

**Main Settings:**
```swift
@Published var format: ExportFormat          // .gif, .apng, .webp
@Published var frameDelay: Double            // milliseconds
@Published var frameRate: Double             // FPS
@Published var loopCount: Int                // 0 = infinite
@Published var quality: Double               // 0.0 - 1.0
@Published var enableDithering: Bool
@Published var colorDepthEnabled: Bool
@Published var colorDepthLevels: Double      // 2-30
@Published var resizeEnabled: Bool
@Published var canvasWidth: Double
@Published var canvasHeight: Double
// ... more settings
```

**Enums:**
```swift
enum ExportFormat: String, CaseIterable {
    case gif = "GIF"
    case webp = "WebP"
    case apng = "APNG"
}

enum ResizeInstruction {
    case scale(percent: Double)
    case fill(size: CGSize)
}

enum SortOrder {
    case fileName
    case modificationDate
    case manual
}
```

**Platform Presets:**
- WhatsApp Sticker (512×512, <1MB)
- Discord Emoji (320×320, 512KB)
- Slack Sticker (512×512, <1MB)
- Telegram Sticker (512×512, <2MB)

**Resize Presets:**
- Per-format presets (GIF: Square, SD, 720p, 1080p, etc.)
- Automatic preset selection

**Computed Properties:**
```swift
var resizeInstruction: ResizeInstruction?
var resolvedCanvasSize: CGSize?
var effectiveFrameSkipInterval: Int
var clampedColorDepthLevels: Int
var approximateColorCount: Int
```

**Helpful Methods:**
- `updateFrameRateFromDelay()` - Sync FPS with delay
- `updateDelayFromFrameRate()` - Sync delay with FPS
- Frame rate snapping to common values

---

## 🛠️ Utilities/

### NSImage Extensions (from ImageItem.swift)

#### Orientation Handling
```swift
static func loadedNormalizingOrientation(from: URL) -> NSImage?
```
- Loads image and applies EXIF orientation
- Fixes rotated images from cameras/phones
- Essential for proper image display

#### CGImage Conversion
```swift
extension NSImage {
    func cgImageRespectingOrientation() -> CGImage?
}
```
- Converts NSImage to CGImage
- Respects original orientation
- Required for export functions

#### Resizing
```swift
extension NSImage {
    func resized(using: ResizeInstruction) -> NSImage
}
```
- Supports `.scale(percent:)` and `.fill(size:)`
- Maintains aspect ratio for .fill
- High-quality interpolation

#### Dithering
```swift
extension NSImage {
    func applyingDither(intensity: Double) -> NSImage?
}
```
- Uses CoreImage CIDither filter
- Helps reduce banding in GIFs
- Default intensity: 0.2

---

## 💾 Error Handling

### ExportError enum
```swift
enum ExportError: LocalizedError {
    case failedToCreateDestination
    case failedToCreateImage
    case failedToFinalizeDestination
    case noImages
    case fileSizeLimitExceeded(maxBytes: Int64, actualBytes: Int64)
}
```

All cases provide user-friendly `errorDescription` strings.

---

## 🔗 Integration Notes

### To Use These Files:

1. **Services:**
   - Copy entire Services folder
   - Add to Xcode project
   - Ensure all are in target membership

2. **Models:**
   - Copy ImageItem.swift first
   - Then ExportSettings.swift (depends on ResizeInstruction)
   - Update any namespace/imports if needed

3. **Dependencies:**
   ```
   GIFExporter needs:
   - ImageItem
   - ExportSettings (ResizeInstruction)
   - ColorDepthReducer
   - ExportError

   APNGExporter needs:
   - ImageItem
   - ExportSettings (ResizeInstruction)
   - ExportError

   ColorDepthReducer:
   - No dependencies (standalone)

   ImageItem needs:
   - ExportSettings (ResizeInstruction)
   ```

4. **Frameworks Required:**
   ```swift
   import Foundation
   import AppKit
   import ImageIO
   import UniformTypeIdentifiers
   import CoreImage
   import CoreGraphics
   ```

---

## ⚠️ Known Issues

1. **Thumbnail Generation:**
   - Happens on main thread
   - May block UI with many images
   - Consider moving to background queue

2. **WebP Support:**
   - Not implemented
   - Would need external library

3. **Memory Usage:**
   - ImageItem caching not implemented
   - May need optimization for large batches

4. **Testing Status:**
   - Export code not fully tested in isolation
   - Was working in old app but may need integration work

---

## 🎯 When to Use This Code

**Use it when you need:**
- GIF export with advanced features (dithering, color reduction)
- APNG export
- Image metadata handling
- Export configuration UI
- Platform-specific presets (Discord, WhatsApp, etc.)

**Don't use it if:**
- You want a simpler export workflow
- You find bugs that are too time-consuming to fix
- Your new design doesn't need these features

---

## 📝 Recommended Usage Strategy

1. **Start fresh** - Build your new UI/data models
2. **When you need export** - Review these files
3. **Test incrementally** - Add one service at a time
4. **Modify as needed** - Don't be afraid to simplify

The export code is likely solid, but the models/utilities may need adjustments for your new architecture.

---

## 🗂️ Original Location

These files were extracted from:
```
Phosphor/
├── Services/
│   ├── GIFExporter.swift
│   ├── APNGExporter.swift
│   ├── ColorDepthReducer.swift
│   └── WebPExporter.swift
└── Models/
    ├── ExportSettings.swift
    └── ImageItem.swift
```

Commit: `3faf94e` (Implement 6-pane workspace with progressive disclosure)
Branch: `feature/6-pane-workspace`

---

## 📊 Code Stats

| File | Lines | Complexity | Status |
|------|-------|------------|--------|
| GIFExporter.swift | 159 | Medium | Untested |
| APNGExporter.swift | 88 | Low | Untested |
| ColorDepthReducer.swift | ~100 | Low | Untested |
| WebPExporter.swift | 30 | N/A | Stub only |
| ExportSettings.swift | 267 | Medium | Likely fine |
| ImageItem.swift | 120 | Medium | Needs review |
| **TOTAL** | **~764** | | |

---

**Last Updated:** 2025-11-13
**Next Step:** Build your new app from scratch, reference this when needed
