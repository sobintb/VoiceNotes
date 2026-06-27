# AudioVisualizerTest
A native iOS voice memo app built with SwiftUI, featuring real-time audio visualization, smooth playback controls, and persistent recording management.

---

## Tech Stack

| | |
|---|---|
| **Language** | Swift 5.9+ |
| **UI Framework** | SwiftUI |
| **Architecture** | MVVM + Coordinator |
| **Persistence** | SwiftData |
| **Audio** | AVFoundation (AVAudioEngine, AVAudioRecorder, AVAudioPlayer) |
| **Minimum iOS** | iOS 17 · Optimized for iOS 26 (Liquid Glass) |

---

## Architecture

The project follows an **MVVM + Coordinator** pattern, keeping views free of business logic and audio/data concerns separated by responsibility.

- **`RecorderViewModel`** — owns all recording logic: `AVAudioEngine`, `AVAudioRecorder`, microphone level metering, and the recording timer. Fires a callback on completion so it has no knowledge of SwiftData.
- **`PlayerViewModel`** — owns all playback logic: `AVAudioPlayer`, progress tracking, and seeking. Fires a callback when playback finishes naturally.
- **`AudioCoordinator`** — the single `@StateObject` injected into views. Wires the two ViewModels together, handles all SwiftData operations (load, save, delete, rename, star), and manages `selectedRecording` state.
- **`RecordingMeta`** (SwiftData `@Model`) and **`Recording`** (UI struct) are kept separate — views never touch the database model directly.

---

## Features

- **Record** audio with a single tap; real-time animated waveform visualizes microphone input during recording
- **Pause & Resume** a recording mid-session; recording timer updates continuously
- **Cancel** an in-progress recording to discard it without saving
- **Playback** with a slide-up mini player, seek slider, and play/pause controls
- **Drag to dismiss** the mini player with a native spring gesture
- **Rename** recordings inline — tapping a card title or the edit button opens a focused text field; the list auto-scrolls to keep the card visible above the keyboard
- **Star** recordings for quick filtering
- **Delete** with a confirmation alert and haptic feedback; card animates out on removal
- **Share** any recording via the system share sheet
- **Search** recordings by name with a live-filtered list
- **Filter chips** — All / Shared / Starred (Shared reserved for future use)
- **Microphone permission handling** — permission-denied state shows a dedicated empty screen with a direct deep link to Settings; record button also shows an alert if tapped while permission is denied
- **Staggered list entrance animation** — cards animate in with a spring delay on load
- **Liquid Glass UI** — adopts iOS 26 `glassEffect` on supported devices, falls back gracefully to `ultraThinMaterial` on iOS 17+

---

## Setup

1. Clone the repository
2. Open `AudioVisualizerTest.xcodeproj` in Xcode 16+
3. Select a simulator or device running iOS 17 or later
4. Build and run — no additional dependencies or configuration required

> Microphone permission is required for recording. The app will prompt on first launch.
