using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Reactive;
using System.Reactive.Linq;
using System.Threading;
using System.Threading.Tasks;
using Avalonia.Media.Imaging;
using Avalonia.Threading;
using PhosphorWindows.Models;
using ReactiveUI;
using SixLabors.ImageSharp;

namespace PhosphorWindows.ViewModels;

public class AppViewModel : ReactiveObject
{
    private ObservableCollection<ImageItem> _imageItems = new();
    private ExportFormat _format = ExportFormat.GIF;
    private double _frameDelay = 100; // milliseconds
    private double _frameRate = 10; // FPS
    private int _loopCount = 0; // 0 = infinite
    private double _quality = 0.8;
    private bool _enableDithering = true;
    private SortOrder _sortOrder = SortOrder.FileName;
    private bool _resizeEnabled = false;
    private double _resizeWidth = 640;
    private double _resizeHeight = 480;
    private ResizeMode _resizeMode = ResizeMode.Common;
    private string _selectedResizePresetID = ResizePresetOption.GetDefaultId(ExportFormat.GIF);
    private bool _maintainAspectRatio = true;
    private bool _isPlaying = false;
    private int _currentFrameIndex = 0;
    private bool _isExporting = false;
    private double _exportProgress = 0.0;
    private DateTime? _exportCompletionDate;
    private bool _isImporting = false;
    private double _importProgress = 0.0;

    private DispatcherTimer? _playbackTimer;
    private CancellationTokenSource? _importCancellationToken;
    private bool _isUpdatingFrameSync = false;
    private SortOrder _lastAutomaticSortOrder = SortOrder.FileName;

    public ObservableCollection<ImageItem> ImageItems
    {
        get => _imageItems;
        set => this.RaiseAndSetIfChanged(ref _imageItems, value);
    }

    public ExportFormat Format
    {
        get => _format;
        set
        {
            this.RaiseAndSetIfChanged(ref _format, value);
            SelectedResizePresetID = ResizePresetOption.GetDefaultId(value);
        }
    }

    public double FrameDelay
    {
        get => _frameDelay;
        set => this.RaiseAndSetIfChanged(ref _frameDelay, value);
    }

    public double FrameRate
    {
        get => _frameRate;
        set => this.RaiseAndSetIfChanged(ref _frameRate, value);
    }

    public int LoopCount
    {
        get => _loopCount;
        set => this.RaiseAndSetIfChanged(ref _loopCount, value);
    }

    public double Quality
    {
        get => _quality;
        set => this.RaiseAndSetIfChanged(ref _quality, value);
    }

    public bool EnableDithering
    {
        get => _enableDithering;
        set => this.RaiseAndSetIfChanged(ref _enableDithering, value);
    }

    public SortOrder SortOrder
    {
        get => _sortOrder;
        set => this.RaiseAndSetIfChanged(ref _sortOrder, value);
    }

    public bool ResizeEnabled
    {
        get => _resizeEnabled;
        set => this.RaiseAndSetIfChanged(ref _resizeEnabled, value);
    }

    public double ResizeWidth
    {
        get => _resizeWidth;
        set => this.RaiseAndSetIfChanged(ref _resizeWidth, value);
    }

    public double ResizeHeight
    {
        get => _resizeHeight;
        set => this.RaiseAndSetIfChanged(ref _resizeHeight, value);
    }

    public ResizeMode ResizeMode
    {
        get => _resizeMode;
        set => this.RaiseAndSetIfChanged(ref _resizeMode, value);
    }

    public string SelectedResizePresetID
    {
        get => _selectedResizePresetID;
        set
        {
            this.RaiseAndSetIfChanged(ref _selectedResizePresetID, value);
            var preset = ResizePresetOption.GetPreset(Format, value);
            if (preset != null)
            {
                ResizeWidth = preset.Width;
                ResizeHeight = preset.Height;
            }
        }
    }

    public bool MaintainAspectRatio
    {
        get => _maintainAspectRatio;
        set => this.RaiseAndSetIfChanged(ref _maintainAspectRatio, value);
    }

    public bool IsPlaying
    {
        get => _isPlaying;
        set => this.RaiseAndSetIfChanged(ref _isPlaying, value);
    }

    public int CurrentFrameIndex
    {
        get => _currentFrameIndex;
        set => this.RaiseAndSetIfChanged(ref _currentFrameIndex, value);
    }

    public bool IsExporting
    {
        get => _isExporting;
        set => this.RaiseAndSetIfChanged(ref _isExporting, value);
    }

