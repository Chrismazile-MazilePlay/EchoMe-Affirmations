//
//  OnboardingView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 6/30/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct OnboardingView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @State private var currentStep = 0
    @State private var selectedGoals: Set<String> = []
    @State private var selectedTone = "gentle"
    @State private var isLoading = false
    
    let goals = [
        ("confidence", "Build Confidence", "💪"),
        ("anxiety", "Manage Anxiety", "🧘"),
        ("motivation", "Daily Motivation", "🚀"),
        ("relationships", "Better Relationships", "❤️"),
        ("success", "Achieve Success", "🎯"),
        ("mindfulness", "Practice Mindfulness", "🌿")
    ]
    
    let tones = [
        ("gentle", "Gentle & Soothing", "🕊️"),
        ("motivational", "Energetic & Motivational", "⚡"),
        ("spiritual", "Spiritual & Reflective", "✨")
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            // Progress indicator
            HStack {
                ForEach(0..<3) { index in
                    Rectangle()
                        .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal)
            
            // Content based on step
            Group {
                if currentStep == 0 {
                    welcomeStep
                } else if currentStep == 1 {
                    goalsStep
                } else if currentStep == 2 {
                    toneStep
                }
            }
            .transition(.slide)
            .animation(.easeInOut, value: currentStep)
            
            Spacer()
            
            // Navigation buttons
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        currentStep -= 1
                    }
                    .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: nextAction) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(currentStep == 2 ? "Get Started" : "Next")
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(canProceed ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(25)
                .disabled(!canProceed || isLoading)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    var welcomeStep: some View {
        VStack(spacing: 20) {
            Text("Welcome to EchoMe")
                .font(.largeTitle)
                .bold()
            
            Text("Let's personalize your affirmation journey")
                .font(.title3)
                .foregroundColor(.gray)
            
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding()
        }
    }
    
    var goalsStep: some View {
        VStack(spacing: 20) {
            Text("What would you like to work on?")
                .font(.title2)
                .bold()
            
            Text("Select all that apply")
                .foregroundColor(.gray)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(goals, id: \.0) { goal in
                    GoalCard(
                        id: goal.0,
                        title: goal.1,
                        emoji: goal.2,
                        isSelected: selectedGoals.contains(goal.0)
                    ) {
                        if selectedGoals.contains(goal.0) {
                            selectedGoals.remove(goal.0)
                        } else {
                            selectedGoals.insert(goal.0)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    var toneStep: some View {
        VStack(spacing: 20) {
            Text("How would you like your affirmations delivered?")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
            
            VStack(spacing: 15) {
                ForEach(tones, id: \.0) { tone in
                    ToneOption(
                        id: tone.0,
                        title: tone.1,
                        emoji: tone.2,
                        isSelected: selectedTone == tone.0
                    ) {
                        selectedTone = tone.0
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    var canProceed: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !selectedGoals.isEmpty
        case 2: return true
        default: return false
        }
    }
    
    func nextAction() {
        if currentStep < 2 {
            currentStep += 1
        } else {
            Task {
                await completeOnboarding()
            }
        }
    }
    
    func completeOnboarding() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        do {
            try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .updateData([
                    "onboardingCompleted": true,
                    "preferences.categories": Array(selectedGoals),
                    "preferences.preferredTone": selectedTone,
                    "preferences.onboardingDate": Date()
                ])
            // AuthenticationManager will automatically detect the change
        } catch {
            print("Error completing onboarding: \(error)")
        }
        
        isLoading = false
    }
}

// Keep the GoalCard and ToneOption views the same...
struct GoalCard: View {
    let id: String
    let title: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(emoji)
                    .font(.system(size: 40))
                
                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(15)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ToneOption: View {
    let id: String
    let title: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Text(emoji)
                    .font(.system(size: 30))
                
                Text(title)
                    .font(.body)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(15)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview("Onboarding") {
    OnboardingView()
        .environment(AuthenticationManager.previewNeedsOnboarding)
} 
