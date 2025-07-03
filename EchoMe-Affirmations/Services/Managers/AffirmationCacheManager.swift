//
//  AffirmationCacheManager.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/2/25.
//
 
import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class AffirmationCacheManager {
    // MARK: - Properties
    private let modelContainer: ModelContainer?
    private let firebaseService: FirebaseService
    private let audioCache = AudioCacheManager()
    
    // Observable state
    var cachedAffirmations: [Affirmation] = []
    var isLoading = false
    var currentBatch: [Affirmation] = []
    var lastBackgroundTime: Date?
    
    // Constants
    private let batchSize = 50
    private let maxCachedAudio = 50
    private let backgroundRefreshHours: Double = 4
    private let reloadThreshold = 10
    
    // MARK: - Initialization
    init(firebaseService: FirebaseService, isPreview: Bool = false) {
        self.firebaseService = firebaseService
        
        if !isPreview {
            do {
                self.modelContainer = try ModelContainer(for: AffirmationCache.self, CachedAudioFile.self)
                loadCachedAffirmations()
            } catch {
                print("❌ Failed to create ModelContainer: \(error)")
                self.modelContainer = nil
            }
        } else {
            self.modelContainer = nil
            loadMockData()
        }
    }
    
    // MARK: - Public Methods
    
    /// Load affirmations for main feed
    func loadBatch(categories: [String], forceRefresh: Bool = false) async {
        // Use cache first if available and not forcing refresh
        if !cachedAffirmations.isEmpty && !forceRefresh {
            currentBatch = Array(cachedAffirmations.prefix(batchSize))
            return
        }
        
        // Load new batch if needed
        if shouldRefreshBatch() || forceRefresh {
            await fetchNewBatch(categories: categories)
        }
    }
    
    /// Check if more affirmations needed
    func checkAndLoadMore(currentIndex: Int, categories: [String]) async {
        let remainingCount = currentBatch.count - currentIndex
        
        if remainingCount <= reloadThreshold {
            await fetchNextBatch(categories: categories)
        }
    }
    
    /// Load affirmations for continuous play
    func loadContinuousPlayBatch(preferences: ContinuousPlayPreferences) async -> [Affirmation] {
        // For now, return shuffled batch based on preferences
        // This will be enhanced with psychological algorithm later
        if MockDataProvider.isPreview {
            return MockDataProvider.shared.getDailyAffirmations().shuffled()
        }
        
        let categories = preferences.focusAreas
        await fetchNewBatch(categories: categories)
        return currentBatch.shuffled()
    }
    
    /// Cache audio file
    func cacheAudioFile(for affirmationId: String, audioData: Data) async {
        await audioCache.store(audioData: audioData, for: affirmationId)
    }
    
    /// Get cached audio
    func getCachedAudio(for affirmationId: String) -> URL? {
        return audioCache.getAudioURL(for: affirmationId)
    }
    
    // MARK: - Private Methods
    
    private func loadCachedAffirmations() {
        guard let modelContainer = modelContainer else { return }
        
        do {
            let descriptor = FetchDescriptor<AffirmationCache>(
                sortBy: [SortDescriptor(\.order)]
            )
            let context = ModelContext(modelContainer)
            let cached = try context.fetch(descriptor)
            
            self.cachedAffirmations = cached.map { $0.affirmation }
            self.currentBatch = Array(cachedAffirmations.prefix(batchSize))
            
            print("📱 Loaded \(cached.count) cached affirmations")
        } catch {
            print("❌ Failed to load cache: \(error)")
        }
    }
    
    private func shouldRefreshBatch() -> Bool {
        // Check if we need background refresh
        if let lastBackground = lastBackgroundTime {
            let hoursSince = Date().timeIntervalSince(lastBackground) / 3600
            return hoursSince >= backgroundRefreshHours
        }
        return true
    }
    
    private func fetchNewBatch(categories: [String]) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetchedData = try await firebaseService.fetchAffirmations(
                categories: categories.isEmpty ? nil : categories,
                limit: batchSize * 2 // Fetch extra for smooth scrolling
            )
            
            let affirmations = fetchedData.compactMap { data -> Affirmation? in
                guard let id = data["id"] as? String,
                      let text = data["text"] as? String else { return nil }
                
                return Affirmation(
                    id: id,
                    text: text,
                    categories: data["categories"] as? [String] ?? [],
                    tone: data["tone"] as? String,
                    length: data["length"] as? String
                )
            }
            
            await updateCache(with: affirmations)
            self.cachedAffirmations = affirmations
            self.currentBatch = Array(affirmations.prefix(batchSize))
            self.lastBackgroundTime = Date()
            
        } catch {
            print("❌ Failed to fetch affirmations: \(error)")
        }
    }
    
    private func fetchNextBatch(categories: [String]) async {
        // For infinite scroll, we'll append to current batch
        // In production, this would fetch next page from Firebase
        if currentBatch.count < cachedAffirmations.count {
            let startIndex = currentBatch.count
            let endIndex = min(startIndex + batchSize, cachedAffirmations.count)
            currentBatch.append(contentsOf: cachedAffirmations[startIndex..<endIndex])
        } else {
            // Loop back to beginning
            currentBatch.append(contentsOf: Array(cachedAffirmations.prefix(batchSize)))
        }
    }
    
    private func updateCache(with affirmations: [Affirmation]) async {
        guard let modelContainer = modelContainer else { return }
        
        let context = ModelContext(modelContainer)
        
        // Clear old cache
        do {
            try context.delete(model: AffirmationCache.self)
        } catch {
            print("❌ Failed to clear cache: \(error)")
        }
        
        // Add new items
        for (index, affirmation) in affirmations.enumerated() {
            let cached = AffirmationCache(
                id: affirmation.id,
                text: affirmation.text,
                categories: affirmation.categories,
                tone: affirmation.tone,
                length: affirmation.length,
                order: index
            )
            context.insert(cached)
        }
        
        do {
            try context.save()
        } catch {
            print("❌ Failed to save cache: \(error)")
        }
    }
    
    private func loadMockData() {
        let mockAffirmations = MockDataProvider.shared.getDailyAffirmations()
        cachedAffirmations = mockAffirmations
        currentBatch = Array(mockAffirmations.prefix(batchSize))
    }
}

