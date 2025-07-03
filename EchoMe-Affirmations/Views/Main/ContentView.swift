//
//  ContentView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/2/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.services) private var services
    @State private var viewModel = ContentViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Full screen affirmations
                if !viewModel.affirmations.isEmpty {
                    affirmationPageView
                } else if services.affirmationCacheManager.isLoading && viewModel.affirmations.isEmpty {
                    LoadingView(message: "Loading your affirmations...")
                } else {
                    EmptyStateView(
                        icon: "sparkles",
                        title: "No affirmations found",
                        subtitle: "Try updating your preferences"
                    )
                }
                
                // Floating menu overlay
                VStack {
                    HStack {
                        Spacer()
                        FloatingMenuButton()
                            .padding(.trailing, 20)
                    }
                    .padding(.top, 60)
                    Spacer()
                }
            }
            .ignoresSafeArea(.all)
            .preferredColorScheme(.dark)
            .onAppear {
                viewModel.onAppear()
            }
            .onDisappear {
                viewModel.onDisappear()
            }
            .onChange(of: viewModel.currentIndex) { _, newIndex in
                viewModel.checkForMoreAffirmations(at: newIndex)
            }
            .task {
                if !viewModel.hasInitiallyLoaded {
                    viewModel.setup(with: services)
                }
            }
            .errorToast(error: $viewModel.error)  // Added error handling
        }
    }
    
    // MARK: - Views
    private var affirmationPageView: some View {
        TabView(selection: $viewModel.currentIndex) {
            ForEach(Array(viewModel.affirmations.enumerated()), id: \.element.id) { index, affirmation in
                FullScreenAffirmationView(
                    affirmation: affirmation,
                    isFavorite: viewModel.isFavorite(affirmation.id),
                    onFavoriteToggle: { viewModel.toggleFavorite(affirmation) },
                    isOffline: viewModel.isOffline && index == viewModel.affirmations.count - 1
                )
                .tag(index)
                .environment(\.services, services)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environment(\.services, ServicesContainer.previewWithMockData)
}
