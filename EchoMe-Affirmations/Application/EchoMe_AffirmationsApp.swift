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
        print("🟦 EchoMeApp: Starting initialization")
        FirebaseConfiguration.configure()
        print("🟦 EchoMeApp: Firebase configured")
        
        // Set up model container
        do {
            modelContainer = try ModelContainer(for: AffirmationCache.self)
            print("🟦 EchoMeApp: ModelContainer created")
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
        // Set up services container
        let container = ServicesContainer.production(modelContext: modelContainer.mainContext)
        print("🟦 EchoMeApp: ServicesContainer created")
        _servicesContainer = State(initialValue: container)
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.services, servicesContainer)
                .modelContainer(modelContainer)
        }
    }
}
