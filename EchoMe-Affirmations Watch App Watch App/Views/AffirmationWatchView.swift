//
//  AffirmationWatchView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import SwiftUI

struct AffirmationWatchView: View {
    let affirmation: Affirmation
    let index: Int
    let total: Int
    let showSyncStatus: Bool
    
    @State private var isFavorite = false
    @State private var isSpeaking = false
    @State private var connectivityManager = WatchConnectivityManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            // Top section with sync status only (removed counter)
            HStack {
                Spacer()
                
                if showSyncStatus {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green.opacity(0.7))
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            
            // Main affirmation text
            Text(affirmation.text)
                .font(.system(size: dynamicFontSize, weight: .medium))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
                .frame(maxHeight: .infinity)
            
            // Categories (compact)
            if !affirmation.categories.isEmpty {
                HStack(spacing: 4) {
                    ForEach(affirmation.categories.prefix(2), id: \.self) { category in
                        CompactCategoryBadge(category: category)
                    }
                    if affirmation.categories.count > 2 {
                        Text("+\(affirmation.categories.count - 2)")
                            .font(.system(size: 9))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.bottom, 4)
            }
            
            // Action buttons (compact)
            HStack(spacing: 16) {
                // Speak button
                Button(action: speakAffirmation) {
                    VStack(spacing: 2) {
                        Image(systemName: isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                            .font(.system(size: 20))
                        Text("Speak")
                            .font(.system(size: 9))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(isSpeaking ? .blue : .primary)
                
                // Favorite button
                Button(action: toggleFavorite) {
                    VStack(spacing: 2) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                        Text("Save")
                            .font(.system(size: 9))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(isFavorite ? .red : .primary)
            }
            .padding(.bottom, 8)
        }
        .onAppear {
            loadFavoriteStatus()
        }
    }
    
    // Dynamic font size based on text length
    private var dynamicFontSize: CGFloat {
        let textLength = affirmation.text.count
        switch textLength {
        case 0..<50:
            return 16
        case 50..<100:
            return 14
        case 100..<150:
            return 13
        default:
            return 12
        }
    }
    
    // MARK: - Actions
    private func speakAffirmation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isSpeaking = true
        }
        
        // Simulate speaking duration
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(affirmation.estimatedReadTime)) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isSpeaking = false
            }
        }
    }
    
    private func toggleFavorite() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isFavorite.toggle()
        }
        
        // Send favorite update to iPhone
        connectivityManager.toggleFavorite(
            affirmationId: affirmation.id ?? "",
            affirmationText: affirmation.text )
    }
    
    private func loadFavoriteStatus() {
        if MockDataProvider.isPreview {
            isFavorite = Int.random(in: 0...2) == 0
        } else {
            // Check if this affirmation is in favorites
            isFavorite = connectivityManager.favoriteIds.contains(affirmation.id ?? "")
        }
    }
}

// Rest of the file remains the same...

// Compact category badge for watch
struct CompactCategoryBadge: View {
    let category: String
    
    var body: some View {
        if let cat = Affirmation.Category(rawValue: category) {
            HStack(spacing: 2) {
                Text(cat.emoji)
                    .font(.system(size: 9))
                Text(cat.displayName)
                    .font(.system(size: 9))
                    .lineLimit(1)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
        } else {
            Text(category.capitalized)
                .font(.system(size: 9))
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
        }
    }
}

// MARK: - Previews using MockDataProvider
#Preview("Various Affirmations") {
    struct PreviewWrapper: View {
        @State private var currentIndex = 0
        let affirmations = MockDataProvider.shared.getDailyAffirmations(count: 3)
        
        var body: some View {
            TabView(selection: $currentIndex) {
                ForEach(Array(affirmations.enumerated()), id: \.0) { index, affirmation in
                    AffirmationWatchView(
                        affirmation: affirmation,
                        index: index + 1,
                        total: affirmations.count,
                        showSyncStatus: true
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
        }
    }
    
    return PreviewWrapper()
}

#Preview("Single Affirmation") {
    AffirmationWatchView(
        affirmation: MockDataProvider.shared.mockAffirmations.first!,
        index: 1,
        total: 1,
        showSyncStatus: false
    )
}