    public double ExportProgress
    {
        get => _exportProgress;
        set => this.RaiseAndSetIfChanged(ref _exportProgress, value);
    }

    public DateTime? ExportCompletionDate
    {
        get => _exportCompletionDate;
        set => this.RaiseAndSetIfChanged(ref _exportCompletionDate, value);
    }

    public bool IsImporting
    {
        get => _isImporting;
        set => this.RaiseAndSetIfChanged(ref _isImporting, value);
    }

    public double ImportProgress
    {
        get => _importProgress;
        set => this.RaiseAndSetIfChanged(ref _importProgress, value);
    }

    public List<ImageItem> SortedImages
    {
        get
        {
            return SortOrder switch
            {
                SortOrder.FileName => ImageItems.OrderBy(x => x.FileName, StringComparer.CurrentCultureIgnoreCase).ToList(),
                SortOrder.ModificationDate => ImageItems.OrderBy(x => x.ModificationDate).ToList(),
                SortOrder.Manual => ImageItems.ToList(),
                _ => ImageItems.ToList()
            };
        }
    }

    public ImageItem? CurrentImageItem
    {
        get
        {
            var sorted = SortedImages;
            if (sorted.Count == 0 || CurrentFrameIndex >= sorted.Count)
                return null;
            return sorted[CurrentFrameIndex];
        }
    }

    public Bitmap? CurrentImage
    {
        get
        {
            var item = CurrentImageItem;
            if (item == null) return null;

            try
            {
                return new Bitmap(item.FilePath);
            }
            catch
            {
                return null;
            }
        }
    }

    public int TotalFrames => SortedImages.Count;

    public ExportResizeConfiguration? ActiveResizeConfiguration
    {
        get
        {
            if (!ResizeEnabled) return null;
            return new ExportResizeConfiguration
            {
                Width = Math.Max(1, ResizeWidth),
                Height = Math.Max(1, ResizeHeight),
                PreserveAspectRatio = MaintainAspectRatio
            };
        }
    }

    public ReactiveCommand<Unit, Unit> TogglePlaybackCommand { get; }
    public ReactiveCommand<Unit, Unit> NextFrameCommand { get; }
    public ReactiveCommand<Unit, Unit> PreviousFrameCommand { get; }
    public ReactiveCommand<Unit, Unit> ClearAllCommand { get; }

    public AppViewModel()
    {
        // Set up frame rate/delay synchronization
        this.WhenAnyValue(x => x.FrameRate)
            .Skip(1)
            .Subscribe(rate =>
            {
                if (!_isUpdatingFrameSync && rate > 0)
                {
                    _isUpdatingFrameSync = true;
                    var snappedRate = SnapFrameRate(rate);
                    FrameRate = snappedRate;
                    FrameDelay = 1000.0 / snappedRate;
                    _isUpdatingFrameSync = false;
                }
            });

        this.WhenAnyValue(x => x.FrameDelay)
            .Skip(1)
            .Subscribe(delay =>
            {
                if (!_isUpdatingFrameSync && delay > 0)
                {
                    _isUpdatingFrameSync = true;
                    var rate = 1000.0 / delay;
                    var snappedRate = SnapFrameRate(rate);
                    FrameRate = snappedRate;
                    FrameDelay = 1000.0 / snappedRate;
                    _isUpdatingFrameSync = false;
                }
            });

        // Monitor sort order changes
        this.WhenAnyValue(x => x.SortOrder)
            .Skip(1)
            .Subscribe(newOrder =>
            {
                if (newOrder == SortOrder.Manual)
                {
                    ApplyAutomaticSort(_lastAutomaticSortOrder);
                }
                else
                {
                    _lastAutomaticSortOrder = newOrder;
                }
                this.RaisePropertyChanged(nameof(SortedImages));
            });

        // Update sorted images when ImageItems changes
        ImageItems.CollectionChanged += (s, e) =>
        {
            this.RaisePropertyChanged(nameof(SortedImages));
            this.RaisePropertyChanged(nameof(TotalFrames));
            this.RaisePropertyChanged(nameof(CurrentImageItem));
            this.RaisePropertyChanged(nameof(CurrentImage));
        };

        // Commands
        TogglePlaybackCommand = ReactiveCommand.Create(TogglePlayback);
        NextFrameCommand = ReactiveCommand.Create(NextFrame);
        PreviousFrameCommand = ReactiveCommand.Create(PreviousFrame);
        ClearAllCommand = ReactiveCommand.Create(ClearAll);
    }

