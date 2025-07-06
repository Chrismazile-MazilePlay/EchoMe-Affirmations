//
//  FavoritesRepositoryProtocol.swift
//  EchoMe-Affirmations
//
//  Created by Christopher Mazile on 7/5/25.
//

import Foundation
import Combine

protocol FavoritesRepositoryProtocol {
    var favoriteIdsPublisher: AnyPublisher<Set<String>, Never> { get }
    func addFavorite(affirmationId: String, text: String) async throws
    func removeFavorite(affirmationId: String) async throws
    func isFavorite(affirmationId: String) -> Bool
    func getFavoriteIds() -> Set<String>
    func syncWithWatch(favoriteIds: [String]) async throws
}
