# Plan: Aspect Ratio Lock for Custom Canvas Mode

## Overview

Add a "lock aspect ratio" toggle to the Custom canvas mode that maintains proportions when the user changes width or height.

## Research Summary

### UI Pattern (Industry Standard)
- **Chain link icon** between width/height fields ([Iconfinder](https://www.iconfinder.com/icons/3360177/aspect_chain_close_interface_link_lock_ratio_icon))
- Toggle states: linked (locked) vs unlinked (free)
- [Adobe InDesign 2025](https://community.adobe.com/t5/indesign-discussions/issue-with-constrain-proportions-in-indesign-2025-20-0/td-p/14933789) uses this pattern with automatic activation
- [Figma](https://forum.figma.com/t/constrain-proportions-when-changing-width-height-variable-of-a-component-icon/46650) also uses constrain proportions for components

### SF Symbols Options
Per [Apple SF Symbols](https://developer.apple.com/sf-symbols/):
- `link` - chain link (for locked state)
- `link.badge.plus` - available but semantically wrong
- Alternative: use opacity/color to indicate unlocked state

**Chosen approach:** `link` icon with full opacity when locked, dimmed when unlocked.

### SwiftUI Implementation
Per [SwiftUI aspectRatio documentation](https://developer.apple.com/documentation/swiftui/view/aspectratio(_:contentmode:)-771ow), we can use the ratio for calculations but need custom binding logic for linked fields.

---

## Current State

**ResizeSection.swift** (lines 100-129):
```swift
private var customDimensionsSection: some View {
    VStack(alignment: .leading, spacing: 8) {
        HStack {
            Text("Width:")
            TextField("", value: $settings.canvasWidth, format: .number)
            Text("px")
        }
        HStack {
            Text("Height:")
            TextField("", value: $settings.canvasHeight, format: .number)
            Text("px")
        }
    }
}
```

**ExportSettings.swift**:
- `canvasWidth: Double = 640`
- `canvasHeight: Double = 480`
- `automaticCanvasSize: CGSize?` (from imported images)

---

## Implementation Plan

### Wave 1: Model Changes (ExportSettings.swift)

Add to `ExportSettings`:

```swift
/// Whether aspect ratio is locked in Custom mode
@Published var aspectRatioLocked: Bool = true

/// The locked aspect ratio (width/height), captured when lock is enabled
@Published var lockedAspectRatio: CGFloat?
```

Add computed property:

```swift
/// Current aspect ratio from custom dimensions
var customAspectRatio: CGFloat {
    guard canvasHeight > 0 else { return 1.0 }
    return canvasWidth / canvasHeight
}
```

Add method to capture ratio:

```swift
/// Captures the current aspect ratio for locking
func captureAspectRatio() {
    lockedAspectRatio = customAspectRatio
}

/// Updates width based on locked aspect ratio
func updateWidthFromHeight() {
    guard let ratio = lockedAspectRatio, ratio > 0 else { return }
    canvasWidth = canvasHeight * ratio
}

/// Updates height based on locked aspect ratio
func updateHeightFromWidth() {
    guard let ratio = lockedAspectRatio, ratio > 0 else { return }
    canvasHeight = canvasWidth / ratio
}
```

### Wave 2: UI Changes (ResizeSection.swift)

Redesign `customDimensionsSection` to include lock toggle:

```swift
private var customDimensionsSection: some View {
    VStack(alignment: .leading, spacing: 8) {
        // Width row
        HStack {
            Text("Width:")
                .frame(width: 50, alignment: .leading)

            TextField("", value: widthBinding, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)

            Text("px")
                .foregroundColor(.secondary)
        }

        // Lock toggle row (centered between fields)
        HStack {
            Spacer()
                .frame(width: 50)

            Button(action: toggleAspectLock) {
                Image(systemName: "link")
                    .opacity(settings.aspectRatioLocked ? 1.0 : 0.4)
                    .foregroundColor(settings.aspectRatioLocked ? .accentColor : .secondary)
            }
            .buttonStyle(.borderless)
            .help(settings.aspectRatioLocked ? "Unlock aspect ratio" : "Lock aspect ratio")

            Spacer()
        }

        // Height row
        HStack {
            Text("Height:")
                .frame(width: 50, alignment: .leading)

            TextField("", value: heightBinding, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)

            Text("px")
                .foregroundColor(.secondary)
        }

        // Range hint
        Text("Range: 64–4096 px")
            .font(.caption)
            .foregroundColor(.secondary)
    }
}
```

### Wave 3: Linked Field Bindings

Create custom bindings that update the other field when locked:

```swift
private var widthBinding: Binding<Double> {
    Binding(
        get: { settings.canvasWidth },
        set: { newValue in
            settings.canvasWidth = newValue
            if settings.aspectRatioLocked {
                settings.updateHeightFromWidth()
            }
        }
    )
}

private var heightBinding: Binding<Double> {
    Binding(
        get: { settings.canvasHeight },
        set: { newValue in
            settings.canvasHeight = newValue
            if settings.aspectRatioLocked {
                settings.updateWidthFromHeight()
            }
        }
    )
}

private func toggleAspectLock() {
    settings.aspectRatioLocked.toggle()
    if settings.aspectRatioLocked {
        settings.captureAspectRatio()
    }
}
```

### Wave 4: Initialize from Source Images

When switching to Custom mode or importing images, auto-populate from source:

In `ResizeSection`, add `.onAppear` or `.onChange`:

```swift
.onAppear {
    initializeCustomDimensionsIfNeeded()
}
.onChange(of: settings.canvasMode) { _, newMode in
    if newMode == .custom {
        initializeCustomDimensionsIfNeeded()
    }
}

private func initializeCustomDimensionsIfNeeded() {
    // If switching to Custom and dimensions are default, use source image size
    if let sourceSize = settings.automaticCanvasSize,
       settings.canvasWidth == 640 && settings.canvasHeight == 480 {
        settings.canvasWidth = sourceSize.width
        settings.canvasHeight = sourceSize.height
    }
    // Capture initial aspect ratio
    if settings.lockedAspectRatio == nil {
        settings.captureAspectRatio()
    }
}
```

---

## UI Layout

```
┌─────────────────────────────────────┐
│ Canvas                              │
├─────────────────────────────────────┤
│ Size  [Original] [Preset] [Custom]  │
│                                     │
│ Width:   [____640____] px           │
│              🔗                     │  ← Link icon (toggle)
│ Height:  [____480____] px           │
│                                     │
│ Range: 64–4096 px                   │
│                                     │
│ Scale  [  Fit  ] [  Fill  ]         │
└─────────────────────────────────────┘
```

---

## Edge Cases

1. **Very small ratio** (e.g., 10:1): Clamp to dimension range (64-4096)
2. **Zero values**: Prevent division by zero, minimum 1
3. **Switching from Preset to Custom**: Copy preset dimensions, capture ratio
4. **First import**: Initialize from source image dimensions

---

## Testing Checklist

- [ ] Lock enabled: changing width updates height proportionally
- [ ] Lock enabled: changing height updates width proportionally
- [ ] Lock disabled: width and height change independently
- [ ] Toggle state persists across mode switches
- [ ] Dimensions stay within 64-4096 range
- [ ] Preview updates correctly with linked changes
- [ ] Export uses correct final dimensions

---

## Files to Modify

| File | Changes |
|------|---------|
| `ExportSettings.swift` | Add `aspectRatioLocked`, `lockedAspectRatio`, helper methods |
| `ResizeSection.swift` | Redesign `customDimensionsSection` with lock toggle |

---

## Estimated Complexity

- **Model changes**: ~20 lines
- **UI changes**: ~50 lines
- **Total**: ~70 lines

---

*Created: 2026-01-31*
