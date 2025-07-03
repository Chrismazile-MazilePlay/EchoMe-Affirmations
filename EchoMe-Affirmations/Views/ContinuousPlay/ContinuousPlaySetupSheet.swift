//
//  ContinuousPlaySetupSheet.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/2/25.
//

import SwiftUI

struct ContinuousPlaySetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var preferences: ContinuousPlayPreferences
    let onComplete: (ContinuousPlayPreferences) -> Void
    
    @State private var selectedMood = ""
    @State private var selectedFocusAreas: Set<String> = []
    @State private var selectedEnergyLevel = ""
    
    private let moods = ["Calm", "Energized", "Focused", "Relaxed", "Motivated"]
    private let focusAreas = ["Confidence", "Success", "Health", "Relationships", "Abundance", "Peace"]
    private let energyLevels = ["Low", "Medium", "High"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.indigo.opacity(0.3), Color.purple.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.purple)
                        
                        Text("Personalize Your Session")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Answer a few quick questions to optimize your experience")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Questions
                    VStack(spacing: 25) {
                        // Mood selection
                        QuestionSection(title: "How are you feeling?") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(moods, id: \.self) { mood in
                                        SelectionChip(
                                            title: mood,
                                            isSelected: selectedMood == mood
                                        ) {
                                            selectedMood = mood
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Focus areas
                        QuestionSection(title: "What would you like to focus on?") {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                                ForEach(focusAreas, id: \.self) { area in
                                    SelectionChip(
                                        title: area,
                                        isSelected: selectedFocusAreas.contains(area)
                                    ) {
                                        if selectedFocusAreas.contains(area) {
                                            selectedFocusAreas.remove(area)
                                        } else {
                                            selectedFocusAreas.insert(area)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Energy level
                        QuestionSection(title: "Current energy level?") {
                            HStack(spacing: 20) {
                                ForEach(energyLevels, id: \.self) { level in
                                    SelectionChip(
                                        title: level,
                                        isSelected: selectedEnergyLevel == level
                                    ) {
                                        selectedEnergyLevel = level
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                    
                    // Buttons
                    VStack(spacing: 12) {
                        Button(action: completeSetup) {
                            Text("Start Session")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.purple)
                                )
                        }
                        
                        Button(action: skipSetup) {
                            Text("Skip & Use Defaults")
                                .font(.subheadline)
                                .foregroundColor(.purple)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func completeSetup() {
        preferences.mood = selectedMood.isEmpty ? nil : selectedMood
        preferences.focusAreas = Array(selectedFocusAreas)
        preferences.energyLevel = selectedEnergyLevel.isEmpty ? nil : selectedEnergyLevel
        preferences.skipQuestions = false
        
        onComplete(preferences)
        dismiss()
    }
    
    private func skipSetup() {
        preferences.skipQuestions = true
        onComplete(preferences)
        dismiss()
    }
}

// MARK: - Question Section
struct QuestionSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            content
        }
    }
}

// MARK: - Selection Chip
struct SelectionChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.purple : Color.gray.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

// MARK: - Preview
#Preview {
    ContinuousPlaySetupSheet(
        preferences: .constant(.default),
        onComplete: { _ in }
    )
}
