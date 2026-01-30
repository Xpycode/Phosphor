# Phosphor App Concept

**Last Updated:** 2025-11-13
**Author:** User + Claude

---

## Overview

Phosphor is a **simple, NLE-inspired GIF/WebP/APNG creation application** for macOS that combines features typically scattered across multiple tools:

- Per-frame delay control
- Canvas/sequence-based workflow
- Mixed image dimension handling
- Timeline-based frame arrangement

The app draws inspiration from professional video editing applications (Avid Media Composer, Adobe Premiere Pro, Final Cut Pro) but is designed to be **approachable for users who have never opened an NLE**.

---

## Core Philosophy

### What Makes Phosphor Different

Most animation creation tools fall into two camps:

1. **Simple drag-and-drop converters**: Fast but limited control
2. **Complex animation software**: Powerful but overwhelming

Phosphor bridges this gap by:

- Using familiar NLE concepts (sequences, timelines, canvas)
- Providing sensible defaults and progressive disclosure
- Keeping the interface simple until complexity is needed

### Target Workflow

1. User imports images into a **media library**
2. Creates a **sequence** with defined canvas size and frame rate
3. Drags images onto a **timeline** to arrange frames
4. Adjusts per-frame settings (delay, crop, position) as needed
5. Exports to GIF, WebP, or APNG

---

## Six-Pane Layout

The application uses a **six-pane workspace** arranged in a 3×2 grid:

```
┌─────────────┬─────────────┬─────────────┐
│  SEQUENCES  │   VIEWER    │  SEQUENCE   │
│             │             │  SETTINGS   │
├─────────────┼─────────────┼─────────────┤
│  MEDIA      │  TIMELINE   │   EXPORT    │
│  (File List)│             │  SETTINGS   │
└─────────────┴─────────────┴─────────────┘
```

### Top Row

#### 1. Sequences (Top-Left)
- Lists all sequences in the current project
- Users can have multiple sequences with different canvas sizes
- Click to switch between sequences
- Shows sequence name, dimensions, and frame count
- **Collapsible**

#### 2. Viewer (Top-Center)
- Displays the current frame of the active sequence
- Playback controls (play/pause, previous/next frame)
- Frame counter and scrubber
- **Below playback controls**: Global FPS/delay controls
  - Makes timing adjustments discoverable and contextual
  - "More Settings" button expands sequence settings pane
- **Not collapsible** (primary preview area)

#### 3. Sequence Settings (Top-Right)
- Canvas size settings
- Default frame delay / FPS
- Loop count
- Default fit mode (fill, fit, stretch, custom)
- **Future**: Text layer editing tools when text is selected
- **Collapsible**

### Bottom Row

#### 4. Media / File List (Bottom-Left)
- Imported images organized in bins/folders
- Shows thumbnails, filenames, dimensions
- Drag files from here to timeline
- Can import via toolbar or direct drag from Finder
- **Collapsible**

#### 5. Timeline (Bottom-Center)
- Horizontal frame sequence for active sequence
- Drag to reorder frames
- Select one or more frames to edit
- **Below timeline**: Frame settings panel for selected frames
  - Per-frame delay override
  - Crop/zoom controls
  - Position/transform (future)
  - Effects (future)
- **Not collapsible** (core editing area)

#### 6. Export Settings (Bottom-Right)
- Format selection (GIF, WebP, APNG)
- Quality settings
- Size limit controls
- Export button (appears when pane is visible)
- **Not a modal** - dedicated space for export iteration workflow
- **Collapsible** - hidden most of the time, expanded when needed

---

## Progressive Disclosure Strategy

### Initial State (First Launch)

When the app first opens, users see **only two panes**:

- **Viewer** (center-top)
- **Timeline** (center-bottom)

This minimizes intimidation and focuses attention on the core workflow.

### Progressive Appearance

**Step 1: Import Images**
- User clicks "Import" in toolbar (or drags from Finder)
- **Media pane** (bottom-left) appears automatically
- Images load with thumbnails

**Step 2: First Sequence Creation**

When user drags images from Media to Timeline:

1. **Auto-create first sequence** using largest image dimensions
   - No modal, no decision paralysis
   - Just works immediately
2. Sequence appears in **Sequences pane** (top-left, now visible)
3. Timeline populates with frames
4. Viewer shows first frame

**Step 3: Adjust Settings**

- User can adjust global FPS/delay directly below Viewer
- "More Settings" button reveals **Sequence Settings pane** if hidden
- Clicking on frames in Timeline reveals **Frame Settings** below timeline

**Step 4: Export**

