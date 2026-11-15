//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// Brand tokens for the Datamori look. Keep every brand value here so the
/// rest of the fork only references names, never raw hex values.
enum Datamori {

    // MARK: - Colours (from the web theme's --dm-* variables)

    /// `--dm-ink` page background.
    static let ink = Color(dmHex: 0x0E0E0F)
    /// `--dm-panel` panels / sections.
    static let panel = Color(dmHex: 0x161617)
    /// `--dm-raise` raised surfaces, cards.
    static let raised = Color(dmHex: 0x1F1F21)
    /// `--dm-line` hairlines.
    static let hairline = Color(dmHex: 0x2E2E31)
    /// `--dm-gray` secondary text.
    static let secondaryText = Color(dmHex: 0x8A8A8E)
    /// `--dm-paper` primary text.
    static let primaryText = Color(dmHex: 0xEDEDED)
    /// `--dm-red` the ONE accent: focus and marks.
    static let red = Color(dmHex: 0xD85860)
    /// `--dm-red-hi` brighter red for emphasis on focus.
    static let redHi = Color(dmHex: 0xE7787F)
    /// `--dm-red-soft` translucent red wash.
    static let redSoft = Color(dmHex: 0xD85860).opacity(0.16)
    /// Glass overlay.
    static let glass = Color(dmHex: 0x0E0E0F).opacity(0.88)
    /// Progress / slider track.
    static let track = Color.white.opacity(0.14)

    // MARK: - Shape

    /// The web theme uses a 2px radius. On a 1080p tvOS canvas (2x on 4K)
    /// that reads as a 4pt corner.
    static let cornerRadius: CGFloat = 4

    /// Focus mark stroke width.
    static let focusStroke: CGFloat = 3

    /// How much tvOS's focus lift enlarges a poster (measured: ~12%).
    static let focusLiftScale: CGFloat = 1.12

    // MARK: - Assets

    /// Datamori heart mark (light-on-dark), in the tvOS asset catalog.
    static let markImageName = "DatamoriMark"
}

extension Color {

    /// sRGB colour from a 0xRRGGBB literal.
    init(dmHex hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Typography

extension View {

    /// Thin, wide-tracked UPPERCASE label used for titles and row headers.
    ///
    /// Uses the system text styles (so Dynamic Type sizes still apply) at a
    /// light weight, with ~0.12em letter spacing like the web theme.
    @ContentBuilder
    func datamoriLabel(
        _ style: Font.TextStyle = .title3,
        weight: Font.Weight = .light
    ) -> some View {
        modifier(DatamoriLabelModifier(style: style, weight: weight))
    }
}

private struct DatamoriLabelModifier: ViewModifier {

    let style: Font.TextStyle
    let weight: Font.Weight

    private var tracking: CGFloat {
        UIFont.preferredFont(forTextStyle: style.uiTextStyle).pointSize * 0.12
    }

    @ContentBuilder
    func body(content: Content) -> some View {
        content
            .font(.system(style, weight: weight))
            .textCase(.uppercase)
            .tracking(tracking)
    }
}

private extension Font.TextStyle {

    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .callout: .callout
        case .caption: .caption1
        case .caption2: .caption2
        case .footnote: .footnote
        default: .body
        }
    }
}
