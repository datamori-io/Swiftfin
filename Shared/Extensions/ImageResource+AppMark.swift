//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ImageResource {

    /// App logo used in forms and toolbars.
    /// Datamori fork: the Datamori heart mark on tvOS.
    static var appMark: ImageResource {
        #if os(tvOS)
        .datamoriMark
        #else
        .jellyfinBlobBlue
        #endif
    }
}
