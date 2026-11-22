//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// Datamori action button: raised dark surface at rest, accent red when
/// focused (instead of the system white/grey focus).
struct DatamoriButtonStyle: ButtonStyle {

    @ContentBuilder
    func makeBody(configuration: Configuration) -> some View {
        DatamoriButtonBody(configuration: configuration)
    }
}

private struct DatamoriButtonBody: View {

    @Environment(\.isFocused)
    private var isFocused

    let configuration: ButtonStyleConfiguration

    @ContentBuilder
    var body: some View {
        configuration.label
            .foregroundStyle(isFocused ? Color.white : Datamori.primaryText)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(
                isFocused ? Datamori.red : Datamori.raised,
                in: RoundedRectangle(cornerRadius: Datamori.cornerRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: Datamori.cornerRadius)
                    .strokeBorder(isFocused ? Datamori.redHi : Datamori.hairline, lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : (isFocused ? 1.06 : 1))
            .shadow(color: isFocused ? Datamori.red.opacity(0.35) : .clear, radius: 18, y: 8)
            .animation(.easeOut(duration: 0.15), value: isFocused)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == DatamoriButtonStyle {

    static var datamori: DatamoriButtonStyle {
        DatamoriButtonStyle()
    }
}
