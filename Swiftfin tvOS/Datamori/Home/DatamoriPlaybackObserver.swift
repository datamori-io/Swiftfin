//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import SwiftUI

extension View {

    /// Signals `DatamoriHomeEvents.playbackEnded` whenever a playback
    /// session finishes, so Home refreshes Continue Watching / Next Up.
    @ContentBuilder
    func datamoriObservesPlaybackEnd() -> some View {
        modifier(DatamoriPlaybackObserver())
    }
}

private struct DatamoriPlaybackObserver: ViewModifier {

    @Injected(\.mediaPlayerManager)
    private var mediaPlayerManager

    @ContentBuilder
    func body(content: Content) -> some View {
        content
            .onChange(of: mediaPlayerManager.currentSession == nil) { wasNil, isNil in
                if !wasNil, isNil {
                    // Give the server a moment to record the final position.
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        DatamoriHomeEvents.playbackEnded.send()
                    }
                }
            }
    }
}
