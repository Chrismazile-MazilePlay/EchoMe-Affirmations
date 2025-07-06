//
//  ServicesContainer.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import Foundation

final class ServicesContainer {
    private var factories: [ObjectIdentifier: Any] = [:]
    private var instances: [ObjectIdentifier: Any] = [:]
    
    func register<T>(_ type: T.Type, factory: @escaping (ServicesContainer) -> T) {
        factories[ObjectIdentifier(type)] = factory
    }
    
    func resolve<T>(_ type: T.Type) -> T {
        let key = ObjectIdentifier(type)
        
        // Return cached instance if exists
        if let instance = instances[key] as? T {
            return instance
        }
        
        // Create new instance using factory
        guard let factory = factories[key] as? (ServicesContainer) -> T else {
            fatalError("Service \(type) not registered. Please check your registration logic.")
        }
        
        let instance = factory(self)
        instances[key] = instance
        return instance
    }
    
    // Computed properties for backward compatibility
    var authViewModel: AuthenticationViewModel {
        resolve(AuthenticationViewModel.self)
    }
    
    var mockDataProvider: MockDataProvider {
        resolve(MockDataProvider.self)
    }
}
