//
//  ServiceAssembly.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import Foundation
import SwiftData

extension ServicesContainer {
    static func production(modelContext: ModelContext? = nil) -> ServicesContainer {
        let container = ServicesContainer()
        
        // Core Services
        container.register(FirebaseServiceProtocol.self) { _ in
            FirebaseService()
        }
        
        container.register(MockDataProvider.self) { _ in
            MockDataProvider(isPreview: false)
        }
        
        // Repositories - all should use FirebaseServiceProtocol
        container.register(AuthenticationRepositoryProtocol.self) { container in
            let firebaseService = container.resolve(FirebaseServiceProtocol.self)
            return AuthenticationRepository(firebaseService: firebaseService)
        }
        
        container.register(FavoritesRepositoryProtocol.self) { container in
            let firebaseService = container.resolve(FirebaseServiceProtocol.self)
            return FavoritesRepository(firebaseService: firebaseService)
        }
        
        container.register(AffirmationRepositoryProtocol.self) { container in
            let firebaseService = container.resolve(FirebaseServiceProtocol.self)
            return AffirmationRepository(firebaseService: firebaseService, modelContext: modelContext)
        }
        
        container.register(UserRepositoryProtocol.self) { container in
            let firebaseService = container.resolve(FirebaseServiceProtocol.self)
            return UserRepository(firebaseService: firebaseService)
        }
        
        // ViewModels
        container.register(AuthenticationViewModel.self) { _ in
            return AuthenticationViewModel()
        }
        
        // ViewModels
        container.register(AuthenticationViewModel.self) { container in
            return AuthenticationViewModel()
        }
        
        return container
    }
    
    static var preview: ServicesContainer {
        let container = ServicesContainer()
        
        // Mock Services for preview/testing
        container.register(FirebaseServiceProtocol.self) { _ in
            MockFirebaseService()  // This is where MockFirebaseService is used
        }
        
        container.register(MockDataProvider.self) { _ in
            MockDataProvider(isPreview: true)
        }
        
        // Same repositories but they'll use MockFirebaseService
        container.register(AuthenticationRepositoryProtocol.self) { container in
            let firebaseService = container.resolve(FirebaseServiceProtocol.self)
            return AuthenticationRepository(firebaseService: firebaseService)
        }
        
        container.register(FavoritesRepositoryProtocol.self) { container in
            let firebaseService = container.resolve(FirebaseServiceProtocol.self)
            return FavoritesRepository(firebaseService: firebaseService)
        }
        
        container.register(AffirmationRepositoryProtocol.self) { container in
            let firebaseService = container.resolve(FirebaseServiceProtocol.self)
            return AffirmationRepository(firebaseService: firebaseService)
        }
        
        container.register(UserRepositoryProtocol.self) { container in
            let firebaseService = container.resolve(FirebaseServiceProtocol.self)
            return UserRepository(firebaseService: firebaseService)
        }
        
        // ViewModels
        container.register(AuthenticationViewModel.self) { _ in
            return AuthenticationViewModel()
        }
        
        return container
    }
}
