# Next Session Brief - Phosphor Fresh Start

**Date:** 2025-11-13
**Status:** Ready for complete rebuild
**User Goal:** Start completely fresh with new UI design based on mockup

---

## 🎯 CURRENT SITUATION

### What Happened
1. User built a 6-pane NLE-style workspace (commits `fef4b33` → `3faf94e`)
2. App is buggy and crashes (Slider range issues, view recreation bugs)
3. User doesn't like the current look/design
4. **Decision:** Start completely fresh from scratch

### What We Did This Session
1. ✅ Analyzed codebase - found ~800 lines of good export/model code
2. ✅ Salvaged all reusable code to `SALVAGED_CODE/` directory
3. ✅ Created comprehensive documentation
4. ✅ Saved reference files from last stable version (`30ba339`)
5. ✅ **User will create mockup for new design**

---

## 📁 IMPORTANT DIRECTORIES

### SALVAGED_CODE/ ⭐
**DO NOT DELETE - Contains all potentially reusable code**

```
SALVAGED_CODE/
├── Services/
│   ├── GIFExporter.swift           ✅ Working GIF export (159 lines)
│   ├── APNGExporter.swift          ✅ Working APNG export (88 lines)
│   ├── ColorDepthReducer.swift     ✅ Color optimization (~100 lines)
│   └── WebPExporter.swift          ⚠️ Stub only (needs implementation)
├── Models/
│   ├── ExportSettings.swift        ✅ Export configuration (267 lines)
│   └── ImageItem.swift             ✅ Image metadata model (120 lines)
├── REFERENCE_ContentView_stable.swift       📖 Old working 3-pane UI
├── REFERENCE_FileListView_stable.swift      📖 Old file list
├── REFERENCE_PreviewPlayerView_stable.swift 📖 Old preview/player
└── README.md                       📖 Complete API documentation
```

**Total salvaged: ~764 lines of code**
**Status: UNTESTED** - User couldn't test export functionality

### Documentation Files (Keep for Reference)
```
REUSABLE_CODE_ANALYSIS.md    - What code is worth keeping
FRESH_START_PLAN.md          - Strategy for rebuild
NEXT_SESSION_BRIEF.md        - This file (for you!)
ISSUES_REPORT.md             - All known bugs in current version
```

---

## 🗑️ FILES/DIRECTORIES THAT CAN BE DELETED

### Safe to Delete (Buggy/Obsolete UI Code)

