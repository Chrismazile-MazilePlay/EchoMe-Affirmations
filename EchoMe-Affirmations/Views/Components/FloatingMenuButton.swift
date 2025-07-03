//
//  FloatingMenuButton.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/2/25.
//

import SwiftUI

struct FloatingMenuButton: View {
    @Environment(\.services) private var services
    @Environment(\.showingContinuousPlay) private var showingContinuousPlay
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
                Image(systemName: "house.fill")
                Text("Home")
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
            // Header with user info
            menuHeader
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Menu items (removed Home)
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
                
                Button(action: {
                    isExpanded = false
                    showingContinuousPlay.wrappedValue = true
                }) {
                    menuItem(icon: "infinity", title: "Continuous Play")
                }
                
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
            }
            .padding(.bottom, 8)
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
    
    private var menuHeader: some View {
        HStack(spacing: 12) {
            // User avatar
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(getUserInitials())
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(getUserName())
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Image(systemName: "gearshape.fill")
                        .font(.caption2)
                    Text("Settings")
                        .font(.caption)
                }
                .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: {}) {
                Text("Edit")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )
            }
        }
        .padding(16)
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
    
    private func getUserInitials() -> String {
        if let displayName = services.authManager.userProfile?.displayName {
            return displayName
                .split(separator: " ")
                .compactMap { $0.first.map(String.init) }
                .joined()
                .uppercased()
        }
        return "CM"
    }
    
    private func getUserName() -> String {
        services.authManager.userProfile?.displayName ?? "User"
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
