using System;
using System.Collections.Generic;
using System.Linq;

namespace PhosphorWindows.Models;

public enum ExportFormat
{
    GIF,
    WebP,
    APNG
}

public static class ExportFormatExtensions
{
    public static string GetFileExtension(this ExportFormat format)
    {
        return format switch
        {
            ExportFormat.GIF => "gif",
            ExportFormat.WebP => "webp",
            ExportFormat.APNG => "png",
            _ => "gif"
        };
    }

    public static string GetDisplayName(this ExportFormat format)
    {
        return format switch
        {
            ExportFormat.GIF => "GIF",
            ExportFormat.WebP => "WebP",
            ExportFormat.APNG => "APNG",
            _ => "GIF"
        };
    }
}

public enum SortOrder
{
    FileName,
    ModificationDate,
    Manual
}

public enum ResizeMode
{
    Common,
    Custom
}

public class ResizePresetOption
{
    public string Id { get; init; } = string.Empty;
    public string Label { get; init; } = string.Empty;
    public double Width { get; init; }
    public double Height { get; init; }

    public string DisplayLabel => $"{Label} ({(int)Width}×{(int)Height})";

    public static List<ResizePresetOption> GetPresets(ExportFormat format)
    {
        return format switch
        {
            ExportFormat.GIF => new List<ResizePresetOption>
            {
                new() { Id = "gif-square", Label = "Square", Width = 480, Height = 480 },
                new() { Id = "gif-sd", Label = "SD", Width = 640, Height = 480 },
                new() { Id = "gif-720", Label = "HD 720p", Width = 1280, Height = 720 },
                new() { Id = "gif-1080", Label = "HD 1080p", Width = 1920, Height = 1080 }
            },
            ExportFormat.WebP => new List<ResizePresetOption>
            {
                new() { Id = "webp-story", Label = "Story", Width = 1080, Height = 1920 },
                new() { Id = "webp-720", Label = "HD 720p", Width = 1280, Height = 720 },
                new() { Id = "webp-1080", Label = "HD 1080p", Width = 1920, Height = 1080 },
                new() { Id = "webp-1440", Label = "QHD", Width = 2560, Height = 1440 }
            },
            ExportFormat.APNG => new List<ResizePresetOption>
            {
                new() { Id = "apng-small", Label = "Small", Width = 512, Height = 512 },
                new() { Id = "apng-720", Label = "HD 720p", Width = 1280, Height = 720 },
                new() { Id = "apng-1080", Label = "HD 1080p", Width = 1920, Height = 1080 },
                new() { Id = "apng-1440", Label = "QHD", Width = 2560, Height = 1440 }
            },
            _ => new List<ResizePresetOption>()
        };
    }

    public static string GetDefaultId(ExportFormat format)
    {
        return GetPresets(format).FirstOrDefault()?.Id ?? "custom";
    }

    public static ResizePresetOption? GetPreset(ExportFormat format, string id)
    {
        return GetPresets(format).FirstOrDefault(p => p.Id == id);
    }
}

public class ExportResizeConfiguration
{
    public double Width { get; init; }
    public double Height { get; init; }
    public bool PreserveAspectRatio { get; init; }
}
