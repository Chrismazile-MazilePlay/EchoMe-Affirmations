//
//  FirebaseService.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import Observation

// MARK: - Clean Data Transfer Objects (No Firebase Types)

struct AuthUser {
    let uid: String
    let email: String?
}

struct UserProfileData {
    let email: String
    let displayName: String?
    let onboardingCompleted: Bool
    let preferences: [String: Any]
    let createdAt: Date
    let lastActiveAt: Date?
    let totalAffirmationsViewed: Int
    let favoriteCount: Int
    let currentStreak: Int
    let longestStreak: Int
}

struct FavoriteData {
    let id: String
    let affirmationId: String
    let text: String
    let savedAt: Date
}

// MARK: - Listener Wrapper
// Wraps Firebase listeners to hide implementation details
public class FirebaseListener {
    private let removeHandler: () -> Void
    
    fileprivate init(removeHandler: @escaping () -> Void) {
        self.removeHandler = removeHandler
    }
    
    public func remove() {
        removeHandler()
    }
}

// MARK: - Firebase Service

@Observable
@MainActor
public class FirebaseService {
    // MARK: - Singleton
    static let shared = FirebaseService()
    
    // MARK: - Properties
    private var auth: Auth?
    private var db: Firestore?
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var firestoreListeners: [ListenerRegistration] = []
    
    // Observable state
    var currentAuthUser: AuthUser?
    
