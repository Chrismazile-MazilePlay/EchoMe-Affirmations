//
//  ProfileView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import SwiftUI

struct ProfileView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @State private var showingEditName = false
    @State private var editedName = ""
    
    var body: some View {
        NavigationStack {
            profileContent
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showingEditName) {
                    editNameSheet
                }
        }
    }
    
    // MARK: - View Components
    
    private var profileContent: some View {
        Group {
            if let profile = authManager.userProfile {
                profileList(for: profile)
            } else {
                loadingView
            }
        }
    }
    
    private var loadingView: some View {
        ProgressView()
    }
    
    private func profileList(for profile: User) -> some View {
        List {
            ProfileHeaderSection(profile: profile)
            ProfileStatisticsSection(profile: profile)
            ProfilePreferencesSection(profile: profile)
            ProfileActionsSection(
                onEditName: { showingEditName = true }
            )
        }
    }
    
    private var editNameSheet: some View {
        EditDisplayNameView(
            currentName: authManager.userProfile?.displayName ?? "",
            onSave: updateDisplayName
        )
    }
    
    // MARK: - Actions
    
    private func updateDisplayName(_ newName: String) {
        Task {
            try? await authManager.updateDisplayName(newName)
        }
    }
}

// MARK: - Section Views

struct ProfileHeaderSection: View {
    let profile: User
    
    var body: some View {
        Section {
            HStack {
                avatarView
                userInfoView
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    private var avatarView: some View {
        Text(profile.initials)
            .font(.title)
            .fontWeight(.semibold)
            .frame(width: 80, height: 80)
            .background(Circle().fill(Color.blue.gradient))
            .foregroundColor(.white)
    }
    
    private var userInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(profile.displayNameOrEmail)
                .font(.title3)
                .fontWeight(.medium)
            
            Text(profile.email)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(profile.membershipDuration)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ProfileStatisticsSection: View {
    let profile: User
    
    var body: some View {
        Section("Your Journey") {
            StatRow(icon: "quote.bubble", title: "Affirmations Viewed", value: "\(profile.totalAffirmationsViewed)")
            StatRow(icon: "heart.fill", title: "Favorites", value: "\(profile.favoriteCount)")
            StatRow(icon: "flame", title: "Current Streak", value: "\(profile.currentStreak) days")
            StatRow(icon: "trophy", title: "Longest Streak", value: "\(profile.longestStreak) days")
        }
    }
}

struct ProfilePreferencesSection: View {
    let profile: User
    
    var body: some View {
        Section("Preferences") {
            preferenceRow("Categories", icon: "tag", value: categoriesText)
            preferenceRow("Voice", icon: "speaker.wave.2", value: profile.preferences.voiceProfile)
            preferenceRow("Daily Affirmations", icon: "calendar", value: "\(profile.preferences.dailyAffirmationCount)")
            preferenceRow("Theme", icon: "moon", value: profile.preferences.theme.displayName)
        }
    }
    
    private var categoriesText: String {
        profile.preferences.categories.isEmpty ? "None selected" : "\(profile.preferences.categories.count) selected"
    }
    
    private func preferenceRow(_ title: String, icon: String, value: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct ProfileActionsSection: View {
    let onEditName: () -> Void
    
    var body: some View {
        Section {
            Button(action: onEditName) {
                Label("Edit Display Name", systemImage: "pencil")
            }
            
            NavigationLink {
                OnboardingCategoriesView(isUpdatingPreferences: true)
            } label: {
                Label("Update Categories", systemImage: "tag")
            }
        }
    }
}

// MARK: - Supporting Views

struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
}

struct EditDisplayNameView: View {
    @Environment(\.dismiss) private var dismiss
    let currentName: String
    let onSave: (String) -> Void
    
    @State private var name: String = ""
    
    var body: some View {
        NavigationStack {
            editForm
                .navigationTitle("Edit Display Name")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        cancelButton
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        saveButton
                    }
                }
                .onAppear { loadCurrentName() }
        }
    }
    
    private var editForm: some View {
        Form {
            TextField("Display Name", text: $name)
                .textContentType(.name)
                .autocorrectionDisabled()
        }
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            dismiss()
        }
    }
    
    private var saveButton: some View {
        Button("Save") {
            onSave(name)
            dismiss()
        }
        .disabled(!canSave)
    }
    
    private var canSave: Bool {
        !name.isEmpty && name != currentName
    }
    
    private func loadCurrentName() {
        name = currentName
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environment(AuthenticationManager.previewAuthenticated)
}
