# Phase 11: Per-Frame Transforms - Implementation Plan

**Date:** 2026-01-31
**Status:** Ready for implementation
**Scope:** Add move, scale, rotate transforms for individual frames

---

## Research Summary

### Sources Consulted
- [Apple SwiftUI Gesture Documentation](https://developer.apple.com/documentation/swiftui/gesture) - `DragGesture`, `simultaneously(with:)`, combining gestures
- [SwiftUI Rotation Gestures](https://developer.apple.com/documentation/SwiftUI/RotateGesture) - `RotateGesture`, `rotationEffect`
- [Apple Motion Transform Handles](https://support.apple.com/en-kg/guide/motion/motn227c21ee/mac) - Standard transform handle UX pattern
- [Ezgif Frame-by-Frame Positioning](https://ezgif.com/add-image) - Per-frame X/Y offset approach in web tools
- [SwiftUI Bounding Box Implementation](https://github.com/littleossa/BoundingBox) - Reference SwiftUI implementation
- [Hacking with Swift Gestures](https://www.hackingwithswift.com/books/ios-swiftui/how-to-use-gestures-in-swiftui) - Gesture modifiers and combining
- [Kodeco SwiftUI Rotating Views](https://www.kodeco.com/books/swiftui-cookbook/v1.0/chapters/5-rotating-views-with-gestures-in-swiftui) - Rotation gesture patterns
- [Design+Code Drag Gesture](https://designcode.io/swiftui-handbook-drag-gesture/) - DragGesture implementation

### Key Findings

| Aspect | Standard Pattern | Our Approach |
|--------|------------------|--------------|
| **Rotation** | RotateGesture + handle | 90° buttons (simpler, meets stated need) |
| **Position** | DragGesture on object | Drag in preview + numeric fields |
| **Scale** | MagnifyGesture/handles | Slider (50%-200%) - clearer for batch ops |
| **Anchor** | Center or corner pivot | Anchor grid presets (sets offset values) |

---

## User Requirements

1. **Rotation:** 90° increments only (orientation fixes)
2. **Position:** Anchor presets + offset (intuitive approach)
3. **Interaction:** Both numeric inputs AND direct manipulation in preview
4. **Batch:** Per-frame and "Apply to All" capability

---

## Data Model

### New: FrameTransform Struct

```swift
// Models/FrameTransform.swift
struct FrameTransform: Equatable, Codable {
    var rotation: Int = 0           // 0, 90, 180, 270 only
    var scale: Double = 100         // 50-200%
    var offsetX: CGFloat = 0        // pixels from center
    var offsetY: CGFloat = 0        // pixels from center

    static let identity = FrameTransform()

    var isIdentity: Bool {
        rotation == 0 && scale == 100 && offsetX == 0 && offsetY == 0
    }

    mutating func rotate90Clockwise() {
        rotation = (rotation + 90) % 360
    }

    mutating func rotate90CounterClockwise() {
        rotation = (rotation - 90 + 360) % 360
    }
}
```

### Extend ImageItem

```swift
struct ImageItem: Identifiable, Equatable {
    // ... existing properties ...
    var transform: FrameTransform = .identity
}
```

### Anchor Enum (UI only, not persisted)

```swift
enum PositionAnchor: CaseIterable {
    case topLeft, topCenter, topRight
    case middleLeft, center, middleRight
    case bottomLeft, bottomCenter, bottomRight
}
```

---

## UI Components

### 1. Transform Section (Settings Sidebar)

Only visible when a frame is selected.

```
┌─ Transform ─────────────────────┐
│                                 │
│  Rotation:  [↺] [↻] [180°]      │
│             Current: 0°         │
│                                 │
│  Scale:     [====●====] 100%    │
│             50%          200%   │
│                                 │
│  Position:  ┌───┬───┬───┐       │
│             │ ● │ ○ │ ○ │       │
│             ├───┼───┼───┤       │
│             │ ○ │ ○ │ ○ │       │
│             ├───┼───┼───┤       │
│             │ ○ │ ○ │ ○ │       │
│             └───┴───┴───┘       │
│                                 │
│  Offset X:  [    0    ] px      │
│  Offset Y:  [    0    ] px      │
│                                 │
│  [Reset] [Apply to All]         │
└─────────────────────────────────┘
```

**Behavior:**
- Clicking anchor preset calculates offset to position image at that location
- Offset fields allow fine-tuning from anchor position
- "Reset" returns to identity transform
- "Apply to All" copies current frame's transform to all frames (with confirmation)

### 2. Preview Pane - Direct Manipulation

```swift
// Apply transforms to preview image
Image(nsImage: currentFrame)
    .scaleEffect(transform.scale / 100)
    .rotationEffect(.degrees(Double(transform.rotation)))
    .offset(x: transform.offsetX, y: transform.offsetY)
    .gesture(
        DragGesture()
            .onChanged { value in
                appState.updateCurrentFrameOffset(
                    x: baseOffset.x + value.translation.width,
                    y: baseOffset.y + value.translation.height
                )
            }
            .onEnded { _ in
                appState.commitCurrentFrameOffset()
            }
    )
```

**Visual Indicators:**
- Show transform badge on frame thumbnail when non-identity
- Optional: dashed outline showing original bounds in preview

---

## Anchor Preset Calculations

The anchor grid provides quick positioning. Clicking an anchor calculates the offset needed to position the image at that location on the canvas.

```swift
func offsetForAnchor(
    _ anchor: PositionAnchor,
    imageSize: CGSize,
    canvasSize: CGSize,
    scale: Double
) -> (x: CGFloat, y: CGFloat) {
    let scaledImage = CGSize(
        width: imageSize.width * scale / 100,
        height: imageSize.height * scale / 100
    )
    let halfCanvas = CGSize(width: canvasSize.width / 2, height: canvasSize.height / 2)
    let halfImage = CGSize(width: scaledImage.width / 2, height: scaledImage.height / 2)

    switch anchor {
    case .topLeft:
        return (-halfCanvas.width + halfImage.width, halfCanvas.height - halfImage.height)
    case .topCenter:
        return (0, halfCanvas.height - halfImage.height)
    case .topRight:
        return (halfCanvas.width - halfImage.width, halfCanvas.height - halfImage.height)
    case .middleLeft:
        return (-halfCanvas.width + halfImage.width, 0)
    case .center:
        return (0, 0)
    case .middleRight:
        return (halfCanvas.width - halfImage.width, 0)
    case .bottomLeft:
        return (-halfCanvas.width + halfImage.width, -halfCanvas.height + halfImage.height)
    case .bottomCenter:
        return (0, -halfCanvas.height + halfImage.height)
    case .bottomRight:
        return (halfCanvas.width - halfImage.width, -halfCanvas.height + halfImage.height)
    }
}
```

**Note:** SwiftUI's coordinate system has Y increasing upward in some contexts. Verify during implementation.

---

## Export Transform Pipeline

Transforms are applied during export in this order:

```
Original Image
     │
     ▼
1. Rotate (0/90/180/270°)
   - Use CGAffineTransform or CGContext rotation
   - Image bounds change for 90°/270°
     │
     ▼
2. Scale (50-200%)
   - Scale relative to image center
   - Produces intermediate sized image
     │
     ▼
3. Position on Canvas
   - Create canvas-sized context
   - Draw scaled/rotated image at offset from center
     │
     ▼
4. Apply Canvas Mode (Fit/Fill)
   - Already handled by existing resize logic
   - Transform happens BEFORE canvas resize
     │
     ▼
5. Encode Frame
   - Pass to GIF/APNG/WebP exporter
```

### Implementation in NSImage Extension

```swift
extension NSImage {
    func applying(transform: FrameTransform, canvasSize: CGSize) -> NSImage {
        // 1. Rotate
        let rotated = self.rotated(by: transform.rotation)

        // 2. Scale
        let scaleFactor = transform.scale / 100.0
        let scaledSize = CGSize(
            width: rotated.size.width * scaleFactor,
            height: rotated.size.height * scaleFactor
        )
        let scaled = rotated.resized(to: scaledSize, preservingAspectRatio: false)

        // 3. Position on canvas
        let canvas = NSImage(size: canvasSize)
        canvas.lockFocus()

        // Clear canvas (or fill with background color)
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: canvasSize).fill()

        // Calculate draw position (offset from center)
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

    private func rotated(by degrees: Int) -> NSImage {
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
```

---

## Implementation Phases

### Phase 11a: Model + Sidebar Controls
**Scope:** Create data model and basic UI controls

1. Create `FrameTransform` struct in `Models/`
2. Add `transform` property to `ImageItem`
3. Create `TransformSection.swift` view component
4. Implement rotation buttons (↺90°, ↻90°, 180°)
5. Implement scale slider (50-200%)
6. Implement offset X/Y text fields
7. Wire to AppState methods

**Files:**
- `Models/FrameTransform.swift` (new)
- `Models/ImageItem.swift` (modify)
- `Views/Settings/TransformSection.swift` (new)
- `Views/SettingsSidebar.swift` (modify)
- `AppState.swift` (modify)

### Phase 11b: Anchor Presets + Batch Operations
**Scope:** Add position presets and Apply to All

1. Create `AnchorGridView` component (3x3 grid of buttons)
2. Implement `offsetForAnchor()` calculation
3. Add "Reset" button functionality
4. Add "Apply to All" with confirmation alert
5. Show transform indicator on frame thumbnails

**Files:**
- `Views/Settings/AnchorGridView.swift` (new)
- `Views/TransformSection.swift` (modify)
- `Views/FrameThumbnailView.swift` (modify - add badge)
- `AppState.swift` (modify)

### Phase 11c: Preview Direct Manipulation
**Scope:** Enable drag-to-position in preview

1. Apply transform modifiers to preview image
2. Add DragGesture for position offset
3. Track drag state (base offset + delta)
4. Sync preview drag with sidebar offset fields
5. Optional: Show original bounds indicator

**Files:**
- `Views/PreviewPane.swift` (modify)
- `AppState.swift` (modify - add drag state)

### Phase 11d: Export Integration
**Scope:** Apply transforms during export

1. Add `NSImage.applying(transform:canvasSize:)` extension
2. Add `NSImage.rotated(by:)` helper
3. Modify exporters to apply transform before encoding
4. Test with all formats (GIF, APNG, WebP)
5. Verify transform + canvas resize interaction

**Files:**
- `Models/ImageItem.swift` or new extension file
- `Services/GIFExporter.swift` (modify)
- `Services/APNGExporter.swift` (modify)
- `Services/WebPExporter.swift` (modify)

---

## Edge Cases

| Case | Behavior |
|------|----------|
| Rotation changes image bounds | Recalculate to keep visually centered |
| Scale > 100% exceeds canvas | Crop to canvas bounds |
| Offset moves image off-canvas | Allow (user may want partial visibility) |
| Batch apply with different image sizes | Apply same offset values (position varies) |
| Transform + Original canvas mode | Apply transform, use original dimensions |
| Transform + Preset canvas mode | Apply transform, fit/fill to preset |

---

## Testing Checklist

- [ ] Rotation buttons cycle correctly (0 → 90 → 180 → 270 → 0)
- [ ] Scale slider updates preview in real-time
- [ ] Offset fields accept positive and negative values
- [ ] Anchor presets position image correctly
- [ ] Drag in preview updates offset fields
- [ ] Reset clears all transform values
- [ ] Apply to All affects all frames
- [ ] Transform badge appears on thumbnails
- [ ] GIF export includes transforms
- [ ] APNG export includes transforms
- [ ] WebP export includes transforms
- [ ] Rotation + scale + offset combine correctly
- [ ] Large offsets don't crash export

---

## Estimated Effort

| Phase | Lines of Code | Complexity |
|-------|---------------|------------|
| 11a: Model + Sidebar | ~150 | Low |
| 11b: Anchor + Batch | ~100 | Low |
| 11c: Preview Drag | ~80 | Medium |
| 11d: Export Integration | ~120 | Medium |
| **Total** | **~450** | |

---

## Dependencies

- Phase 11a: None (can start immediately)
- Phase 11b: Requires 11a
- Phase 11c: Requires 11a
- Phase 11d: Requires 11a, integrates with existing export pipeline

Phases 11b and 11c can be developed in parallel after 11a is complete.

---

## Open Questions

1. **Rotation pivot point:** Should rotation pivot around image center or canvas center?
   - Recommendation: Image center (standard behavior)

2. **Scale limits:** 50-200% or wider range?
   - Recommendation: Start with 50-200%, expand if needed

3. **Transform persistence:** Save transforms in project file?
   - Recommendation: Yes, if project saving is implemented later

---

*Ready for implementation.*
