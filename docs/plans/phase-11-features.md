# Phase 11: Undo/Redo, Export Dialog, Per-Frame Timing

## Overview

This plan implements three features for Phosphor's Phase 11: a full undo/redo system using the Command pattern, an export dialog that separates format/quality settings from the main sidebar, and per-frame timing support. The approach uses three separate milestones to enable incremental testing and independent deployment.

The undo system provides foundation-level functionality that wraps all user actions. Per-frame timing extends the ImageItem model and wires to existing exporters. The export dialog uses a state-driven sheet with settings → progress → completion views.

## Planning Context

### Decision Log

| Decision | Reasoning Chain |
|----------|-----------------|
| Command Pattern for undo | SwiftUI's built-in UndoManager has limited @Observable integration → need explicit control over action capture and reversal → Command pattern provides named commands with execute()/undo() symmetry and supports action names in menu |
| Sheet for export dialog | Phosphor only needs single export at a time → sheet is simpler than separate NSWindow → stays attached to main window, provides proper real estate for format/quality/progress states |
| Commands store frame UUIDs not indices | Frame indices change on reorder/delete → restoring by index would put frame in wrong position → UUID is stable identity, lookup by ID ensures correct restoration regardless of array mutations |
| Per-frame timing in sidebar not timeline | Timeline shows thumbnails with limited space → adding timing controls would clutter → sidebar already has contextual sections (Transform shows when frame selected) → timing section follows same pattern |
| Max 50 undo stack depth | Unbounded stack grows memory with large frame imports → 50 is typical undo depth in creative apps → old commands discarded FIFO when limit reached |
| Sidebar keeps Canvas + Timing only | User confirmed: Format/Quality are export-time decisions → Canvas/Timing affect live preview and should stay visible → clean separation between "working" settings and "output" settings |
| customDelay as Optional not default value | nil semantics distinguish "inherit global" from "explicitly set to match global" → enables Reset to Global button to appear only when override exists → user can tell at a glance which frames have custom timing |
| Timing range 10-2000ms | 10ms minimum prevents sub-frame delays that break playback timing (screen refresh ~16ms at 60fps) → 2000ms maximum (2 seconds) covers practical slideshow use cases without allowing multi-minute single-frame hangs |
| buildPerFrameDelays returns nil optimization | Exporters have faster codepath for uniform timing (single delay value vs array iteration) → returning nil when all frames use global delay leverages optimized path |
| ExportState one-way transitions | State machine prevents invalid transitions (can't go from .completed back to .exporting) → ensures progress bar only moves forward → cancel returns to .idle from any state to support user abort |
| Command.execute() throws for error safety | Import and other operations can fail (disk full, permission denied) → commands must propagate errors → failing commands never reach undoStack preventing corrupt undo state |
| isImporting flag for async safety | importImages() is async → user could trigger undo before import completes → isImporting flag disables undo menu during import (same pattern as isExporting) |

### Rejected Alternatives

| Alternative | Why Rejected |
|-------------|--------------|
| SwiftUI UndoManager only | Limited integration with @Observable; cannot easily name actions or batch operations; Command pattern gives explicit control |
| Export as popover | Too small for format picker + quality sliders + progress bar + completion state; sheet provides proper real estate for 4-state workflow |
| Per-frame timing in timeline | Would clutter timeline thumbnails; timeline is for visual ordering, sidebar is for properties; matches existing Transform section pattern |
| Store frame indices in commands | Indices shift on reorder/delete; restoring to stale index corrupts frame order; UUID lookup is O(n) but n is small (typically <100 frames) |
| Infallible command execution | Commands call async operations that can fail; if execute() doesn't throw, failing operations leave undoStack in corrupt state |

### Constraints & Assumptions

- **Technical**: Swift/SwiftUI, macOS 14.0+, @MainActor for all state
- **Existing patterns**: Section views in Settings/ folder with @AppStorage for expansion state, GroupBox styling
- **Dependencies**: Exporters already support `perFrameDelays: [Double]?` parameter

### Known Risks

| Risk | Mitigation | Anchor |
|------|------------|--------|
| Undo breaks frame indices after reorder | Commands store UUIDs; restore uses `frames.firstIndex(where: { $0.id == uuid })` with guard against nil | ImageItem.swift:13 `let id = UUID()` |
| Per-frame delay breaks preview sync | Playback checks `customDelay ?? globalDelay` before scheduling next frame | AppState.swift:113-118 timer logic to be modified |
| Undo during export corrupts state | Disable undo menu items while `isExporting == true` | AppState.swift:66 `@Published var isExporting` |
| Undo during import race condition | Add `isImporting` flag, disable undo menu while importing, await import completion before pushing command | New pattern, follows isExporting |
| Export sheet dismissed mid-export | Sheet not dismissable during .exporting state; only Cancel button works | Standard sheet pattern |
| UUID lookup fails during undo | Commands guard against nil with `guard let index = ... else { throw CommandError.frameNotFound }` | New error handling |
| App quit during export | AppDelegate.applicationShouldTerminate checks isExporting, shows confirmation, cleans up partial files | New lifecycle handling |

## Invisible Knowledge

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AppState                              │
│  ┌──────────────┐  ┌─────────────┐  ┌──────────────────┐    │
│  │ UndoManager  │  │   frames    │  │  exportSettings  │    │
│  │ ┌──────────┐ │  │ [ImageItem] │  │                  │    │
│  │ │ undoStack│ │  │ - customDel │  │                  │    │
│  │ │ redoStack│ │  │             │  │                  │    │
│  │ └──────────┘ │  └─────────────┘  └──────────────────┘    │
│  └──────────────┘                                            │
└─────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   Command       │  │  SettingsSidebar │  │  ExportSheet    │
│  - ImportCmd    │  │  - Transform     │  │  - Settings     │
│  - DeleteCmd    │  │  - Canvas        │  │  - Progress     │
│  - ReorderCmd   │  │  - Timing        │  │  - Complete     │
│  - MuteCmd      │  │  - FrameTiming   │  │                 │
│  - TransformCmd │  │    (contextual)  │  │                 │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

### Data Flow

```
User Action → Create Command → execute() throws → Push to undoStack → Clear redoStack
                                    │
                              (on error: show alert, don't push)

    ⌘Z      → Pop undoStack  → undo() throws → Push to redoStack
    ⌘⇧Z     → Pop redoStack  → execute()     → Push to undoStack

Export Flow:
Click Export → Show Sheet(.configuring) → Configure → Export Button
            → .exporting(progress) → .completed(url) / .failed(error)
            → Show in Finder / Dismiss
```

### Why This Structure

- **Undo/ folder**: Separates undo infrastructure from domain code; Command protocol + implementations are cohesive module
- **Export/ folder**: Each state gets its own view for clarity; ExportSheet orchestrates state transitions
- **FrameTimingSection in Settings/**: Follows existing section pattern (TransformSection, ResizeSection); appears contextually when frame selected

### Invariants

- undoStack + redoStack depth never exceeds 50 total
- Commands never mutate state directly; they call AppState methods
- Failing commands are never pushed to undoStack
- perFrameDelays array length must equal unmutedFrames.count at export time
- ExportState transitions are one-way except cancel (any → .idle)
- Undo/Redo menu items disabled while isImporting or isExporting is true

### Tradeoffs

- **UUID lookup vs index storage**: O(n) lookup cost accepted for correctness; typical n < 100 frames
- **Sheet vs window**: Sacrificed concurrent exports for simpler code; Phosphor use case is single export at a time
- **50 action limit**: Memory bounded but may lose early history on large imports; acceptable for creative app
- **Throws on command execution**: Extra error handling complexity accepted for data safety

## Milestones

### Milestone 1: Undo/Redo System

**Files**:
- NEW: `Phosphor/Undo/UndoManager.swift`
- NEW: `Phosphor/Undo/Command.swift`
- NEW: `Phosphor/Undo/CommandError.swift`
- MODIFY: `Phosphor/AppState.swift`
- MODIFY: `Phosphor/ContentView.swift`

**Flags**: [needs conformance check] - First use of Command pattern in codebase

**Requirements**:
1. `Command` protocol with `execute(on:) throws`, `undo(on:) throws`, and `actionName: String`
2. `CommandError` enum with `.frameNotFound(UUID)`, `.operationFailed(Error)`
3. `UndoManager` class with `undoStack`, `redoStack` (max 50 items total)
4. `UndoManager.perform()` wraps execute in do-catch; on failure shows alert, does NOT push to stack
5. Commands: `ImportFramesCommand`, `DeleteFrameCommand`, `ReorderFramesCommand`, `ToggleMuteCommand`, `TransformCommand`
6. Add `isImporting` flag to AppState; disable undo while true
7. `⌘Z` triggers `undo()`, `⌘⇧Z` triggers `redo()` via `.commands` modifier
8. Edit menu shows "Undo [action name]" / "Redo [action name]"
9. Menu items disabled when respective stack is empty OR isImporting/isExporting is true

**Acceptance Criteria**:
- [ ] Import 3 images → ⌘Z removes all 3 → ⌘⇧Z restores all 3
- [ ] Delete frame at index 1 → ⌘Z restores frame at index 1
- [ ] Reorder [A,B,C] to [B,A,C] → ⌘Z restores [A,B,C]
- [ ] Mute frame → ⌘Z unmutes → ⌘⇧Z mutes again
- [ ] Rotate 90° → ⌘Z restores 0° rotation
- [ ] Edit menu shows "Undo Import" after import action
- [ ] ⌘Z disabled while import is in progress (isImporting == true)
- [ ] Import fails → error alert shown, undo stack unchanged
- [ ] Delete frame → delete again via other means → ⌘Z shows "frame not found" alert

**Test Strategy**: Automated XCTest for state transitions (undo/redo stack depth, UUID lookup, error cases). Manual QA for UX flows (keyboard shortcuts, menu item states).

**Code Changes**:

```diff
--- /dev/null
+++ b/Phosphor/Undo/Command.swift
@@ -0,0 +1,20 @@
+import Foundation
+
+/// Command protocol for undo/redo support.
+/// Command pattern provides explicit control over action capture and reversal
+/// for @Observable state. SwiftUI's built-in UndoManager has limited
+/// @Observable integration.
+protocol Command {
+    /// Human-readable name for Edit menu (e.g., "Import", "Delete Frame")
+    var actionName: String { get }
+
+    /// Execute the command, mutating app state. Throws on failure.
+    func execute(on state: AppState) throws
+
+    /// Reverse the command, restoring previous state. Throws if frame not found.
+    func undo(on state: AppState) throws
+}
```

```diff
--- /dev/null
+++ b/Phosphor/Undo/CommandError.swift
@@ -0,0 +1,12 @@
+import Foundation
+
+/// Errors that can occur during command execution or undo
+enum CommandError: LocalizedError {
+    case frameNotFound(UUID)
+    case operationFailed(Error)
+
+    var errorDescription: String? {
+        switch self {
+        case .frameNotFound(let id): return "Frame no longer exists (ID: \(id.uuidString.prefix(8)))"
+        case .operationFailed(let error): return error.localizedDescription
+        }
+    }
+}
```

```diff
--- a/Phosphor/AppState.swift
+++ b/Phosphor/AppState.swift
@@ -14,6 +14,12 @@ import AppKit
 @MainActor
 class AppState: ObservableObject {
+    // MARK: - Undo/Redo
+    let undoManager = PhosphorUndoManager()
+
+    /// True while async import is in progress; disables undo menu
+    @Published var isImporting: Bool = false
+
     // MARK: - Frame Data
```

---

### Milestone 2: Per-Frame Timing

**Files**:
- MODIFY: `Phosphor/Models/ImageItem.swift`
- NEW: `Phosphor/Views/Settings/FrameTimingSection.swift`
- MODIFY: `Phosphor/Views/SettingsSidebar.swift`
- MODIFY: `Phosphor/AppState.swift`

**Requirements**:
1. Add `customDelay: Double?` to `ImageItem` (nil = use global FPS, value = override in ms)
2. `FrameTimingSection` appears when a frame is selected
3. `FrameTimingSection` uses `@AppStorage("frameTimingSectionExpanded")` for disclosure state persistence
4. Slider range 10-2000ms with current value display
5. "Reset to Global" button clears customDelay to nil
6. Playback timer uses `frame.customDelay ?? globalDelay`
7. Export builds `perFrameDelays` array from frames and passes to exporters

**Acceptance Criteria**:
- [ ] Select frame → FrameTimingSection appears in sidebar
- [ ] Set frame 2 to 500ms while global is 100ms → frame 2 visibly plays slower
- [ ] "Reset to Global" button appears only when customDelay is set
- [ ] Export GIF → inspect with `gifsicle -I` shows frame 2 has different delay
- [ ] No frame selected → FrameTimingSection hidden
- [ ] Close and reopen app → FrameTimingSection expansion state persists

**Test Strategy**: Manual QA for timing behavior and playback. Automated verification of exported GIF frame delays.

**Code Changes**:

```diff
--- a/Phosphor/Models/ImageItem.swift
+++ b/Phosphor/Models/ImageItem.swift
@@ -18,6 +18,11 @@ struct ImageItem: Identifiable, Equatable {
     let modificationDate: Date
     var isMuted: Bool = false

+    /// Per-frame delay override in milliseconds.
+    /// nil indicates frame inherits global FPS; non-nil enables per-frame timing.
+    /// Nullable design allows UI to distinguish "no override" from "override matches global".
+    var customDelay: Double? = nil
+
     /// Per-frame transform (rotation, scale, position)
     var transform: FrameTransform = .identity
```

```diff
--- a/Phosphor/AppState.swift
+++ b/Phosphor/AppState.swift
@@ -380,6 +380,18 @@ class AppState: ObservableObject {
+    /// Build per-frame delays array for export.
+    /// Returns nil if no custom delays are set, enabling exporters to use
+    /// optimized uniform-timing codepath (single delay vs array iteration).
+    private func buildPerFrameDelays() -> [Double]? {
+        let delays = unmutedFrames.map { frame -> Double in
+            frame.customDelay ?? exportSettings.frameDelay
+        }
+        // Return nil when all frames use global delay for exporter optimization
+        let hasCustom = unmutedFrames.contains { $0.customDelay != nil }
+        return hasCustom ? delays : nil
+    }
```

---

### Milestone 3: Export Dialog + Sidebar Reorder

**Files**:
- NEW: `Phosphor/Models/ExportState.swift`
- NEW: `Phosphor/Views/Export/ExportSheet.swift`
- NEW: `Phosphor/Views/Export/ExportSettingsView.swift`
- NEW: `Phosphor/Views/Export/ExportProgressView.swift`
- NEW: `Phosphor/Views/Export/ExportCompleteView.swift`
- MODIFY: `Phosphor/Views/SettingsSidebar.swift`
- MODIFY: `Phosphor/PhosphorApp.swift` (add app termination handling)
- DELETE: `Phosphor/Views/Settings/FormatSelectionSection.swift`
- DELETE: `Phosphor/Views/Settings/QualitySection.swift`
- DELETE: `Phosphor/Views/Settings/ColorDepthSection.swift`

**Flags**: [needs error review] - Export can fail, needs proper error display

**Requirements**:
1. `ExportState` enum: `.idle`, `.configuring`, `.exporting(progress: Double)`, `.completed(url: URL)`, `.failed(error: String)`
2. Export button in sidebar opens sheet with `.configuring` state
3. `ExportSettingsView`: Format picker (GIF/APNG/WebP), Quality slider (GIF only), Dithering toggle, Color depth
4. `ExportProgressView`: Progress bar, percentage, Cancel button
5. `ExportCompleteView`: Success icon, filename, "Show in Finder" button, Done button
6. Sidebar removes Format, Quality, ColorDepth sections; keeps Transform, Canvas, Timing, FrameTiming
7. App termination checks if export in progress; shows confirmation dialog; cleans up partial files

**Acceptance Criteria**:
- [ ] Click "Export" in sidebar → sheet appears with format/quality options
- [ ] Select APNG → quality/dithering options disappear (APNG doesn't use them)
- [ ] Click "Export" in sheet → save panel → progress view with live percentage
- [ ] Export completes → completion view with checkmark and "Show in Finder"
- [ ] Export fails → error view with message and "Done" button
- [ ] Sidebar shows only: Transform, FrameTiming, Timing, Canvas sections
- [ ] Quit app during export → confirmation dialog appears
- [ ] Confirm quit during export → partial file deleted

**Test Strategy**: Manual QA for full export workflow. Automated test for ExportState transitions.

**Code Changes**:

```diff
--- /dev/null
+++ b/Phosphor/Models/ExportState.swift
@@ -0,0 +1,18 @@
+import Foundation
+
+/// State machine for export workflow.
+/// Single modal flow prevents concurrent exports (Phosphor exports one file at a time).
+/// State transitions are one-way except cancel (any → .idle).
+enum ExportState: Equatable {
+    case idle
+    case configuring
+    case exporting(progress: Double)
+    case completed(url: URL)
+    case failed(error: String)
+
+    var isExporting: Bool {
+        if case .exporting = self { return true }
+        return false
+    }
+}
```

```diff
--- a/Phosphor/Views/SettingsSidebar.swift
+++ b/Phosphor/Views/SettingsSidebar.swift
@@ -20,15 +20,12 @@ struct SettingsSidebar: View {
             ScrollView {
                 VStack(alignment: .leading, spacing: 10) {
                     // Transform (per-frame, only when selected)
                     TransformSection(appState: appState)

-                    // Format Selection
-                    FormatSelectionSection(settings: appState.exportSettings)
+                    // Frame Timing (per-frame, only when selected)
+                    FrameTimingSection(appState: appState)

                     // Timing (FPS, Loop Count)
                     TimingSection(settings: appState.exportSettings)

-                    // Quality (GIF only)
-                    QualitySection(settings: appState.exportSettings)
-
-                    // Color Depth (GIF only)
-                    ColorDepthSection(settings: appState.exportSettings)
-
-                    // Resize Options
+                    // Canvas Options
                     ResizeSection(settings: appState.exportSettings)
```

---

### Milestone 4: Documentation

**Files**:
- `docs/CLAUDE.md` (update index)
- `01_Project/Phosphor/README.md` (if exists, add architecture)

**Requirements**:
- Update CLAUDE.md index with new files: Undo/, Export/, FrameTimingSection
- Each entry has WHAT (contents) and WHEN (task triggers)
- Add architecture diagram from Invisible Knowledge section

**Acceptance Criteria**:
- [ ] CLAUDE.md lists Undo/UndoManager.swift, Undo/Command.swift, Undo/CommandError.swift
- [ ] CLAUDE.md lists Export/*.swift files
- [ ] Architecture diagram appears in README.md or CLAUDE.md

**Source Material**: `## Invisible Knowledge` section of this plan

## Milestone Dependencies

```
M1 (Undo) ─────────────┐
                       ├──→ M4 (Docs)
M2 (Per-Frame) ───────┤
         │             │
         └──→ M3 ─────┘
         (Export Dialog)
```

M1 and M2 can execute in parallel.
M3 depends on M2 (needs perFrameDelays for export).
M4 runs after all implementation milestones complete.
