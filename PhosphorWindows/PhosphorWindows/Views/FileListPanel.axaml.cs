using System.Linq;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Interactivity;
using Avalonia.Platform.Storage;
using PhosphorWindows.Models;
using PhosphorWindows.ViewModels;

namespace PhosphorWindows.Views;

public partial class FileListPanel : UserControl
{
    public FileListPanel()
    {
        InitializeComponent();
        AddHandler(DragDrop.DropEvent, Drop);
        AddHandler(DragDrop.DragOverEvent, DragOver);
    }

    private AppViewModel? ViewModel => DataContext as AppViewModel;

    private async void AddImages_Click(object? sender, RoutedEventArgs e)
    {
        var topLevel = TopLevel.GetTopLevel(this);
        if (topLevel == null) return;

        var files = await topLevel.StorageProvider.OpenFilePickerAsync(new FilePickerOpenOptions
        {
            Title = "Open Images",
            AllowMultiple = true,
            FileTypeFilter = new[]
            {
                new FilePickerFileType("Images")
                {
                    Patterns = ImageItem.SupportedExtensions.Select(ext => $"*{ext}").ToArray()
                }
            }
        });

        if (files.Count > 0 && ViewModel != null)
        {
            var paths = files.Select(f => f.Path.LocalPath).ToArray();
            await ViewModel.AddImagesAsync(paths);
        }
    }

    private void RemoveButton_Click(object? sender, RoutedEventArgs e)
    {
        if (sender is Button button && button.Tag is ImageItem item && ViewModel != null)
        {
            ViewModel.RemoveImage(item);
        }
    }

    private void Item_PointerPressed(object? sender, PointerPressedEventArgs e)
    {
        if (sender is Border border && border.DataContext is ImageItem item && ViewModel != null)
        {
            var index = ViewModel.SortedImages.IndexOf(item);
            if (index >= 0)
            {
                ViewModel.SeekToFrame(index);
            }
        }
    }

    private void DragOver(object? sender, DragEventArgs e)
    {
        e.DragEffects = DragDropEffects.Copy;
    }

    private async void Drop(object? sender, DragEventArgs e)
    {
        if (e.Data.Contains(DataFormats.Files) && ViewModel != null)
        {
            var files = e.Data.GetFiles();
            if (files != null)
            {
                var paths = files.Select(f => f.Path.LocalPath)
                                .Where(ImageItem.IsSupported)
                                .ToArray();
                if (paths.Length > 0)
                {
                    await ViewModel.AddImagesAsync(paths);
                }
            }
        }
    }
}
