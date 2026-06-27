//
//  RecorderViewModel.swift
//  AudioVisualizerTest
//
//  Created by S O B I N on 21/06/26.
//

import AVFoundation
import SwiftUI
import Combine

// MARK: - RecorderState

enum RecorderState {
    case idle
    case recording
    case paused
    case permissionDenied
}

// MARK: - RecorderViewModel

/// Owns all audio recording logic — AVAudioRecorder, AVAudioEngine,
/// microphone level metering, and the recording timer.
/// Fires `onRecordingFinished` when a recording is complete so
/// the coordinator can persist metadata without this ViewModel
/// knowing anything about SwiftData.
final class RecorderViewModel: NSObject, ObservableObject {

    // MARK: - Published State

    @Published var state: RecorderState = .idle
    @Published var audioLevel: Double = 0
    @Published var recordingSeconds: Int = 0

    // MARK: - Callbacks

    /// Called by the coordinator — receives the finished file URL.
    var onRecordingFinished: ((URL) -> Void)?

    // MARK: - Private Properties

    private let audioEngine = AVAudioEngine()
    private var recorder: AVAudioRecorder?
    private var recordedFileURL: URL?
    private var recordingTimer: Timer?
    private var smoothedLevel: Double = 0

    // MARK: - Permission

    func requestPermission() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    print("Microphone permission accepted")
                } else {
                    print("Microphone permission denied")
                    self?.state = .permissionDenied
                }
            }
        }
    }

    // MARK: - Start Recording

    func startRecording() {
        guard state != .recording else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let url = makeRecordingURL()
            recorder = try AVAudioRecorder(url: url, settings: recordingSettings)
            recorder?.record()

            recordedFileURL = url
            setupAudioEngine()
            state = .recording
            startRecordingTimer()

            print("Recording started at: \(url.lastPathComponent)")

        } catch {
            print("recordStartError== \(error)")
        }
    }

    // MARK: - Pause Recording

    func pauseRecording() {
        guard state == .recording else { return }

        recorder?.pause()
        teardownAudioEngine()

        state = .paused
        pauseRecordingTimer()
        print("Recording paused")
    }

    // MARK: - Resume Recording

    func resumeRecording() {
        guard state == .paused else { return }

        recorder?.record()
        setupAudioEngine()

        state = .recording
        startRecordingTimer()
        print("Recording resumed")
    }

    // MARK: - Stop Recording

    func stopRecording() {
        guard let url = recordedFileURL else { return }

        recorder?.stop()
        recorder = nil
        teardownAudioEngine()

        state = .idle
        stopRecordingTimer()

        // Notify coordinator — it handles SwiftData persistence
        onRecordingFinished?(url)

        recordedFileURL = nil
        print("Recording stopped: \(url.lastPathComponent)")
    }

    // MARK: - Cancel Recording

    /// Discards the in-progress recording — file deleted, nothing persisted.
    func cancelRecording() {
        guard let url = recordedFileURL else { return }

        recorder?.stop()
        recorder = nil
        teardownAudioEngine()

        state = .idle
        stopRecordingTimer()

        do {
            try FileManager.default.removeItem(at: url)
            print("Recording cancelled and file deleted: \(url.lastPathComponent)")
        } catch {
            print("Cancel: failed to delete file: \(error)")
        }

        recordedFileURL = nil
    }

    // MARK: - Audio Engine

    private func setupAudioEngine() {
        do {
            if audioEngine.isRunning {
                audioEngine.inputNode.removeTap(onBus: 0)
                audioEngine.stop()
            }

            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.processBuffer(buffer)
            }

            try audioEngine.start()
            print("Audio Engine Started")

        } catch {
            print("Audio setup failed: \(error)")
        }
    }

    private func teardownAudioEngine() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        audioLevel = 0
    }

    // MARK: - Buffer Processing

    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        var sum: Float = 0

        for i in 0..<frameLength {
            let sample = channelData[i]
            sum += sample * sample
        }

        let rms = sqrt(sum / Float(frameLength))

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let db = 20 * log10(max(rms, 0.00001))
            let normalized = max(0, min((db + 50) / 50, 1))
            self.smoothedLevel = (self.smoothedLevel * 0.8) + (Double(normalized) * 0.2)
            self.audioLevel = self.smoothedLevel
        }
    }

    // MARK: - Recording Timer

    private func startRecordingTimer() {
        recordingSeconds = 0
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.recordingSeconds += 1
        }
    }

    private func pauseRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingSeconds = 0
    }

    // MARK: - Helpers

    private func makeRecordingURL() -> URL {
        let documents = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        return documents.appendingPathComponent("Recording - \(formatter.string(from: Date())).m4a")
    }

    private var recordingSettings: [String: Any] {
        [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    }

    // MARK: - Deinit

    deinit {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
}