// MARK: - Audio Cache Manager
private class AudioCacheManager {
    private let cacheDirectory: URL
    private let maxCacheSize = 50
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("AudioCache")
        
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func store(audioData: Data, for affirmationId: String) async {
        let fileURL = cacheDirectory.appendingPathComponent("\(affirmationId).m4a")
        
        do {
            try audioData.write(to: fileURL)
            await cleanOldFiles()
        } catch {
            print("❌ Failed to cache audio: \(error)")
        }
    }
    
    func getAudioURL(for affirmationId: String) -> URL? {
        let fileURL = cacheDirectory.appendingPathComponent("\(affirmationId).m4a")
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    
    private func cleanOldFiles() async {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            if files.count > maxCacheSize {
                let sortedFiles = try files.sorted { url1, url2 in
                    let date1 = try url1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                    let date2 = try url2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                    return date1 < date2
                }
                
                // Remove oldest files
                let filesToRemove = sortedFiles.prefix(files.count - maxCacheSize)
                for file in filesToRemove {
                    try FileManager.default.removeItem(at: file)
                }
            }
        } catch {
            print("❌ Failed to clean audio cache: \(error)")
        }
    }
}

// MARK: - Supporting Types
struct ContinuousPlayPreferences {
    var mood: String?
    var focusAreas: [String]
    var energyLevel: String?
    var skipQuestions: Bool
    
    static var `default`: ContinuousPlayPreferences {
        ContinuousPlayPreferences(
            mood: nil,
            focusAreas: [],
            energyLevel: nil,
            skipQuestions: true
        )
    }
}

// MARK: - Preview Support
extension AffirmationCacheManager {
    static var preview: AffirmationCacheManager {
        AffirmationCacheManager(firebaseService: FirebaseService.shared, isPreview: true)
    }
}