**Views/** - All current view files (~2000 lines)
```bash
# Delete these buggy view files:
rm Phosphor/Views/ProjectWorkspaceView.swift          # Buggy 6-pane workspace
rm Phosphor/Views/TimelineView.swift                  # Complex timeline
rm Phosphor/Views/SequencesPaneView.swift             # 6-pane design
rm Phosphor/Views/MediaPaneView.swift                 # 6-pane design
rm Phosphor/Views/SequenceSettingsPaneView.swift      # 6-pane design
rm Phosphor/Views/FrameSettingsView.swift             # Over-engineered
rm Phosphor/Views/NewSequenceSheet.swift              # NLE-specific
rm Phosphor/Views/SequenceTimelineView.swift          # Complex
rm Phosphor/Views/MediaLibraryView.swift              # NLE-specific
rm Phosphor/Views/ProjectSidebarView.swift            # NLE-specific
rm Phosphor/Views/WorkspaceView.swift                 # Unused

# Keep these for now (may need reference):
# Phosphor/Views/FileListView.swift          (old working version)
# Phosphor/Views/PreviewPlayerView.swift     (old working version)
# Phosphor/Views/SettingsPanelView.swift     (old working version)
```

**Models/** - NLE-specific models (~500 lines)
```bash
# Delete these over-engineered models:
rm Phosphor/Models/ProjectStructure.swift     # NLE-specific
rm Phosphor/Models/Sequence.swift             # NLE-specific
rm Phosphor/Models/MediaLibrary.swift         # Over-engineered
rm Phosphor/Models/WorkspaceState.swift       # 6-pane specific

# Keep these (in SALVAGED_CODE anyway):
# Phosphor/Models/ImageItem.swift          (may need)
# Phosphor/Models/ExportSettings.swift     (may need)
```

**Documentation/** - Obsolete design docs (~2000+ lines)
```bash
# Delete obsolete documentation:
rm IMPLEMENTATION_COMPLETE.md
rm NLE_WORKFLOW_COMPLETE.md
rm SEQUENCE_ARCHITECTURE.md
rm SESSION_LOG_2025-11-12.md
rm session-2025-11-13-1402-utc.md
rm session-2025-11-13-refactor-6pane.md
rm docs/APP_CONCEPT.md

# Keep these:
# SALVAGED_CODE/
# REUSABLE_CODE_ANALYSIS.md
# FRESH_START_PLAN.md
# NEXT_SESSION_BRIEF.md (this file)
# ISSUES_REPORT.md (for reference)
# README.md (if it exists)
```

### Total Deletable: ~4500+ lines of buggy/obsolete code

---

## 🔒 FILES TO KEEP (DO NOT DELETE)

### Core App Structure
```
✅ Phosphor/PhosphorApp.swift              (Entry point)
✅ Phosphor/ContentView.swift              (Will be rewritten)
✅ Phosphor.xcodeproj/                     (Xcode project)
✅ Phosphor/Assets.xcassets/               (Assets)
✅ Phosphor/Info.plist                     (App metadata)
✅ Phosphor/Phosphor.entitlements          (Permissions)
✅ .gitignore                              (Git config)
```

### Services (Currently Working - Don't Delete from Main)
```
✅ Phosphor/Services/GIFExporter.swift
✅ Phosphor/Services/APNGExporter.swift
✅ Phosphor/Services/ColorDepthReducer.swift
✅ Phosphor/Services/WebPExporter.swift
```
**Note:** These are also in SALVAGED_CODE/ as backup

### Models (May Need - Review First)
```
⚠️ Phosphor/Models/ImageItem.swift         (May need - also in SALVAGED_CODE/)
⚠️ Phosphor/Models/ExportSettings.swift    (May need - also in SALVAGED_CODE/)
```

### ViewModels
```
⚠️ Phosphor/ViewModels/AppViewModel.swift  (Has import logic - review before deleting)
```

### Reference Files
```
✅ SALVAGED_CODE/                          (All salvaged code)
✅ REUSABLE_CODE_ANALYSIS.md               (Analysis document)
✅ FRESH_START_PLAN.md                     (Rebuild strategy)
✅ NEXT_SESSION_BRIEF.md                   (This file)
✅ ISSUES_REPORT.md                        (Bug documentation)
```

---

## 🎬 WHAT TO DO NEXT SESSION

### Step 1: User Shows Mockup
**User will provide:**
- Mockup/sketch/description of desired UI
- Layout preferences
- Workflow vision

**You should ask:**
1. How many panes/panels?
2. What's the workflow? (Import → ? → Export)
3. Do they need sequences or just a simple frame list?
4. Where should settings go? (sidebar, modal, inline)
5. What features are must-have vs nice-to-have?

### Step 2: Review Mockup & Plan
**Discuss:**
- Feasibility of design
- Which salvaged code to use
- Data model needs (simple vs complex)
- Estimated implementation complexity

### Step 3: Clean Slate Setup
**If user approves plan:**

```bash
# 1. Create new branch
git checkout -b feature/fresh-start

# 2. Optionally reset to stable version
git reset --hard 30ba339
# (This reverts to last working 3-pane design)

# 3. Or keep current state and just delete bad files
# (Delete files from list above)
```

### Step 4: Build New UI
**Incremental approach:**

1. **Phase 1: UI Shell**
   - Create basic layout matching mockup
   - Static UI, no functionality
   - Get the look right

2. **Phase 2: Import**
   - Add file import
   - Display imported images
   - Reference: `AppViewModel.swift` import logic if needed

3. **Phase 3: Preview**
   - Show selected image
   - Basic playback controls
   - Frame rate control

4. **Phase 4: Export**
   - Integrate `GIFExporter` from SALVAGED_CODE/
   - Add export button
   - **TEST IT!** (User hasn't tested export yet)

5. **Phase 5: Settings & Polish**
   - Export settings UI
   - Quality controls
   - Platform presets

---

## 💡 KEY DECISIONS TO MAKE WITH USER

### Design Decisions
- [ ] Layout: 2-pane? 3-pane? Custom?
- [ ] Workflow: Simple (import→export) or Advanced (sequences)?
- [ ] Settings: Sidebar? Modal? Inline?
- [ ] Timeline: Yes/no? Simple list instead?

### Technical Decisions
- [ ] Use salvaged `ImageItem` model? Or create simpler version?
- [ ] Use salvaged `ExportSettings`? Or create simpler version?
- [ ] Keep `AppViewModel` pattern or use different architecture?
- [ ] Need sequences/canvas system? Or just frame array?

### Feature Decisions
- [ ] GIF export only? Or GIF + APNG?
- [ ] Basic settings only? Or advanced (dithering, color depth)?
- [ ] Platform presets needed? (Discord, WhatsApp, etc.)
- [ ] Resize/canvas options needed?

---

## 📊 CODE INTEGRATION STRATEGY

### When Integrating Salvaged Code

**Order of integration** (if using salvaged code):
1. `ExportSettings.swift` (defines ResizeInstruction enum)
2. `ImageItem.swift` (uses ResizeInstruction)
3. `ColorDepthReducer.swift` (standalone)
4. `GIFExporter.swift` (uses all above)
5. `APNGExporter.swift` (uses ImageItem, ExportSettings)

**Dependencies:**
```
GIFExporter needs:
├── ImageItem
├── ExportSettings (ResizeInstruction enum)
├── ColorDepthReducer
└── ExportError enum

APNGExporter needs:
├── ImageItem
├── ExportSettings (ResizeInstruction enum)
└── ExportError enum

ImageItem needs:
└── ExportSettings (ResizeInstruction enum)
```

**Testing approach:**
- Add one file at a time
- Compile after each addition
- Test immediately
- Fix integration issues before continuing

---

## ⚠️ KNOWN ISSUES WITH SALVAGED CODE

### GIFExporter.swift
- ✅ Well-structured async/await
- ✅ Good error handling
- ⚠️ **UNTESTED** - User couldn't test export
- ⚠️ May have integration issues with new architecture

### ImageItem.swift
- ✅ Good image metadata handling
- ⚠️ Thumbnail generation on main thread (minor perf issue)
- ⚠️ May be more complex than needed

### ExportSettings.swift
- ✅ Comprehensive settings
- ⚠️ May be over-engineered for simple use case
- ⚠️ 267 lines - consider simplifying

### ColorDepthReducer.swift
- ✅ Simple, standalone
- ✅ Should work fine

### APNGExporter.swift
- ✅ Clean implementation
- ⚠️ **UNTESTED**

---

## 🔍 WHAT HAPPENED IN LAST SESSION

### Timeline of Events
1. User reported: "Can't see preview without clicking sequence" + app crashes
2. I found crash: Slider range `0...-1` when sequence has 0 frames
3. I tried fixing with `.id()` modifiers - made it worse
4. User said: "Can't test export, don't like current look"
5. I analyzed codebase: ~60% reusable, 40% should be scrapped
6. We decided: **Start completely fresh**
7. I salvaged all good code to SALVAGED_CODE/
8. User will create mockup for new design

### Git State
```
Current branch: feature/6-pane-workspace
Current commit: 3faf94e (Implement 6-pane workspace with progressive disclosure)
Last stable:    30ba339 (Refactor resize concept and normalize image orientation)

Changes since stable: +5707 lines, -98 lines
- Added: 6-pane workspace, NLE models, sequences, timeline
- Problems: Crashes, bugs, user doesn't like design
```

---

## 📖 REFERENCE DOCUMENTS

### For You (Next Claude)
Read these files in SALVAGED_CODE/:
1. **README.md** - Complete API docs for all salvaged code
2. **REUSABLE_CODE_ANALYSIS.md** - What to keep/scrap analysis
3. **FRESH_START_PLAN.md** - Rebuild strategy and mockup guidelines

### For User
- **SALVAGED_CODE/README.md** - API documentation
- **FRESH_START_PLAN.md** - What to do next
- **NEXT_SESSION_BRIEF.md** - This file

---

## 🎯 SUCCESS CRITERIA

### Minimal Viable Product
✅ Import images from disk
✅ Display images in list/grid
✅ Preview selected image
✅ Basic playback (play/pause, frame rate)
✅ Export to GIF
✅ Basic settings (frame rate, loop count)

### Nice to Have
⭐ APNG export
⭐ Quality/dithering settings
⭐ Resize options
⭐ Platform presets
⭐ Per-frame timing

### Can Skip Initially
- Multiple sequences
- Persistence/save projects
- Undo/redo
- Bins/folders
- Complex timeline
- Canvas presets

---

## 💬 CONVERSATION STYLE

The user:
- Is technical and capable
- Appreciates directness
- Wants clean, simple code
- Values good architecture
- Prefers starting fresh over fixing complex bugs
- Will create mockup before starting

Your approach should be:
- Wait for user's mockup
- Ask clarifying questions about design
- Suggest simplifications where appropriate
- Integrate salvaged code incrementally
- Test as you go
- Keep architecture simple

---

## 🚦 IMMEDIATE NEXT STEPS

1. **User shows mockup** → You review and discuss
2. **Agree on approach** → Simple vs complex
3. **Clean slate** → Delete old code or reset to stable
4. **Build UI shell** → Match mockup exactly
5. **Add functionality** → Import → Preview → Export
6. **Integrate exports** → Use SALVAGED_CODE/ as needed
7. **Test export** → This is critical! (hasn't been tested yet)

---

## 📋 CHECKLIST FOR NEXT SESSION

Before starting:
- [ ] User has provided mockup
- [ ] You've read SALVAGED_CODE/README.md
- [ ] You've read REUSABLE_CODE_ANALYSIS.md
- [ ] You understand what to delete vs keep

During design discussion:
- [ ] Clarify layout/pane structure
- [ ] Clarify workflow (simple vs complex)
- [ ] Decide on data model (simple vs NLE-style)
- [ ] Decide which salvaged code to use
- [ ] Agree on feature priorities

Before coding:
- [ ] Create new branch
- [ ] Clean up old files
- [ ] Verify Xcode project structure
- [ ] Plan incremental implementation

During implementation:
- [ ] Build UI shell first
- [ ] Add features incrementally
- [ ] Test after each addition
- [ ] Keep architecture simple

Final testing:
- [ ] Test import functionality
- [ ] Test preview/playback
- [ ] **Test GIF export end-to-end** (critical!)
- [ ] Test with various image formats
- [ ] Test with multiple images

---

## 🎨 MOCKUP GUIDELINES (Remind User)

Good mockup should show:
1. **Layout** - How many panes/panels?
2. **Content** - What goes in each section?
3. **Workflow** - Import → ? → Export
4. **Controls** - Where are buttons/settings?
5. **Priority** - What's essential vs optional?

Can be:
- Screenshot from another app
- Hand-drawn sketch
- Figma/Sketch design
- Text description

---

## 🎁 WHAT'S READY FOR YOU

✅ All good code salvaged and documented
✅ Reference files from stable version
✅ Clear analysis of what to keep/scrap
✅ Comprehensive API documentation
✅ Known issues documented
✅ Git history preserved
✅ Clean starting point ready

**You have everything you need!**

Just wait for the user's mockup, discuss the approach, and build exactly what they want.

---

**Good luck! The foundation is solid. Now build something great! 🚀**
