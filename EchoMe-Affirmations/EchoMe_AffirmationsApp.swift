//
//  EchoMe_AffirmationsApp.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 6/30/25.
//

import SwiftUI

@main
struct EchoMe_AffirmationsApp: App {
    @State private var services = ServicesContainer()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.services, services)
        }
    }
}
