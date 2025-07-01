//
//  FavoritesView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FavoritesView: View {
    @State private var favorites: [Affirmation] = []
    @State private var isLoading = true
    @State private var favoritesManager = FavoritesManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if favorites.isEmpty {
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
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(favorites) { favorite in
                                AffirmationCard(
                                    id: favorite.id ?? "",
                                    text: favorite.text
                                )
                            }
                        }
                        .padding()
                        .padding(.top, 12)
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if MockDataProvider.isPreview {
                loadMockFavorites()
            } else {
                // Start listening if not already
                if !favoritesManager.isListening {
                    favoritesManager.startListening()
                }
                Task {
                    await loadFavorites()
                }
            }
        }
        .onChange(of: favoritesManager.favoriteIds) { oldValue, newValue in
            // Reload favorites when the favorite IDs change
            if !MockDataProvider.isPreview {
                Task {
                    await loadFavorites()
                }
            }
        }
    }
    
    func loadMockFavorites() {
        MockDataProvider.simulateLoading(seconds: 0.3) {
            self.favorites = MockDataProvider.shared.getFavoriteAffirmations()
            self.isLoading = false
        }
    }
    
    func loadFavorites() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.isLoading = false
            return
        }
        
        do {
            let snapshot = try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .collection("favorites")
                .order(by: "savedAt", descending: true)
                .getDocuments()
            
            self.favorites = snapshot.documents.compactMap { doc in
                let data = doc.data()
                if let text = data["text"] as? String {
                    // Create Affirmation from favorite data
                    return Affirmation(
                        id: doc.documentID,
                        text: text,
                        categories: data["categories"] as? [String] ?? [],
                        tone: data["tone"] as? String ?? "gentle"
                    )
                }
                return nil
            }
        } catch {
            print("Error loading favorites: \(error)")
        }
        
        self.isLoading = false
    }
}

#Preview("Favorites with Items") {
    FavoritesView()
}
