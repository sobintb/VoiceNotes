//
//  PlayerViewModel.swift
//  AudioVisualizerTest
//
//  Created by S O B I N on 25/06/26.
//

import AVFoundation
import SwiftUI
import Combine

// MARK: - PlayerViewModel

/// Owns all audio playback logic — AVAudioPlayer, progress tracking,
/// and seeking. Fires `onPlaybackFinished` when a track ends naturally
/// so the coordinator can react (e.g. reset selected recording).
final class PlayerViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {

    // MARK: - Published State

    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isSeeking: Bool = false

    // MARK: - Callbacks

    /// Called when the player finishes naturally (not on manual stop/dismiss).
    var onPlaybackFinished: (() -> Void)?

    // MARK: - Private Properties

    private var player: AVAudioPlayer?
    private var progressTimer: Timer?
    private var wasPlayingBeforeSeek = false

    // MARK: - Play

    func playRecording(url: URL) {
        do {
            player?.stop()
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            duration = player?.duration ?? 0
            currentTime = 0
            player?.play()
            isPlaying = true
            startProgressTimer()
            print("Playback started: \(url.lastPathComponent)")
        } catch {
            print("Playback error: \(error)")
        }
    }

    // MARK: - Pause

    func pausePlayback() {
        player?.pause()
        isPlaying = false
        stopProgressTimer()
        print("Playback paused")
    }

    // MARK: - Resume

    func resumePlayback() {
        player?.play()
        isPlaying = true
        startProgressTimer()
        print("Playback resumed")
    }

    // MARK: - Stop

    /// Full stop — resets position and clears state.
    func stopPlayback() {
        player?.stop()
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        stopProgressTimer()
        print("Playback stopped")
    }

    // MARK: - Seek

    func beginSeeking() {
        wasPlayingBeforeSeek = isPlaying
        if isPlaying { player?.pause() }
        isSeeking = true
    }

    func endSeeking(at time: TimeInterval) {
        let safeTime = min(max(0, time), duration)
        player?.currentTime = safeTime
        currentTime = safeTime
        if wasPlayingBeforeSeek { player?.play() }
        isSeeking = false
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = 0
        stopProgressTimer()
        onPlaybackFinished?()
        print("Playback finished")
    }

    // MARK: - Progress Timer

    private func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, !self.isSeeking else { return }
            self.currentTime = self.player?.currentTime ?? 0
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}
