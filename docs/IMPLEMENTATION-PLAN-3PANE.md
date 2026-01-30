# Implementation Plan: 3-Pane Phosphor

**Date:** 2026-01-30
**Goal:** Clean rebuild with 3-pane layout

---

## Design Summary

```
┌─────────────────────────────────────────┬──────────────┐
│                                         │              │
│              Preview Pane               │   Settings   │
│         (current frame + controls)      │    Pane      │
│                                         │              │
│    ┌─────────────────────────────┐      │  ┌────────┐  │
│    │                             │      │  │Global  │  │
│    │                             │      │  ├────────┤  │
│    │        [frame image]        │      │  │Per-fram│  │
│    │                             │      │  └────────┘  │
│    └─────────────────────────────┘      │              │
│       [◀] [▶/❚❚] [▶] [3/12]            │              │
├─────────────────────────────────────────┤  [Export]    │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐     │              │
│ │ 01 │ │ 02 │ │🔇03│ │ 04 │ │ 05 │     │              │
│ └────┘ └────┘ └────┘ └────┘ └────┘     │              │
│        Timeline (drag to reorder)       │              │
└─────────────────────────────────────────┴──────────────┘
```

## Workflow
1. **Import** → File > Open or drag-drop → images to timeline
2. **Reorder** → Drag thumbnails in timeline
3. **Mute** → Right-click or button → greyed out, skipped in export
4. **Delete** → Right-click or button → removed from timeline
5. **Settings** → Global (FPS, loops, quality) + per-frame (custom delay)
6. **Export** → Export button → GIF/APNG output

---

## Data Model

### TimelineItem.swift (NEW)
```swift
struct TimelineItem: Identifiable, Equatable {
    let id: UUID
    let imageItem: ImageItem  // from salvaged code
    var isMuted: Bool = false
    var customDelay: Double?  // nil = use global, in seconds

    var effectiveDelay: Double {
        customDelay ?? AppViewModel.shared.exportSettings.frameDelay / 1000.0
    }
}
```

### Reuse from SALVAGED_CODE/
- `ImageItem.swift` → image metadata, thumbnail, orientation handling
- `ExportSettings.swift` → export configuration (simplify if needed)
- `GIFExporter.swift` → GIF export
- `APNGExporter.swift` → APNG export
- `ColorDepthReducer.swift` → GIF optimization

---

## View Architecture

### File Structure (Target)
```
Phosphor/
├── PhosphorApp.swift          (keep)
├── ContentView.swift          (rewrite - 3 pane layout)
├── Models/
│   ├── TimelineItem.swift     (NEW)
│   ├── ImageItem.swift        (from SALVAGED)
│   └── ExportSettings.swift   (from SALVAGED, simplify?)
├── ViewModels/
│   └── AppViewModel.swift     (rewrite)
├── Views/
│   ├── PreviewPane.swift      (NEW)
│   ├── TimelinePane.swift     (NEW)
│   ├── TimelineThumbnail.swift (NEW)
│   ├── SettingsPane.swift     (NEW)
│   └── PlaybackControls.swift (NEW)
└── Services/
    ├── GIFExporter.swift      (from SALVAGED)
    ├── APNGExporter.swift     (from SALVAGED)
    └── ColorDepthReducer.swift (from SALVAGED)
```

---

## Implementation Phases

### Phase 1: Clean Slate + UI Shell
**Goal:** Empty 3-pane layout that compiles

