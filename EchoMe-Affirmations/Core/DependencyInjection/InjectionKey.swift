//
//  InjectionKey.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import SwiftUI

// MARK: - Environment Key for ServicesContainer
struct ServicesContainerKey: EnvironmentKey {
    @MainActor
    static var defaultValue = ServicesContainer()
}

extension EnvironmentValues {
    var services: ServicesContainer {
        get { self[ServicesContainerKey.self] }
        set { self[ServicesContainerKey.self] = newValue }
    }
}
