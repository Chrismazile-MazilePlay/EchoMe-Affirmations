import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import WatchConnectivity

struct ContentView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @State private var affirmations: [Affirmation] = []
    @State private var isLoading = true
    @State private var userCategories: [String] = []
    @State private var watchConnectivity = WatchConnectivityManager.shared
    @State private var favoritesManager = FavoritesManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if affirmations.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No affirmations found")
                            .font(.title3)
                            .foregroundColor(.gray)
                        Text("Try updating your preferences")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Category tags
                            if !userCategories.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(userCategories, id: \.self) { category in
                                            CategoryTag(category: category)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.top, 12)
                                .padding(.bottom, 16)
                            }
                            
                            // Affirmations
                            VStack(spacing: 15) {
                                ForEach(affirmations) { affirmation in
                                    AffirmationCard(
                                        id: affirmation.id,
                                        text: affirmation.text
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Your Daily Affirmations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        NavigationLink {
                            FavoritesView()
                        } label: {
                            Label("My Favorites", systemImage: "heart.fill")
                        }
                        
                        NavigationLink {
                            VoiceSettingsView()
                        } label: {
                            Label("Voice Settings", systemImage: "speaker.wave.3")
                        }
                        
                        Divider()
                        
                        Button(action: { authManager.signOut() }) {
                            Label("Sign Out", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            loadContent()
            // Start listening to favorites changes
            if !MockDataProvider.isPreview {
                favoritesManager.startListening()
            }
        }
        .onDisappear {
            // Stop listening when view disappears
            if !MockDataProvider.isPreview {
                favoritesManager.stopListening()
            }
        }
    }
    
    private func loadContent() {
        if MockDataProvider.isPreview {
            loadMockData()
        } else {
            Task {
                await fetchPersonalizedAffirmations()
            }
        }
    }
    
    func loadMockData() {
        MockDataProvider.simulateLoading(seconds: 0.3) {
            self.affirmations = MockDataProvider.shared.getDailyAffirmations()
            self.userCategories = MockDataProvider.shared.getUserCategories()
            self.isLoading = false
            
            // Send to watch
            sendAffirmationsToWatch()
        }
    }
    
    func fetchPersonalizedAffirmations() async {
        // Guard against preview environment
        guard !MockDataProvider.isPreview else {
            loadMockData()
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            self.isLoading = false
            return
        }
        
        do {
            let db = Firestore.firestore()
            
            // Get user preferences
            let userDoc = try await db.collection("users").document(userId).getDocument()
            
            if let data = userDoc.data(),
               let preferences = data["preferences"] as? [String: Any],
               let categories = preferences["categories"] as? [String] {
                
                self.userCategories = categories
                
                // Fetch affirmations
                if !categories.isEmpty {
                    self.affirmations = try await Affirmation.fetchByCategories(categories, limit: 10)
                        .shuffled()
                        .prefix(5)
                        .map { $0 }
                } else {
                    self.affirmations = try await Affirmation.fetchRandom(limit: 5)
                }
            } else {
                self.affirmations = try await Affirmation.fetchRandom(limit: 5)
            }
        } catch {
            print("Error fetching affirmations: \(error)")
        }
        
        self.isLoading = false
        
        // Send affirmations to watch after loading
        sendAffirmationsToWatch()
    }
    
    private func sendAffirmationsToWatch() {
        print("📱 Sending \(affirmations.count) affirmations to watch")
        watchConnectivity.sendAffirmationsToWatch(affirmations)
    }
}

// Category Tag Component
struct CategoryTag: View {
    let category: String
    
    var body: some View {
        Text(category.capitalized)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(15)
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
    .environment(AuthenticationManager.previewAuthenticated)
}
