//
//  FavoritesView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import SwiftUI

struct FavoritesView: View {
    @Environment(\.services) private var services
    @State private var viewModel = FavoritesViewModel()
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Content
                if viewModel.isLoading {
                    LoadingView(message: "Loading your favorites...")
                } else if viewModel.isEmpty {
                    EmptyStateView(
                        icon: "heart.slash",
                        title: "No favorites yet",
                        subtitle: "Tap the heart on affirmations you love"
                    )
                } else {
                    favoritesList
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $viewModel.searchText, prompt: "Search favorites")
            .task {
                viewModel.setup(with: services)
            }
            .onDisappear {
                viewModel.cleanup()
            }
            .alert("Error", isPresented: $showingError, presenting: viewModel.error) { _ in
                Button("OK") { viewModel.error = nil }
                Button("Retry") {
                    Task { viewModel.loadFavorites() }
                }
            } message: { error in
                Text(error.localizedDescription)
            }
            .onChange(of: viewModel.error) { _, newError in
                showingError = newError != nil
            }
        }
    }
    
    private var favoritesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredFavorites) { affirmation in
                    FavoriteCard(
                        affirmation: affirmation,
                        onRemove: {
                            Task {
                                await viewModel.removeFavorite(affirmation)
                            }
                        },
                        onSpeak: {
                            viewModel.speakAffirmation(affirmation)
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .move(edge: .leading))
                    ))
                }
            }
            .padding()
        }
    }
}

#Preview {
    FavoritesView()
        .environment(\.services, ServicesContainer.previewWithMockData)
}
