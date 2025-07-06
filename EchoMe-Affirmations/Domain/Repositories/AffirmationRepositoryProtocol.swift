//
//  AffirmationRepositoryProtocol.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import Foundation

protocol AffirmationRepositoryProtocol: ServiceProtocol {
    func fetchAffirmations() async throws -> [Affirmation]
    func fetchAffirmation(id: String) async throws -> Affirmation?
    func fetchAffirmationsByCategory(_ category: String) async throws -> [Affirmation]
    func searchAffirmations(query: String) async throws -> [Affirmation]
    func cacheAffirmations(_ affirmations: [Affirmation]) async throws
    func getCachedAffirmations() async throws -> [Affirmation]
}
