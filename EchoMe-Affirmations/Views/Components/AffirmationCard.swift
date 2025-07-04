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
    @Environment(\.services) private var services
    
    // Access managers through services
    private var authManager: AuthenticationManager { services.authManager }
    private var favoritesManager: FavoritesManager { services.favoritesManager }
    private var speechManager: SpeechManager { services.speechManager }
    
    let id: String
    let text: String
    
    @State private var isAnimatingHeart = false
    @State private var userVoiceProfile: VoiceProfile?
    
    var body: some View {
        GlassCard(material: .regularMaterial) {
            VStack {
                affirmationText
                actionButtons
            }
        }
    }
    
    // MARK: - View Components
    
    private var affirmationText: some View {
        Text(text)
            .font(.body)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var actionButtons: some View {
        HStack {
            playButton
            Spacer()
            shareButton
            favoriteButton
        }
    }
    
    private var playButton: some View {
        Button(action: toggleSpeech) {
            HStack(spacing: 6) {
                Image(systemName: playButtonIcon)
                Text(playButtonText)
                    .font(.caption)
            }
            .foregroundColor(.blue)
        }
        .buttonStyle(.plain)
    }
    
    private var shareButton: some View {
        Button(action: share) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 20))
                .foregroundColor(.gray)
        }
        .buttonStyle(.plain)
    }
    
    private var favoriteButton: some View {
        Button(action: toggleFavorite) {
            Image(systemName: favoriteIcon)
                .font(.system(size: 22))
                .foregroundColor(favoriteColor)
                .scaleEffect(heartScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimatingHeart)
        }
        .buttonStyle(.plain)
    }
    
    private var cardBackground: some View {
        Color(.systemBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Computed Properties
    
    private var isCurrentlyPlaying: Bool {
        speechManager.isSpeaking && speechManager.currentUtteranceId == id
    }
    
    private var playButtonIcon: String {
        isCurrentlyPlaying ? "stop.circle.fill" : "play.circle.fill"
    }
    
    private var playButtonText: String {
        isCurrentlyPlaying ? "Stop" : "Play"
    }
    
    private var isFavorite: Bool {
        favoritesManager.isFavorite(id)
    }
    
    private var favoriteIcon: String {
        isFavorite ? "heart.fill" : "heart"
    }
    
    private var favoriteColor: Color {
        isFavorite ? .red : .gray
    }
    
    private var heartScale: CGFloat {
        isAnimatingHeart ? 1.2 : 1.0
    }
    
    // MARK: - Actions
    
    private func toggleSpeech() {
        if isCurrentlyPlaying {
            speechManager.stop()
        } else {
            speak()
        }
    }
    
    private func speak() {
        let voiceProfile = userVoiceProfile ?? VoiceProfile.defaultVoiceProfile
        speechManager.speak(text, voice: voiceProfile)
    }
    
    private func share() {
        ShareHelper.share(text: text)
    }
    
    private func loadUserVoiceProfile() {
        // 1. First check UserDefaults
        if let savedVoiceProfileName = UserDefaults.standard.string(forKey: "selectedVoiceProfile") {
            if let profile = VoiceProfile.allProfiles.first(where: { $0.name == savedVoiceProfileName }) {
                userVoiceProfile = profile
                return
            }
        }
        
        // 2. Then check Firebase user preferences
        if let voiceProfileName = authManager.userProfile?.preferences.voiceProfile {
            if let profile = VoiceProfile.allProfiles.first(where: { $0.name == voiceProfileName }) {
                userVoiceProfile = profile
                return
            }
        }
        
        // 3. Fall back to default
        userVoiceProfile = VoiceProfile.defaultVoiceProfile
    }
    
    private func toggleFavorite() {
        animateHeart()
        favoritesManager.toggleFavorite(affirmationId: id, affirmationText: text)
    }
    
    private func animateHeart() {
        isAnimatingHeart = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimatingHeart = false
        }
    }
}

// MARK: - Helper

struct ShareHelper {
    static func share(text: String) {
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else { return }
        
        rootVC.present(activityVC, animated: true)
    }
}

#Preview {
    AffirmationCard(
        id: "preview",
        text: "I am capable of achieving great things in my life"
    )
    .padding()
    .environment(\.services, ServicesContainer.preview)
}
