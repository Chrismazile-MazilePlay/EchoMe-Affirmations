//
//  VoiceSettingsView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import SwiftUI

struct VoiceSettingsView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @State private var selectedVoice: String = ""
    @State private var isSaving = false
    @State private var showingSavedAlert = false
    @State private var speechManager = SpeechManager()
    
    private let sampleText = "I am confident, capable, and ready to embrace all the wonderful opportunities coming my way."
    
    var body: some View {
        NavigationStack {
            voiceSettingsList
                .navigationTitle("Voice Settings")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear { loadCurrentVoice() }
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
        authManager.userProfile?.preferences.voiceProfile ?? "Calm & Clear"
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
        speechManager.speak(sampleText, voice: profile)
    }
    
    private func saveVoiceProfile() {
        isSaving = true
        
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
            }
        }
    }
}

// MARK: - Supporting Views

struct VoiceOptionRow: View {
    let profile: VoiceProfile
    let isSelected: Bool
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
            Image(systemName: "play.circle")
                .font(.title2)
                .foregroundColor(.blue)
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
    .environment(AuthenticationManager.previewAuthenticated)
}
