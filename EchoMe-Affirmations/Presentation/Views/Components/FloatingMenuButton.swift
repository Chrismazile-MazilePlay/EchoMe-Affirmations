//
//  FloatingMenuButton.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import SwiftUI

struct FloatingMenuButton: View {
    @State private var isExpanded = false
    let onPlayTap: () -> Void
    let onSearchTap: () -> Void
    let onAddTap: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Menu Items
            if isExpanded {
                VStack(spacing: 16) {
                    MenuItemButton(
                        icon: "play.fill",
                        color: .green,
                        action: {
                            onPlayTap()
                            isExpanded = false
                        }
                    )
                    
                    MenuItemButton(
                        icon: "magnifyingglass",
                        color: .blue,
                        action: {
                            onSearchTap()
                            isExpanded = false
                        }
                    )
                    
                    MenuItemButton(
                        icon: "plus",
                        color: .purple,
                        action: {
                            onAddTap()
                            isExpanded = false
                        }
                    )
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Main Button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "xmark" : "ellipsis")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .frame(width: 56, height: 56)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .scaleEffect(isExpanded ? 1.1 : 1.0)
        }
        .padding()
    }
}

struct MenuItemButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(color)
                .clipShape(Circle())
                .shadow(radius: 2)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingMenuButton(
                    onPlayTap: { print("Play") },
                    onSearchTap: { print("Search") },
                    onAddTap: { print("Add") }
                )
            }
        }
    }
}
