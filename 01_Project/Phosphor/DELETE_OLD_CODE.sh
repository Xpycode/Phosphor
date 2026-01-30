#!/bin/bash
# DELETE_OLD_CODE.sh
# Script to delete buggy/obsolete files when starting fresh
#
# ⚠️ WARNING: This will delete files! Make sure code is backed up in SALVAGED_CODE/
#
# Usage: bash DELETE_OLD_CODE.sh

set -e  # Exit on error

echo "=========================================="
echo "Phosphor - Delete Old/Buggy Code"
echo "=========================================="
echo ""
echo "⚠️  WARNING: This will delete buggy UI code!"
echo "✅ Good code is backed up in SALVAGED_CODE/"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted. No files deleted."
    exit 0
fi

echo ""
echo "Starting deletion..."
echo ""

# Counter for deleted files
deleted_count=0

# Function to safely delete file
delete_file() {
    if [ -f "$1" ]; then
        echo "  Deleting: $1"
        rm "$1"
        ((deleted_count++))
    else
        echo "  ⚠️  Not found: $1"
    fi
}

# Delete buggy view files
echo "📁 Deleting buggy view files..."
delete_file "Phosphor/Views/ProjectWorkspaceView.swift"
delete_file "Phosphor/Views/TimelineView.swift"
delete_file "Phosphor/Views/SequencesPaneView.swift"
delete_file "Phosphor/Views/MediaPaneView.swift"
delete_file "Phosphor/Views/SequenceSettingsPaneView.swift"
delete_file "Phosphor/Views/FrameSettingsView.swift"
delete_file "Phosphor/Views/NewSequenceSheet.swift"
delete_file "Phosphor/Views/SequenceTimelineView.swift"
delete_file "Phosphor/Views/MediaLibraryView.swift"
delete_file "Phosphor/Views/ProjectSidebarView.swift"
delete_file "Phosphor/Views/WorkspaceView.swift"

# Delete NLE-specific models
echo ""
echo "📦 Deleting NLE-specific models..."
delete_file "Phosphor/Models/ProjectStructure.swift"
delete_file "Phosphor/Models/Sequence.swift"
delete_file "Phosphor/Models/MediaLibrary.swift"
delete_file "Phosphor/Models/WorkspaceState.swift"

# Delete obsolete documentation
echo ""
echo "📄 Deleting obsolete documentation..."
delete_file "IMPLEMENTATION_COMPLETE.md"
delete_file "NLE_WORKFLOW_COMPLETE.md"
delete_file "SEQUENCE_ARCHITECTURE.md"
delete_file "SESSION_LOG_2025-11-12.md"
delete_file "session-2025-11-13-1402-utc.md"
delete_file "session-2025-11-13-refactor-6pane.md"
delete_file "docs/APP_CONCEPT.md"

# Optional: Delete ViewModels if user wants fresh start
echo ""
read -p "Delete ViewModels/AppViewModel.swift? (has import logic) (yes/no): " delete_vm
if [ "$delete_vm" = "yes" ]; then
    delete_file "Phosphor/ViewModels/AppViewModel.swift"
fi

# Optional: Delete old UI views (might want for reference)
echo ""
read -p "Delete old UI views (FileListView, PreviewPlayerView, SettingsPanelView)? (yes/no): " delete_old_ui
if [ "$delete_old_ui" = "yes" ]; then
    delete_file "Phosphor/Views/FileListView.swift"
    delete_file "Phosphor/Views/PreviewPlayerView.swift"
    delete_file "Phosphor/Views/SettingsPanelView.swift"
fi

echo ""
echo "=========================================="
echo "✅ Deletion complete!"
echo "   Files deleted: $deleted_count"
echo "=========================================="
echo ""
echo "What's left:"
echo "  ✅ SALVAGED_CODE/          (Backup of good code)"
echo "  ✅ Phosphor/Services/       (Export code)"
echo "  ✅ Phosphor/PhosphorApp.swift"
echo "  ✅ Phosphor/ContentView.swift"
echo "  ✅ Xcode project files"
echo ""
echo "Next steps:"
echo "  1. Create your mockup"
echo "  2. Build new UI from scratch"
echo "  3. Integrate code from SALVAGED_CODE/ as needed"
echo ""
echo "📖 See NEXT_SESSION_BRIEF.md for full instructions"
echo ""
