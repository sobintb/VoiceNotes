//
//  MiniPlayerView.swift
//  AudioVisualizerTest
//
//  Created by S O B I N on 22/06/26.
//

import SwiftUI

// MARK: - MiniPlayerView

struct MiniPlayerView: View {

    @ObservedObject var player: PlayerViewModel
    @ObservedObject var coordinator: AudioCoordinator

    @State private var dragOffset: CGFloat = 0
    @State private var isClosing = false

    var body: some View {
        if let recording = coordinator.selectedRecording {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 12) {

                    // Drag handle
                    Capsule()
                        .fill(.secondary)
                        .frame(width: 40, height: 5)
                        .opacity(0.5)
                        .padding(.bottom, 4)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())

                    PlayerComponents(
                        titleName: recording.displayName,
                        currentTime: player.currentTime,
                        totalDuration: player.duration,
                        isPlaying: player.isPlaying,
                        actionPlay: {
                            player.resumePlayback()
                        },
                        actionPause: {
                            player.pausePlayback()
                        }
                    )

                    Slider(
                        value: Binding(
                            get: { player.currentTime },
                            set: { player.currentTime = $0 }
                        ),
                        in: 0...max(player.duration, 1),
                        onEditingChanged: { editing in
                            print("edit== \(editing)")
                            if editing {
                                player.beginSeeking()
                            } else {
                                player.endSeeking(at: player.currentTime)
                            }
                        }
                    )
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding()
                .shadow(radius: 10)
                .overlay(
                    VStack {
                        DragDismissView(
                            onChanged: { translation in
                                dragOffset = translation
                            },
                            onEnded: { translation in
                                if translation > 80 {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    coordinator.dismissPlayer()
                                } else {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        dragOffset = 0
                                    }
                                }
                            }
                        )
                        .frame(height: 40)

                        Spacer()
                    }
                )

                // Close button
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()

                    isClosing = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                        coordinator.dismissPlayer()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                        .frame(width: 33, height: 33)
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .scaleEffect(isClosing ? 0.75 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isClosing)
            }
            .background(Color.clear)
            .offset(y: dragOffset)
            .opacity(max(0.5, 1.0 - dragOffset / 200.0))
        }
    }
}

// MARK: - PlayerComponents

/// Reusable title + time label + play/pause button row used inside MiniPlayerView.
private struct PlayerComponents: View {

    let titleName: String
    let currentTime: TimeInterval
    let totalDuration: TimeInterval
    let isPlaying: Bool

    let actionPlay: () -> Void
    let actionPause: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(titleName)
                    .font(.headline)
                    .lineLimit(1)

                Text("\(formatTime(currentTime)) / \(formatTime(totalDuration))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                if isPlaying {
                    actionPause()
                } else {
                    actionPlay()
                }
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
    }
}

// MARK: - Time Formatter

/// Formats a TimeInterval as mm:ss. Used by MiniPlayerView and PlayerComponents.
func formatTime(_ time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

#Preview {
    let coordinator = AudioCoordinator()
    let player = PlayerViewModel()

    coordinator.selectedRecording = .preview

    player.currentTime = 45
    player.duration = 156
    player.isPlaying = true

    return MiniPlayerView(
        player: player,
        coordinator: coordinator
    )
}
