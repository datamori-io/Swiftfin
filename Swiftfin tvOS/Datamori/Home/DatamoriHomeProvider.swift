//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import FactoryKit
import Foundation
import JellyfinAPI

/// Posted when a playback session ends, so Home can refresh Continue
/// Watching and Next Up (fixes stale Next Up after watching an episode).
enum DatamoriHomeEvents {

    static let playbackEnded = PassthroughSubject<Void, Never>()
}

/// The Datamori Home screen.
///
/// Hero (newest addition + Continue Watching) first, then the rows in the
/// order set in Settings → Home Rows. The order is never changed by the app.
struct DatamoriHomeProvider: ContentGroupProvider {

    @Injected(\.currentUserSession)
    var userSession: UserSession?

    let displayTitle: String = L10n.home
    let id: String = "datamori-home"

    var refreshRequests: AnyPublisher<ContentGroupRefreshRequest, Never> {
        DatamoriHomeEvents.playbackEnded
            .map { ContentGroupRefreshRequest() }
            .eraseToAnyPublisher()
    }

    func makeGroups(environment: Empty) async throws -> [any ContentGroup] {
        guard let userSession else { return [] }

        let parameters = Paths.GetUserViewsParameters(userID: userSession.user.id)
        let userViews = try await userSession.send(Paths.getUserViews(parameters: parameters)).value.items ?? []

        func ids(named names: [String]) -> [String] {
            let wanted = Set(names.map { $0.lowercased() })
            return userViews
                .filter { wanted.contains(($0.name ?? "").lowercased()) }
                .compactMap(\.id)
        }

        return _makeGroups(
            rows: Defaults[.datamoriHomeRows],
            genres: Defaults[.datamoriGenreRows],
            trendingIDs: ids(named: DatamoriLibraryNames.trending),
            leavingSoonIDs: ids(named: DatamoriLibraryNames.leavingSoon)
        )
    }

    @ContentGroupBuilder
    private func _makeGroups(
        rows: [DatamoriHomeRow],
        genres: [String],
        trendingIDs: [String],
        leavingSoonIDs: [String]
    ) -> [any ContentGroup] {
        DatamoriHeroContentGroup()

        for row in rows {
            switch row {
            case .nextUp:
                PosterGroup(
                    id: "datamori-next-up",
                    library: NextUpLibrary(),
                    posterDisplayType: .landscape,
                    posterSize: .small
                )

            case .recentlyAdded:
                PosterGroup(
                    id: "datamori-recently-added",
                    library: RecentlyAddedLibrary()
                )

            case .trending:
                if trendingIDs.isNotEmpty {
                    DatamoriBadgedPosterGroup(
                        group: PosterGroup(
                            id: "datamori-trending",
                            library: DatamoriTrendingLibrary(parentIDs: trendingIDs),
                            environment: .init(isHeaderButtonEnabled: false)
                        ),
                        badge: .rank
                    )
                }

            case .leavingSoon:
                if leavingSoonIDs.isNotEmpty {
                    DatamoriBadgedPosterGroup(
                        group: PosterGroup(
                            id: "datamori-leaving-soon",
                            library: DatamoriLeavingSoonLibrary(parentIDs: leavingSoonIDs),
                            environment: .init(isHeaderButtonEnabled: false)
                        ),
                        badge: .label("Leaving soon")
                    )
                }

            case .genres:
                for genre in genres {
                    PosterGroup(
                        id: "datamori-genre-\(genre)",
                        library: DatamoriGenreLibrary(genre: genre)
                    )
                }
            }
        }
    }
}
