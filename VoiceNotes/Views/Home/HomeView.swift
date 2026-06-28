//
//  HomeView.swift
//  AudioVisualizerTest
//
//  Created by S O B I N on 22/06/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {

    // MARK: - Environment & Coordinator

    @Environment(\.modelContext) private var modelContext
    @StateObject private var coordinator = AudioCoordinator()

    // MARK: - Search & Filter State

    @State private var searchStr: String = ""
    @State private var showStarredOnly = false
    @State private var showSharedOnly = false   // placeholder — filter logic to be added
    @State private var showAll: Bool = true     // placeholder — filter logic to be added
    @State private var listID = UUID()

    // MARK: - Alert State

    @State private var showAlert: Bool = false
    @State private var msg: String = ""

    // MARK: - Focus

    @FocusState private var isSearchFocused: Bool

    // MARK: - Computed Properties

    private var filteredRecordings: [Recording] {
        let search = searchStr.trimmingCharacters(in: .whitespacesAndNewlines)

        return coordinator.recordings.filter { recording in
            let matchesSearch = search.isEmpty ||
                recording.displayName.localizedCaseInsensitiveContains(search)
            let matchesStar = !showStarredOnly || recording.isStarred
            return matchesSearch && matchesStar
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {

                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 10) {
                    searchBar
                    filterChipLayer
                    listOrEmptyStateLayer
                }
                .safeAreaPadding(.bottom, 20)

                if coordinator.selectedRecording != nil {
                    MiniPlayerView(
                        player: coordinator.player,
                        coordinator: coordinator
                    )
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        )
                    )
                    .zIndex(1)
                }
            }
            .ignoresSafeArea(.keyboard)
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Voice Notes")
            .animation(
                .spring(response: 0.45, dampingFraction: 0.82),
                value: coordinator.selectedRecording
            )
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    HStack(spacing: 10) {
                        Button {
                            print("Plus clicked")
                            msg = "Plus"
                            showAlert = true
                        } label: {
                            Image(systemName: "plus")
                        }

                        Button {
                            print("Calender clicked")
                            msg = "Calender"
                            showAlert = true
                        } label: {
                            Image(systemName: "calendar")
                        }

                        Button {
                            print("Settings clicked")
                            msg = "Settings"
                            showAlert = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                    .tint(Color(.gray))
                    .padding(.horizontal, 8)
                }
            }
        }
        .task {
            coordinator.setup(modelContext: modelContext)
        }
        .onAppear {
            coordinator.requestPermission()
        }
        .alert("Alert", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(msg) - Not Implemented")
        }
    }

    // MARK: - List / Empty State Layer

    /// Switches between the recording list, an empty-recordings notice,
    /// and a full permission-denied screen depending on app state.
    @ViewBuilder
    private var listOrEmptyStateLayer: some View {
        ZStack(alignment: .bottom) {
            if coordinator.recorder.state == .permissionDenied && coordinator.recordings.isEmpty {
                // Full screen — permission denied with no existing recordings
                permissionDeniedEmptyState

            } else if coordinator.recordings.isEmpty {
                // Permission is fine, but no recordings have been made yet
                noRecordingsEmptyState

            } else {
                // Normal list
                recordingList
            }

            RecordButtonView(recorder: coordinator.recorder)
                .frame(maxWidth: .infinity)
                .padding()
        }
    }

    // MARK: - Recording List

    private var recordingList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(
                        Array(filteredRecordings.enumerated()),
                        id: \.element.id
                    ) { index, recording in
                        AnimatedCardWrapper(index: index) {
                            RecordingCardView(
                                recording: recording,
                                coordinator: coordinator,
                                scrollProxy: proxy,
                                playAction: {
                                    coordinator.playRecording(recording)
                                },
                                renameAction: { newName in
                                    coordinator.renameRecording(recording, newName: newName)
                                },
                                deleteAction: {
                                    print("dlt clicked")
                                    coordinator.deleteRecording(recording)
                                },
                                starAction: {
                                    coordinator.toggleStar(recording)
                                },
                                shareAction: {
                                    print("Call sheet internally")
                                }
                            )
                            .id(recording.id)
                        }
                    }
                }
                .padding(.bottom, 300)
                .id(listID)
                .onChange(of: showStarredOnly) { _, _ in listID = UUID() }
                .onChange(of: showSharedOnly)  { _, _ in listID = UUID() }
                .onChange(of: searchStr)       { _, _ in listID = UUID() }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    // MARK: - Empty State: No Recordings

    private var noRecordingsEmptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "waveform")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(.secondary)

            Text("No Recordings Yet")
                .font(.title3.weight(.semibold))

            Text("Tap Record below to capture your first audio.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State: Permission Denied

    private var permissionDeniedEmptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "mic.slash.fill")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(.red.opacity(0.8))

            Text("Microphone Access Required")
                .font(.title3.weight(.semibold))

            Text("AudioVisualizerTest needs microphone access to record audio. Please enable it in Settings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Open Settings", systemImage: "gear")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding(.top, 4)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search", text: $searchStr)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        if isSearchFocused {
                            Button("Cancel") {
                                searchStr = ""
                                isSearchFocused = false
                            }
                            .foregroundStyle(.secondary)

                            Spacer()

                            Button("Done") {
                                isSearchFocused = false
                            }
                            .fontWeight(.semibold)
                        }
                    }
                }

            Button {
                if searchStr.isEmpty {
                    print("Clicked AI")
                    msg = "Ask AI"
                    showAlert = true
                } else {
                    searchStr = ""
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: searchStr.isEmpty
                          ? "brain.filled.head.profile"
                          : "xmark.circle.fill")
                        .contentTransition(.symbolEffect(.replace))
                        .symbolRenderingMode(.hierarchical)

                    if searchStr.isEmpty {
                        Text("Ask AI")
                            .transition(.opacity)
                    }
                }
                .font(.system(size: 14.5, weight: .semibold))
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color(.systemBackground))
                )
            }
            .frame(minHeight: 40)
            .buttonStyle(ShrinkButtonStyle())
            .appGlass()
            .animation(.smooth(duration: 0.3), value: searchStr.isEmpty)
        }
        .padding(8)
        .padding(.leading, 8)
        .background(
            Capsule()
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Filter Chip Layer

    private var filterChipLayer: some View {
        HStack(alignment: .top, spacing: 8) {
            ChipButton(
                btnAction: {
                    showAll.toggle()
                    showSharedOnly = false
                    showStarredOnly = false
                },
                btnName: "All",
                isActive: showAll
            )

            ChipButton(
                btnAction: {
                    showSharedOnly.toggle()
                    showAll = false
                    showStarredOnly = false
                },
                btnName: "Shared",
                isActive: showSharedOnly
            )

            ChipButton(
                btnAction: {
                    showStarredOnly.toggle()
                    showAll = false
                    showSharedOnly = false
                },
                btnName: "Starred",
                isActive: showStarredOnly
            )
        }
        .tint(Color(.darkGray))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 15)
    }
}

// MARK: - ChipButton

/// Reusable filter chip used in the HomeView filter row.
private struct ChipButton: View {

    let btnAction: () -> Void
    let btnName: String
    let isActive: Bool

    var body: some View {
        Button {
            btnAction()
        } label: {
            Text(btnName)
                .font(.subheadline)
                .foregroundStyle(isActive ? Color(.black) : Color(.darkGray))
                .padding(.vertical, 5)
                .padding(.horizontal, 14)
                .background(
                    Capsule()
                        .fill(Color(.systemGray6))
                )
                .overlay {
                    Capsule()
                        .stroke(Color(.systemBlue), lineWidth: isActive ? 1 : 0)
                }
        }
        .buttonStyle(ShrinkButtonStyle())
    }
}

// MARK: - Previews

#Preview {
    HomeView()
        .modelContainer(for: RecordingMeta.self)
}

#Preview("Chip") {
    ChipButton(btnAction: {
        print("chip clicked")
    }, btnName: "Test Chip", isActive: true)
}
