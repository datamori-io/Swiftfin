//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import JellyfinAPI
import SwiftUI
import UIKit

// MARK: - Tabs

extension TabItem {

    /// IDs of the tabs shown icon-only at the end of the Datamori tab bar.
    static let datamoriIconOnlyTabIDs: Set<String> = [TabItem.search.id, TabItem.settings.id]

    /// A tab that opens one Jellyfin library, found by its name on the server.
    static func datamoriLibrary(title: String, libraryName: String, systemImage: String) -> TabItem {
        TabItem(
            id: "datamori-library-\(libraryName)",
            title: title,
            systemImage: systemImage
        ) {
            DatamoriLibraryTabView(libraryName: libraryName, title: title)
        }
    }
}

/// Resolves a library by name, then shows it as a normal library grid.
struct DatamoriLibraryTabView: View {

    @Injected(\.currentUserSession)
    private var userSession

    let libraryName: String
    let title: String

    @State
    private var library: BaseItemDto?
    @State
    private var failed = false

    @ContentBuilder
    var body: some View {
        Group {
            if let library {
                PagingLibraryView(library: ItemLibrary(parent: library), displayTitle: title)
            } else if failed {
                ContentUnavailableView(
                    "\(title) library not found",
                    systemImage: "rectangle.stack.badge.minus",
                    description: Text("No library named “\(libraryName)” on this server.")
                )
                .focusable()
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            guard library == nil, let userSession else { return }

            do {
                let parameters = Paths.GetUserViewsParameters(userID: userSession.user.id)
                let views = try await userSession.send(Paths.getUserViews(parameters: parameters)).value.items ?? []
                if let match = views.first(where: { ($0.name ?? "").caseInsensitiveCompare(libraryName) == .orderedSame }) {
                    library = match
                } else {
                    failed = true
                }
            } catch {
                failed = true
            }
        }
    }
}

// MARK: - Tab bar look

enum DatamoriTabBarAppearance {

    /// Thin, wide-tracked uppercase titles; red focus pill.
    static func apply() {
        let font = UIFont.systemFont(ofSize: 30, weight: .light)
        let normal: [NSAttributedString.Key: Any] = [
            .font: font,
            .kern: 3.6,
            .foregroundColor: UIColor(Datamori.secondaryText),
        ]
        let focused: [NSAttributedString.Key: Any] = [
            .font: font,
            .kern: 3.6,
            .foregroundColor: UIColor.white,
        ]
        // White on the red selection pill (red-on-red was unreadable).
        let selected: [NSAttributedString.Key: Any] = [
            .font: font,
            .kern: 3.6,
            .foregroundColor: UIColor.white,
        ]

        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.selectionIndicatorTintColor = UIColor(Datamori.red)

        for layout in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
            layout.normal.titleTextAttributes = normal
            layout.normal.iconColor = UIColor(Datamori.secondaryText)
            layout.selected.titleTextAttributes = selected
            layout.selected.iconColor = .white
            layout.focused.titleTextAttributes = focused
            layout.focused.iconColor = .white
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().tintColor = UIColor(Datamori.red)
    }
}
