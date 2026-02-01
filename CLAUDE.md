# Phosphor

A macOS app for creating animated GIFs, WebP, and APNG files from image sequences.

## Tech Stack
- **Platform:** macOS 14.0+
- **Language:** Swift
- **UI Framework:** SwiftUI
- **Architecture:** MVVM

## Project Structure
```
01_Project/Phosphor/     - Xcode project
  ├── Phosphor/
  │   ├── Models/        - Data models (AppState, ImageItem, ExportSettings)
  │   ├── ViewModels/    - View models
  │   ├── Views/         - SwiftUI views
  │   │   ├── Export/    - Export dialog sheet
  │   │   └── Settings/  - Canvas/timing/format settings
  │   ├── Undo/          - Undo/Redo system
  │   │   └── Commands/  - Command pattern implementations
  │   └── Exporters/     - GIF/APNG/WebP export engines
  └── SALVAGED_CODE/     - Original export code reference
02_Design/               - Design assets
03_Screenshots/          - App screenshots
04_Exports/              - Test exports
docs/                    - Directions documentation
```

## Key Architecture Decisions
- Fresh restart from 6-pane NLE design (too complex)
- Salvaged working export code: GIFExporter, APNGExporter, ColorDepthReducer
- Simple workflow: Import images → Preview → Export
- Command pattern for undo/redo operations
- Per-frame timing with customDelay override
- Export settings moved to modal sheet (separated from sidebar)

## Architecture

### State Management
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
```

## Current State
**Phase:** Implementation (Phase 11 complete)

See `docs/PROJECT_STATE.md` for current focus and next actions.
See `01_Project/Phosphor/NEXT_SESSION_BRIEF.md` for detailed context.
