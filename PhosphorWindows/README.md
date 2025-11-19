# Phosphor for Windows

A native Windows version of Phosphor - an animated image creator for GIF, WebP, and APNG formats.

## Overview

Phosphor for Windows is built using **Avalonia UI**, a cross-platform .NET UI framework that provides a native Windows experience with XAML-based development.

## Features

- **Multi-format Support**: Export animations as GIF, WebP, or APNG
- **Frame Rate Control**: Adjust FPS and frame delay with real-time synchronization
- **Flexible Resize Options**: Choose from common presets or set custom dimensions
- **Quality Settings**: Control export quality and enable dithering for better results
- **Drag & Drop**: Easy image import via drag-and-drop
- **Live Preview**: Real-time animation playback with scrubber controls
- **Manual Reordering**: Drag frames to reorder in manual sort mode

## Requirements

- Windows 10 or later
- .NET 8.0 Runtime

## Building from Source

### Prerequisites

- .NET 8.0 SDK
- Visual Studio 2022 or JetBrains Rider (optional)

### Build Instructions

```bash
cd PhosphorWindows/PhosphorWindows
dotnet restore
dotnet build
dotnet run
```

### Publishing for Distribution

To create a self-contained executable:

```bash
# For Windows x64
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true

# For Windows ARM64
dotnet publish -c Release -r win-arm64 --self-contained true -p:PublishSingleFile=true
```

The executable will be in `bin/Release/net8.0/win-x64/publish/`

## Technology Stack

- **UI Framework**: Avalonia 11.0
- **MVVM**: ReactiveUI
- **Image Processing**: ImageSharp 3.1
- **GIF Export**: AnimatedGif 2.0
- **Language**: C# 12 (.NET 8)

## Architecture

```
PhosphorWindows/
├── Models/              # Data models (ImageItem, ExportSettings)
├── ViewModels/          # MVVM ViewModels with ReactiveUI
├── Views/               # Avalonia XAML views
│   ├── MainWindow.axaml
│   ├── FileListPanel.axaml
│   ├── PreviewPanel.axaml
│   └── SettingsPanel.axaml
├── Services/            # Export services for GIF/APNG/WebP
├── Converters/          # XAML value converters
└── Assets/              # Icons and resources
```

## Differences from macOS Version

This Windows version maintains feature parity with the macOS version while using native Windows technologies:

- **UI Framework**: Avalonia (XAML) instead of SwiftUI
- **Image Processing**: ImageSharp instead of Core Graphics/ImageIO
- **Platform**: Cross-platform .NET instead of macOS-specific Swift
- **Performance**: Optimized for Windows with native rendering

## Known Limitations

- APNG export uses simplified PNG encoding (limited animation support)
- WebP animated export is in development (currently exports single frame)
- Some advanced image formats may have limited support compared to macOS version

## Contributing

Contributions are welcome! Please ensure code follows the established architecture patterns and includes appropriate error handling.

## License

Same license as the main Phosphor project.
