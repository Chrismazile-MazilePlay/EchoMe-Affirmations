//
//  OnboardingView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.services) private var services
    @State private var currentStep = 0
    @State private var viewModel: OnboardingViewModel?
    
    var body: some View {
        TabView(selection: $currentStep) {
            WelcomeView()
                .tag(0)
            
            CategorySelectionView(selectedCategories: Binding(
                get: { viewModel?.selectedCategories ?? [] },
                set: { viewModel?.selectedCategories = $0 }
            ))
            .tag(1)
            
            VoiceSelectionView(selectedVoice: Binding(
                get: { viewModel?.selectedVoice ?? "Samantha" },
                set: { viewModel?.selectedVoice = $0 }
            ))
            .tag(2)
            
            OnboardingCompleteView(isLoading: viewModel?.isCompleting ?? false) {
                Task {
                    try await viewModel?.completeOnboarding()
                }
            }
            .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .onAppear {
            if viewModel == nil {
                viewModel = services.resolve(OnboardingViewModel.self)
            }
        }
    }
}

// MARK: - Onboarding Steps

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 100))
                .foregroundColor(.accentColor)
            
            VStack(spacing: 16) {
                Text("Welcome to EchoMe")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your daily dose of positivity")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("Swipe to continue")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.bottom, 50)
        }
        .padding()
    }
}

struct CategorySelectionView: View {
    @Binding var selectedCategories: Set<String>
    let categories = ["Self-Love", "Confidence", "Motivation", "Peace", "Success", "Gratitude"]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Choose Your Focus")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 60)
            
            Text("Select categories that resonate with you")
                .font(.body)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                ForEach(categories, id: \.self) { category in
                    CategoryChip(
                        title: category,
                        isSelected: selectedCategories.contains(category)
                    ) {
                        if selectedCategories.contains(category) {
                            selectedCategories.remove(category)
                        } else {
                            selectedCategories.insert(category)
                        }
                    }
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct VoiceSelectionView: View {
    @Binding var selectedVoice: String
    let voices = ["Samantha", "Daniel", "Karen"]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Choose Your Voice")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 60)
            
            Text("Select a voice for your affirmations")
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                ForEach(voices, id: \.self) { voice in
                    VoiceOptionCard(
                        name: voice,
                        isSelected: selectedVoice == voice
                    ) {
                        selectedVoice = voice
                    }
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
}

struct VoiceOptionCard: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "speaker.wave.2")
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(name)
                        .font(.headline)
                    Text("Tap to preview")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct OnboardingCompleteView: View {
    let isLoading: Bool
    let onComplete: () async -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)
            
            VStack(spacing: 16) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Start your journey with daily affirmations")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button {
                Task {
                    await onComplete()
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Get Started")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isLoading)
            .padding(.horizontal)
            .padding(.bottom, 50)
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
        .environment(\.services, ServicesContainer.preview)
}
