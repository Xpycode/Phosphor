//
//  VideoPlayerView.swift
//  Phosphor
//
//  Created on 2025-11-18
//

import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: NSViewRepresentable {
    let url: URL
    @Binding var currentTime: Double
    @Binding var isPlaying: Bool
    let duration: Double

    func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        playerView.controlsStyle = .none
        playerView.showsFullScreenToggleButton = false
        playerView.showsSharingServiceButton = false
        playerView.allowsPictureInPicturePlayback = false

        let player = AVPlayer(url: url)
        playerView.player = player

        context.coordinator.player = player
        context.coordinator.setupObservers()

        return playerView
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        guard let player = nsView.player else { return }

        // Update playback state
        if isPlaying {
            if player.rate == 0 {
                player.play()
            }
        } else {
            if player.rate != 0 {
                player.pause()
            }
        }

        // Seek if currentTime changed externally
        let playerTime = player.currentTime().seconds
        if abs(playerTime - currentTime) > 0.1 {
            player.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(currentTime: $currentTime, isPlaying: $isPlaying, duration: duration)
    }

    class Coordinator: NSObject {
        @Binding var currentTime: Double
        @Binding var isPlaying: Bool
        let duration: Double
        var player: AVPlayer?
        private var timeObserver: Any?
        private var statusObserver: NSKeyValueObservation?
        private var rateObserver: NSKeyValueObservation?

        init(currentTime: Binding<Double>, isPlaying: Binding<Bool>, duration: Double) {
            self._currentTime = currentTime
            self._isPlaying = isPlaying
            self.duration = duration
        }

        func setupObservers() {
            guard let player = player else { return }

            // Observe current time
            let interval = CMTime(seconds: 0.03, preferredTimescale: 600) // ~30fps updates
            timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                guard let self = self else { return }
                let seconds = time.seconds
                if seconds.isFinite {
                    self.currentTime = seconds
                }

                // Loop video when it reaches the end
                if seconds >= self.duration - 0.1 && self.isPlaying {
                    player.seek(to: .zero)
                }
            }

            // Observe player status
            statusObserver = player.observe(\.status, options: [.new]) { [weak self] player, _ in
                if player.status == .failed {
                    print("Player failed: \(player.error?.localizedDescription ?? "Unknown error")")
                }
            }

            // Observe rate changes
            rateObserver = player.observe(\.rate, options: [.new]) { [weak self] player, _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.isPlaying = player.rate > 0
                }
            }
        }

        deinit {
            if let observer = timeObserver {
                player?.removeTimeObserver(observer)
            }
            statusObserver?.invalidate()
            rateObserver?.invalidate()
        }
    }
}
