//
//  FavoriteCard.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/3/25.
//

import SwiftUI

struct FavoriteCard: View {
    let affirmation: Affirmation
    let onRemove: () -> Void
    let onSpeak: () -> Void
    
    @State private var isRemoving = false
    
    var body: some View {
        GlassCard(material: .thinMaterial) {
            VStack(alignment: .leading, spacing: 12) {
                // Affirmation text
                Text(affirmation.text)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                // Action buttons
                HStack {
                    // Speak button
                    Button(action: onSpeak) {
                        Label("Speak", systemImage: "speaker.wave.2.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // Remove button
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isRemoving = true
                        }
                        // Delay the actual removal for animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onRemove()
                        }
                    }) {
                        Label("Remove", systemImage: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scaleEffect(isRemoving ? 0.8 : 1.0)
        .opacity(isRemoving ? 0 : 1)
        .offset(x: isRemoving ? -300 : 0)
    }
}

#Preview {
    ZStack {
        Color.black
        
        FavoriteCard(
            affirmation: Affirmation(
                id: "1",
                text: "I am worthy of love and respect",
                categories: ["self-worth"],
                tone: "gentle",
                length: "short",
                isActive: true,
                createdAt: Date()
            ),
            onRemove: { print("Remove") },
            onSpeak: { print("Speak") }
        )
        .padding()
    }
}
