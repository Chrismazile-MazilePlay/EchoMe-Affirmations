//
//  VoiceSettingsView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// Voice Settings View with persistence
struct VoiceSettingsView: View {
    @State private var selectedVoice = VoiceProfile.defaultVoiceProfile
    @State private var speechManager = SpeechManager()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section("Choose Voice") {
                ForEach(VoiceProfile.allProfiles, id: \.name) { voice in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(voice.name)
                                .font(.body)
                        }
                        
                        Spacer()
                        
                        if voice.name == selectedVoice.name {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedVoice = voice
                        saveVoicePreference(voice)
                    }
                }
            }
            
            Section("Preview") {
                VStack(spacing: 15) {
                    Text("Tap to hear a sample with the selected voice")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button(action: playPreview) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                            Text("Play Sample")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Voice Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadVoicePreference()
        }
    }
    
    func saveVoicePreference(_ voice: VoiceProfile) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "preferences.voiceProfile": voice.name
        ]) { error in
            if let error = error {
                print("Error saving voice preference: \(error)")
            }
        }
    }
    
    func loadVoicePreference() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let preferences = data["preferences"] as? [String: Any],
               let voiceName = preferences["voiceProfile"] as? String {
                
                if let voice = VoiceProfile.allProfiles.first(where: { $0.name == voiceName }) {
                    self.selectedVoice = voice
                }
            }
        }
    }
    
    func playPreview() {
        speechManager.speak(
            "I am confident and capable of achieving my goals. This is how your affirmations will sound.",
            id: "preview",
            voice: selectedVoice
        )
    }
}

#Preview {
    NavigationStack {
        VoiceSettingsView()
    }
} 
