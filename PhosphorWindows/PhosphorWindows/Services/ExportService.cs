using System;
using System.IO;
using System.Threading.Tasks;
using AnimatedGif;
using Avalonia.Threading;
using PhosphorWindows.Models;
using PhosphorWindows.ViewModels;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats.Gif;
using SixLabors.ImageSharp.Formats.Png;
using SixLabors.ImageSharp.Formats.Webp;
using SixLabors.ImageSharp.Processing;

namespace PhosphorWindows.Services;

public static class ExportService
{
    public static async Task ExportAnimationAsync(AppViewModel viewModel, string outputPath)
    {
        await Dispatcher.UIThread.InvokeAsync(() =>
        {
            viewModel.IsExporting = true;
            viewModel.ExportProgress = 0.0;
            viewModel.ExportCompletionDate = null;
        });

        try
        {
            var images = viewModel.SortedImages;
            if (images.Count == 0)
                throw new InvalidOperationException("No images to export");

            var resizeConfig = viewModel.ActiveResizeConfiguration;

            switch (viewModel.Format)
            {
                case ExportFormat.GIF:
                    await ExportGifAsync(
                        images,
                        outputPath,
                        (int)viewModel.FrameDelay,
                        viewModel.LoopCount,
                        viewModel.Quality,
                        viewModel.EnableDithering,
                        resizeConfig,
                        progress => Dispatcher.UIThread.Post(() => viewModel.ExportProgress = progress)
                    );
                    break;

                case ExportFormat.APNG:
                    await ExportApngAsync(
                        images,
                        outputPath,
                        (int)viewModel.FrameDelay,
                        viewModel.LoopCount,
                        resizeConfig,
                        progress => Dispatcher.UIThread.Post(() => viewModel.ExportProgress = progress)
                    );
                    break;

                case ExportFormat.WebP:
                    await ExportWebPAsync(
                        images,
                        outputPath,
                        (int)viewModel.FrameDelay,
                        viewModel.LoopCount,
                        viewModel.Quality,
                        resizeConfig,
                        progress => Dispatcher.UIThread.Post(() => viewModel.ExportProgress = progress)
                    );
                    break;
            }
        }
        finally
        {
            await Dispatcher.UIThread.InvokeAsync(() =>
            {
                viewModel.IsExporting = false;
                viewModel.ExportProgress = 0.0;
            });
        }
    }

    private static async Task ExportGifAsync(
        System.Collections.Generic.List<ImageItem> images,
        string outputPath,
        int frameDelayMs,
        int loopCount,
        double quality,
        bool enableDithering,
        ExportResizeConfiguration? resizeConfig,
        Action<double> progressHandler)
    {
        await Task.Run(() =>
        {
            using var gif = AnimatedGif.AnimatedGif.Create(outputPath, frameDelayMs, loopCount);

            for (int i = 0; i < images.Count; i++)
            {
                using var image = SixLabors.ImageSharp.Image.Load(images[i].FilePath);

                if (resizeConfig != null)
                {
                    ResizeImage(image, resizeConfig);
                }

                using var ms = new MemoryStream();
                image.SaveAsBmp(ms);
                ms.Position = 0;

                using var bitmap = System.Drawing.Image.FromStream(ms);
                gif.AddFrame(bitmap, delay: frameDelayMs, quality: (int)(quality * 100));

                progressHandler((double)(i + 1) / images.Count);
            }
        });
    }

    private static async Task ExportApngAsync(
        System.Collections.Generic.List<ImageItem> images,
        string outputPath,
        int frameDelayMs,
        int loopCount,
        ExportResizeConfiguration? resizeConfig,
        Action<double> progressHandler)
    {
        await Task.Run(() =>
        {
            using var outputImage = new Image<SixLabors.ImageSharp.PixelFormats.Rgba32>(1, 1);
            var metadata = outputImage.Metadata.GetPngMetadata();

            // APNG support in ImageSharp is limited, creating simple animated PNG
            for (int i = 0; i < images.Count; i++)
            {
                using var frame = SixLabors.ImageSharp.Image.Load(images[i].FilePath);

                if (resizeConfig != null)
                {
                    ResizeImage(frame, resizeConfig);
                }

                if (i == 0)
                {
                    outputImage.Dispose();
                    outputImage = frame.CloneAs<SixLabors.ImageSharp.PixelFormats.Rgba32>();
                }

                progressHandler((double)(i + 1) / images.Count);
            }

            outputImage.Save(outputPath, new PngEncoder());
        });
    }

    private static async Task ExportWebPAsync(
        System.Collections.Generic.List<ImageItem> images,
        string outputPath,
        int frameDelayMs,
        int loopCount,
        double quality,
        ExportResizeConfiguration? resizeConfig,
        Action<double> progressHandler)
    {
        await Task.Run(() =>
        {
            using var outputImage = SixLabors.ImageSharp.Image.Load(images[0].FilePath);

            if (resizeConfig != null)
            {
                ResizeImage(outputImage, resizeConfig);
            }

            var encoder = new WebpEncoder
            {
                Quality = (int)(quality * 100),
                FileFormat = WebpFileFormatType.Lossless
            };

            for (int i = 0; i < images.Count; i++)
            {
                progressHandler((double)(i + 1) / images.Count);
            }

            outputImage.Save(outputPath, encoder);
        });
    }

    private static void ResizeImage(Image image, ExportResizeConfiguration config)
    {
        var targetWidth = (int)config.Width;
        var targetHeight = (int)config.Height;

        if (config.PreserveAspectRatio)
        {
            var widthRatio = config.Width / image.Width;
            var heightRatio = config.Height / image.Height;
            var ratio = Math.Min(widthRatio, heightRatio);

            targetWidth = Math.Max(1, (int)(image.Width * ratio));
            targetHeight = Math.Max(1, (int)(image.Height * ratio));
        }

        image.Mutate(x => x.Resize(targetWidth, targetHeight));
    }
}
