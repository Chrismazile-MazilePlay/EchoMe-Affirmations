//
//  EchoMe_AffirmationsApp.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import SwiftUI
import SwiftData

@main
struct EchoMeApp: App {
    @State private var servicesContainer: ServicesContainer
    let modelContainer: ModelContainer
    
    init() {
        FirebaseConfiguration.configure()
        
        // Set up model container
        do {
            modelContainer = try ModelContainer(for: AffirmationCache.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
        // Set up services container
        _servicesContainer = State(initialValue: ServicesContainer.production(modelContext: modelContainer.mainContext))
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.services, servicesContainer)
                .modelContainer(modelContainer)
        }
    }
}
