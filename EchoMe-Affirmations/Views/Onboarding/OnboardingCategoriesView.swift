//
//  OnboardingCategoriesView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import SwiftUI

struct OnboardingCategoriesView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    
    let isUpdatingPreferences: Bool
    
    @State private var categories: [CategorySelection] = []
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(isUpdatingPreferences: Bool = false) {
        self.isUpdatingPreferences = isUpdatingPreferences
    }
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarHidden(!isUpdatingPreferences)
                .toolbar { toolbarContent }
                .onAppear { setupCategories() }
                .alert("Error", isPresented: $showError) { errorAlert }
        }
    }
    
    // MARK: - View Components
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            if !isUpdatingPreferences {
                onboardingHeader
            }
            categoriesGrid
            bottomSection
        }
    }
    
    private var onboardingHeader: some View {
        OnboardingHeader()
    }
    
    private var categoriesGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: gridColumns,
                spacing: 16
            ) {
                categoryCards
            }
            .padding()
        }
    }
    
    private var categoryCards: some View {
        ForEach($categories) { $categorySelection in
            CategoryCard(
                category: categorySelection.category,
                isSelected: categorySelection.isSelected,
                onTap: { toggleCategory($categorySelection) }
            )
        }
    }
    
    private var bottomSection: some View {
        VStack(spacing: 16) {
            selectionIndicator
            actionButton
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private var selectionIndicator: some View {
        HStack {
            Text("\(selectedCount) selected")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("Select at least 1")
                .font(.caption)
                .foregroundColor(selectionWarningColor)
        }
    }
    
    private var actionButton: some View {
        SaveCategoriesButton(
            title: buttonTitle,
            isSaving: isSaving,
            isEnabled: canSave,
            action: saveCategories
        )
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isUpdatingPreferences {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
    
    private var errorAlert: some View {
        Button("OK", role: .cancel) { }
    }
    
    // MARK: - Computed Properties
    
    private var navigationTitle: String {
        isUpdatingPreferences ? "Update Categories" : ""
    }
    
    private var gridColumns: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }
    
    private var selectedCount: Int {
        categories.filter { $0.isSelected }.count
    }
    
    private var selectionWarningColor: Color {
        selectedCount == 0 ? .red : .secondary
    }
    
    private var buttonTitle: String {
        isUpdatingPreferences ? "Update Categories" : "Continue"
    }
    
    private var canSave: Bool {
        selectedCount > 0 && !isSaving
    }
    
    // MARK: - Actions
    
    private func setupCategories() {
        if categories.isEmpty {
            categories = Affirmation.Category.allCases.map {
                CategorySelection(category: $0, isSelected: false)
            }
        }
        loadCurrentCategories()
    }
    
    private func loadCurrentCategories() {
        guard let currentCategories = authManager.userProfile?.preferences.categories else { return }
        
        for i in categories.indices {
            categories[i].isSelected = currentCategories.contains(categories[i].category.rawValue)
        }
    }
    
    private func toggleCategory(_ category: Binding<CategorySelection>) {
        withAnimation(.spring(response: 0.3)) {
            category.wrappedValue.isSelected.toggle()
        }
    }
    
    private func saveCategories() {
        let selectedCategories = categories
            .filter { $0.isSelected }
            .map { $0.category.rawValue }
        
        guard !selectedCategories.isEmpty else { return }
        
        isSaving = true
        
        Task {
            await performSave(selectedCategories)
        }
    }
    
    private func performSave(_ selectedCategories: [String]) async {
        do {
            if isUpdatingPreferences {
                var updatedPreferences = authManager.userProfile?.preferences ?? UserPreferences()
                updatedPreferences.categories = selectedCategories
                try await authManager.updateUserPreferences(updatedPreferences)
                
                await MainActor.run {
                    dismiss()
                }
            } else {
                try await authManager.completeOnboarding(categories: selectedCategories)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                isSaving = false
            }
        }
    }
}

// MARK: - Supporting Views

struct OnboardingHeader: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Choose Your Focus")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Select categories that resonate with you")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
        .padding(.top, 20)
        .padding(.bottom, 30)
    }
}

struct CategorySelection: Identifiable {
    let id = UUID()
    let category: Affirmation.Category
    var isSelected: Bool
}

struct CategoryCard: View {
    let category: Affirmation.Category
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(CategoryCardStyle(isSelected: isSelected))
    }
    
    private var cardContent: some View {
        VStack(spacing: 12) {
            Text(category.emoji)
                .font(.system(size: 36))
            
            Text(category.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }
}

struct CategoryCardStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(backgroundView)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
    }
}

struct SaveCategoriesButton: View {
    let title: String
    let isSaving: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            buttonContent
        }
        .disabled(!isEnabled)
    }
    
    private var buttonContent: some View {
        HStack {
            Text(title)
                .fontWeight(.semibold)
            
            if isSaving {
                ProgressView()
                    .scaleEffect(0.8)
                    .padding(.leading, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(backgroundColor)
        .foregroundColor(.white)
        .cornerRadius(12)
    }
    
    private var backgroundColor: Color {
        isEnabled && !isSaving ? Color.blue : Color.gray
    }
}

#Preview {
    OnboardingCategoriesView()
        .environment(AuthenticationManager.previewNeedsOnboarding)
}
