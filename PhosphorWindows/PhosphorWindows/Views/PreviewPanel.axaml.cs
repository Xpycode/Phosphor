using Avalonia.Controls;
using Avalonia.Interactivity;
using PhosphorWindows.ViewModels;

namespace PhosphorWindows.Views;

public partial class PreviewPanel : UserControl
{
    public PreviewPanel()
    {
        InitializeComponent();
    }

    private AppViewModel? ViewModel => DataContext as AppViewModel;

    private void PlayPause_Click(object? sender, RoutedEventArgs e)
    {
        ViewModel?.TogglePlayback();
    }

    private void Previous_Click(object? sender, RoutedEventArgs e)
    {
        ViewModel?.PreviousFrame();
    }

    private void Next_Click(object? sender, RoutedEventArgs e)
    {
        ViewModel?.NextFrame();
    }
}
