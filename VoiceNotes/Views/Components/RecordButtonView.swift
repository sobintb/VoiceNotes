//
//  RecordButtonView.swift
//  AudioVisualizerTest
//
//  Created by S O B I N on 20/06/26.
//

import SwiftUI

struct RecordButtonView: View {

    @ObservedObject var recorder: RecorderViewModel

    // MARK: - Derived State

    private var isActive: Bool {
        recorder.state == .recording || recorder.state == .paused
    }

    private var isPaused: Bool {
        recorder.state == .paused
    }

    private var timerDisplay: String {
        let s = recorder.recordingSeconds
        let mm = s / 60
        let ss = s % 60
        return String(format: "%02d:%02d", mm, ss)
    }

    // MARK: - Permission Alert State

    @State private var showPermissionAlert = false

    @Namespace private var morphNamespace

    // MARK: - Body

    var body: some View {
        HStack(spacing: 10) {

            // ── Main capsule button ──────────────────────────────────
            Button {
                switch recorder.state {
                case .idle:
                    recorder.startRecording()

                case .recording, .paused:
                    recorder.stopRecording()

                case .permissionDenied:
                    showPermissionAlert = true
                }
            } label: {
                ZStack {
                    // Wave — visible only while actively recording
                    WaveformView(
                        level: recorder.state == .recording ? recorder.audioLevel : 0
                    )
                    .opacity(recorder.state == .recording ? 1 : 0)
                    .clipShape(Capsule())

                    // Label + timer
                    VStack(spacing: 2) {
                        HStack(spacing: 10) {
                            Image(systemName: isActive ? "stop.fill" : "mic.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .contentTransition(.symbolEffect(.replace))

                            Text(isActive ? "Stop" : "Record")
                                .font(.headline)
                                .lineLimit(1)
                                .contentTransition(.symbolEffect(.replace))
                        }

                        // Timer — only visible when recording or paused
                        if isActive {
                            Text(timerDisplay)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .transition(.opacity.combined(with: .scale(scale: 0.85)))
                        }
                    }
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.75),
                        value: isActive
                    )
                }
                .frame(maxWidth: isActive ? nil : .infinity)
                .frame(height: 56)
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .appGlass()
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
            .matchedGeometryEffect(id: "recordCapsule", in: morphNamespace)
            .alert("Microphone Access Denied", isPresented: $showPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("AudioVisualizerTest needs microphone access to record audio. Please enable it in Settings.")
            }

            // ── Pause / Resume button — only when active ─────────────
            if isActive {
                Button {
                    if isPaused {
                        recorder.resumeRecording()
                    } else {
                        recorder.pauseRecording()
                    }
                } label: {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 56, height: 56)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .appGlass()
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.4).combined(with: .opacity),
                        removal: .scale(scale: 0.4).combined(with: .opacity)
                    )
                )
                .matchedGeometryEffect(id: "pauseCircle", in: morphNamespace)

                // ── Cancel button ────────────────────────────────────
                Button {
                    recorder.cancelRecording()
                    print("Cancel tapped")
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 56, height: 56)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .tint(Color(.systemRed))
                .appGlass()
                .overlay {
                    Circle()
                        .stroke(.red.opacity(0.25), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.4).combined(with: .opacity),
                        removal: .scale(scale: 0.4).combined(with: .opacity)
                    )
                )
                .matchedGeometryEffect(id: "cancelCircle", in: morphNamespace)
            }
        }
        .animation(
            .spring(response: 0.42, dampingFraction: 0.78),
            value: isActive
        )
        .animation(
            .spring(response: 0.3, dampingFraction: 0.7),
            value: isPaused
        )
        .padding(.horizontal)
    }
}

#Preview() {
    let recorder = RecorderViewModel()

    return RecordButtonView(
        recorder: recorder
    )
}
