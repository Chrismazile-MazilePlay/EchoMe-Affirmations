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
        print("🟩 ServiceAssembly: Creating production container")
        let container = ServicesContainer()
        
        // Core Services
//        container.register(FirebaseServiceProtocol.self) { _ in
//            FirebaseService()
//        }
        
        container.register(FirebaseServiceProtocol.self) { _ in
            print("🟩 ServiceAssembly: Creating FirebaseService")
            return FirebaseService()
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
        
        // ViewModels - NOW PROPERLY INJECTED
//        container.register(AuthenticationViewModel.self) { container in
//            let authRepository = container.resolve(AuthenticationRepositoryProtocol.self)
//            return AuthenticationViewModel(authRepository: authRepository)
//        }
        
        container.register(AuthenticationViewModel.self) { container in
            print("🟩 ServiceAssembly: Creating AuthenticationViewModel")
            let authRepository = container.resolve(AuthenticationRepositoryProtocol.self)
            print("🟩 ServiceAssembly: AuthRepository resolved: \(authRepository)")
            return AuthenticationViewModel(authRepository: authRepository)
        }
        
        container.register(OnboardingViewModel.self) { container in
            let userRepository = container.resolve(UserRepositoryProtocol.self)
            let authViewModel = container.resolve(AuthenticationViewModel.self)
            return OnboardingViewModel(userRepository: userRepository, authViewModel: authViewModel)
        }
        
        print("🟩 ServiceAssembly: Production container ready")
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
        
        // ViewModels - NOW PROPERLY INJECTED
        container.register(AuthenticationViewModel.self) { container in
            let authRepository = container.resolve(AuthenticationRepositoryProtocol.self)
            return AuthenticationViewModel(authRepository: authRepository)
        }
        
        container.register(OnboardingViewModel.self) { container in
            let userRepository = container.resolve(UserRepositoryProtocol.self)
            let authViewModel = container.resolve(AuthenticationViewModel.self)
            return OnboardingViewModel(userRepository: userRepository, authViewModel: authViewModel)
        }
        
        return container
    }
}
