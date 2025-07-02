//
//  EchoMe_AffirmationsApp.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 6/30/25.
//

import SwiftUI
import FirebaseCore

@main
struct EchoMe_AffirmationsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var services = ServicesContainer()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.services, services)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Only configure Firebase if not in preview mode
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            FirebaseApp.configure()
        }
        return true
    }
}
