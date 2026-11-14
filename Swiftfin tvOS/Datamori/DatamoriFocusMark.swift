//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension View {

    /// Draws a thin accent-red outline on the view while its enclosing
    /// focusable control (button) has focus. The system lift/parallax
    /// still applies; this adds the brand "mark".
    @ContentBuilder
    func datamoriFocusMark(cornerRadius: CGFloat = Datamori.cornerRadius) -> some View {
        modifier(DatamoriFocusMarkModifier(cornerRadius: cornerRadius))
    }
}

private struct DatamoriFocusMarkModifier: ViewModifier {

    @Environment(\.isFocused)
    private var isFocused

    let cornerRadius: CGFloat

    @ContentBuilder
    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Datamori.red, lineWidth: Datamori.focusStroke)
                    .opacity(isFocused ? 1 : 0)
                    .animation(.easeOut(duration: 0.15), value: isFocused)
                    .allowsHitTesting(false)
            }
    }
}
