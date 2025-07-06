//
//  ServicesContainer.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import Foundation

final class ServicesContainer {
    private var services: [ObjectIdentifier: Any] = [:]
    
    func register<T>(_ type: T.Type, factory: @escaping (ServicesContainer) -> T) {
        services[ObjectIdentifier(type)] = factory
    }
    
    func resolve<T>(_ type: T.Type) -> T {
        guard let factory = services[ObjectIdentifier(type)] as? (ServicesContainer) -> T else {
            fatalError("Service \(type) not registered. Please check your registration logic.")
        }
        return factory(self)
    }
    
    // Computed properties for backward compatibility
    var authViewModel: AuthenticationViewModel {
        resolve(AuthenticationViewModel.self)
    }
    
    var mockDataProvider: MockDataProvider {
        resolve(MockDataProvider.self)
    }
}
