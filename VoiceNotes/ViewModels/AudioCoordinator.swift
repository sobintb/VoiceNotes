//
//  AudioCoordinator.swift
//  AudioVisualizerTest
//
//  Created by S O B I N on 25/06/26.
//

import AVFoundation
import SwiftData
import SwiftUI
import Combine

// MARK: - AudioCoordinator

/// Central coordinator that owns `RecorderViewModel` and `PlayerViewModel`.
/// Responsible for:
///   - Wiring callbacks between the two ViewModels
///   - All SwiftData persistence (load, save, delete, rename, star)
///   - Managing `selectedRecording` and `dismissPlayer()`
///
/// Views observe the coordinator for data-level state,
/// and observe `recorder` / `player` directly for fast UI state
/// (audio level, playback progress) to avoid full-view re-renders.
@MainActor
final class AudioCoordinator: ObservableObject {

    // MARK: - Child ViewModels

    /// Injected into RecordButtonView — owns recording state and audio level.
    let recorder = RecorderViewModel()

    /// Injected into MiniPlayerView — owns playback state and progress.
    let player = PlayerViewModel()

    // MARK: - Published State

    @Published var recordings: [Recording] = []
    @Published var selectedRecording: Recording?

    // MARK: - Private

    private var modelContext: ModelContext?

    // MARK: - Init

    init() {
        wireCallbacks()
    }

    // MARK: - Setup

    /// Call once from HomeView's `.task` block after the SwiftUI
    /// environment ModelContext becomes available.
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        print("✅ ModelContext set: \(modelContext)")
        loadRecordings()
    }

    // MARK: - Permission

    func requestPermission() {
        recorder.requestPermission()
    }

    // MARK: - Playback Entry Point

    /// Called by views to start playing a recording.
    /// Coordinator sets `selectedRecording` then delegates to PlayerViewModel.
    func playRecording(_ recording: Recording) {
        selectedRecording = recording
        player.playRecording(url: recording.url)
    }

    // MARK: - Dismiss Player

    func dismissPlayer() {
        player.stopPlayback()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            selectedRecording = nil
        }
    }

    // MARK: - Callback Wiring

    /// Connects RecorderViewModel and PlayerViewModel callbacks
    /// so they can notify the coordinator without knowing about each other.
    private func wireCallbacks() {

        // When a recording finishes, persist its metadata and refresh the list.
        recorder.onRecordingFinished = { [weak self] url in
            self?.saveMetadata(for: url)
        }

        // When playback ends naturally, clear the selected recording.
        player.onPlaybackFinished = { [weak self] in
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    self?.selectedRecording = nil
                }
            }
        }
    }

    // MARK: - SwiftData: Load

    func loadRecordings() {
        guard let modelContext else {
            print("❌ loadRecordings called but modelContext is nil")
            return
        }
        print("✅ loadRecordings running")

        let descriptor = FetchDescriptor<RecordingMeta>(
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )

        do {
            let results = try modelContext.fetch(descriptor)
            recordings = results.map { Recording(from: $0) }
        } catch {
            print("Failed to load recordings: \(error)")
        }
    }

    // MARK: - SwiftData: Save Metadata

    private func saveMetadata(for url: URL) {
        guard let modelContext else { return }

        let duration = (try? AVAudioPlayer(contentsOf: url))?.duration ?? 0
        let fileSize = (try? FileManager.default
            .attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        let displayName = url.deletingPathExtension().lastPathComponent

        let meta = RecordingMeta(
            fileName: url.lastPathComponent,
            displayName: displayName,
            duration: duration,
            fileSize: fileSize
        )

        modelContext.insert(meta)
        persistChanges()
        loadRecordings()
    }

    // MARK: - SwiftData: Delete

    func deleteRecording(_ recording: Recording) {
        guard let modelContext else { return }

        do {
            try FileManager.default.removeItem(at: recording.url)
            print("File deleted: \(recording.url.lastPathComponent)")
        } catch {
            print("Failed to delete file: \(error)")
        }

        let id = recording.id
        let descriptor = FetchDescriptor<RecordingMeta>(
            predicate: #Predicate { $0.id == id }
        )

        if let meta = try? modelContext.fetch(descriptor).first {
            modelContext.delete(meta)
            try? modelContext.save()
        }

        if selectedRecording?.id == recording.id {
            dismissPlayer()
        }

        loadRecordings()
    }

    // MARK: - SwiftData: Rename

    func renameRecording(_ recording: Recording, newName: String) {
        print("rename called")
        guard let modelContext else { return }
        print("got modelContext")

        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let id = recording.id
        let descriptor = FetchDescriptor<RecordingMeta>(
            predicate: #Predicate { $0.id == id }
        )

        if let meta = try? modelContext.fetch(descriptor).first {
            print("meta== \(meta)")
            print("descriptor== \(descriptor)")
            print("rename displayname")
            meta.displayName = trimmed
            persistChanges()
        }

        if selectedRecording?.id == recording.id {
            selectedRecording?.displayName = trimmed
        }

        loadRecordings()
    }

    // MARK: - SwiftData: Toggle Star

    func toggleStar(_ recording: Recording) {
        guard let modelContext else { return }

        let id = recording.id
        let descriptor = FetchDescriptor<RecordingMeta>(
            predicate: #Predicate { $0.id == id }
        )

        if let meta = try? modelContext.fetch(descriptor).first {
            meta.isStarred.toggle()
            persistChanges()
        }

        if selectedRecording?.id == recording.id {
            selectedRecording?.isStarred.toggle()
        }

        loadRecordings()
    }

    // MARK: - SwiftData: Persist

    private func persistChanges() {
        guard let modelContext else { return }
        do {
            print("model== \(modelContext)")
            try modelContext.save()
        } catch {
            print("❌ SwiftData save failed: \(error)")
        }
    }
}
