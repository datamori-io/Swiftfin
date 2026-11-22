//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension NavigationRoute {

    static var datamoriHomeSettings: NavigationRoute {
        NavigationRoute(id: "datamoriHomeSettings") {
            DatamoriHomeSettingsView()
        }
    }

    static func datamoriHomeRowOrder(selection: Binding<[DatamoriHomeRow]>) -> NavigationRoute {
        NavigationRoute(id: "datamoriHomeRowOrder") {
            OrderedSectionSelectorView(selection: selection, sources: DatamoriHomeRow.allCases)
                .navigationTitle("Home Rows")
        }
    }
}

/// Settings → Home Rows: row order, Trending list URLs, genre rows.
struct DatamoriHomeSettingsView: View {

    @Default(.datamoriHomeRows)
    private var rows
    @Default(.datamoriTrendingListURLs)
    private var trendingURLs
    @Default(.datamoriGenreRows)
    private var genres

    @Router
    private var router

    /// Three editable URL slots (TV, movies, anime).
    private func urlBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { index < trendingURLs.count ? trendingURLs[index] : "" },
            set: { newValue in
                var urls = trendingURLs
                while urls.count <= index {
                    urls.append("")
                }
                urls[index] = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                trendingURLs = urls // keep empty slots so TV/movies/anime stay in place
            }
        )
    }

    private var genresBinding: Binding<String> {
        Binding(
            get: { genres.joined(separator: ", ") },
            set: { newValue in
                genres = newValue
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            }
        )
    }

    @ContentBuilder
    var body: some View {
        Form(image: .appMark) {
            Section {
                ChevronButton(
                    "Row Order",
                    content: rows.map(\.displayTitle).joined(separator: " · ")
                ) {
                    router.route(to: .datamoriHomeRowOrder(selection: $rows))
                }
            } header: {
                Text("Rows")
            } footer: {
                Text("Continue Watching and the newest addition always stay at the top. The order here is never changed automatically.")
            }

            Section {
                TextField("TV list URL", text: urlBinding(0))
                TextField("Movies list URL", text: urlBinding(1))
                TextField("Anime list URL", text: urlBinding(2))
            } header: {
                Text("Top 10 Trending — MDBList")
            } footer: {
                Text(
                    "MDBList list JSON URLs, ending in /json/ (TV, movies, anime). If a list can't be loaded, the row falls back to date added."
                )
            }

            Section {
                TextField("Genres", text: genresBinding)
            } header: {
                Text("Genre Rows")
            } footer: {
                Text("Comma-separated, shown in this order. Genres with no items are skipped.")
            }
        }
        .navigationTitle("Home Rows")
    }
}
