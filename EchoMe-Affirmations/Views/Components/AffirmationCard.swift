//
//  AffirmationCard.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AffirmationCard: View {
    let id: String
    let text: String
    @State private var speechManager = SpeechManager()
    @State private var isPlaying = false
    @State private var userVoiceProfile = VoiceProfile.defaultVoiceProfile
    @State private var isAnimatingHeart = false
    @State private var favoritesManager = FavoritesManager.shared
    
    var isFavorite: Bool {
        favoritesManager.isFavorite(id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Button(action: toggleSpeech) {
                    HStack(spacing: 6) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title2)
                        
                        if isPlaying {
                            HStack(spacing: 3) {
                                ForEach(0..<3) { i in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.blue)
                                        .frame(width: 3, height: isPlaying ? 15 : 8)
                                        .animation(
                                            Animation.easeInOut(duration: 0.5)
                                                .repeatForever(autoreverses: true)
                                                .delay(Double(i) * 0.1),
                                            value: isPlaying
                                        )
                                }
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Button(action: toggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .gray)
                        .scaleEffect(isAnimatingHeart ? 1.3 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimatingHeart)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(15)
        .onChange(of: speechManager.isSpeaking) { oldValue, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                isPlaying = newValue && speechManager.currentUtteranceId == id
            }
        }
        .onAppear {
            loadUserVoicePreference()
        }
    }
    
    func toggleSpeech() {
        if isPlaying {
            speechManager.stop()
        } else {
            speechManager.speak(text, id: id, voice: userVoiceProfile)
        }
    }
    
    func loadUserVoicePreference() {
        guard !MockDataProvider.isPreview,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let preferences = data["preferences"] as? [String: Any],
               let voiceName = preferences["voiceProfile"] as? String {
                
                if let voice = VoiceProfile.allProfiles.first(where: { $0.name == voiceName }) {
                    self.userVoiceProfile = voice
                }
            }
        }
    }
    
    func toggleFavorite() {
        // Animate the heart
        isAnimatingHeart = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimatingHeart = false
        }
        
        // Toggle favorite using the manager
        favoritesManager.toggleFavorite(
            affirmationId: id,
            affirmationText: text
        )
    }
}

#Preview {
    AffirmationCard(
        id: "preview",
        text: "I am capable of achieving great things in my life"
    )
    .padding()
}
