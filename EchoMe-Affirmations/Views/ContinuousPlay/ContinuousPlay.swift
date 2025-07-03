//
//  ContinuousPlay.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/2/25.
//

//
//  ContinuousPlayView.swift
//  EchoMe-Affirmations
//
//  Created on July 02, 2025.
//

import SwiftUI
import AVFoundation

struct ContinuousPlayView: View {
    @Environment(\.services) private var services
    @Environment(\.dismiss) private var dismiss
    
    @State private var affirmations: [Affirmation] = []
    @State private var currentPlayingIndex: Int? = nil
    @State private var isPlaying = false
    @State private var showingSetup = true
    @State private var preferences = ContinuousPlayPreferences.default
    @State private var isLoading = false
    
    // Audio controls
    @State private var affirmationVolume: Double = 1.0
    @State private var binauralVolume: Double = 0.5
    @State private var melodyVolume: Double = 0.3
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.indigo.opacity(0.8), Color.purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if isLoading {
                    loadingView
                } else if affirmations.isEmpty && !showingSetup {
                    emptyStateView
                } else if !affirmations.isEmpty {
                    continuousPlayContent
                }
            }
            .navigationTitle("Continuous Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        stopPlayback()
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !affirmations.isEmpty {
                        playPauseButton
                    }
                }
            }
            .sheet(isPresented: $showingSetup) {
                ContinuousPlaySetupSheet(
                    preferences: $preferences,
                    onComplete: { prefs in
                        preferences = prefs
                        showingSetup = false
                        Task {
                            await loadAffirmations()
                        }
                    }
                )
            }
        }
        .onAppear {
            if MockDataProvider.isPreview {
                loadMockData()
                showingSetup = false
            }
        }
        .onDisappear {
            stopPlayback()
        }
    }
    
    // MARK: - Views
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Preparing your session...")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.7))
            
            Text("No affirmations loaded")
                .font(.title3)
                .foregroundColor(.white)
            
            Button("Setup Again") {
                showingSetup = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
    }
    
    private var continuousPlayContent: some View {
        VStack(spacing: 0) {
            // Affirmations list
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(affirmations.enumerated()), id: \.element.id) { index, affirmation in
                            ContinuousPlayRow(
                                affirmation: affirmation,
                                isPlaying: currentPlayingIndex == index,
                                index: index
                            )
                            .id(index)
                        }
                    }
                    .padding()
                }
                .onChange(of: currentPlayingIndex) { _, newIndex in
                    if let newIndex = newIndex {
                        withAnimation {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            }
            
            // Audio controls
            audioControlsPanel
        }
    }
    
    private var playPauseButton: some View {
        Button(action: togglePlayback) {
            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .font(.title2)
                .foregroundColor(.white)
        }
    }
    
    private var audioControlsPanel: some View {
        VStack(spacing: 20) {
            // Volume controls
            VStack(spacing: 16) {
                VolumeSlider(
                    title: "Affirmations",
                    value: $affirmationVolume,
                    icon: "speaker.wave.2.fill"
                )
                
                VolumeSlider(
                    title: "Binaural Beats",
                    value: $binauralVolume,
                    icon: "waveform"
                )
                
                VolumeSlider(
                    title: "Background Melody",
                    value: $melodyVolume,
                    icon: "music.note"
                )
            }
            .padding(.horizontal)
            
            // Playback info
            if let currentIndex = currentPlayingIndex {
                Text("Playing \(currentIndex + 1) of \(affirmations.count)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.3))
                )
        )
        .padding()
    }
    
    // MARK: - Actions
    
    private func loadAffirmations() async {
        isLoading = true
        
        let loadedAffirmations = await services.affirmationCacheManager.loadContinuousPlayBatch(
            preferences: preferences
        )
        
        await MainActor.run {
            self.affirmations = loadedAffirmations
            self.isLoading = false
            
            // Auto-start playback
            if !affirmations.isEmpty {
                startPlayback()
            }
        }
    }
    
    private func loadMockData() {
        affirmations = MockDataProvider.shared.getDailyAffirmations().shuffled()
    }
    
    private func togglePlayback() {
        if isPlaying {
            pausePlayback()
        } else {
            startPlayback()
        }
    }
    
    private func startPlayback() {
        isPlaying = true
        currentPlayingIndex = 0
        playCurrentAffirmation()
    }
    
    private func pausePlayback() {
        isPlaying = false
        services.speechManager.stop()
    }
    
    private func stopPlayback() {
        isPlaying = false
        currentPlayingIndex = nil
        services.speechManager.stop()
    }
    
    private func playCurrentAffirmation() {
        guard isPlaying,
              let currentIndex = currentPlayingIndex,
              currentIndex < affirmations.count else { return }
        
        let affirmation = affirmations[currentIndex]
        
        // Configure speech with continuous play settings
        services.speechManager.speakForContinuousPlay(
            affirmation.text,
            completion: playNextAffirmation
        )
    }
    
    private func playNextAffirmation() {
        guard isPlaying else { return }
        
        if let currentIndex = currentPlayingIndex {
            // Simple algorithm for now - just play next
            // Will be enhanced with repetition logic later
            if currentIndex < affirmations.count - 1 {
                currentPlayingIndex = currentIndex + 1
            } else {
                // Loop back to beginning
                currentPlayingIndex = 0
            }
            
            // Add small delay between affirmations
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.playCurrentAffirmation()
            }
        }
    }
}

// MARK: - Continuous Play Row
struct ContinuousPlayRow: View {
    let affirmation: Affirmation
    let isPlaying: Bool
    let index: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Playing indicator
            if isPlaying {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                    .transition(.scale)
            } else {
                Text("\(index + 1)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 24)
            }
            
            // Affirmation text
            Text(affirmation.text)
                .font(.body)
                .foregroundColor(isPlaying ? .white : .white.opacity(0.8))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Categories
            if !affirmation.categories.isEmpty {
                Text(affirmation.categories.first ?? "")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isPlaying ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
        )
        .animation(.easeInOut(duration: 0.3), value: isPlaying)
    }
}

// MARK: - Volume Slider
struct VolumeSlider: View {
    let title: String
    @Binding var value: Double
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 100, alignment: .leading)
            
            Slider(value: $value, in: 0...1)
                .tint(.white)
            
            Text("\(Int(value * 100))%")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 40)
        }
    }
}

// MARK: - Preview
#Preview {
    ContinuousPlayView()
        .environment(\.services, ServicesContainer.previewWithMockData)
}
