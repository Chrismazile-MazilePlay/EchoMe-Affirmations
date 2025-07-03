//
//  EchoMe_AffirmationsApp.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 6/30/25.
//

import SwiftUI

@main
struct EchoMeAffirmationsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var services = ServicesContainer()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.services, services)
                .modelContainer(for: AffirmationCache.self)
        }
    }
}
