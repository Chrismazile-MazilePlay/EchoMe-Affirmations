//
//  FloatingMenuButton.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/2/25.
//

import SwiftUI

struct FloatingMenuButton: View {
    @Environment(\.services) private var services
    @State private var isExpanded = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background tap area when expanded
            if isExpanded {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isExpanded = false
                        }
                    }
                    .ignoresSafeArea()
            }
            
            // Menu content
            VStack(alignment: .trailing, spacing: 0) {
                if isExpanded {
                    expandedMenu
                        .transition(.scale(scale: 0.1, anchor: .topTrailing).combined(with: .opacity))
                }
                
                if !isExpanded {
                    collapsedButton
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
    }
    
    // MARK: - Collapsed State
    private var collapsedButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded = true
            }
        }) {
            GlassCard(
                padding: 0,
                cornerRadius: 25, // Half of height for capsule look
                material: .ultraThinMaterial
            ) {
                HStack(spacing: 12) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                    Text("Menu")
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.2))
                )
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Expanded State
    private var expandedMenu: some View {
        GlassCard(padding: 0, cornerRadius: 20, material: .ultraThinMaterial) {
            VStack(alignment: .leading, spacing: 0) {
                // Menu items
                VStack(alignment: .leading, spacing: 0) {
                    NavigationLink(destination: FavoritesView()) {
                        menuItem(icon: "heart.fill", title: "Favorites", color: .red)
                    }
                    .simultaneousGesture(TapGesture().onEnded { _ in
                        withAnimation {
                            isExpanded = false
                        }
                    })
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    NavigationLink(destination: VoiceSettingsView()) {
                        menuItem(icon: "speaker.wave.3.fill", title: "Voice Settings", color: .blue)
                    }
                    .simultaneousGesture(TapGesture().onEnded { _ in
                        withAnimation {
                            isExpanded = false
                        }
                    })
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    NavigationLink(destination: ContinuousPlayView()) {
                        menuItem(icon: "infinity", title: "Continuous Play", color: .purple)
                    }
                    .simultaneousGesture(TapGesture().onEnded { _ in
                        withAnimation {
                            isExpanded = false
                        }
                    })
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    NavigationLink(destination: ProfileView()) {
                        menuItem(icon: "person.circle.fill", title: "Profile", color: .green)
                    }
                    .simultaneousGesture(TapGesture().onEnded { _ in
                        withAnimation {
                            isExpanded = false
                        }
                    })
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                        .padding(.vertical, 8)
                    
                    Button(action: {
                        isExpanded = false
                        services.authManager.signOut()
                    }) {
                        menuItem(icon: "arrow.right.square.fill", title: "Sign Out", color: .orange)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // Close button at the bottom
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isExpanded = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.gray)
                                .frame(width: 24)
                            
                            Text("Close")
                                .font(.body)
                            
                            Spacer()
                        }
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(width: 280)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.green.opacity(0.15))
            )
        }
    }
    
    private func menuItem(
        icon: String,
        title: String,
        color: Color = .white
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .fontWeight(.medium)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .hoverEffect(.lift)
    }
}

// MARK: - Custom Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack {
            HStack {
                Spacer()
                FloatingMenuButton()
                    .padding()
            }
            Spacer()
        }
    }
    .environment(\.services, ServicesContainer.preview)
}
