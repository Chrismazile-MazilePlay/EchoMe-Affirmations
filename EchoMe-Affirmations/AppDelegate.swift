//
//  AppDelegate.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/2/25.
//

import UIKit
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure Firebase only if not in preview mode
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            FirebaseApp.configure()
            print("🔥 Firebase configured in AppDelegate")
        } else {
            print("📱 Skipping Firebase configuration in preview mode")
        }
        
        return true
    }
}