- User clicks "Export" in toolbar
- **Export Settings pane** (bottom-right) appears
- User configures format, quality, etc.
- Clicks "Export" button within the pane

### Rationale

This approach:

- **Simple for beginners**: Just import and drag, app handles the rest
- **Discoverable**: Panes appear contextually when needed
- **Powerful for advanced users**: Full control available progressively
- **Non-modal**: No blocking dialogs interrupting flow

---

## Mixed Image Dimensions Handling

### The Problem

Users often drag images of different sizes into a sequence. How should the canvas be sized?

### Solution: Auto-Detect Largest

When creating a sequence from multiple images:

1. **Scan all images** for dimensions (fast, reads headers only)
2. **Use largest dimensions** as canvas size
3. Apply default fit mode to all frames

**Why largest?**

- No quality loss (no upscaling)
- All images fit within canvas
- Predictable and fast

**Alternative (if user wants)**:

- User can manually change sequence canvas size in Sequence Settings pane
- Fit mode per frame can be adjusted in Frame Settings below timeline

---

## Image Import Performance

### Reading Dimensions

**Operation**: Read image width/height from file headers

- **Speed**: Very fast (~1ms per image, even for 17MB files)
- **No UI feedback needed**: Imperceptible to user
- **Use case**: Auto-detecting canvas size for new sequences

### Full Image Import

**Operation**: Decode image, generate thumbnail, cache in memory

- **Speed**: Slower for large files (50×17MB JPEGs = several seconds)
- **UI feedback**: Progress indicator at bottom of Media pane
- **Use case**: Importing into media library

### Finder-to-Timeline Direct Drag

**When user drags from Finder directly to Timeline**:

1. Clips appear on timeline **immediately** (placeholder thumbnails)
2. Dimension scan happens in background (~100-200ms for typical batch)
3. Canvas size adjusts within first few frames
4. Full image loading happens in background
5. Thumbnails populate as images finish loading
6. Progress shown in Media pane (if visible) or status bar

**No blocking, no status messages** - feels instant for typical workflows.

---

## Sequence Management

### Multiple Sequences

Users can create multiple sequences in one project:

- Different canvas sizes (e.g., Instagram square + Instagram story)
- Different frame rates
- Different source images
- Switch between sequences via Sequences pane

### Sequence Creation Flow

**Option 1: Auto-Create (First Time)**

- Drag images to Timeline → sequence created automatically
- Uses largest image dimensions
- Default 10 FPS
- Fill fit mode

**Option 2: Manual Create**

- Click "New Sequence" in toolbar
- Modal appears with settings:
  - Name
  - Canvas size (presets or custom)
  - Frame rate
  - Default fit mode
- Empty sequence created
- User drags images from Media to Timeline

**Option 3: Duplicate Sequence**

- Right-click sequence → "Duplicate"
- Creates copy with same settings, different frames

---

## Frame Settings (Below Timeline)

When user selects one or more frames in Timeline, the **Frame Settings panel** appears below the timeline.

### Current Settings

- **Custom Delay**: Override global FPS for this frame(s)
- **Fit Mode**: Fill, Fit, Stretch, Custom
- **Crop/Zoom**: Visual crop editor (future)

### Future Settings

- **Position**: X/Y offset within canvas
- **Rotation**: Rotate frame
- **Effects**: Blur, brightness, saturation, etc.
- **Transitions**: Fade, dissolve (between frames)

### Multi-Selection Behavior

When multiple frames are selected:

- Changing settings applies to **all selected frames**
- Mixed values shown as "—" (dash) in controls
- Useful for batch operations (e.g., set all frames to 200ms delay)

---

## Export Workflow

### Why Dedicated Export Pane?

Export is **not a one-time operation** in Phosphor. Typical workflow:

1. Configure export settings (quality, size limit, etc.)
2. Export
3. Check file size / preview result
4. Tweak quality or frame skip
5. Export again
6. Repeat until satisfied

A **modal dialog** would be tedious for this iteration cycle. A **dedicated pane** keeps settings visible and accessible.

### Export Settings

- **Format**: GIF, WebP, APNG (radio buttons)
- **Quality**: Slider (0-100%)
- **Dithering** (GIF only): On/Off
- **Color Depth** (GIF only): Slider
- **Size Limit**: Enable + input field (KB/MB)
- **Frame Skip**: Export every Nth frame (reduces file size)
- **Estimated Size**: Live preview of output file size
- **Warning**: If estimated size exceeds limit

### Export Button

Located **within Export Settings pane** (not toolbar) when pane is visible.

