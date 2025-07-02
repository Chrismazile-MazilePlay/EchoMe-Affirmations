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
import FirebaseFirestore
import FirebaseAuth
import WatchConnectivity

struct ContentView: View {
    @Environment(\.services) private var services
    
    // Access managers through services
    private var authManager: AuthenticationManager { services.authManager }
    private var favoritesManager: FavoritesManager { services.favoritesManager }
    private var watchConnectivityManager: WatchConnectivityManager { services.watchConnectivityManager }
    
    @State private var affirmations: [Affirmation] = []
    @State private var isLoading = true
    @State private var userCategories: [String] = []
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Your Daily Affirmations")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        navigationMenu
                    }
                }
                .onAppear { handleOnAppear() }
                .onDisappear { handleOnDisappear() }
        }
    }
    
    // MARK: - View Components
    
    private var mainContent: some View {
        ZStack(alignment: .top) {
            if isLoading {
                loadingView
            } else if affirmations.isEmpty {
                emptyStateView
            } else {
                affirmationsList
            }
        }
    }
    
    private var loadingView: some View {
        ProgressView()
            .scaleEffect(1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        ContentEmptyState()
    }
    
    private var affirmationsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                categoryTagsSection
                affirmationsSection
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var categoryTagsSection: some View {
        Group {
            if !userCategories.isEmpty {
                CategoryTagsRow(categories: userCategories)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
            }
        }
    }
    
    private var affirmationsSection: some View {
        VStack(spacing: 15) {
            ForEach(affirmations) { affirmation in
                AffirmationCard(
                    id: affirmation.id,
                    text: affirmation.text
                )
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    private var navigationMenu: some View {
        Menu {
            menuContent
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
    
    private var menuContent: some View {
        Group {
            NavigationLink {
                FavoritesView()
            } label: {
                Label("My Favorites", systemImage: "heart.fill")
            }
            
            NavigationLink {
                VoiceSettingsView()
            } label: {
                Label("Voice Settings", systemImage: "speaker.wave.3")
            }
            
            NavigationLink {
                ProfileView()
            } label: {
                Label("Profile", systemImage: "person.circle")
            }
            
            Divider()
            
            Button(action: { authManager.signOut() }) {
                Label("Sign Out", systemImage: "arrow.right.square")
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleOnAppear() {
        loadContent()
        if !MockDataProvider.isPreview {
            favoritesManager.startListening()
        }
    }
    
    private func handleOnDisappear() {
        if !MockDataProvider.isPreview {
            favoritesManager.stopListening()
        }
    }
    
    private func loadContent() {
        if MockDataProvider.isPreview {
            loadMockData()
        } else {
            Task {
                await fetchPersonalizedAffirmations()
            }
        }
    }
    
    private func loadMockData() {
        MockDataProvider.simulateLoading(seconds: 0.3) {
            self.affirmations = MockDataProvider.shared.getDailyAffirmations()
            self.userCategories = MockDataProvider.shared.getUserCategories()
            self.isLoading = false
            sendAffirmationsToWatch()
        }
    }
    
    private func fetchPersonalizedAffirmations() async {
        guard !MockDataProvider.isPreview else {
            loadMockData()
            return
        }
        
        guard let userProfile = authManager.userProfile else {
            self.isLoading = false
            return
        }
        
        self.userCategories = userProfile.preferences.categories
        
        do {
            let affirmationLimit = userProfile.preferences.dailyAffirmationCount
            
            if !userCategories.isEmpty {
                self.affirmations = try await Affirmation
                    .fetchByCategories(userCategories, limit: 10)
                    .shuffled()
                    .prefix(affirmationLimit)
                    .map { $0 }
            } else {
                self.affirmations = try await Affirmation
                    .fetchRandom(limit: affirmationLimit)
            }
        } catch {
            print("Error fetching affirmations: \(error)")
        }
        
        self.isLoading = false
        sendAffirmationsToWatch()
    }
    
    private func sendAffirmationsToWatch() {
        print("📱 Sending \(affirmations.count) affirmations to watch")
        watchConnectivityManager.sendAffirmationsToWatch(affirmations)
    }
}

// MARK: - Supporting Views

struct ContentEmptyState: View {
    var body: some View {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CategoryTagsRow: View {
    let categories: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(categories, id: \.self) { category in
                    CategoryTag(category: category)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryTag: View {
    let category: String
    
    var body: some View {
        Text(category.capitalized)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(15)
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
    .environment(\.services, ServicesContainer.preview)
}
