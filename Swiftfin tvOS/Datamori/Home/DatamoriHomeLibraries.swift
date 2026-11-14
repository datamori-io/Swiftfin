//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Get
import JellyfinAPI

// MARK: - Shared request helper

@MainActor
private func datamoriItemsRequest(
    pageState: LibraryPageState,
    parentID: String? = nil,
    genres: [String]? = nil,
    sortBy: [ItemSortBy],
    sortOrder: [JellyfinAPI.SortOrder],
    limit: Int,
    startIndex: Int = 0,
    extraFields: [ItemFields] = []
) -> Request<BaseItemDtoQueryResult> {
    var parameters = Paths.GetItemsParameters()
    parameters.enableUserData = true
    parameters.fields = PosterSubtitleField.itemFields + extraFields
    parameters.genres = genres
    parameters.includeItemTypes = [.movie, .series]
    parameters.isRecursive = true
    parameters.limit = limit
    parameters.parentID = parentID
    parameters.sortBy = sortBy
    parameters.sortOrder = sortOrder
    parameters.startIndex = startIndex
    parameters.userID = pageState.userSession.user.id
    return Paths.getItems(parameters: parameters)
}

// MARK: - Leaving Soon

/// Items in the Janitorr-filled "Leaving Soon" libraries, merged into one row.
/// Single page only: these libraries are small by design.
struct DatamoriLeavingSoonLibrary: BaseItemKindLibrary {

    let libraryItemTypes: [BaseItemKind] = [.movie, .series]
    let parent: TitledLibraryParent = .init(displayTitle: "Leaving Soon", id: "datamori-leaving-soon")

    /// IDs of the "Shows (Leaving Soon)" / "Movies (Leaving Soon)" libraries.
    let parentIDs: [String]

    func retrievePage(environment: Empty, pageState: LibraryPageState) async throws -> [ItemPatch] {
        guard pageState.pageOffset == 0 else { return [] }

        var patches: [ItemPatch] = []
        for parentID in parentIDs {
            let request = datamoriItemsRequest(
                pageState: pageState,
                parentID: parentID,
                sortBy: [.dateCreated],
                sortOrder: [.ascending],
                limit: 40
            )
            let response = try await pageState.userSession.client.send(request)
            patches += try response.patches()
        }

        // Oldest additions first: the likeliest to be removed next.
        return patches.sorted {
            ($0.value.dateCreated ?? .distantFuture) < ($1.value.dateCreated ?? .distantFuture)
        }
    }
}

// MARK: - Top 10 Trending

/// Items in the "Trending" libraries, ranked by MDBList list position.
/// Falls back to newest-first when the lists can't be loaded.
struct DatamoriTrendingLibrary: BaseItemKindLibrary {

    let libraryItemTypes: [BaseItemKind] = [.movie, .series]
    let parent: TitledLibraryParent = .init(displayTitle: "Top 10 Trending", id: "datamori-trending")

    /// IDs of the "Trending", "Trending Movies" and "Trending Anime" libraries.
    let parentIDs: [String]

    func retrievePage(environment: Empty, pageState: LibraryPageState) async throws -> [ItemPatch] {
        guard pageState.pageOffset == 0 else { return [] }

        var patches: [ItemPatch] = []
        for parentID in parentIDs {
            let request = datamoriItemsRequest(
                pageState: pageState,
                parentID: parentID,
                sortBy: [.dateCreated],
                sortOrder: [.descending],
                limit: 300,
                extraFields: [.providerIDs]
            )
            let response = try await pageState.userSession.client.send(request)
            patches += try response.patches()
        }

        // De-duplicate across libraries.
        var seen = Set<String>()
        patches = patches.filter { patch in
            guard let id = patch.value.id else { return false }

            return seen.insert(id).inserted
        }

        let ranks = await MDBListTrending.shared.ranks()

        guard ranks.isNotEmpty else {
            return Array(patches.sorted {
                ($0.value.dateCreated ?? .distantPast) > ($1.value.dateCreated ?? .distantPast)
            }
            .prefix(10))
        }

        let ranked = patches
            .compactMap { patch -> (ItemPatch, Int)? in
                guard let rank = MDBListTrending.rank(for: patch.value, in: ranks) else { return nil }

                return (patch, rank)
            }
            .sorted { $0.1 < $1.1 }
            .map(\.0)

        return Array(ranked.prefix(10))
    }
}

// MARK: - Genre row

/// Movies and shows in one genre, newest first. Paged.
struct DatamoriGenreLibrary: BaseItemKindLibrary {

    let libraryItemTypes: [BaseItemKind] = [.movie, .series]
    let genre: String

    var parent: TitledLibraryParent {
        .init(displayTitle: genre, id: "datamori-genre-\(genre)")
    }

    func retrievePage(environment: Empty, pageState: LibraryPageState) async throws -> [ItemPatch] {
        let request = datamoriItemsRequest(
            pageState: pageState,
            genres: [genre],
            sortBy: [.dateCreated],
            sortOrder: [.descending],
            limit: pageState.pageSize,
            startIndex: pageState.pageOffset
        )
        let response = try await pageState.userSession.client.send(request)
        return try pageState.items(from: response)
    }
}
