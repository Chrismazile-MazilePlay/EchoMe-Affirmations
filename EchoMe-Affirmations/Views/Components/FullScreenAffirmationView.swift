//
//  FullScreenAffirmationView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/3/25.
//

import SwiftUI

// MARK: - Full Screen Affirmation View
struct FullScreenAffirmationView: View {
    @Environment(\.services) private var services
    
    let affirmation: Affirmation
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    let isOffline: Bool
    
    @State private var isAnimatingHeart = false
    @State private var userVoiceProfile: VoiceProfile?
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
            
            // Content
            VStack {
                Spacer()
                
                // Affirmation text
                Text(affirmation.text)
                    .font(.system(size: AppConstants.UI.affirmationFontSize, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppConstants.UI.largePadding)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                
                Spacer()
                
                // Offline indicator
                if isOffline {
                    VStack(spacing: 10) {
                        Image(systemName: "wifi.slash")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("End of feed - Check your connection")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.bottom, 30)
                }
            }
            
            // Action buttons overlay
            VStack {
                Spacer()
                
                HStack(alignment: .bottom, spacing: 20) {
                    Spacer()
                    
                    VStack(spacing: 25) {
                        // Favorite button
                        ActionButton(
                            icon: isFavorite ? "heart.fill" : "heart",
                            color: isFavorite ? .red : .white,
                            scale: isAnimatingHeart ? AppConstants.UI.heartAnimationScale : 1.0
                        ) {
                            withAnimation(.spring(response: AppConstants.UI.animationDuration, dampingFraction: 0.6)) {
                                isAnimatingHeart = true
                                onFavoriteToggle()
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isAnimatingHeart = false
                            }
                        }
                        
                        // Speak button
                        ActionButton(
                            icon: "speaker.wave.2.fill",
                            color: .white
                        ) {
                            speakAffirmation()
                        }
                        
                        // Share button
                        ActionButton(
                            icon: "square.and.arrow.up",
                            color: .white
                        ) {
                            shareAffirmation()
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, AppConstants.UI.bottomActionsPadding)
                }
            }
        }
        .onAppear {
            loadUserVoiceProfile()
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: backgroundColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var backgroundColors: [Color] {
        // Generate colors based on affirmation ID for variety
        let hash = affirmation.id.hashValue
        let hue = Double(abs(hash) % 360) / 360.0
        
        return [
            Color(hue: hue, saturation: 0.7, brightness: 0.8),
            Color(hue: (hue + 0.2).truncatingRemainder(dividingBy: 1.0), saturation: 0.6, brightness: 0.6)
        ]
    }
    
    // MARK: - Actions
    
    private func loadUserVoiceProfile() {
        // 1. First check UserDefaults
        if let savedVoiceProfileName = UserDefaults.standard.string(forKey: "selectedVoiceProfile") {
            if let profile = VoiceProfile.allProfiles.first(where: { $0.name == savedVoiceProfileName }) {
                userVoiceProfile = profile
                return
            }
        }
        
        // 2. Then check Firebase user preferences
        if let voiceProfileName = services.authManager.userProfile?.preferences.voiceProfile {
            if let profile = VoiceProfile.allProfiles.first(where: { $0.name == voiceProfileName }) {
                userVoiceProfile = profile
                return
            }
        }
        
        // 3. Fall back to default
        userVoiceProfile = VoiceProfile.defaultVoiceProfile
    }
    
    private func speakAffirmation() {
        let voiceProfile = userVoiceProfile ?? VoiceProfile.defaultVoiceProfile
        services.speechManager.speak(affirmation.text, voice: voiceProfile)
    }
    
    private func shareAffirmation() {
        ShareHelper.share(text: affirmation.text)
    }
}
