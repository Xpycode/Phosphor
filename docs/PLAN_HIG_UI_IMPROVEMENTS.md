# Phosphor UI Improvements Plan (HIG Compliance)

**Created:** 2026-01-31
**Status:** Ready for implementation
**Estimated scope:** 5 focused changes (~50 min total)

---

## Overview

This plan addresses UI polish issues identified when reviewing Phosphor against Apple Human Interface Guidelines (HIG). The goal is to make the app feel more native and professional, especially in the empty/first-launch state.

---

## 1. Inspector Sidebar: Material Background

### Problem
The settings sidebar uses an opaque `controlBackgroundColor`, which looks flat and doesn't feel integrated with the modern macOS design language.

### HIG Guidance
> "Standard materials help with visual differentiation within the content layer... Thicker materials, which are more opaque, can provide better contrast for text and other elements with fine features."
> — [HIG: Materials](https://developer.apple.com/design/human-interface-guidelines/materials)

### Solution
Replace the opaque background with a translucent material that lets content show through subtly.

### Implementation

**File:** `Views/SettingsSidebar.swift`

**Current code (line 83):**
```swift
.background(Color(nsColor: .controlBackgroundColor))
```

**Replace with:**
```swift
.background(.thickMaterial)
```

**Alternative options:**
- `.regularMaterial` — more translucent, shows more content through
- `.thickMaterial` — less translucent, better text contrast (recommended for inspector with lots of controls)
- `.ultraThickMaterial` — almost opaque, maximum contrast

### Notes
- Materials require macOS 12.0+ (we target 14.0+, so this is fine)
- Materials automatically adapt to light/dark mode
- The sidebar has many text labels and controls, so `.thickMaterial` provides better legibility

---

## 2. Empty State: ContentUnavailableView

### Problem
The current empty state is minimal — just a small icon and "Drop images here" text. It doesn't guide users or explain the app's purpose.

### HIG Guidance
> "Use ContentUnavailableView in situations where a view's content cannot be displayed. That could be caused by a network error, a list without items, a search that returns no results etc."
> — [SwiftUI: ContentUnavailableView](https://developer.apple.com/documentation/swiftui/contentunavailableview)

> "Explain the benefits of creating an account and how to sign up... Delay sign-in for as long as possible. Give people a chance to get a sense of what your app does."
> — [HIG: Launching](https://developer.apple.com/design/human-interface-guidelines/launching)

### Solution
Replace custom empty states with `ContentUnavailableView` that explains what the app does and how to get started.

### Implementation

**File:** `Views/PreviewPane.swift`

**Current code (lines 138-143):**
```swift
private var emptyState: some View {
    // Minimal placeholder - import prompt is in the timeline toolbar
    Image(systemName: "photo.on.rectangle.angled")
        .font(.system(size: 48))
        .foregroundColor(.secondary.opacity(0.5))
}
```

**Replace with:**
```swift
private var emptyState: some View {
    ContentUnavailableView {
        Label("No Images", systemImage: "photo.on.rectangle.angled")
    } description: {
        Text("Import images to create an animated GIF or APNG")
    } actions: {
        Button("Import Images") {
            // Need to pass import action from parent or use NotificationCenter
        }
        .buttonStyle(.borderedProminent)
    }
}
```

**Challenge:** The import action is defined in `ContentView`. Options:
1. Pass the import closure down through `AppState`
2. Use `NotificationCenter` to trigger import
3. Add `onImport` closure parameter to `PreviewPane`

**Recommended:** Option 3 — add `onImport: (() -> Void)?` parameter to `PreviewPane`

---

**File:** `Views/TimelinePane.swift`

**Current code (lines 32-44):**
```swift
private var emptyStateView: some View {
    // Drop zone indicator only - import button is in toolbar
    VStack(spacing: 8) {
        Image(systemName: "arrow.down.doc")
            .font(.system(size: 28))
            .foregroundColor(.secondary.opacity(0.6))

        Text("Drop images here")
            .font(.subheadline)
            .foregroundColor(.secondary.opacity(0.6))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
```

**Replace with:**
```swift
private var emptyStateView: some View {
    ContentUnavailableView {
        Label("Drop Images", systemImage: "arrow.down.doc")
    } description: {
        Text("Drag image files here to add them to your animation")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
```

### Notes
- `ContentUnavailableView` requires macOS 14.0+ (we target this)
- It automatically handles styling, spacing, and accessibility
- The preview pane gets the primary CTA button; timeline just shows drop hint

---

## 3. Drop Zone Visual Feedback

### Problem
When dragging files over the app, there's no visual feedback indicating valid drop targets.

### HIG Guidance
> "Show people whether a destination can accept dragged content. Display highlighting or other visual cues only while the content is positioned above the destination."
> — [HIG: Drag and Drop](https://developer.apple.com/design/human-interface-guidelines/drag-and-drop)

### Solution
Add visual feedback when dragging over the timeline drop zone.

### Implementation

**File:** `Views/TimelinePane.swift`

Add state to track drag targeting:
```swift
@State private var isDropTargeted = false
```

Modify the drop handler:
```swift
.onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
    handleDrop(providers: providers)
}
```

Add visual feedback:
```swift
.overlay {
    if isDropTargeted {
        RoundedRectangle(cornerRadius: 8)
            .stroke(Color.accentColor, lineWidth: 3)
            .background(Color.accentColor.opacity(0.1))
            .padding(4)
    }
}
```

---

## 4. Timeline Toolbar Position (No Change Needed)

### Decision
Keep the timeline toolbar between preview and timeline. This follows HIG guidance:

> "A toolbar provides convenient access to frequently used commands, controls, navigation, and search... Toolbars act on content in the view."
> — [HIG: Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars)

The Import button and zoom controls act on the timeline content, so positioning them adjacent to the timeline is correct. Moving them to the window title bar would disconnect them from their context.

---

## 5. (Optional) Liquid Glass for macOS 26+

### Context
macOS 26 (Tahoe) introduces "Liquid Glass" as a new design language. If targeting macOS 26+, controls can adopt this appearance.

### HIG Guidance
> "Liquid Glass forms a distinct functional layer for controls and navigation elements — like tab bars and sidebars — that floats above the content layer."
> — [HIG: Materials](https://developer.apple.com/design/human-interface-guidelines/materials)

### Implementation (Future)
This would require:
- Updating deployment target to macOS 26.0
- Using `.glassEffect()` modifier on appropriate controls
- Testing with new design system

**Status:** Deferred — current target is macOS 14.0+

---

## 6. Sidebar Compaction

### Problem
The settings sidebar is vertically verbose. Each section uses `GroupBox` with generous spacing, making the panel feel bloated.

### Current Layout Issues
```
GroupBox (adds border + padding)
  └── VStack(spacing: 12)     ← generous
       └── .padding(.top, 8)  ← extra top padding
           └── Divider()      ← visual separator

Main VStack: spacing: 16     ← between sections
```

### Solution Options

#### Option A: Form-Based Layout (Recommended)
Replace `GroupBox` sections with a native `Form` using `Section` headers. Forms are compact and standard for macOS settings.

**SettingsSidebar.swift changes:**
```swift
var body: some View {
    VStack(spacing: 0) {
        Form {
            Section("Export Format") {
                // Format picker
            }

            Section("Timing") {
                // FPS slider
                // Loop count
            }

            // etc...
        }
        .formStyle(.grouped)  // macOS grouped appearance

        // Export button section stays as-is
    }
}
```

#### Option B: Tighter Spacing (Quick Win)
Keep `GroupBox` but reduce spacing throughout:

**Each section file:**
```swift
// Before
VStack(alignment: .leading, spacing: 12) { ... }
.padding(.top, 8)

// After
VStack(alignment: .leading, spacing: 8) { ... }
.padding(.top, 4)
```

**SettingsSidebar.swift:**
```swift
// Before
VStack(alignment: .leading, spacing: 16) { ... }

// After
VStack(alignment: .leading, spacing: 10) { ... }
```

#### Option C: Inline Labels
Put labels and values on the same line where possible:

**Before:**
```swift
VStack(alignment: .leading, spacing: 4) {
    HStack {
        Text("Frame Rate")
        Spacer()
        Text("\(Int(settings.frameRate)) fps")
    }
    Slider(value: $settings.frameRate, ...)
}
```

**After:**
```swift
HStack {
    Text("Frame Rate")
    Slider(value: $settings.frameRate, ...)
        .frame(maxWidth: 120)
    Text("\(Int(settings.frameRate)) fps")
        .frame(width: 50)
}
```

#### Option D: DisclosureGroups for Advanced Options
Collapse less-used options by default:

```swift
DisclosureGroup("Color Depth") {
    Toggle("Reduce color depth", isOn: $settings.colorDepthEnabled)
    if settings.colorDepthEnabled {
        // Levels slider
    }
}
```

### Recommendation
Start with **Option B** (quick win) + **Option D** for Color Depth section. This provides immediate compaction without restructuring the entire sidebar.

### Files to Modify
- `Views/SettingsSidebar.swift` — reduce main spacing
- `Views/Settings/FormatSelectionSection.swift` — reduce internal spacing
- `Views/Settings/TimingSection.swift` — reduce internal spacing, remove Divider
- `Views/Settings/QualitySection.swift` — reduce internal spacing, remove Divider
- `Views/Settings/ColorDepthSection.swift` — wrap in DisclosureGroup
- `Views/Settings/ResizeSection.swift` — reduce internal spacing

---

## Implementation Order

1. **Inspector Material Background** (~5 min)
   - Single line change in `SettingsSidebar.swift`
   - Immediate visual improvement

2. **Sidebar Compaction** (~15 min)
   - Reduce spacing in all section files
   - Remove unnecessary Dividers
   - Optionally wrap Color Depth in DisclosureGroup

3. **Empty State: ContentUnavailableView** (~20 min)
   - Update `PreviewPane.swift` empty state
   - Update `TimelinePane.swift` empty state
   - Wire up import action to preview pane

4. **Drop Zone Feedback** (~10 min)
   - Add `isDropTargeted` state
   - Update `.onDrop` modifier
   - Add overlay for visual feedback

---

## Testing Checklist

- [ ] Build succeeds
- [ ] App launches with improved empty state
- [ ] Import button in empty state works
- [ ] Sidebar has translucent material background
- [ ] Sidebar fits more content without scrolling
- [ ] All sidebar controls still functional
- [ ] Drop zone highlights when dragging files over
- [ ] Timeline functions normally after import
- [ ] Light mode appearance is acceptable
- [ ] Dark mode appearance is acceptable

---

## References

- [HIG: Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [HIG: Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars)
- [HIG: Drag and Drop](https://developer.apple.com/design/human-interface-guidelines/drag-and-drop)
- [HIG: Color](https://developer.apple.com/design/human-interface-guidelines/color)
- [SwiftUI: ContentUnavailableView](https://developer.apple.com/documentation/swiftui/contentunavailableview)
- [SwiftUI: Material](https://developer.apple.com/documentation/swiftui/material)

---

*Plan created: 2026-01-31*
