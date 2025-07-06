//
//  ContentView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.services) private var services
    @State private var viewModel: ContentViewModel?
    @State private var currentIndex = 0
    
    var body: some View {
        ZStack {
            if let viewModel = viewModel {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if !viewModel.affirmations.isEmpty {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(viewModel.affirmations.enumerated()), id: \.element.id) { index, affirmation in
                            FullScreenAffirmationView(
                                affirmation: affirmation,
                                isFavorite: viewModel.isFavorite(affirmation.id),
                                onFavoriteTap: {
                                    viewModel.toggleFavorite(for: affirmation)
                                },
                                onPlayTap: {
                                    viewModel.playAffirmation(affirmation)
                                },
                                onShareTap: {
                                    viewModel.shareAffirmation(affirmation)
                                }
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .ignoresSafeArea()
                }
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingMenuButton(
                        onPlayTap: {
                            print("Start continuous play")
                        },
                        onSearchTap: {
                            print("Search affirmations")
                        },
                        onAddTap: {
                            print("Add custom affirmation")
                        }
                    )
                }
            }
        }
        .task {
            if viewModel == nil {
                viewModel = ContentViewModel(mockDataProvider: services.mockDataProvider)
                viewModel?.loadAffirmations()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.services, ServicesContainer.preview)
}
