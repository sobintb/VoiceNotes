//
//  Recording.swift
//  AudioVisualizerTest
//
//  Created by S O B I N on 21/06/26.
//

import Foundation

/// Lightweight UI-facing struct built from a `RecordingMeta` database row.
/// Keeps SwiftData models out of Views entirely.
struct Recording: Identifiable, Equatable {

    let id: UUID
    let url: URL
    var displayName: String
    let createdDate: Date
    let duration: TimeInterval
    let fileSize: Int64
    var isStarred: Bool

    // MARK: - Init from RecordingMeta

    init(from meta: RecordingMeta) {
        self.id = meta.id
        self.url = meta.fileURL
        self.displayName = meta.displayName
        self.createdDate = meta.createdDate
        self.duration = meta.duration
        self.fileSize = meta.fileSize
        self.isStarred = meta.isStarred
    }

    // MARK: - Formatted Helpers

    /// "2m 35s" style duration label for UI display.
    var formattedDuration: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        if mins > 0 {
            return "\(mins)m \(secs)s"
        }
        return "\(secs)s"
    }

    /// "2.3 MB" style file size label for UI display.
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

// MARK: - Preview & Testing

extension Recording {

    /// Direct init for previews and unit tests — no `RecordingMeta` required.
    init(
        id: UUID = UUID(),
        url: URL = URL(fileURLWithPath: "/sample.m4a"),
        displayName: String,
        createdDate: Date = .now,
        duration: TimeInterval,
        fileSize: Int64 = 0,
        isStarred: Bool = false
    ) {
        self.id = id
        self.url = url
        self.displayName = displayName
        self.createdDate = createdDate
        self.duration = duration
        self.fileSize = fileSize
        self.isStarred = isStarred
    }

    static let preview = Recording(
        displayName: "Test Recording",
        createdDate: .now,
        duration: 155
    )
}
