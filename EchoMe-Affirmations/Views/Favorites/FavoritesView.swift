//
//  FavoritesView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

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
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            FavoritesContent(
                favorites: favorites,
                isLoading: isLoading,
                onRemoveFavorite: removeFavorite
            )
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { loadInitialData() }
        .onChange(of: services.favoritesManager.favoriteIds) { _, _ in
            reloadFavorites()
        }
    }
    
    // MARK: - Data Loading
    private func loadInitialData() {
        if MockDataProvider.isPreview {
            loadMockFavorites()
        } else {
            ensureListenerStarted()
            Task { await loadFavorites() }
        }
    }
    
    private func ensureListenerStarted() {
        if !services.favoritesManager.isListening {
            services.favoritesManager.startListening()
        }
    }
    
    private func reloadFavorites() {
        if !MockDataProvider.isPreview {
            Task { await loadFavorites() }
        }
    }
    
    private func loadMockFavorites() {
        MockDataProvider.simulateLoading(seconds: 0.3) {
            self.favorites = MockDataProvider.shared.getFavoriteAffirmations()
            self.isLoading = false
        }
    }
    
    private func loadFavorites() async {
        guard let userId = services.authManager.currentUser?.uid else {
            await MainActor.run {
                self.isLoading = false
            }
            return
        }
        
        do {
            let favoriteData = try await services.firebaseService.fetchFavorites(userId: userId)
            
            await MainActor.run {
                self.favorites = favoriteData.map { data in
                    Affirmation(
                        id: data.id,
                        text: data.text,
                        categories: [],  // Favorites don't store categories
                        tone: nil,
                        length: nil
                    )
                }
                self.isLoading = false
            }
        } catch {
            print("Error loading favorites: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Actions
    private func removeFavorite(_ affirmation: Affirmation) {
        Task {
            try? await services.favoritesManager.toggleFavorite(
                affirmationId: affirmation.id,
                affirmationText: affirmation.text
            )
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
