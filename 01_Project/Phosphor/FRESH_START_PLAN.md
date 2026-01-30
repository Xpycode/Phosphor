# Fresh Start Plan - Phosphor Rebuild

**Date:** 2025-11-13
**Current State:** Buggy 6-pane workspace
**Goal:** Clean rebuild with new UI design

---

## ✅ What's Been Done

1. **Salvaged Good Code** → `SALVAGED_CODE/` directory
   - GIFExporter.swift (159 lines)
   - APNGExporter.swift (88 lines)
   - ColorDepthReducer.swift (~100 lines)
   - WebPExporter.swift (30 lines stub)
   - ExportSettings.swift (267 lines)
   - ImageItem.swift (120 lines)
   - **Total: ~764 lines of potentially reusable code**

2. **Saved Reference UI** (from stable version `30ba339`)
   - REFERENCE_ContentView_stable.swift
   - REFERENCE_FileListView_stable.swift
   - REFERENCE_PreviewPlayerView_stable.swift

3. **Documented Everything**
   - `SALVAGED_CODE/README.md` - Complete API documentation
   - `REUSABLE_CODE_ANALYSIS.md` - What to keep/scrap analysis
   - `ISSUES_REPORT.md` - All known problems

---

## 🎯 Next Steps

### Step 1: Create Your Mockup
**Your Task:**
- Design the UI you actually want
- Consider: layout, panes, controls, workflow
- Tools: Sketch, Figma, paper, or just describe it

**Questions to Answer:**
1. How many panes/panels?
2. What goes in each pane?
3. Workflow: Import → ? → Export
4. Do you need sequences/timeline or just simple frame list?
5. Settings location (sidebar, modal, inline)?

---

### Step 2: Review Mockup Together
**What We'll Discuss:**
- Feasibility
- Which salvaged code to use
- Data model needs
- Implementation approach

---

### Step 3: Clean Slate Implementation
Once mockup is approved:

#### 3a. Create New Branch
```bash
git checkout -b feature/fresh-start
git reset --hard 30ba339  # Reset to stable version
```

#### 3b. Remove Old Code
Keep only:
- PhosphorApp.swift (entry point)
- Basic Xcode project structure
- Assets

Remove:
- All current Views/
- All current Models/ (except what we bring back)
- All current ViewModels/
- Complex documentation

#### 3c. Minimal Starting Structure
```
Phosphor/
├── PhosphorApp.swift
├── ContentView.swift          (NEW - your mockup)
├── Assets.xcassets/
├── Info.plist
├── Phosphor.entitlements
└── [Add code incrementally as needed from SALVAGED_CODE/]
```

---

## 📋 Implementation Strategy

### Phase 1: Basic UI Shell (Day 1)
- Create UI structure matching mockup
- Static layout, no functionality
- Get the look right first

### Phase 2: Import Images (Day 1-2)
- Add basic import functionality
- Display imported images in UI
- Extract import logic from SALVAGED_CODE if helpful

### Phase 3: Preview/Playback (Day 2)
- Show selected image
- Basic playback controls
- Frame rate control

### Phase 4: Export Integration (Day 3)
- Integrate GIFExporter from SALVAGED_CODE
- Test export pipeline
- Verify it actually works!

### Phase 5: Settings & Polish (Day 4+)
- Export settings UI
- Quality controls
- Platform presets
- Final polish

---

## 🔧 Code Integration Guidelines

### When Adding Salvaged Code:

1. **Start Small**
   - Add one file at a time
   - Test immediately
   - Fix any integration issues

2. **Don't Copy Blindly**
   - Review the code first
   - Simplify if possible
   - Adapt to new architecture

3. **Dependencies Matter**
   ```
   Order to add files:
   1. ExportSettings.swift (has ResizeInstruction)
   2. ImageItem.swift (uses ResizeInstruction)
   3. ColorDepthReducer.swift (standalone)
   4. GIFExporter.swift (uses all above)
   5. APNGExporter.swift (uses ImageItem, ExportSettings)
   ```

4. **Test Each Integration**
   - Does it compile?
   - Does it work?
   - Is it simpler to rewrite?

---

## 🎨 Mockup Considerations

Think about:

### Layout Options

**Option A: Classic 3-Pane (like stable version)**
```
┌──────────┬────────────┬──────────┐
│  Files   │   Preview  │ Settings │
│  List    │   Player   │  Export  │
└──────────┴────────────┴──────────┘
```
- Simple
- Everything visible
- Proven to work

**Option B: 2-Pane Minimal**
```
┌────────────┬──────────┐
│  Preview   │  Files   │
│  Player    │  List    │
│  Timeline  │  Export  │
└────────────┴──────────┘
```
- Clean
- Focus on preview
- Settings in modal?

**Option C: Your Custom Design**
- Draw what you want
- Don't be constrained by old design

### Workflow Options

**Simple Workflow (No Sequences):**
1. Import images
2. Set frame rate
3. Reorder frames
4. Export

**Advanced Workflow (With Sequences):**
1. Import images
2. Create sequence(s)
3. Add frames to sequence
4. Edit sequence settings
5. Export

### Feature Priority

**Must Have:**
- Import images
- Preview/playback
- Basic export (GIF)
- Frame rate control

**Nice to Have:**
- Multiple sequences
- Per-frame settings
- APNG/WebP export
- Platform presets
- Resize options

**Can Skip:**
- Undo/redo
- Persistence
- Bins/folders
- Complex timeline

---

## 📝 Current Git State

```bash
Current branch: feature/6-pane-workspace
Current commit: 3faf94e (Implement 6-pane workspace with progressive disclosure)

Stable reference: 30ba339 (Refactor resize concept and normalize image orientation)
```

### Salvaged Code Location
```
SALVAGED_CODE/
├── Services/
│   ├── GIFExporter.swift
│   ├── APNGExporter.swift
│   ├── ColorDepthReducer.swift
│   └── WebPExporter.swift
├── Models/
│   ├── ExportSettings.swift
│   └── ImageItem.swift
└── README.md (Full API documentation)
```

### Reference Code
```
SALVAGED_CODE/
├── REFERENCE_ContentView_stable.swift       (3-pane layout)
├── REFERENCE_FileListView_stable.swift      (file list UI)
└── REFERENCE_PreviewPlayerView_stable.swift (preview/playback)
```

---

## 🚀 Ready to Start

**When you're ready with your mockup:**

1. Share the mockup (screenshot, sketch, or description)
2. We'll discuss the approach
3. I'll help you:
   - Reset to clean state
   - Build new UI structure
   - Integrate salvaged code as needed
   - Test export functionality

**No rush!** Take your time to design what you actually want. The salvaged code will be waiting when you need it.

---

## 💡 Tips for Mockup

- **Keep it simple** - You can always add features later
- **Focus on workflow** - How should it feel to use?
- **Don't overthink** - Sometimes simpler is better
- **Consider your use case** - What will you actually use this for?

---

## 📞 When You're Ready

Just say:
- "Here's my mockup: [description/image]"
- "I want to start fresh now"
- "Let's review the salvaged code first"
- Or any questions!

The foundation is saved. Now build what you actually want. 🎨
