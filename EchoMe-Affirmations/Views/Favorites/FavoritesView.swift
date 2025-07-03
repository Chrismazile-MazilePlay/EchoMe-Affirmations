//
//  FavoritesView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import SwiftUI

struct FavoritesView: View {
    @Environment(\.services) private var services
    @State private var favorites: [Affirmation] = []
    
    var body: some View {
        ZStack(alignment: .top) {
            if favorites.isEmpty {
                emptyStateView
            } else {
                favoritesList
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadFavorites()
            startListeningIfNeeded()
        }
        .onChange(of: services.favoritesManager.favoriteIds) { _, _ in
            loadFavorites()
        }
    }
    
    // MARK: - Views
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No favorites yet",
            systemImage: "heart.slash",
            description: Text("Tap the heart on affirmations you love")
        )
    }
    
    private var favoritesList: some View {
        ScrollView {
            VStack(spacing: 15) {
                ForEach(favorites) { favorite in
                    AffirmationCard(
                        id: favorite.id,
                        text: favorite.text
                    )
                }
            }
            .padding()
            .padding(.top, 12)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadFavorites() {
        if MockDataProvider.isPreview {
            favorites = MockDataProvider.shared.getFavoriteAffirmations()
            return
        }
        
        // Load from cache immediately
        let cachedFavoriteData = services.favoritesManager.getCachedFavorites()
        favorites = cachedFavoriteData.map { data in
            Affirmation(
                id: data.id,
                text: data.text,
                categories: [],
                tone: nil,
                length: nil
            )
        }
    }
    
    private func startListeningIfNeeded() {
        if !MockDataProvider.isPreview && !services.favoritesManager.isListening {
            services.favoritesManager.startListening()
        }
    }
}

// MARK: - Content Container
private struct FavoritesContent: View {
    let favorites: [Affirmation]
    let isLoading: Bool
    let onRemoveFavorite: (Affirmation) -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            if isLoading {
                LoadingView()
            } else if favorites.isEmpty {
                EmptyFavoritesView()
            } else {
                FavoritesList(
                    favorites: favorites,
                    onRemoveFavorite: onRemoveFavorite
                )
            }
        }
    }
}

// MARK: - Loading View
private struct LoadingView: View {
    var body: some View {
        ProgressView()
            .scaleEffect(1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State
private struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No favorites yet")
                .font(.title3)
                .foregroundColor(.gray)
            
            Text("Tap the heart on affirmations you love")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Favorites List
private struct FavoritesList: View {
    let favorites: [Affirmation]
    let onRemoveFavorite: (Affirmation) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                ForEach(favorites) { favorite in
                    FavoriteCard(
                        affirmation: favorite,
                        onRemove: { onRemoveFavorite(favorite) }
                    )
                }
            }
            .padding()
            .padding(.top, 12)
        }
    }
}

// MARK: - Favorite Card
private struct FavoriteCard: View {
    @Environment(\.services) private var services
    let affirmation: Affirmation
    let onRemove: () -> Void
    @State private var isRemoving = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Affirmation text
            Text(affirmation.text)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Action buttons
            HStack(spacing: 16) {
                // Speak button
                Button(action: speakAffirmation) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                // Remove button
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isRemoving = true
                        onRemove()
                    }
                }) {
                    Image(systemName: "heart.fill")
                        .font(.title3)
                        .foregroundColor(isRemoving ? .gray : .red)
                }
                .disabled(isRemoving)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .opacity(isRemoving ? 0.5 : 1.0)
        .scaleEffect(isRemoving ? 0.95 : 1.0)
    }
    
    private func speakAffirmation() {
        services.speechManager.speak(affirmation.text)
        print("🔊 Debug FavoritsView - Saved voice: \(UserDefaults.standard.string(forKey: "selectedVoiceProfile") ?? "nil")")
        print("🔊 Debug FavoritsView - User profile voice: \(services.authManager.userProfile?.preferences.voiceProfile ?? "nil")")
    }
}

// MARK: - Firebase Service Extension
extension FirebaseService {
    func fetchFavorites(userId: String) async throws -> [FavoriteData] {
        // This should already exist in your FirebaseService
        // If not, add this method to FirebaseService.swift:
        /*
        func fetchFavorites(userId: String) async throws -> [FavoriteData] {
            guard let db = db else {
                throw FirebaseError.notConfigured
            }
            
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("favorites")
                .order(by: "savedAt", descending: true)
                .getDocuments()
            
            return snapshot.documents.compactMap { doc in
                let data = doc.data()
                guard let text = data["text"] as? String else { return nil }
                
                return FavoriteData(
                    id: doc.documentID,
                    affirmationId: data["affirmationId"] as? String ?? doc.documentID,
                    text: text,
                    savedAt: (data["savedAt"] as? Timestamp)?.dateValue() ?? Date()
                )
            }
        }
        */
        
        // Use the existing listenToFavorites with a one-time fetch
        var favorites: [FavoriteData] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        let listener = listenToFavorites(userId: userId) { fetchedFavorites in
            favorites = fetchedFavorites
            semaphore.signal()
        }
        
        semaphore.wait()
        listener?.remove()
        
        return favorites
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        FavoritesView()
    }
    .environment(\.services, ServicesContainer.preview)
}