    private double SnapFrameRate(double value)
    {
        var clamped = Math.Max(1, Math.Min(60, value));
        return Math.Round(clamped);
    }

    public async Task AddImagesAsync(string[] filePaths)
    {
        if (filePaths.Length == 0) return;

        IsImporting = true;
        ImportProgress = 0.0;

        _importCancellationToken?.Cancel();
        _importCancellationToken = new CancellationTokenSource();
        var token = _importCancellationToken.Token;

        await Task.Run(() =>
        {
            var buffer = new List<ImageItem>();
            for (int i = 0; i < filePaths.Length; i++)
            {
                if (token.IsCancellationRequested) break;

                var item = ImageItem.FromFile(filePaths[i]);
                if (item != null)
                {
                    buffer.Add(item);
                }

                if (buffer.Count == 8 || i == filePaths.Length - 1)
                {
                    var itemsToAdd = buffer.ToList();
                    buffer.Clear();

                    Dispatcher.UIThread.Post(() =>
                    {
                        foreach (var img in itemsToAdd)
                        {
                            ImageItems.Add(img);
                        }
                        ImportProgress = (double)(i + 1) / filePaths.Length;
                    });
                }
                else
                {
                    Dispatcher.UIThread.Post(() =>
                    {
                        ImportProgress = (double)(i + 1) / filePaths.Length;
                    });
                }
            }
        }, token);

        IsImporting = false;
        ImportProgress = 0.0;
    }

    public void CancelImport()
    {
        _importCancellationToken?.Cancel();
        IsImporting = false;
        ImportProgress = 0.0;
    }

    public void RemoveImage(ImageItem item)
    {
        ImageItems.Remove(item);
        if (CurrentFrameIndex >= ImageItems.Count && CurrentFrameIndex > 0)
        {
            CurrentFrameIndex = ImageItems.Count - 1;
        }
    }

    public void ClearAll()
    {
        ImageItems.Clear();
        CurrentFrameIndex = 0;
        StopPlayback();
    }

    public void MoveItems(int[] sourceIndices, int destination)
    {
        var itemsToMove = sourceIndices.Select(i => ImageItems[i]).ToList();
        foreach (var index in sourceIndices.OrderByDescending(x => x))
        {
            ImageItems.RemoveAt(index);
        }

        foreach (var item in itemsToMove)
        {
            ImageItems.Insert(destination, item);
        }
    }

    public void TogglePlayback()
    {
        if (IsPlaying)
            StopPlayback();
        else
            StartPlayback();
    }

    public void StartPlayback()
    {
        if (SortedImages.Count == 0) return;

        IsPlaying = true;

        _playbackTimer?.Stop();
        _playbackTimer = new DispatcherTimer
        {
            Interval = TimeSpan.FromMilliseconds(FrameDelay)
        };
        _playbackTimer.Tick += (s, e) => NextFrame();
        _playbackTimer.Start();
    }

    public void StopPlayback()
    {
        IsPlaying = false;
        _playbackTimer?.Stop();
        _playbackTimer = null;
    }

    public void NextFrame()
    {
        if (SortedImages.Count == 0) return;
        CurrentFrameIndex = (CurrentFrameIndex + 1) % SortedImages.Count;
        this.RaisePropertyChanged(nameof(CurrentImageItem));
        this.RaisePropertyChanged(nameof(CurrentImage));
    }

    public void PreviousFrame()
    {
        if (SortedImages.Count == 0) return;
        CurrentFrameIndex = (CurrentFrameIndex - 1 + SortedImages.Count) % SortedImages.Count;
        this.RaisePropertyChanged(nameof(CurrentImageItem));
        this.RaisePropertyChanged(nameof(CurrentImage));
    }

    public void SeekToFrame(int index)
    {
        if (index >= 0 && index < SortedImages.Count)
        {
            CurrentFrameIndex = index;
            this.RaisePropertyChanged(nameof(CurrentImageItem));
            this.RaisePropertyChanged(nameof(CurrentImage));
        }
    }

    private void ApplyAutomaticSort(SortOrder order)
    {
        var sorted = order switch
        {
            SortOrder.FileName => ImageItems.OrderBy(x => x.FileName, StringComparer.CurrentCultureIgnoreCase).ToList(),
            SortOrder.ModificationDate => ImageItems.OrderBy(x => x.ModificationDate).ToList(),
            _ => ImageItems.ToList()
        };

        ImageItems.Clear();
        foreach (var item in sorted)
        {
            ImageItems.Add(item);
        }
    }
}
