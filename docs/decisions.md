# Decisions Log

This file tracks the WHY behind technical and design decisions.

---

## Template

### [Date] - [Decision Title]
**Context:** [What situation prompted this decision?]
**Options Considered:**
1. [Option A] - [pros/cons]
2. [Option B] - [pros/cons]

**Decision:** [What we chose]
**Rationale:** [Why we chose it]
**Consequences:** [What this means going forward]

---

## Decisions

### 2026-01-30 - 3-Pane Layout Design
**Context:** Rebuilding from scratch after 6-pane NLE design was too complex and buggy.

**Options Considered:**
1. 4-pane (Image pool, Preview, Timeline, Settings) - extra pane for loaded images
2. 3-pane (Preview, Timeline, Settings) - images go directly to timeline

**Decision:** 3-pane layout
**Rationale:**
- Simpler workflow: import → reorder → export
- No confusion between "pool" and "timeline"
- Mute feature provides soft-delete without separate pool
- User prefers simplicity

**Design Details:**
- Horizontal timeline with draggable thumbnails
- Preview pane with playback controls (play/pause, frame nav)
- Settings sidebar: global (FPS, loops, quality) + per-frame (custom delay)
- Both mute and delete available
- Drag-drop import + toolbar button

**Consequences:**
- Need TimelineItem wrapper for mute/per-frame state
- Reuse salvaged ImageItem, ExportSettings, exporters

---
*Add decisions as they are made. Future-you will thank present-you.*
