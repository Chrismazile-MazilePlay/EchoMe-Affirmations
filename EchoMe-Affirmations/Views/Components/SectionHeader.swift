//
//  SectionHeader.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/3/25.
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    let icon: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        icon: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            if let action = action {
                Button(action: action) {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    ZStack {
        Color.black
        VStack {
            SectionHeader(title: "Recent", icon: "clock.fill")
            SectionHeader(title: "Favorites", icon: "heart.fill", action: { print("More") })
        }
    }
}
