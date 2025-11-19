using System;
using System.IO;
using Avalonia.Media.Imaging;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;

namespace PhosphorWindows.Models;

public class ImageItem : IEquatable<ImageItem>
{
    public Guid Id { get; } = Guid.NewGuid();
    public string FilePath { get; init; } = string.Empty;
    public Bitmap? Thumbnail { get; init; }
    public int Width { get; init; }
    public int Height { get; init; }
    public long FileSize { get; init; }
    public DateTime ModificationDate { get; init; }

    public string FileName => Path.GetFileName(FilePath);

    public string FileSizeFormatted
    {
        get
        {
            string[] sizes = { "B", "KB", "MB", "GB" };
            double len = FileSize;
            int order = 0;
            while (len >= 1024 && order < sizes.Length - 1)
            {
                order++;
                len /= 1024;
            }
            return $"{len:0.##} {sizes[order]}";
        }
    }

    public string ResolutionString => $"{Width} × {Height}";

    public static string[] SupportedExtensions { get; } = new[]
    {
        ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".tif", ".webp", ".tga"
    };

    public static ImageItem? FromFile(string filePath)
    {
        if (!IsSupported(filePath))
            return null;

        try
        {
            var fileInfo = new FileInfo(filePath);
            if (!fileInfo.Exists)
                return null;

            // Load image to get dimensions
            using var image = SixLabors.ImageSharp.Image.Load(filePath);

            // Create thumbnail
            var thumbnail = CreateThumbnail(filePath, 60, 60);

            return new ImageItem
            {
                FilePath = filePath,
                Thumbnail = thumbnail,
                Width = image.Width,
                Height = image.Height,
                FileSize = fileInfo.Length,
                ModificationDate = fileInfo.LastWriteTime
            };
        }
        catch
        {
            return null;
        }
    }

    public static bool IsSupported(string filePath)
    {
        var ext = Path.GetExtension(filePath).ToLowerInvariant();
        return Array.Exists(SupportedExtensions, supported => supported == ext);
    }

    private static Bitmap? CreateThumbnail(string filePath, int maxWidth, int maxHeight)
    {
        try
        {
            using var image = SixLabors.ImageSharp.Image.Load(filePath);

            // Calculate aspect-preserving dimensions
            var widthRatio = (double)maxWidth / image.Width;
            var heightRatio = (double)maxHeight / image.Height;
            var ratio = Math.Min(widthRatio, heightRatio);

            var newWidth = Math.Max((int)(image.Width * ratio), 1);
            var newHeight = Math.Max((int)(image.Height * ratio), 1);

            image.Mutate(x => x.Resize(newWidth, newHeight));

            // Convert to Avalonia Bitmap
            using var ms = new MemoryStream();
            image.SaveAsPng(ms);
            ms.Position = 0;
            return new Bitmap(ms);
        }
        catch
        {
            return null;
        }
    }

    public bool Equals(ImageItem? other)
    {
        if (other is null) return false;
        return Id == other.Id;
    }

    public override bool Equals(object? obj) => Equals(obj as ImageItem);
    public override int GetHashCode() => Id.GetHashCode();
}
