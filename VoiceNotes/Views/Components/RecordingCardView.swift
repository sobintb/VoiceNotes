//
//  RecordingCardView.swift
//  AudioVisualizerTest
//
//  Created by S O B I N on 21/06/26.
//

import SwiftUI

struct RecordingCardView: View {

    let recording: Recording
    @ObservedObject var coordinator: AudioCoordinator
    let scrollProxy: ScrollViewProxy

    let playAction: () -> Void
    let renameAction: (String) -> Void
    let deleteAction: () -> Void
    let starAction: () -> Void
    let shareAction: () -> Void

    // MARK: - Inline Edit State

    @State private var isEditing = false
    @State private var editedName = ""
    @FocusState private var isFocused: Bool

    // MARK: - Delete Animation State

    @State private var isDeleting = false
    @State private var showDeleteAlert = false
    @State private var showShareSheet = false

    // MARK: - Derived State

    /// Live lookup — always reflects the current starred state from the source of truth.
    private var isStarred: Bool {
        coordinator.recordings.first { $0.id == recording.id }?.isStarred ?? false
    }

    private var isPlaying: Bool {
        coordinator.selectedRecording?.id == recording.id && coordinator.player.isPlaying
    }

    // MARK: - Body

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 12) {

                // Date stamp
                Text(
                    recording.createdDate,
                    format: .dateTime.month().day().hour().minute()
                )
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

                // MARK: Title Row (display or inline edit)
                HStack {
                    if isEditing {
                        TextField("Recording name", text: $editedName)
                            .font(.system(size: 16, weight: .semibold))
                            .focused($isFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                commitRename()
                            }
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Button("Cancel") {
                                        cancelEditing()
                                    }
                                    .foregroundStyle(.secondary)

                                    Spacer()

                                    Button("Done") {
                                        commitRename()
                                    }
                                    .fontWeight(.semibold)
                                }
                            }
                    } else {
                        Text(recording.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .onTapGesture {
                                startEditing()
                            }
                    }

                    Spacer()

                    if isEditing {
                        Button("Done") {
                            commitRename()
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            Capsule()
                                .fill(Color(.blue))
                        )
                    }
                }
                .frame(minHeight: 30)

                // MARK: Action Row
                HStack {

                    // Play / pause button with duration label
                    Button {
                        if isPlaying {
                            coordinator.player.pausePlayback()
                        } else {
                            playAction()
                        }
                    } label: {
                        Label(
                            formatTime(recording.duration),
                            systemImage: isPlaying ? "pause.fill" : "play.fill"
                        )
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .contentTransition(.symbolEffect(.replace))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color(.secondarySystemBackground))
                        )
                        .overlay {
                            Capsule()
                                .stroke(Color(.blue), lineWidth: isPlaying ? 1 : 0)
                        }
                    }
                    .buttonStyle(ShrinkButtonStyle())

                    Spacer()

                    HStack(spacing: 10) {

                        // Star button
                        RoundedButton(
                            action: {
                                starAction()
                                print("Star Clicked")
                            },
                            isActive: isStarred,
                            sysImgName: "star",
                            changeSysImgname: "star.fill"
                        )
                        .tint(isStarred ? Color(.systemBlue) : .black)

                        // Rename / edit button
                        RoundedButton(
                            action: {
                                print("edit icon clicked")
                                startEditing()
                            },
                            isActive: nil,
                            sysImgName: "pencil.and.outline",
                            changeSysImgname: nil
                        )
                        .buttonStyle(.plain)

                        // Share button
                        RoundedButton(
                            action: {
                                print("share icon clicked")
                                showShareSheet = true
                            },
                            isActive: nil,
                            sysImgName: "paperplane",
                            changeSysImgname: nil
                        )
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showShareSheet) {
                            ShareSheet(url: recording.url)
                                .presentationDetents([.medium, .large])
                        }

                        // More options menu
                        Menu {
                            Button("Rename") {
                                startEditing()
                            }

                            Button("Share") {
                                showShareSheet = true
                            }

                            Button("Delete", role: .destructive) {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.prepare()
                                impact.impactOccurred()
                                showDeleteAlert = true
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.callout)
                                .frame(width: 31, height: 31)
                                .background(
                                    Circle()
                                        .fill(Color(.secondarySystemBackground))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 10)

            Divider()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))

        // MARK: Delete Animation
        .scaleEffect(isDeleting ? 0.95 : 1.0)
        .opacity(isDeleting ? 0 : 1)
        .frame(maxHeight: isDeleting ? 0 : .infinity)
        .clipped()

        // Tap outside the card to cancel editing
        .onTapGesture {
            if isEditing {
                cancelEditing()
            }
        }
        .alert("Delete Recording?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                triggerDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\"\(recording.displayName)\" will be permanently deleted.")
        }
    }

    // MARK: - Edit Helpers

    private func startEditing() {
        editedName = recording.displayName
        isEditing = true

        // Show keyboard first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isFocused = true
        }

        // Wait for keyboard animation to finish, then scroll card into view
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeInOut(duration: 0.25)) {
                scrollProxy.scrollTo(recording.id, anchor: UnitPoint(x: 0.5, y: 0.2))
            }
        }
    }

    private func commitRename() {
        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && trimmed != recording.displayName {
            renameAction(trimmed)
        }
        isEditing = false
        isFocused = false
    }

    private func cancelEditing() {
        isEditing = false
        isFocused = false
        editedName = ""
    }

    // MARK: - Delete

    private func triggerDelete() {
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.prepare()
        impact.impactOccurred()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isDeleting = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            deleteAction()
        }
    }
}

// MARK: - RoundedButton

/// Reusable circular icon button used in the RecordingCardView action row.
/// Supports optional toggling between two system images based on `isActive`.
private struct RoundedButton: View {

    let action: () -> Void
    let isActive: Bool?
    let sysImgName: String
    let changeSysImgname: String?

    var body: some View {
        Button {
            action()
        } label: {
            if let active = isActive, let changeImgTo = changeSysImgname {
                Image(systemName: active ? changeImgTo : sysImgName)
                    .font(.callout)
                    .frame(width: 31, height: 31)
                    .background(Circle().fill(Color(.secondarySystemBackground)))
                    .contentTransition(.symbolEffect(.replace))
            } else {
                Image(systemName: sysImgName)
                    .font(.callout)
                    .frame(width: 31, height: 31)
                    .background(Circle().fill(Color(.secondarySystemBackground)))
                    .contentTransition(.symbolEffect(.replace))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollViewReader { proxy in
        RecordingCardView(
            recording: .preview,
            coordinator: AudioCoordinator(),
            scrollProxy: proxy,
            playAction: { print("play") },
            renameAction: { _ in print("rename") },
            deleteAction: { print("delete") },
            starAction: { print("starred") },
            shareAction: { print("share") }
        )
    }
}
