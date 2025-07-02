//
//  ServicesContainer.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

//
//  ServicesContainer.swift
//  EchoMe-Affirmations
//
//  Created on [Current Date].
//

import SwiftUI

@Observable
@MainActor
class ServicesContainer {
    let favoritesManager: FavoritesManager
    let watchConnectivityManager: WatchConnectivityManager
    let speechManager: SpeechManager
    
    init(
        favoritesManager: FavoritesManager? = nil,
        watchConnectivityManager: WatchConnectivityManager? = nil,
        speechManager: SpeechManager? = nil
    ) {
        self.favoritesManager = favoritesManager ?? FavoritesManager()
        self.watchConnectivityManager = watchConnectivityManager ?? WatchConnectivityManager()
        self.speechManager = speechManager ?? SpeechManager()
        
        // Set up dependencies
        self.favoritesManager.watchConnectivityManager = self.watchConnectivityManager
    }
}

// MARK: - Environment Key
private struct ServicesContainerKey: @preconcurrency EnvironmentKey {
    @MainActor
    static let defaultValue = ServicesContainer()
}

extension EnvironmentValues {
    var services: ServicesContainer {
        get { self[ServicesContainerKey.self] }
        set { self[ServicesContainerKey.self] = newValue }
    }
}
