//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

/// Rows on the Datamori Home screen below the hero.
///
/// The hero (newest addition + Continue Watching) is always first and is not
/// part of this list. The order of the remaining rows is fixed, set in
/// Settings, and never reshuffled automatically.
enum DatamoriHomeRow: String, CaseIterable, Displayable, Hashable, Defaults.Serializable {

    case nextUp
    case recentlyAdded
    case trending
    case leavingSoon
    case genres

    var displayTitle: String {
        switch self {
        case .nextUp: "Next Up"
        case .recentlyAdded: "Recently Added"
        case .trending: "Top 10 Trending"
        case .leavingSoon: "Leaving Soon"
        case .genres: "Genre Rows"
        }
    }
}

/// Jellyfin library names the Datamori rows are built from.
enum DatamoriLibraryNames {

    static let trending = ["Trending", "Trending Movies", "Trending Anime"]
    static let leavingSoon = ["Shows (Leaving Soon)", "Movies (Leaving Soon)"]
}

extension Defaults.Keys {

    /// Enabled Home rows, in display order.
    static let datamoriHomeRows = Key<[DatamoriHomeRow]>(
        "datamori.home.rows",
        default: DatamoriHomeRow.allCases
    )

    /// MDBList list JSON URLs used to rank Top 10 Trending.
    /// Order: TV, movies, anime. All three answer with a JSON array at `/json/`.
    static let datamoriTrendingListURLs = Key<[String]>(
        "datamori.home.trendingListURLs",
        default: [
            "https://mdblist.com/lists/datamori-io/trending/json/",
            "https://mdblist.com/lists/datamori/trending-movies/json/",
            "https://mdblist.com/lists/datamori/trending-anime/json/",
        ]
    )

    /// Genre rows, in display order. Genres with no items are skipped.
    static let datamoriGenreRows = Key<[String]>(
        "datamori.home.genreRows",
        default: ["Action", "Comedy", "Drama", "Animation", "Science Fiction", "Documentary"]
    )
}
