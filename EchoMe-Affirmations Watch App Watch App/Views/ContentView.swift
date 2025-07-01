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
        contentView
            .onAppear {
                handleOnAppear()
            }
    }
    
    // Break down complex views into separate computed properties
    @ViewBuilder
    private var contentView: some View {
        if isLoading && !MockDataProvider.isPreview {
            loadingView
        } else if currentAffirmations.isEmpty && !MockDataProvider.isPreview {
            emptyStateView
        } else {
            affirmationsView
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Loading...")
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: connectivityManager.isConnected ? "iphone.gen3" : "iphone.slash")
                .font(.system(size: 40))
                .foregroundColor(connectivityManager.isConnected ? .blue : .gray)
            
            Text(emptyStateMessage)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                connectivityManager.requestAffirmations()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                    Text("Refresh")
                        .font(.caption)
                }
            }
            .buttonStyle(BorderedButtonStyle(tint: .blue))
            .controlSize(.small)
        }
        .padding()
    }
    
    private var affirmationsView: some View {
        TabView(selection: $currentIndex) {
            ForEach(affirmationsWithIndex, id: \.0) { index, affirmation in
                AffirmationWatchView(
                    affirmation: affirmation,
                    index: index + 1,
                    total: currentAffirmations.count,
                    showSyncStatus: connectivityManager.lastSyncDate != nil || MockDataProvider.isPreview
                )
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle())
    }
    
    // Helper computed properties
    private var currentAffirmations: [Affirmation] {
        if MockDataProvider.isPreview {
            return MockDataProvider.shared.getDailyAffirmations(count: 3)
        } else {
            return connectivityManager.affirmations
        }
    }
    
    private var affirmationsWithIndex: [(Int, Affirmation)] {
        Array(currentAffirmations.enumerated())
    }
    
    private var emptyStateMessage: String {
        if connectivityManager.affirmations.isEmpty && connectivityManager.lastSyncDate != nil {
            return "Tap refresh to load"
        }
        return connectivityManager.isConnected ? "Waiting for affirmations" : "Open EchoMe on iPhone"
    }
    
    // Helper methods
    private func handleOnAppear() {
        if MockDataProvider.isPreview {
            loadMockData()
        } else {
            isLoading = false
            if connectivityManager.affirmations.isEmpty {
                connectivityManager.requestAffirmations()
            }
        }
    }
    
    private func loadMockData() {
        MockDataProvider.simulateLoading(seconds: 0.3) {
            self.isLoading = false
        }
    }
}

#Preview {
    ContentView()
}
