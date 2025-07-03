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
                    .fill(.ultraThinMaterial)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.3))
                    )
            )
        }
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Expanded State
    private var expandedMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Menu items only - no header
            VStack(alignment: .leading, spacing: 0) {
                NavigationLink(destination: FavoritesView()) {
                    menuItem(icon: "heart.fill", title: "Favorites")
                }
                .simultaneousGesture(TapGesture().onEnded { _ in
                    withAnimation {
                        isExpanded = false
                    }
                })
                
                NavigationLink(destination: VoiceSettingsView()) {
                    menuItem(icon: "speaker.wave.3.fill", title: "Voice Settings")
                }
                .simultaneousGesture(TapGesture().onEnded { _ in
                    withAnimation {
                        isExpanded = false
                    }
                })
                
                NavigationLink(destination: ContinuousPlayView()) {
                    menuItem(icon: "infinity", title: "Continuous Play")
                }
                .simultaneousGesture(TapGesture().onEnded { _ in
                    withAnimation {
                        isExpanded = false
                    }
                })
                
                NavigationLink(destination: ProfileView()) {
                    menuItem(icon: "person.circle.fill", title: "Profile")
                }
                .simultaneousGesture(TapGesture().onEnded { _ in
                    withAnimation {
                        isExpanded = false
                    }
                })
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.vertical, 8)
                
                Button(action: {
                    isExpanded = false
                    services.authManager.signOut()
                }) {
                    menuItem(icon: "arrow.right.square.fill", title: "Sign Out")
                }
                
                // Close button at the bottom
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isExpanded = false
                    }
                }) {
                    HStack {
                        Image(systemName: "xmark")
                            .font(.title3)
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
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.green.opacity(0.3))
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    private func menuItem(
        icon: String,
        title: String
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
            
            Spacer()
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.green.opacity(0.3)
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