    // MARK: - Initialization
    private init() {
        // Initialize Firebase services only after Firebase is configured
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            // Firebase should already be configured by AppDelegate
            if FirebaseApp.app() != nil {
                auth = Auth.auth()
                db = Firestore.firestore()
                print("🔥 FirebaseService initialized with Auth and Firestore")
            } else {
                print("⚠️ FirebaseApp not configured yet")
            }
        }
    }
    
    // MARK: - Cleanup
    nonisolated func cleanup() {
        Task { @MainActor in
            // Remove auth listener
            if let authListener = authStateListener {
                Auth.auth().removeStateDidChangeListener(authListener)
                self.authStateListener = nil
            }
            
            // Remove Firestore listeners
            firestoreListeners.forEach { $0.remove() }
            firestoreListeners.removeAll()
        }
    }
    
    // MARK: - Remove Listener
    func removeListener(_ listener: FirebaseListener) {
        listener.remove()
    }
    
    // MARK: - Authentication
    
    func startAuthStateListener(handler: @escaping (AuthUser?) -> Void) {
        guard let auth = auth else { return }
        
        authStateListener = auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            let authUser = firebaseUser.map { AuthUser(uid: $0.uid, email: $0.email) }
            self?.currentAuthUser = authUser
            handler(authUser)
        }
    }
    
    func signIn(email: String, password: String) async throws -> AuthUser {
        guard let auth = auth else {
            throw FirebaseError.notConfigured
        }
        
        let result = try await auth.signIn(withEmail: email, password: password)
        return AuthUser(uid: result.user.uid, email: result.user.email)
    }
    
    func signUp(email: String, password: String) async throws -> AuthUser {
        guard let auth = auth else {
            throw FirebaseError.notConfigured
        }
        
        let result = try await auth.createUser(withEmail: email, password: password)
        return AuthUser(uid: result.user.uid, email: result.user.email)
    }
    
    func signOut() throws {
        guard let auth = auth else {
            throw FirebaseError.notConfigured
        }
        
        try auth.signOut()
    }
    
    func resetPassword(email: String) async throws {
        guard let auth = auth else {
            throw FirebaseError.notConfigured
        }
        
        try await auth.sendPasswordReset(withEmail: email)
    }
    
    // MARK: - User Profile
    
    func createUserProfile(userId: String, email: String) async throws {
        guard let db = db else {
            throw FirebaseError.notConfigured
        }
        
        let userData: [String: Any] = [
            "email": email,
            "createdAt": Timestamp(date: Date()),
            "onboardingCompleted": false,
            "preferences": [
                "categories": [],
                "voiceProfile": "Calm & Clear",
                "dailyAffirmationCount": 5,
                "notificationEnabled": false,
                "theme": "system"
            ],
            "totalAffirmationsViewed": 0,
            "favoriteCount": 0,
            "currentStreak": 0,
            "longestStreak": 0
        ]
        
        try await db.collection("users").document(userId).setData(userData)
    }
    
    func listenToUserProfile(userId: String, handler: @escaping (UserProfileData?) -> Void) -> FirebaseListener? {
        guard let db = db else { return nil }
        
        let listener = db.collection("users").document(userId)
            .addSnapshotListener { snapshot, error in
                guard error == nil,
                      let data = snapshot?.data() else {
                    handler(nil)
                    return
                }
                
                let profile = UserProfileData(
                    email: data["email"] as? String ?? "",
                    displayName: data["displayName"] as? String,
                    onboardingCompleted: data["onboardingCompleted"] as? Bool ?? false,
                    preferences: data["preferences"] as? [String: Any] ?? [:],
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    lastActiveAt: (data["lastActiveAt"] as? Timestamp)?.dateValue(),
                    totalAffirmationsViewed: data["totalAffirmationsViewed"] as? Int ?? 0,
                    favoriteCount: data["favoriteCount"] as? Int ?? 0,
                    currentStreak: data["currentStreak"] as? Int ?? 0,
                    longestStreak: data["longestStreak"] as? Int ?? 0
                )
                
                handler(profile)
            }
        
        firestoreListeners.append(listener)
        
        // Return wrapped listener
        return FirebaseListener { [weak self] in
            listener.remove()
            self?.firestoreListeners.removeAll { $0 === listener }
        }
    }
    
    func updateUserData(userId: String, updates: [String: Any]) async throws {
        guard let db = db else {
            throw FirebaseError.notConfigured
        }
        
        var updatesWithTimestamp = updates
        updatesWithTimestamp["lastActiveAt"] = Timestamp(date: Date())
        
        try await db.collection("users").document(userId).updateData(updatesWithTimestamp)
    }
    
    func incrementUserStat(userId: String, field: String, by value: Int64 = 1) async throws {
        guard let db = db else {
            throw FirebaseError.notConfigured
        }
        
        try await db.collection("users").document(userId).updateData([
            field: FieldValue.increment(value),
            "lastActiveAt": Timestamp(date: Date())
        ])
    }
    
    // MARK: - Favorites
    
    func listenToFavorites(userId: String, handler: @escaping ([FavoriteData]) -> Void) -> FirebaseListener? {
        guard let db = db else { return nil }
        
        let listener = db.collection("users").document(userId)
            .collection("favorites")
            .order(by: "savedAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard error == nil else {
                    handler([])
                    return
                }
                
                let favorites = snapshot?.documents.compactMap { doc -> FavoriteData? in
                    let data = doc.data()
                    guard let text = data["text"] as? String else { return nil }
                    
                    return FavoriteData(
                        id: doc.documentID,
                        affirmationId: data["affirmationId"] as? String ?? doc.documentID,
                        text: text,
                        savedAt: (data["savedAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                } ?? []
                
                handler(favorites)
            }
        
        firestoreListeners.append(listener)
        
        // Return wrapped listener
        return FirebaseListener { [weak self] in
            listener.remove()
            self?.firestoreListeners.removeAll { $0 === listener }
        }
    }
    
    func addFavorite(userId: String, affirmationId: String, text: String) async throws {
        guard let db = db else {
            throw FirebaseError.notConfigured
        }
        
        try await db.collection("users").document(userId)
            .collection("favorites").document(affirmationId)
            .setData([
                "affirmationId": affirmationId,
                "text": text,
                "savedAt": Timestamp(date: Date())
            ])
    }
    
    func removeFavorite(userId: String, affirmationId: String) async throws {
        guard let db = db else {
            throw FirebaseError.notConfigured
        }
        
        try await db.collection("users").document(userId)
            .collection("favorites").document(affirmationId)
            .delete()
    }
    
    // MARK: - Affirmations
    
    func fetchAffirmations(categories: [String]? = nil, limit: Int = 10) async throws -> [[String: Any]] {
        guard let db = db else {
            throw FirebaseError.notConfigured
        }
        
        var query: Query = db.collection("affirmations")
            .whereField("isActive", isEqualTo: true)
        
        if let categories = categories, !categories.isEmpty {
            query = query.whereField("categories", arrayContainsAny: categories)
        }
        
        query = query.limit(to: limit)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.map { doc in
            var data = doc.data()
            data["id"] = doc.documentID
            return data
        }
    }
}

// MARK: - Error Types
enum FirebaseError: LocalizedError {
    case notConfigured
    case invalidData
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Firebase is not configured"
        case .invalidData:
            return "Invalid data format"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
