# Session Log: 6-Pane Layout Refactor with Progressive Disclosure

**Date:** 2025-11-13
**Time:** UTC

## Objective

Refactor ProjectWorkspaceView to implement a 6-pane NLE-inspired layout with progressive disclosure, as documented in `docs/APP_CONCEPT.md`.

## Changes Made

### 1. Created New Files

The following new files were created and need to be added to the Xcode project:

#### Models
- **`Phosphor/Models/WorkspaceState.swift`** - Manages visibility state for all six panes
  - Controls which panes are shown/hidden
  - Implements progressive disclosure logic
  - Methods to reveal panes contextually

#### Views
- **`Phosphor/Views/SequencesPaneView.swift`** - Top-left pane showing all sequences
- **`Phosphor/Views/MediaPaneView.swift`** - Bottom-left pane showing imported media
- **`Phosphor/Views/SequenceSettingsPaneView.swift`** - Top-right pane for sequence settings

### 2. Modified Existing Files

#### `Phosphor/Views/ProjectWorkspaceView.swift`
- Refactored from 3-column to 6-pane (3×2 grid) layout
- Added `@StateObject private var workspaceState = WorkspaceState()`
- Implemented conditional pane rendering based on `workspaceState`
- Updated `PreviewMonitorView` to include:
  - FPS/Delay controls below playback controls
  - "More Settings" button to toggle Sequence Settings pane
- Updated import/export handlers to reveal appropriate panes
- Added `.onAppear` to auto-reveal sequences pane if sequences exist

#### `Phosphor/Views/TimelineView.swift`
- Changed `@State private var selectedFrameIDs` to `@Binding var selectedFrameIDs`
- Now receives selection state from parent (ProjectWorkspaceView)

#### `Phosphor/Views/NewSequenceSheet.swift`
- Added `var workspaceState: WorkspaceState` parameter
- Calls `workspaceState.revealSequencesPane()` when sequence is created
- Updated preview to pass WorkspaceState

### 3. Documentation

- **`docs/APP_CONCEPT.md`** - Comprehensive documentation of the 6-pane concept, progressive disclosure strategy, and design rationale

## 6-Pane Layout Structure

```
┌─────────────┬─────────────┬─────────────┐
│  SEQUENCES  │   VIEWER    │  SEQUENCE   │
│ (top-left)  │ (top-center)│  SETTINGS   │
│             │             │ (top-right) │
├─────────────┼─────────────┼─────────────┤
│  MEDIA      │  TIMELINE   │   EXPORT    │
│ (bot-left)  │ (bot-center)│  SETTINGS   │
│             │             │ (bot-right) │
└─────────────┴─────────────┴─────────────┘
```

### Pane Visibility Rules

- **Always Visible**: Viewer (top-center), Timeline (bottom-center)
- **Collapsible**:
  - Sequences (top-left)
  - Media (bottom-left)
  - Sequence Settings (top-right)
  - Export Settings (bottom-right)

## Progressive Disclosure Flow

### Initial State
- Only **Viewer** and **Timeline** visible
- Minimalist interface for first-time users

### Step 1: Import
- User clicks "Import" → **Media pane** appears

### Step 2: Create Sequence
- User clicks "New Sequence" or drags images to timeline → **Sequences pane** appears

### Step 3: Adjust Settings
- User adjusts FPS/delay below Viewer
- Clicks "More Settings" button → **Sequence Settings pane** appears

### Step 4: Export
- User clicks "Export" in toolbar → **Export Settings pane** appears

## Key Features Implemented

### 1. FPS Controls in Viewer
- Frame Rate text field (edits sequence.frameRate)
- Frame Delay read-only display (calculated from FPS)
- "More Settings" button → reveals Sequence Settings pane

### 2. Sequence Settings Pane
- Name editor
- Canvas size (width × height)
- Frame rate with delay display
- Default fit mode (Fill, Fit, Stretch, Custom)
- Loop count
- Frame count (total and enabled)

### 3. Pane Headers
All panes now have consistent headers:
- Pane name in CAPS
- Contextual info (e.g., sequence name, item count)
- Background color: `.controlBackgroundColor`

### 4. Empty States
All panes show friendly empty states when no content:
- Icon
- Descriptive text
- Encourages user action

## Next Steps (Manual Xcode Tasks)

⚠️ **IMPORTANT**: The following files were created but need to be manually added to the Xcode project:

1. Open **Phosphor.xcodeproj** in Xcode
2. Right-click on the **Models** folder → "Add Files to Phosphor..."
   - Select `WorkspaceState.swift`
3. Right-click on the **Views** folder → "Add Files to Phosphor..."
   - Select `SequencesPaneView.swift`
   - Select `MediaPaneView.swift`
   - Select `SequenceSettingsPaneView.swift`
4. Ensure all files are checked for the **Phosphor** target
5. Build the project (`Cmd+B`)

