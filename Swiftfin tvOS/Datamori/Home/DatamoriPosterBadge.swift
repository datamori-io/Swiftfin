//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// What badge, if any, posters in a row should show.
enum DatamoriPosterBadge: Equatable {

    /// A fixed label, e.g. "Leaving soon".
    case label(String)
    /// The poster's 1-based position in the row (Top 10).
    case rank
}

extension EnvironmentValues {

    /// Set by a Datamori row; read by `PosterButton` on tvOS.
    @Entry
    var datamoriPosterBadge: DatamoriPosterBadge? = nil

    /// The poster's 1-based position, for `.rank` badges.
    @Entry
    var datamoriPosterIndex: Int? = nil
}

extension View {

    /// Overlays the row's badge (if any) on a poster.
    @ContentBuilder
    func datamoriPosterBadge() -> some View {
        modifier(DatamoriPosterBadgeModifier())
    }
}

private struct DatamoriPosterBadgeModifier: ViewModifier {

    @Environment(\.datamoriPosterBadge)
    private var badge
    @Environment(\.datamoriPosterIndex)
    private var index

    private var text: String? {
        switch badge {
        case let .label(label): label
        case .rank: index.map { "#\($0)" }
        case nil: nil
        }
    }

    @ContentBuilder
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topLeading) {
                if let text {
                    Text(text)
                        .datamoriLabel(.caption2, weight: .semibold)
                        .foregroundStyle(Datamori.primaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Datamori.red, in: RoundedRectangle(cornerRadius: Datamori.cornerRadius))
                        .padding(10)
                        .allowsHitTesting(false)
                }
            }
    }
}

/// A poster row that badges every poster ("Leaving soon", "#1"…).
struct DatamoriBadgedPosterGroup<Library: PagingLibrary>: ContentGroup
where Library.Element: LibraryElement, Library.Element: Poster {

    let group: PosterGroup<Library>
    let badge: DatamoriPosterBadge

    var id: String {
        group.id
    }

    var viewModel: PagingLibraryViewModel<Library> {
        group.viewModel
    }

    var _shouldBeResolved: Bool {
        group._shouldBeResolved
    }

    @ContentBuilder
    func body(with viewModel: PagingLibraryViewModel<Library>) -> some View {
        group.body(with: viewModel)
            .environment(\.datamoriPosterBadge, badge)
    }
}
