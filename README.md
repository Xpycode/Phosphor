# Phosphor

A modern macOS app for creating animated GIFs, WebP, and APNG files from image sequences.

## Features

- **3-Pane Interface**: Clean, intuitive layout with file list, preview player, and settings panel
- **Image Management**:
  - Drag and drop support for adding images
  - Thumbnail preview with file information (resolution, file size)
  - Multiple sort options (filename, modification date, manual reordering)
  - Add/remove images at any time
- **Preview Player**:
  - Real-time preview of animation
  - Play/pause controls
  - Frame-by-frame navigation
  - Scrubber for seeking through frames
  - Current frame counter
- **Export Formats**:
  - GIF (fully supported)
  - APNG (fully supported)
  - WebP (requires external library - not yet implemented)
- **Export Settings**:
  - Frame rate control (FPS)
  - Frame delay control (milliseconds)
  - Loop count (infinite or specific number)
  - Quality adjustment
  - Dithering toggle (reduces color banding in GIFs)

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later (for building)

## Building

1. Clone the repository:
   ```bash
   git clone https://github.com/Xpycode/Phosphor.git
   cd Phosphor
   ```

2. Open the project in Xcode:
   ```bash
   open Phosphor.xcodeproj
   ```

3. Build and run (⌘+R)

## Usage

1. **Add Images**:
   - Click "Add Images" button or drag and drop image files into the file list
   - Supported formats: PNG, JPEG, HEIC, and other common image formats

2. **Preview Animation**:
   - Click the play button to preview your animation
   - Use the scrubber or frame navigation buttons to move through frames
   - The current frame is highlighted in the file list

3. **Adjust Settings**:
   - Set frame rate (1-60 FPS) or frame delay (16-5000 ms)
   - Choose loop count (0 for infinite)
   - Adjust quality (10-100%)
   - Enable/disable dithering for GIFs
   - Choose sort order for frames

4. **Export**:
   - Select your desired format (GIF, APNG, or WebP)
   - Click "Export Animation"
   - Choose save location and filename

## Architecture

The app is built with SwiftUI and follows MVVM architecture:

- `PhosphorApp.swift` - Main app entry point
- `ContentView.swift` - Root view with 3-pane layout
- `Models/` - Data models (ImageItem, ExportSettings)
- `Views/` - SwiftUI views (FileListView, PreviewPlayerView, SettingsPanelView)
- `ViewModels/` - AppViewModel (main app state and logic)
- `Services/` - Export services (GIFExporter, APNGExporter, WebPExporter)

## Known Limitations

- WebP export is not yet implemented (requires libwebp library)
- Manual reordering of frames requires changing sort order to "Manual" first

## Future Enhancements

- WebP export support via libwebp
- Video file import support
- Batch export options
- Custom app icon
- Frame editing (crop, resize, rotate)
- Watermark support

## License

See LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.
