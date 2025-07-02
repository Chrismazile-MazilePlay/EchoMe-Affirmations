//
//  RootView.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/1/25.
//

import SwiftUI

struct RootView: View {
    @Environment(\.services) private var services
    
    private var navigationState: NavigationState { services.navigationState }
    
    var body: some View {
        Group {
            switch navigationState.currentView {
            case .authentication:
                AuthenticationView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            
            case .onboarding:
                OnboardingCategoriesView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            
            case .main:
                ContentView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: navigationState.currentView)
    }
}

#Preview("Authenticated") {
    RootView()
        .environment(\.services, ServicesContainer.preview)
}

#Preview("Needs Onboarding") {
    RootView()
        .environment(\.services, ServicesContainer.previewNeedsOnboarding)
}

#Preview("Not Authenticated") {
    RootView()
        .environment(\.services, ServicesContainer.previewUnauthenticated)
}
