//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import SwiftUI

struct PosterHStack<
    Data: Collection
>: View where Data.Element: Poster, Data.Index == Int {

    @AdaptiveLayout
    private var viewLayout

    let elements: Data
    let displayType: PosterDisplayType
    let size: PosterDisplayType.Size
    let action: (Data.Element, Namespace.ID) -> Void

    private var layout: CollectionHStackLayout {
        #if os(tvOS)
        .grid(
            columns: displayType == .landscape ? 5 : 7,
            rows: 1,
            columnTrailingInset: 0
        )
        #else
        .minimumWidth(
            columnWidth: viewLayout.posterMinimumWidth(for: displayType, size: size),
            rows: 1,
            columnFraction: 0.5
        )
        #endif
    }

    #if os(tvOS)
    /// 1-based position of an element, for Datamori rank badges.
    private func datamoriPosition(of item: Data.Element) -> Int? {
        elements.firstIndex { $0.id == item.id }.map { $0 - elements.startIndex + 1 }
    }
    #endif

    @ContentBuilder
    var body: some View {
        CollectionHStack(
            uniqueElements: elements,
            layout: layout
        ) { item in
            PosterButton(
                item: item,
                displayType: displayType,
                size: size
            ) { namespace in
                action(item, namespace)
            }
            #if os(tvOS)
            .environment(\.datamoriPosterIndex, datamoriPosition(of: item))
            #endif
        }
        .clipsToBounds(false)
        .insets(horizontal: viewLayout.edgePadding)
        .itemSpacing(viewLayout.itemSpacing)
        .scrollBehavior(.continuousLeadingEdge)
        .contentInsetAdjustmentBehavior(.never)
        .withViewContext(.isThumb)
    }
}