### Expected Build Errors (Before Adding Files)

```
error: cannot find type 'WorkspaceState' in scope
error: cannot find 'SequencesPaneView' in scope
error: cannot find 'MediaPaneView' in scope
error: cannot find 'SequenceSettingsPaneView' in scope
```

These will resolve once files are added to the Xcode project.

## Testing Checklist

Once build succeeds, test the following workflow:

### Progressive Disclosure
- [ ] App launches with only Viewer + Timeline visible
- [ ] Click "Import" → Media pane appears on left
- [ ] Import some images → they appear in Media pane
- [ ] Click "New Sequence" → modal appears
- [ ] Create sequence → Sequences pane appears on top-left
- [ ] New sequence appears in Sequences pane and becomes active

### FPS Controls
- [ ] Viewer shows FPS controls below playback when sequence has frames
- [ ] Editing Frame Rate updates the sequence
- [ ] Frame Delay display updates automatically
- [ ] "More Settings" button toggles Sequence Settings pane

### Sequence Settings Pane
- [ ] Shows active sequence settings
- [ ] Can edit sequence name, canvas size, FPS, fit mode, loop count
- [ ] Changes reflect in sequence immediately
- [ ] Shows "Select a sequence" when no active sequence

### Timeline & Frame Settings
- [ ] Timeline shows frames for active sequence
- [ ] Selecting frames shows Frame Settings below timeline
- [ ] Frame settings apply to selected frames

### Export
- [ ] Click "Export" in toolbar → Export Settings pane appears
- [ ] Export pane shows sequence info
- [ ] Export button is disabled when no sequence active

### Collapsible Panes
- [ ] Panes appear/disappear based on actions
- [ ] Layout adjusts smoothly when panes show/hide
- [ ] Minimum sizes respected (13" MacBook Air)

## Known Issues / Future Work

### Drag from Finder to Timeline
- Not yet implemented
- Planned: Auto-create sequence from dragged images
- Should use largest image dimensions

### Auto-Detect Canvas Size
- Logic exists in legacy AppViewModel (`computeAutomaticCanvasSize()`)
- Needs to be integrated into new Project model
- Should scan images and use largest dimensions

### Thumbnail Generation
- ImageItem has thumbnail support
- Need to ensure thumbnails are generated on import
- Check performance with 50+ images

### Pane Collapse Animation
- Currently instant show/hide
- Could add smooth animation (low priority)

### Keyboard Shortcuts
- Add shortcuts for toggling panes
- Add shortcut for "More Settings" button

### State Persistence
- Pane visibility state not persisted
- Could save to UserDefaults or AppStorage

## Technical Notes

### HSplitView / VSplitView
- Using native SwiftUI split views
- Resizable dividers work out of the box
- Frame constraints ensure minimum sizes

### Binding Pattern
- TimelineView now receives `selectedFrameIDs` as Binding
- Allows FrameSettingsView to see selection changes
- Single source of truth in ProjectWorkspaceView

### ObservableObject Pattern
- WorkspaceState is ObservableObject
- Published properties trigger UI updates
- No explicit objectWillChange.send() needed

### Performance
- No performance issues expected
- All views are lazy-loaded
- Image caching handled by ImageItem

## Architecture Diagram

```
ProjectWorkspaceView (root)
├── WorkspaceState (manages visibility)
├── Project (data model)
├── ImportManager (import progress)
│
├── Left Column (VSplitView)
│   ├── SequencesPaneView (if visible)
│   └── MediaPaneView (if visible)
│
├── Center Column (VSplitView) [always visible]
│   ├── PreviewMonitorView
│   │   ├── Viewer
│   │   ├── Playback controls
│   │   └── FPS controls + "More Settings"
│   └── Timeline + FrameSettings (VStack)
│       ├── TimelineView
│       └── FrameSettingsView
│
└── Right Column (VSplitView)
    ├── SequenceSettingsPaneView (if visible)
    └── ExportPanelView (if visible)
```

## Code Reuse

### From ProjectSidebarView
- `SequenceContainerRow`, `SequenceRow` → reused in SequencesPaneView
- `MediaBinRow`, `MediaItemRow` → reused in MediaPaneView
- ProjectSidebarView.swift can be deleted after migration

### From Legacy AppViewModel
- Import logic with progress (already in ProjectWorkspaceView)
- Auto canvas size computation (needs migration to Project model)
- Image caching logic (in ImageItem)

## Related Documentation

- `docs/APP_CONCEPT.md` - Full app concept and design rationale
- `session-2025-11-13-1402-utc.md` - Previous session (sidebar simplification)

## Result

The 6-pane layout with progressive disclosure is now implemented and ready for testing once the new files are added to the Xcode project. The architecture follows the documented concept and provides a clean separation of concerns with appropriate state management.
