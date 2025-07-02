//
//  ContentView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 6/30/25.
//

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
                backgroundGradient
                
                VStack(spacing: 0) {
                    headerView
                    mainContent
                    bottomNavigation
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .onAppear { setupView() }
        .onDisappear { services.favoritesManager.stopListening() }
        .onChange(of: services.authManager.userProfile?.preferences.categories) { _, newCategories in
            handleCategoriesChange(newCategories)
        }
    }
    
    // MARK: - View Components
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var headerView: some View {
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
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if !affirmations.isEmpty {
            VStack(spacing: 0) {
                affirmationCarousel
                pageIndicators
            }
        } else if services.affirmationCache.isLoading {
            loadingView
        } else {
            EmptyStateView()
        }
    }
    
    private var affirmationCarousel: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(affirmations.enumerated()), id: \.element.id) { index, affirmation in
                AffirmationCard(id: affirmation.id, text: affirmation.text)
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: currentIndex)
    }
    
    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<min(affirmations.count, 10), id: \.self) { index in
                Circle()
                    .fill(index == currentIndex % 10 ? Color.white : Color.white.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut, value: currentIndex)
            }
        }
        .padding(.vertical, 20)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Loading affirmations...")
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var bottomNavigation: some View {
        HStack(spacing: 50) {
            NavigationLink(destination: FavoritesView()) {
                navButton(icon: "heart.fill", label: "Favorites")
            }
            
            Button(action: refreshAffirmations) {
                navButton(icon: "arrow.clockwise", label: "Refresh")
            }
            
            NavigationLink(destination: VoiceSettingsView()) {
                navButton(icon: "gearshape.fill", label: "Settings")
            }
        }
        .padding(.bottom, 30)
    }
    
    private func navButton(icon: String, label: String) -> some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
            Text(label)
                .font(.caption)
        }
        .foregroundColor(.white)
    }
    
    // MARK: - Setup & Data Loading
    
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
        if !services.affirmationCache.cachedAffirmations.isEmpty {
            affirmations = services.affirmationCache.cachedAffirmations
            sendAffirmationsToWatch()
        }
    }
    
    private func handleCategoriesChange(_ newCategories: [String]?) {
        if let categories = newCategories {
            userCategories = categories
            Task {
                await loadAffirmations(forceRefresh: true)
            }
        }
    }
    
    private func loadAffirmations(forceRefresh: Bool = false) async {
        await services.affirmationCache.loadAffirmations(
            categories: userCategories,
            forceRefresh: forceRefresh
        )
        
        await MainActor.run {
            self.affirmations = services.affirmationCache.cachedAffirmations
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
                    services.favoritesManager.toggleFavorite(
                        affirmationId: affirmation.id,
                        affirmationText: affirmation.text
                    )
                }
            }
//             catch {
//                errorMessage = "Failed to update favorite: \(error.localizedDescription)"
//            }
        }
    }
    
    private func speakAffirmation(_ affirmation: Affirmation) {
        services.speechManager.speak(affirmation.text)
    }
    
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