- Clicking opens save dialog
- Format pre-selected based on settings
- Filename auto-generated from sequence name

---

## Technical Implementation Notes

### Architecture

- **Models**: `Project`, `Sequence`, `MediaBin`, `SequenceFrame`, `ImageItem`
- **Views**: Six pane views + toolbar + modals
- **ViewModels**: `Project` (ObservableObject) manages all state
- **Services**: Image loading, dimension reading, export (GIF/WebP/APNG)

### Image Loading Strategy

**Lazy Loading**:

- Thumbnails generated on import
- Full images loaded on-demand (when frame is viewed)
- Image cache (LRU) keeps recent frames in memory
- Autoreleasepool prevents memory spikes during batch operations

**Dimension Reading**:

- Use `CGImageSourceCreateWithURL` + `CGImageSourceCopyPropertiesAtIndex`
- Only reads headers, doesn't decode full image
- Fast enough to run synchronously for small batches (<100 images)

### Canvas Rendering

For each frame in sequence:

1. Create canvas at sequence dimensions
2. Load source image
3. Apply fit mode:
   - **Fill**: Scale to fill canvas, crop overflow
   - **Fit**: Scale to fit inside canvas, add letterboxing
   - **Stretch**: Scale to exact canvas size (distorts aspect)
   - **Custom**: User-defined crop rectangle
4. Render to canvas
5. Pass to encoder

---

## Future Enhancements

### Phase 1 (MVP)

- [x] Six-pane layout
- [x] Image import with progress
- [x] Sequence creation and management
- [x] Timeline frame arrangement
- [x] Basic playback preview
- [ ] Per-frame delay override
- [ ] Canvas fit modes
- [ ] GIF/WebP/APNG export

### Phase 2 (Polish)

- [ ] Drag images directly to timeline from Finder
- [ ] Thumbnail caching for performance
- [ ] Frame settings panel (crop, zoom, position)
- [ ] Export size estimation and warnings
- [ ] Collapsible pane state persistence

### Phase 3 (Advanced)

- [ ] Text layers with editing in Sequence Settings pane
- [ ] Effects (blur, brightness, saturation)
- [ ] Transitions between frames
- [ ] Frame duplication and splitting
- [ ] Onion skinning in Viewer
- [ ] Multiple sequence export (batch)

### Phase 4 (Pro Features)

- [ ] Video import (extract frames)
- [ ] Audio sync (for timing reference)
- [ ] Scripting/automation
- [ ] Plugin system for custom effects
- [ ] Color profiles and ICC support

---

## Design Decisions & Rationale

### Why Six Panes Instead of Modal Dialogs?

**Problem**: Modal dialogs interrupt flow and hide context.

**Solution**: Persistent panes keep all tools accessible and visible. Even when collapsed, they're one click away, not buried in menus.

### Why Timeline Below Viewer (Not Side-by-Side)?

**Rationale**:

- **Horizontal timeline** is standard in video editing (familiar)
- **Vertical space** better for timeline (many frames fit horizontally)
- **Viewer above timeline** matches NLE convention (Premiere, Final Cut)
- **Natural eye flow**: Preview → Timeline → Settings (top to bottom)

### Why Auto-Create First Sequence Instead of Modal?

**Problem**: Asking users to configure a sequence before seeing anything creates decision paralysis.

**Solution**: Create a working sequence immediately using sensible defaults. Users can adjust later if needed. **Momentum over precision** for first-time users.

### Why Not Use List/Grid for Timeline?

**Problem**: `List` and `LazyGrid` in SwiftUI are optimized for vertical scrolling and don't provide the fine-grained control needed for timeline interactions.

**Solution**: Custom horizontal `ScrollView` with frame thumbnails. Allows:

- Drag reordering
- Multi-selection
- Scrubbing playhead
- Zoom in/out (future)

---

## Accessibility Considerations

- All panes keyboard navigable
- VoiceOver labels for all controls
- High contrast mode support
- Resizable text (system font scaling)
- Keyboard shortcuts for common actions (import, export, play/pause)

---

## Minimum System Requirements

- **macOS 13.0+** (Ventura or later)
- **Screen Size**: 13" MacBook Air (1440×900) minimum
- **RAM**: 8GB recommended (4GB minimum for small projects)
- **Disk**: 100MB app + space for media cache

---

## Related Documentation

- `docs/ARCHITECTURE.md` - Code structure and technical details
- `docs/EXPORT_FORMATS.md` - GIF/WebP/APNG specifications and limitations
- `docs/PERFORMANCE.md` - Optimization strategies and benchmarks
- `session-*.md` - Session logs documenting implementation progress
