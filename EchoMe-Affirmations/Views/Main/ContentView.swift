//
//  ContentView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 6/30/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.services) private var services
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    @State private var affirmations: [Affirmation] = []
    @State private var currentIndex = 0
    @State private var errorMessage: String?
    @State private var userCategories: [String] = []
    
    // MARK: - Computed Properties
    private var currentAffirmation: Affirmation? {
        guard !affirmations.isEmpty && currentIndex < affirmations.count else { return nil }
        return affirmations[currentIndex]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Daily Affirmations")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        NavigationLink(destination: ProfileView()) {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 50)
                    
                    // Main content
                    if !affirmations.isEmpty {
                        // Affirmation cards
                        TabView(selection: $currentIndex) {
                            ForEach(Array(affirmations.enumerated()), id: \.element.id) { index, affirmation in
                                AffirmationCard(
                                    affirmation: affirmation,
                                    isFavorite: services.favoritesManager.favoriteIds.contains(affirmation.id),
                                    onFavoriteToggle: { toggleFavorite(affirmation) },
                                    onSpeak: { speakAffirmation(affirmation) }
                                )
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .animation(.easeInOut, value: currentIndex)
                        
                        // Page indicators
                        HStack(spacing: 8) {
                            ForEach(0..<min(affirmations.count, 10), id: \.self) { index in
                                Circle()
                                    .fill(index == currentIndex % 10 ? Color.white : Color.white.opacity(0.5))
                                    .frame(width: 8, height: 8)
                                    .animation(.easeInOut, value: currentIndex)
                            }
                        }
                        .padding(.vertical, 20)
                        
                    } else if services.affirmationCache.isLoading {
                        // Loading state
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("Loading affirmations...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                    } else {
                        // Empty state
                        EmptyStateView()
                    }
                    
                    // Navigation buttons
                    HStack(spacing: 50) {
                        // Favorites button
                        NavigationLink(destination: FavoritesView()) {
                            VStack {
                                Image(systemName: "heart.fill")
                                    .font(.title2)
                                Text("Favorites")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                        }
                        
                        // Refresh button
                        Button(action: refreshAffirmations) {
                            VStack {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title2)
                                Text("Refresh")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                        }
                        
                        // Settings button
                        NavigationLink(destination: VoiceSettingsView()) {
                            VStack {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                Text("Settings")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .onAppear {
            setupView()
        }
        .onDisappear {
            services.favoritesManager.stopListening()
        }
        .onChange(of: services.authManager.userProfile?.preferences.categories) { _, newCategories in
            if let categories = newCategories {
                userCategories = categories
                Task {
                    await loadAffirmations(forceRefresh: true)
                }
            }
        }
    }
    
    // MARK: - Setup
    private func setupView() {
        // Load user preferences
        if let preferences = services.authManager.userProfile?.preferences {
            userCategories = preferences.categories
        }
        
        // Use cached affirmations immediately if available
        if !services.affirmationCache.cachedAffirmations.isEmpty {
            affirmations = services.affirmationCache.cachedAffirmations
            sendAffirmationsToWatch()
        }
        
        // Start listeners
        services.favoritesManager.startListening()
        
        // Load/refresh affirmations in background
        Task {
            await loadAffirmations()
        }
    }
    
    // MARK: - Data Loading
    private func loadAffirmations(forceRefresh: Bool = false) async {
        await services.affirmationCache.loadAffirmations(
            categories: userCategories,
            forceRefresh: forceRefresh
        )
        
        // Update UI with fresh data
        await MainActor.run {
            self.affirmations = services.affirmationCache.cachedAffirmations
            
            // Send to watch
            if !affirmations.isEmpty {
                sendAffirmationsToWatch()
            }
        }
    }
    
    // MARK: - Actions
    private func refreshAffirmations() {
        Task {
            await loadAffirmations(forceRefresh: true)
        }
    }
    
    private func toggleFavorite(_ affirmation: Affirmation) {
        Task {
            do {
                if services.favoritesManager.favoriteIds.contains(affirmation.id) {
                    try await services.favoritesManager.toggleFavorite(affirmationId: affirmation.id, affirmationText: affirmation.text)
                }
            } catch {
                errorMessage = "Failed to update favorite: \(error.localizedDescription)"
            }
        }
    }
    
    private func speakAffirmation(_ affirmation: Affirmation) {
        services.speechManager.speak(affirmation.text)
    }
    
    // MARK: - Watch Connectivity
    private func sendAffirmationsToWatch() {
        print("📱 Sending \(affirmations.count) affirmations to watch")
        services.watchConnectivityManager.sendAffirmationsToWatch(affirmations)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environment(\.services, ServicesContainer.previewWithMockData)
        .modelContainer(for: CachedAffirmation.self, inMemory: true)
}