Tasks:
- [ ] Create feature branch `feature/3-pane-fresh`
- [ ] Delete old Views/* files
- [ ] Delete old complex Models (keep ImageItem, ExportSettings)
- [ ] Write new ContentView with HSplitView/VSplitView
- [ ] Create stub panes: PreviewPane, TimelinePane, SettingsPane
- [ ] Verify builds and runs

Files to create:
- ContentView.swift (rewrite)
- Views/PreviewPane.swift
- Views/TimelinePane.swift
- Views/SettingsPane.swift

### Phase 2: Timeline + Import
**Goal:** Load images, display in timeline

Tasks:
- [ ] Create TimelineItem model
- [ ] Copy ImageItem from SALVAGED (or update existing)
- [ ] Implement AppViewModel with timeline state
- [ ] Add File > Open menu action
- [ ] Add drag-drop to window
- [ ] Display thumbnails in TimelinePane
- [ ] Implement drag-to-reorder

Files to modify/create:
- Models/TimelineItem.swift (NEW)
- ViewModels/AppViewModel.swift (rewrite)
- Views/TimelinePane.swift
- Views/TimelineThumbnail.swift (NEW)

### Phase 3: Preview + Playback
**Goal:** Show current frame, play animation

Tasks:
- [ ] Display selected frame in PreviewPane
- [ ] Create PlaybackControls view
- [ ] Implement play/pause with Timer
- [ ] Implement prev/next frame buttons
- [ ] Sync playback with timeline selection
- [ ] Add frame counter display

Files to modify/create:
- Views/PreviewPane.swift
- Views/PlaybackControls.swift (NEW)
- ViewModels/AppViewModel.swift (add playback logic)

### Phase 4: Mute/Delete
**Goal:** Timeline item management

Tasks:
- [ ] Add mute toggle (UI + logic)
- [ ] Add delete action
- [ ] Show muted state in thumbnail (greyed/badge)
- [ ] Context menu on thumbnails
- [ ] Toolbar buttons for mute/delete
- [ ] Keyboard shortcuts (M for mute, Delete key)

Files to modify:
- Views/TimelineThumbnail.swift
- Views/TimelinePane.swift
- ViewModels/AppViewModel.swift

### Phase 5: Settings Panel
**Goal:** Configure export options

Tasks:
- [ ] Copy/simplify ExportSettings from SALVAGED
- [ ] Build GlobalSettingsSection UI
  - Format picker (GIF/APNG)
  - Frame rate slider (1-60 FPS)
  - Loop count stepper
  - Quality slider
  - Dithering toggle
- [ ] Build PerFrameSettingsSection UI
  - Custom delay override
- [ ] Two-way binding between FPS and delay

Files to modify/create:
- Models/ExportSettings.swift (from SALVAGED)
- Views/SettingsPane.swift

### Phase 6: Export Integration
**Goal:** Working GIF/APNG export

Tasks:
- [ ] Copy GIFExporter from SALVAGED
- [ ] Copy APNGExporter from SALVAGED
- [ ] Copy ColorDepthReducer from SALVAGED
- [ ] Add Export button to SettingsPane
- [ ] Implement export action in AppViewModel
- [ ] Add save panel for destination
- [ ] Show progress during export
- [ ] **TEST END-TO-END** (critical!)

Files to copy/modify:
- Services/GIFExporter.swift (from SALVAGED)
- Services/APNGExporter.swift (from SALVAGED)
- Services/ColorDepthReducer.swift (from SALVAGED)
- ViewModels/AppViewModel.swift

### Phase 7: Polish
**Goal:** Refinements and edge cases

Tasks:
- [ ] Empty state handling (no images)
- [ ] Error handling and alerts
- [ ] Window title with project state
- [ ] Keyboard shortcuts
- [ ] Menu bar items (File > Export)
- [ ] Add more images after initial import
- [ ] Resize handling
- [ ] Performance with many images

---

## Files to Delete (from old implementation)

```bash
# Old complex views
rm Views/ProjectWorkspaceView.swift
rm Views/TimelineView.swift
rm Views/SequencesPaneView.swift
rm Views/MediaPaneView.swift
rm Views/SequenceSettingsPaneView.swift
rm Views/FrameSettingsView.swift
rm Views/NewSequenceSheet.swift
rm Views/SequenceTimelineView.swift
rm Views/MediaLibraryView.swift
rm Views/ProjectSidebarView.swift
rm Views/WorkspaceView.swift

# Old NLE models
rm Models/ProjectStructure.swift
rm Models/Sequence.swift
rm Models/MediaLibrary.swift
rm Models/WorkspaceState.swift
```

## Files to Keep/Reuse

```
# From SALVAGED_CODE/
Services/GIFExporter.swift      → copy to Services/
Services/APNGExporter.swift     → copy to Services/
Services/ColorDepthReducer.swift → copy to Services/
Models/ImageItem.swift          → copy to Models/
Models/ExportSettings.swift     → copy to Models/ (may simplify)

# Core project files
PhosphorApp.swift               → keep
Assets.xcassets/                → keep
Info.plist                      → keep
Phosphor.entitlements           → keep
```

---

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Layout | 3-pane (Preview, Timeline, Settings) | Simpler than 4-pane, images go direct to timeline |
| Timeline | Horizontal thumbnails | Familiar video editor pattern |
| Data model | TimelineItem wraps ImageItem | Adds mute/delay without modifying salvaged code |
| Settings | Right sidebar, always visible | Quick access, no modal dialogs |
| Per-frame | Custom delay only | Keep it simple, add more later if needed |

---

## Success Criteria

### MVP (Phase 6 complete)
- [x] Import images via Open or drag-drop
- [ ] Display thumbnails in horizontal timeline
- [ ] Reorder by dragging
- [ ] Mute/delete frames
- [ ] Preview with playback controls
- [ ] Configure: format, FPS, loops, quality, dithering
- [ ] Per-frame custom delay
- [ ] Export to GIF and APNG
- [ ] **Verified working export** (critical!)

### Nice to Have (Phase 7)
- [ ] Keyboard shortcuts
- [ ] Empty state with helpful message
- [ ] Progress indicator during export
- [ ] Remember window size/position

---

## Risk Areas

1. **Export code untested** → Test early in Phase 6
2. **Drag-drop reorder in SwiftUI** → May need `.onMove` + ForEach id handling
3. **Playback timer accuracy** → Use DisplayLink or precise timer
4. **Large image sets** → Lazy thumbnail loading, background processing

---

*Ready to implement. Start with Phase 1.*
