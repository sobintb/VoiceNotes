//
//  RecordingMeta.swift
//  AudioVisualizerTest
//
//  Created by S O B I N on 23/06/26.
//

import Foundation
import SwiftData

/// SwiftData model representing a single recording entry in the database.
/// Each instance maps to one row — audio file metadata only, no audio data.
@Model
final class RecordingMeta {

    // MARK: - Stored Properties

    /// Primary key — enforces uniqueness across all recordings.
    @Attribute(.unique)
    var id: UUID

    /// Actual filename on disk (e.g. "Recording - 2025-06-23 10-30-00.m4a").
    /// Never renamed — file operations are risky. Only `displayName` changes.
    var fileName: String

    /// The name shown in the UI. Updated on user rename without touching the file.
    var displayName: String

    /// When the recording was created.
    var createdDate: Date

    /// Duration in seconds — captured once when recording stops,
    /// avoiding the cost of opening AVAudioPlayer on every app launch.
    var duration: TimeInterval

    /// File size in bytes — used for UI display (e.g. "2.3 MB").
    var fileSize: Int64

    /// Whether the user has starred this recording.
    var isStarred: Bool = false

    // MARK: - Init

    init(
        id: UUID = UUID(),
        fileName: String,
        displayName: String,
        createdDate: Date = .now,
        duration: TimeInterval,
        fileSize: Int64
    ) {
        self.id = id
        self.fileName = fileName
        self.displayName = displayName
        self.createdDate = createdDate
        self.duration = duration
        self.fileSize = fileSize
    }

    // MARK: - Computed Properties

    /// Reconstructs the full file URL at runtime.
    /// Not stored because the documents directory path can change between app launches.
    var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }
}
