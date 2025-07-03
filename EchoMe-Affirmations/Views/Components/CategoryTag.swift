//
//  CategoryTag.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/3/25.
//

import SwiftUI

struct CategoryTag: View {
    let category: String
    let isSelected: Bool
    let action: (() -> Void)?
    
    init(
        category: String,
        isSelected: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.category = category
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: { action?() }) {
            Text(category.capitalized)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white : Color.white.opacity(0.2))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                )
        }
        .disabled(action == nil)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct CategoryTagList: View {
    let categories: [String]
    @Binding var selectedCategories: Set<String>
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    CategoryTag(
                        category: category,
                        isSelected: selectedCategories.contains(category),
                        action: {
                            if selectedCategories.contains(category) {
                                selectedCategories.remove(category)
                            } else {
                                selectedCategories.insert(category)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [.purple, .blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        VStack(spacing: 30) {
            CategoryTag(category: "confidence", isSelected: false)
            CategoryTag(category: "motivation", isSelected: true)
            
            CategoryTagList(
                categories: ["confidence", "peace", "growth", "love", "success"],
                selectedCategories: .constant(Set(["confidence", "love"]))
            )
        }
    }
}
