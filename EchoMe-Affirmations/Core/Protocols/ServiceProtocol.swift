//
//  ServiceProtocol.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import Foundation

protocol ServiceProtocol {
    func setup() async throws
    func cleanup()
    var isReady: Bool { get }
}

extension ServiceProtocol {
    func cleanup() {}
    
    var isReady: Bool {
        return true
    }
}
