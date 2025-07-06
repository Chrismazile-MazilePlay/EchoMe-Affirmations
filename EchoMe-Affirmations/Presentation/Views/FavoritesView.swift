//
//  FavoritesView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import SwiftUI

struct FavoritesView: View {
    @Environment(\.services) private var services
    @State private var favoriteAffirmations: [Affirmation] = []
    
    var body: some View {
        NavigationStack {
            Group {
                if favoriteAffirmations.isEmpty {
                    ContentUnavailableView(
                        "No favorites yet",
                        systemImage: "heart.slash",
                        description: Text("Tap the heart on affirmations you love")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(favoriteAffirmations) { affirmation in
                                AffirmationCard(affirmation: affirmation)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Favorites")
            .onAppear {
                loadFavorites()
            }
        }
    }
    
    private func loadFavorites() {
        // For now, just show first two affirmations as favorites
        let all = services.mockDataProvider.getAllAffirmations()
        favoriteAffirmations = Array(all.prefix(2))
    }
}

#Preview {
    FavoritesView()
        .environment(\.services, ServicesContainer.preview)
}
