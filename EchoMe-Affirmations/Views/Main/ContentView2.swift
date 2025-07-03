//
//  ContentView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 6/30/25.
//
/*
import SwiftUI

struct ContentView2: View {
    @Environment(\.services) private var services
    
    @State private var affirmations: [Affirmation] = []
    @State private var currentIndex = 0
    @State private var userCategories: [String] = []
    @State private var isOffline = false
    @State private var showingContinuousPlay = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Full screen affirmations
                if !affirmations.isEmpty {
                    affirmationPageView
                } else if services.affirmationCacheManager.isLoading && affirmations.isEmpty {
                    loadingView
                } else {
                    emptyStateView
                }
                
                // Floating menu overlay
                VStack {
                    HStack {
                        Spacer()
                        FloatingMenuButton()
                            .padding(.trailing, 20)
                    }
                    .padding(.top, 60) // Account for status bar
                    Spacer()
                }
            }
            .ignoresSafeArea()
            .preferredColorScheme(.dark) // Force white status bar icons
            .onAppear { setupView() }
            .onDisappear { services.favoritesManager.stopListening() }
            .onChange(of: currentIndex) { _, newIndex in
                checkForMoreAffirmations(at: newIndex)
            }
            .fullScreenCover(isPresented: $showingContinuousPlay) {
                ContinuousPlayView()
            }
        }
        .environment(\.showingContinuousPlay, $showingContinuousPlay)
    }
    
    // MARK: - Views
    
    private var affirmationPageView: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(affirmations.enumerated()), id: \.element.id) { index, affirmation in
                FullScreenAffirmationView(
                    affirmation: affirmation,
                    isFavorite: services.favoritesManager.isFavorite(affirmation.id),
                    onFavoriteToggle: { toggleFavorite(affirmation) },
                    onSpeak: { speakAffirmation(affirmation) },
                    onShare: { shareAffirmation(affirmation) },
                    isOffline: isOffline && index == affirmations.count - 1
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
    }
    
    private var loadingView: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Loading affirmations...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .ignoresSafeArea()
    }
    
    private var emptyStateView: some View {
        ZStack {
            Color.gray.opacity(0.1)
            
            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("No affirmations found")
                    .font(.title3)
                    .foregroundColor(.gray)
                
                Text("Try updating your preferences")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        loadUserPreferences()
        loadCachedAffirmations()
        services.favoritesManager.startListening()
        
        Task {
            await loadAffirmations()
        }
    }
    
    private func loadUserPreferences() {
        if let preferences = services.authManager.userProfile?.preferences {
            userCategories = preferences.categories
        }
    }
    
    private func loadCachedAffirmations() {
        // Show cached affirmations immediately
        if !services.affirmationCacheManager.currentBatch.isEmpty {
            affirmations = services.affirmationCacheManager.currentBatch
            sendAffirmationsToWatch()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadAffirmations() async {
        if MockDataProvider.isPreview {
            // Use mock data in preview
            await MainActor.run {
                self.affirmations = MockDataProvider.shared.getDailyAffirmations()
                sendAffirmationsToWatch()
            }
            return
        }
        
        await services.affirmationCacheManager.loadBatch(
            categories: userCategories,
            forceRefresh: false
        )
        
        await MainActor.run {
            self.affirmations = services.affirmationCacheManager.currentBatch
            self.isOffline = false
            
            if !affirmations.isEmpty {
                sendAffirmationsToWatch()
            }
        }
    }
    
    private func checkForMoreAffirmations(at index: Int) {
        Task {
            await services.affirmationCacheManager.checkAndLoadMore(
                currentIndex: index,
                categories: userCategories
            )
            
            await MainActor.run {
                // Update if we have more affirmations
                let newBatch = services.affirmationCacheManager.currentBatch
                if newBatch.count > affirmations.count {
                    affirmations = newBatch
                } else if index >= affirmations.count - 1 {
                    // We've reached the end and couldn't load more
                    isOffline = true
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleFavorite(_ affirmation: Affirmation) {
        // Optimistic UI - toggle immediately
        services.favoritesManager.toggleFavoriteOptimistic(
            affirmationId: affirmation.id,
            affirmationText: affirmation.text
        )
    }
    
    private func speakAffirmation(_ affirmation: Affirmation) {
        services.speechManager.speak(affirmation.text)
        print("🔊 Debug ContentView - Saved voice: \(UserDefaults.standard.string(forKey: "selectedVoiceProfile") ?? "nil")")
        print("🔊 Debug ContentView - User profile voice: \(services.authManager.userProfile?.preferences.voiceProfile ?? "nil")")
    }
    
    private func shareAffirmation(_ affirmation: Affirmation) {
        ShareHelper.share(text: affirmation.text)
    }
    
    private func sendAffirmationsToWatch() {
        print("📱 Sending \(affirmations.count) affirmations to watch")
        services.watchConnectivityManager.sendAffirmationsToWatch(affirmations)
    }
}

// MARK: - Environment Key for Continuous Play
private struct ShowingContinuousPlayKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var showingContinuousPlay: Binding<Bool> {
        get { self[ShowingContinuousPlayKey.self] }
        set { self[ShowingContinuousPlayKey.self] = newValue }
    }
}

// MARK: - Full Screen Affirmation View
struct FullScreenAffirmationView: View {
    let affirmation: Affirmation
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    let onSpeak: () -> Void
    let onShare: () -> Void
    let isOffline: Bool
    
    @State private var isAnimatingHeart = false
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
            
            // Content
            VStack {
                Spacer()
                
                // Affirmation text
                Text(affirmation.text)
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
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
                            scale: isAnimatingHeart ? 1.3 : 1.0
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
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
                            onSpeak()
                        }
                        
                        // Share button
                        ActionButton(
                            icon: "square.and.arrow.up",
                            color: .white
                        ) {
                            onShare()
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                }
            }
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
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let color: Color
    var scale: CGFloat = 1.0
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .scaleEffect(scale)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environment(\.services, ServicesContainer.previewWithMockData)
}
*/
