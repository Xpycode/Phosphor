# Sequence/Canvas Architecture Implementation

This document describes the new sequence-based architecture for Phosphor, implemented on 2025-11-12.

## Overview

The app has been refactored from a single-list workflow to an NLE-style (Non-Linear Editor) workflow with:
- **Global Media Library**: All imported images stored centrally
- **Sequences**: Project-like containers with canvas size, frame rate, and frame ordering
- **Timeline UI**: Frame-by-frame control with drag-and-drop reordering

## New Files Created

### Models
1. **`Models/Sequence.swift`**
   - `CanvasPreset`: Social media presets (Instagram, Twitter, TikTok, Discord)
   - `SequenceFrame`: Individual frame in a sequence with per-frame settings
   - `PhosphorSequence`: Main sequence class with canvas, frame rate, and frames

2. **`Models/MediaLibrary.swift`**
   - `MediaLibrary`: Global image collection that all sequences reference
   - Import handling with progress tracking
   - Aspect ratio mismatch detection

### Views
3. **`Views/MediaLibraryView.swift`**
   - Grid display of all imported media
   - Drag-and-drop to sequences
   - Selection and bulk operations
   - Aspect mismatch badges

4. **`Views/SequenceTimelineView.swift`**
   - Sequence selector dropdown
   - Canvas info display
   - Horizontal timeline strip
   - Per-frame settings panel (delay, enable/disable, removal)

5. **`Views/WorkspaceView.swift`**
   - New 3-panel layout:
     - Left: MediaLibraryView
     - Center: PreviewPlayerView (existing) + SequenceTimelineView
     - Right: SettingsPanelView (existing)

### Updated Files
6. **`ViewModels/AppViewModel.swift`**
   - Added `mediaLibrary` and `sequences` properties
   - Sequence management methods (create, delete, duplicate)
   - Frame resolution helpers
   - Legacy properties maintained for backward compatibility

7. **`ContentView.swift`**
   - Added toggle between new workspace and legacy view
   - `@AppStorage("useNewWorkspace")` feature flag
   - Toolbar button to switch modes

## Architecture Highlights

### Hybrid NLE Workflow
- **Single global media library**: Import once, use in multiple sequences
- **Sequence-specific timelines**: Each sequence defines canvas, ordering, and per-frame settings
- **Reference-based**: Frames reference ImageItem IDs from the library (no duplication)

### Canvas Presets
Includes presets for:
- Instagram (Square 1:1, Portrait 4:5, Story 9:16)
- Twitter (Landscape 16:9, Square 1:1)
- TikTok (Vertical 9:16)
- Discord (Emoji 320×320, Sticker 512×512)
- Auto-detect from first image

### Aspect Ratio Warnings
- On-import detection of mismatched aspect ratios
- Orange warning badges on thumbnails
- Crop indicators in timeline

## Usage Flow

### Initial State
- **Empty workspace**: No sequences on launch (per user request)
- User must create a sequence before importing or working

### Creating a Sequence
1. Click "No Sequence" dropdown in timeline panel
2. Select "New Sequence"
3. Canvas auto-detects from first library image, or defaults to Instagram Square

### Importing Media
1. Media Library panel → "Import" button
2. Images added to global library
3. Optionally auto-add to active sequence

### Building a Sequence
1. Select images in Media Library
2. Click "Add to Sequence" or double-click items
3. Frames appear in timeline strip
4. Drag to reorder, select to edit per-frame settings

### Exporting
- Export logic will need to be updated to pull from `activeSequence.frames` instead of `imageItems`
- Per-frame delays from sequence frames
- Canvas size from sequence settings

## Next Steps

### To Test This Implementation

1. **Add files to Xcode project**:
   In Xcode:
   - Right-click on `Phosphor` group → Add Files to "Phosphor"
   - Add these 5 new files:
     - `Models/Sequence.swift`
     - `Models/MediaLibrary.swift`
     - `Views/MediaLibraryView.swift`
     - `Views/SequenceTimelineView.swift`
     - `Views/WorkspaceView.swift`
   - Ensure "Add to targets: Phosphor" is checked

2. **Build the project**:
   ```bash
   xcodebuild -scheme Phosphor -configuration Debug build
   ```

3. **Toggle the new workspace**:
   - Launch app
   - Click toolbar button to enable "New Workspace"
   - Create a sequence to start working

### Integration Tasks (Future)

- [ ] Update exporters to read from `activeSequence` instead of legacy `imageItems`
- [ ] Add sequence export settings (currently uses global `ExportSettings`)
- [ ] Implement sequence persistence (save/load projects)
- [ ] Add canvas presets picker in sequence settings
- [ ] Drag-and-drop reordering in timeline
- [ ] Multi-sequence management (tabs or sidebar list)
- [ ] Sequence duplication workflow
- [ ] Media library filtering/search

## Design Decisions

### Why Hybrid Bins?
- More flexible than per-sequence bins
- Matches professional NLE workflows (Premiere, Final Cut)
- Easy to reuse assets across multiple sequences

### Why Empty Initial State?
- User requested explicit sequence creation
- Prevents confusion about where media "belongs"
- Clear separation between library and sequence

### Why Keep Legacy Mode?
- Smooth migration path
- Allows testing new architecture without breaking existing workflow
- Can be removed once new workflow is stable

## Files Location

All new files are in:
```
/Users/sim/XcodeProjects/1-macOS/Phosphor/Phosphor/Phosphor/
├── Models/
│   ├── Sequence.swift (NEW)
│   └── MediaLibrary.swift (NEW)
└── Views/
    ├── MediaLibraryView.swift (NEW)
    ├── SequenceTimelineView.swift (NEW)
    └── WorkspaceView.swift (NEW)
```

## Questions?

See the inline documentation in each file for implementation details.
