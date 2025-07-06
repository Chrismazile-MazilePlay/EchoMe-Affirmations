//
//  AffirmationCard.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import SwiftUI

struct AffirmationCard: View {
    let affirmation: Affirmation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(affirmation.text)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            if !affirmation.categories.isEmpty {
                HStack(spacing: 8) {
                    ForEach(affirmation.categories, id: \.self) { category in
                        Text(category)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.cardCornerRadius)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    AffirmationCard(
        affirmation: Affirmation(
            text: "I am worthy of love and respect.",
            categories: ["Self-Love", "Confidence"]
        )
    )
    .padding()
}
