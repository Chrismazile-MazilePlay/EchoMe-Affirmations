//
//  EnvironmentKeys.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//
//
//import SwiftUI
//
//// MARK: - Environment Key
//private struct ServicesContainerKey: @preconcurrency EnvironmentKey {
//    @MainActor
//    static let defaultValue = ServicesContainer()
//}
//
//extension EnvironmentValues {
//    var services: ServicesContainer {
//        get { self[ServicesContainerKey.self] }
//        set { self[ServicesContainerKey.self] = newValue }
//    }
//}
//
//// MARK: - Preview Helpers
//extension ServicesContainer {
//    @MainActor
//    static var preview: ServicesContainer {
//        ServicesContainer()
//    }
//    
//    @MainActor
//    static var mockWithFavorites: ServicesContainer {
//        let container = ServicesContainer()
//        container.favoritesManager.favoriteIds = ["mock1", "mock2", "mock3"]
//        return container
//    }
//}
