//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

/// Ranks items by their position on Josh's MDBList trending lists.
///
/// Lists are fetched from the URLs in Settings, cached on disk, and refreshed
/// at most every few hours. Items are matched by provider ID
/// (TMDB / TVDB / IMDb in Jellyfin `ProviderIds`).
actor MDBListTrending {

    static let shared = MDBListTrending()

    /// One entry of an MDBList `/json/` list.
    private struct ListEntry: Decodable {

        let rank: Int?
        let id: Int?
        let imdb_id: String?
        let tvdbid: Int?
        let mediatype: String?
    }

    private struct Cache: Codable {

        var fetchedAt: Date
        var urls: [String]
        /// "tmdb:movie:123", "imdb:tt123", "tvdb:123" → combined rank (lower is better)
        var ranks: [String: Int]
    }

    private let refreshInterval: TimeInterval = 4 * 60 * 60
    private var cache: Cache?

    private var cacheURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("datamori-trending-ranks.json")
    }

    /// Returns the cached rank map, refreshing it when stale.
    /// Returns an empty map if no list could be loaded (callers fall back
    /// to date-added order).
    func ranks() async -> [String: Int] {
        let urls = Defaults[.datamoriTrendingListURLs]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if cache == nil {
            cache = loadCache()
        }

        if let cache, cache.urls == urls, Date.now.timeIntervalSince(cache.fetchedAt) < refreshInterval {
            return cache.ranks
        }

        guard let fresh = await fetch(urls: urls), fresh.isNotEmpty else {
            // Keep serving the last good order if a refresh fails.
            return cache?.urls == urls ? cache?.ranks ?? [:] : [:]
        }

        let newCache = Cache(fetchedAt: .now, urls: urls, ranks: fresh)
        cache = newCache
        saveCache(newCache)
        return fresh
    }

    /// Rank for an item, using any of its provider IDs.
    static func rank(for item: BaseItemDto, in ranks: [String: Int]) -> Int? {
        guard let providers = item.providerIDs else { return nil }

        var best: Int?
        for (key, value) in providers {
            let lookup: String? = switch key.lowercased() {
            case "tmdb": "tmdb:\(item.type == .movie ? "movie" : "show"):\(value)"
            case "imdb": "imdb:\(value)"
            case "tvdb": "tvdb:\(value)"
            default: nil
            }
            if let lookup, let rank = ranks[lookup] {
                best = min(best ?? rank, rank)
            }
        }
        return best
    }

    // MARK: - Fetch

    /// Interleaves the lists: rank 1 of every list, then rank 2, and so on.
    private func fetch(urls: [String]) async -> [String: Int]? {
        var lists: [[ListEntry]] = []

        for string in urls {
            guard let url = URL(string: string) else { continue }

            do {
                var request = URLRequest(url: url, timeoutInterval: 15)
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                let (data, response) = try await URLSession.shared.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { continue }

                let entries = try JSONDecoder().decode([ListEntry].self, from: data)
                lists.append(entries.sorted { ($0.rank ?? .max) < ($1.rank ?? .max) })
            } catch {
                continue
            }
        }

        guard lists.isNotEmpty else { return nil }

        var ranks: [String: Int] = [:]
        var position = 0
        let longest = lists.map(\.count).max() ?? 0

        for index in 0 ..< longest {
            for list in lists where index < list.count {
                let entry = list[index]
                var keys: [String] = []
                if let id = entry.id {
                    // TMDB IDs are only unique per media type.
                    let kind = entry.mediatype == "movie" ? "movie" : "show"
                    keys.append("tmdb:\(kind):\(id)")
                }
                if let imdb = entry.imdb_id, !imdb.isEmpty {
                    keys.append("imdb:\(imdb)")
                }
                if let tvdb = entry.tvdbid {
                    keys.append("tvdb:\(tvdb)")
                }
                guard keys.isNotEmpty else { continue }

                for key in keys where ranks[key] == nil {
                    ranks[key] = position
                }
                position += 1
            }
        }

        return ranks
    }

    // MARK: - Disk cache

    private func loadCache() -> Cache? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }

        return try? JSONDecoder().decode(Cache.self, from: data)
    }

    private func saveCache(_ cache: Cache) {
        guard let data = try? JSONEncoder().encode(cache) else { return }

        try? data.write(to: cacheURL, options: .atomic)
    }
}
