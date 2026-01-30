# Plan: Enhanced Resize Section

## Problem Statement
The 511 MB GIF export from 6240×6240 source images revealed that:
1. Users need easy resize options before export
2. Current UI only offers Auto/Custom with manual dimensions
3. No Fill/Fit mode selection
4. Existing preset code isn't wired to UI

## Research Summary

### Current State Analysis
| Component | Status |
|-----------|--------|
| `ResizeInstruction.fill(size:)` | ✅ Implemented (crops overflow) |
| `ResizeInstruction.fit(size:)` | ❌ Missing (needs letterbox) |
| `ResizePresetOption` | ✅ Defined, not in UI |
| `ExportPlatformPreset` | ✅ Defined, not in UI |
| `ResizeSection.swift` | Only Auto/Custom toggle |

### Industry Standard Resize Modes
From [ezgif.com](https://ezgif.com/resize), [RedKetchup](https://redketchup.io/gif-resizer), and [VEED](https://www.veed.io/tools/resize-video/gif-resizer):

| Mode | Behavior | When to Use |
|------|----------|-------------|
| **Fit** | Scales to fit inside bounds, letterbox if needed | Preserve entire image |
| **Fill** | Scales to fill bounds, crops overflow | Full-bleed output |
| **Stretch** | Distorts to exact size | Rarely used |

### Common Presets (per [Speechify guide](https://speechify.com/blog/resizing-gifs/))
- **Small:** 480×480 (social stickers)
- **SD:** 640×480 (classic GIF)
- **HD 720p:** 1280×720 (web/sharing)
- **HD 1080p:** 1920×1080 (high quality)

---

## Proposed Design

### UI Layout (Updated ResizeSection)

```
┌─────────────────────────────────────────┐
│ ☑ Enable Resize                          │
├─────────────────────────────────────────┤
│ Mode:  [Auto] [Preset ▼] [Custom]       │
├─────────────────────────────────────────┤
│ (If Preset selected)                     │
│  Preset: [────────────── 720p HD ▼]     │
│  Scale:  ( ) Fit  (●) Fill              │
│  Output: 1280 × 720 px                  │
├─────────────────────────────────────────┤
│ (If Custom selected)                     │
│  Width:  [1280] px                       │
│  Height: [720 ] px                       │
│  Scale:  (●) Fit  ( ) Fill              │
│  ☐ Lock aspect ratio                    │
└─────────────────────────────────────────┘
```

### Scale Mode Behavior

**Fit Mode (Letterbox):**
- Scales image to fit entirely within target dimensions
- Output matches target size exactly
- Empty space filled with transparent (APNG) or user-selected color (GIF)

**Fill Mode (Crop):**
- Scales image to fill target dimensions completely
- Overflow is cropped from center
- No empty space, image may lose edges

### Data Model Changes

```swift
// Add to ExportSettings.swift

enum ScaleMode: String, CaseIterable, Identifiable {
    case fit   // Letterbox - entire image visible
    case fill  // Crop - fills frame completely

    var id: String { rawValue }
    var label: String {
        switch self {
        case .fit: return "Fit"
        case .fill: return "Fill"
        }
    }
}

enum CanvasMode: String, CaseIterable, Identifiable {
    case automatic  // Use source dimensions
    case preset     // Use predefined sizes
    case custom     // User-specified dimensions
}

// Add to ExportSettings class:
@Published var scaleMode: ScaleMode = .fit
@Published var selectedPresetID: String?
```

```swift
// Add to ResizeInstruction (ExportSettings.swift)

enum ResizeInstruction {
    case scale(percent: Double)
    case fill(size: CGSize)   // existing
    case fit(size: CGSize)    // NEW: letterbox to fit
}
```

### NSImage Extension Changes

```swift
// Add to ImageItem.swift

func resizedToFit(targetSize: CGSize, backgroundColor: NSColor = .clear) -> NSImage {
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
```

---

## Implementation Steps

### Wave 1: Model Layer
1. Add `ScaleMode` enum to `ExportSettings.swift`
2. Update `CanvasMode` to include `.preset` case
3. Add `.fit(size:)` case to `ResizeInstruction`
4. Add `scaleMode` and `selectedPresetID` properties to `ExportSettings`
5. Update `resizeInstruction` computed property to use `scaleMode`

### Wave 2: Image Processing
1. Add `resizedToFit(targetSize:backgroundColor:)` to NSImage extension
2. Update `resized(using:)` to handle new `.fit` case
3. Test with sample images to verify letterbox behavior

### Wave 3: UI Layer
1. Redesign `ResizeSection.swift` with new layout:
   - Three-way mode picker (Auto/Preset/Custom)
   - Preset dropdown (when mode = .preset)
   - Scale mode toggle (Fit/Fill)
   - Dimension preview text
2. Wire presets from `ResizePresetOption.presets(for:)`
3. Add output size preview label

### Wave 4: Integration & Polish
1. Test GIF export with Fit mode (check background color)
2. Test APNG export with Fit mode (check transparency)
3. Verify file size reduction with presets
4. Add to Xcode project if new files created

---

## Files to Modify

| File | Changes |
|------|---------|
| `ExportSettings.swift` | Add `ScaleMode`, update `CanvasMode`, add properties |
| `ImageItem.swift` | Add `resizedToFit()`, update `resized(using:)` |
| `ResizeSection.swift` | Complete redesign |

## Files to Create
None - all changes are to existing files.

---

## Testing Checklist
- [ ] Auto mode: no resize applied
- [ ] Preset 720p + Fit: 6240px image → 1280×720 letterboxed
- [ ] Preset 720p + Fill: 6240px image → 1280×720 cropped
- [ ] Custom 500×500 + Fit: non-square input → letterboxed
- [ ] Custom 500×500 + Fill: non-square input → cropped
- [ ] GIF letterbox: verify background color (white or configurable)
- [ ] APNG letterbox: verify transparency preserved
- [ ] File size: 6240px source → 720p preset should be < 10 MB

---

## Decisions Made

1. **Letterbox background for GIF:** ✅ Auto-detect from first pixel, with user override via color picker
2. **Preset organization:** ✅ Format-specific presets only (GIF gets GIF presets, APNG gets APNG presets)
3. **Default scale mode:** ✅ Fill (crop to fill, no empty space)

---

## Updated UI Layout

```
┌─────────────────────────────────────────┐
│ ☑ Enable Resize                          │
├─────────────────────────────────────────┤
│ Size:  [Auto] [Preset ▼] [Custom]       │
├─────────────────────────────────────────┤
│ (If Preset selected)                     │
│  [────────────── 720p HD ▼]             │
├─────────────────────────────────────────┤
│ (If Custom selected)                     │
│  Width:  [1280] px                       │
│  Height: [720 ] px                       │
├─────────────────────────────────────────┤
│ (If Preset or Custom)                    │
│  Scale:  ( ) Fit  (●) Fill              │
├─────────────────────────────────────────┤
│ (If Fit mode selected - GIF only)        │
│  Background: [■ Auto] [Pick Color...]   │
├─────────────────────────────────────────┤
│  Output: 1280 × 720 px                  │
└─────────────────────────────────────────┘
```

## Additional Model Changes

```swift
// Add to ExportSettings class:
@Published var scaleMode: ScaleMode = .fill  // Default: Fill
@Published var fitBackgroundColor: NSColor? = nil  // nil = auto-detect
@Published var useAutoBackgroundColor: Bool = true
```

```swift
// Add to ResizeInstruction
enum ResizeInstruction {
    case scale(percent: Double)
    case fill(size: CGSize)
    case fit(size: CGSize, backgroundColor: NSColor)
}
```

## Auto-Detect Background Logic

```swift
extension NSImage {
    /// Samples the top-left pixel to detect background color
    func dominantCornerColor() -> NSColor {
        guard let cgImage = cgImageRespectingOrientation(),
              let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return .white
        }

        // Sample top-left pixel (first 4 bytes: RGBA)
        let r = CGFloat(bytes[0]) / 255.0
        let g = CGFloat(bytes[1]) / 255.0
        let b = CGFloat(bytes[2]) / 255.0

        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
```

---

*Plan created: 2026-01-30*
*Decisions finalized: 2026-01-30*
