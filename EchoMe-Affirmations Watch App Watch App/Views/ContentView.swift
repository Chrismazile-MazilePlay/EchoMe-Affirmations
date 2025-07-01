//
//  ContentView.swift
//  EchoMe-Affirmations Watch App Watch App
//
//  Created by Christopher Mazile on 7/1/25.
//

import SwiftUI

struct ContentView: View {
    @State private var connectivityManager = WatchConnectivityManager.shared
    @State private var currentIndex = 0
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("EchoMe")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if let syncDate = connectivityManager.lastSyncDate {
                        ToolbarItem(placement: .topBarTrailing) {
                            VStack(spacing: 2) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption2)
                                Text(syncDate, style: .time)
                                    .font(.system(size: 8))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
        }
        .onAppear {
            loadAffirmations()
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
        } else if connectivityManager.affirmations.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "quote.bubble")
                    .font(.system(size: 30))
                    .foregroundColor(.gray)
                Text("No affirmations")
                    .font(.caption)
                    .foregroundColor(.gray)
                Button("Request from iPhone") {
                    connectivityManager.requestAffirmations()
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            TabView(selection: $currentIndex) {
                ForEach(Array(connectivityManager.affirmations.enumerated()), id: \.element.id) { index, affirmation in
                    VStack(spacing: 15) {
                        Text(affirmation.text)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        HStack(spacing: 20) {
                            Button(action: {
                                toggleFavorite(affirmation)
                            }) {
                                Image(systemName: isFavorite(affirmation.id) ? "heart.fill" : "heart")
                                    .font(.title2)
                                    .foregroundColor(isFavorite(affirmation.id) ? .red : .gray)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                // Placeholder for share
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 10)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.verticalPage)
        }
    }
    
    private func loadAffirmations() {
        // Initial data will come from iPhone via WatchConnectivity
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            if connectivityManager.affirmations.isEmpty {
                // Request from iPhone if no data
                connectivityManager.requestAffirmations()
            }
        }
    }
    
    private func isFavorite(_ affirmationId: String) -> Bool {
        return connectivityManager.favoriteIds.contains(affirmationId)
    }
    
    private func toggleFavorite(_ affirmation: Affirmation) {
        // Toggle favorite through connectivity manager
        connectivityManager.toggleFavorite(
            affirmationId: affirmation.id,
            affirmationText: affirmation.text
        )
    }
}

#Preview {
    ContentView()
}
