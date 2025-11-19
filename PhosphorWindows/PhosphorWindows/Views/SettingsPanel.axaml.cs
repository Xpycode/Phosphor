using System;
using System.Linq;
using System.Threading.Tasks;
using Avalonia.Controls;
using Avalonia.Interactivity;
using Avalonia.Platform.Storage;
using PhosphorWindows.Models;
using PhosphorWindows.Services;
using PhosphorWindows.ViewModels;

namespace PhosphorWindows.Views;

public partial class SettingsPanel : UserControl
{
    public SettingsPanel()
    {
        InitializeComponent();
    }

    private AppViewModel? ViewModel => DataContext as AppViewModel;

    private async void Export_Click(object? sender, RoutedEventArgs e)
    {
        if (ViewModel == null) return;

        var topLevel = TopLevel.GetTopLevel(this);
        if (topLevel == null) return;

        var ext = ViewModel.Format.GetFileExtension();
        var file = await topLevel.StorageProvider.SaveFilePickerAsync(new FilePickerSaveOptions
        {
            Title = "Export Animation",
            SuggestedFileName = $"animation.{ext}",
            FileTypeChoices = new[]
            {
                new FilePickerFileType($"{ViewModel.Format.GetDisplayName()} File")
                {
                    Patterns = new[] { $"*.{ext}" }
                }
            }
        });

        if (file != null)
        {
            try
            {
                await ExportService.ExportAnimationAsync(ViewModel, file.Path.LocalPath);
                ViewModel.ExportCompletionDate = DateTime.Now;
            }
            catch (Exception ex)
            {
                await ShowErrorDialog(topLevel, "Export Failed", ex.Message);
            }
        }
    }

    private static async Task ShowErrorDialog(TopLevel topLevel, string title, string message)
    {
        var dialog = new Window
        {
            Title = title,
            Width = 400,
            Height = 200,
            Content = new StackPanel
            {
                Margin = new Avalonia.Thickness(20),
                Spacing = 16,
                Children =
                {
                    new TextBlock { Text = title, FontWeight = Avalonia.Media.FontWeight.Bold, FontSize = 16 },
                    new TextBlock { Text = message, TextWrapping = Avalonia.Media.TextWrapping.Wrap },
                    new Button { Content = "OK", HorizontalAlignment = Avalonia.Layout.HorizontalAlignment.Right }
                }
            }
        };

        await dialog.ShowDialog((Window)topLevel);
    }
}
