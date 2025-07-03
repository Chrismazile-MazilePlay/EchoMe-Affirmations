//
//  GlassCard.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/3/25.
//

import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = AppConstants.UI.defaultPadding
    var cornerRadius: CGFloat = 12
    var material: Material = .ultraThinMaterial
    
    init(
        padding: CGFloat = AppConstants.UI.defaultPadding,
        cornerRadius: CGFloat = 12,
        material: Material = .ultraThinMaterial,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.material = material
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(material)
                    .shadow(
                        color: Color.black.opacity(0.15),
                        radius: 10,
                        x: 0,
                        y: 5
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Alternative Glass Style (More Prominent)
struct ProminentGlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = AppConstants.UI.defaultPadding
    var cornerRadius: CGFloat = 16
    
    init(
        padding: CGFloat = AppConstants.UI.defaultPadding,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background {
                ZStack {
                    // Base glass layer
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.regularMaterial)
                    
                    // Gradient overlay for depth
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        Color.white.opacity(0.3),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: Color.black.opacity(0.2),
                radius: 15,
                x: 0,
                y: 8
            )
    }
}

// MARK: - Preview
#Preview("Glass Cards") {
    ZStack {
        // Dynamic background
        LinearGradient(
            colors: [.blue, .purple, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 20) {
                // Ultra thin material
                GlassCard {
                    Label("Ultra Thin Material", systemImage: "sparkles")
                        .foregroundColor(.white)
                }
                
                // Thin material
                GlassCard(material: .thinMaterial) {
                    Label("Thin Material", systemImage: "star.fill")
                        .foregroundColor(.white)
                }
                
                // Regular material
                GlassCard(material: .regularMaterial) {
                    Label("Regular Material", systemImage: "heart.fill")
                        .foregroundColor(.white)
                }
                
                // Prominent style
                ProminentGlassCard {
                    VStack(spacing: 10) {
                        Image(systemName: "app.fill")
                            .font(.largeTitle)
                        Text("Prominent Glass")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                }
            }
            .padding()
        }
    }
}
