//
//  VoiceSettingsView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import SwiftUI
import AVFoundation

struct VoiceSettingsView: View {
    @Environment(\.services) private var services
    @Environment(\.dismiss) private var dismiss
    
    // Access managers through services
    private var authManager: AuthenticationManager { services.authManager }
    private var speechManager: SpeechManager { services.speechManager }
    
    @State private var selectedVoice: String = ""
    @State private var isSaving = false
    @State private var showingSavedAlert = false
    @State private var isPlayingVoice = false
    @State private var currentPlayingProfile: String?

    private let sampleText = "I am confident, capable, and ready to embrace all the wonderful opportunities coming my way."
    
    var body: some View {
        NavigationStack {
            voiceSettingsList
                .navigationTitle("Voice Settings")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear { loadCurrentVoice() }
                .onDisappear { speechManager.stop() }
                .alert("Voice Saved", isPresented: $showingSavedAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Your voice preference has been updated")
                }
        }
    }
    
    // MARK: - View Components
    
    private var voiceSettingsList: some View {
        List {
            voiceOptionsSection
            saveButtonSection
        }
    }
    
    private var voiceOptionsSection: some View {
        Section {
            voiceOptionsList
        } header: {
            Text("Available Voices")
        } footer: {
            Text("Select a voice profile for your daily affirmations")
        }
    }
    
    private var voiceOptionsList: some View {
        ForEach(VoiceProfile.allProfiles, id: \.name) { profile in
            VoiceOptionRow(
                profile: profile,
                isSelected: selectedVoice == profile.name,
                isPlaying: currentPlayingProfile == profile.name && isPlayingVoice,
                onSelect: { selectVoice(profile.name) },
                onPreview: { previewVoice(profile) }
            )
        }
    }
    
    private var saveButtonSection: some View {
        Section {
            saveButton
        }
    }
    
    private var saveButton: some View {
        Button(action: saveVoiceProfile) {
            HStack {
                Text("Save Voice Preference")
                Spacer()
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .disabled(isSaving || !hasChanges)
    }
    
    // MARK: - Computed Properties
    
    private var currentUserVoice: String {
        // First check UserDefaults, then fall back to Firebase preferences
        if let savedVoice = UserDefaults.standard.string(forKey: "selectedVoiceProfile") {
            return savedVoice
        }
        return authManager.userProfile?.preferences.voiceProfile ?? "Calm & Clear"
    }
    
    private var hasChanges: Bool {
        selectedVoice != currentUserVoice
    }
    
    // MARK: - Actions
    
    private func loadCurrentVoice() {
        selectedVoice = currentUserVoice
    }
    
    private func selectVoice(_ voiceName: String) {
        selectedVoice = voiceName
    }
    
    private func previewVoice(_ profile: VoiceProfile) {
        if currentPlayingProfile == profile.name && isPlayingVoice {
            speechManager.stop()
            isPlayingVoice = false
            currentPlayingProfile = nil
        } else {
            speechManager.stop()
            currentPlayingProfile = profile.name
            isPlayingVoice = true
            speechManager.speak(sampleText, voice: profile)
            
            // Reset playing state when speech finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if currentPlayingProfile == profile.name {
                    isPlayingVoice = false
                    currentPlayingProfile = nil
                }
            }
        }
    }
    
    private func saveVoiceProfile() {
        isSaving = true
        
        // Save to UserDefaults immediately for local persistence
        UserDefaults.standard.set(selectedVoice, forKey: "selectedVoiceProfile")
        
        // Also save to Firebase for sync across devices
        Task {
            await performSave()
        }
    }
    
    private func performSave() async {
        do {
            var updatedPreferences = authManager.userProfile?.preferences ?? UserPreferences()
            updatedPreferences.voiceProfile = selectedVoice
            
            try await authManager.updateUserPreferences(updatedPreferences)
            
            await MainActor.run {
                isSaving = false
                showingSavedAlert = true
            }
        } catch {
            print("Error saving voice profile: \(error)")
            await MainActor.run {
                isSaving = false
                // Still show saved alert since we saved to UserDefaults
                showingSavedAlert = true
            }
        }
    }
}

// MARK: - Supporting Views

struct VoiceOptionRow: View {
    let profile: VoiceProfile
    let isSelected: Bool
    let isPlaying: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void
    
    var body: some View {
        HStack {
            voiceInfo
            Spacer()
            playButton
            selectionIndicator
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .padding(.vertical, 4)
    }
    
    private var voiceInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(profile.name)
                .font(.headline)
            
            voiceStats
        }
    }
    
    private var voiceStats: some View {
        HStack {
            Label("\(Int(profile.rate * 100))% speed", systemImage: "speedometer")
            Label("\(Int(profile.pitch * 100))% pitch", systemImage: "waveform")
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
    
    private var playButton: some View {
        Button(action: onPreview) {
            Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle")
                .font(.title2)
                .foregroundColor(isPlaying ? .red : .blue)
        }
        .buttonStyle(.plain)
    }
    
    private var selectionIndicator: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.title2)
            .foregroundColor(isSelected ? .blue : .gray)
    }
}

#Preview {
    NavigationStack {
        VoiceSettingsView()
    }
    .environment(\.services, ServicesContainer.preview)
}
