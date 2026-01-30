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
  └── SALVAGED_CODE/     - Reusable export code (~800 lines)
02_Design/               - Design assets
03_Screenshots/          - App screenshots
04_Exports/              - Test exports
docs/                    - Directions documentation
```

## Key Architecture Decisions
- Fresh restart from 6-pane NLE design (too complex)
- Salvaged working export code: GIFExporter, APNGExporter, ColorDepthReducer
- Simple workflow: Import images → Preview → Export

## Current State
**Phase:** Implementation (fresh restart)
**Blocker:** Awaiting user mockup for new UI design

See `docs/PROJECT_STATE.md` for current focus and next actions.
See `01_Project/Phosphor/NEXT_SESSION_BRIEF.md` for detailed context.
