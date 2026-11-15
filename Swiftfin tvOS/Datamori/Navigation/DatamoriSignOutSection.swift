//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import SwiftUI

/// Last section of Settings: Sign Out, behind a confirmation.
/// This is the only place on tvOS that signs the user out.
struct DatamoriSignOutSection: View {

    @InjectedObject(\.userSessionManager)
    private var userSessionManager

    @Router
    private var router

    @State
    private var isConfirming = false

    @ContentBuilder
    var body: some View {
        Section {
            Button(role: .destructive) {
                isConfirming = true
            } label: {
                Text("Sign Out")
                    .datamoriLabel(.callout, weight: .medium)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.datamori)
            .listRowBackground(Color.clear)
            .confirmationDialog(
                "Sign out of this Apple TV?",
                isPresented: $isConfirming,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    Task { @MainActor in
                        await userSessionManager.signOut(reason: .explicit)
                        router.dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let name = userSessionManager.currentSession?.user.username {
                    Text("You're signed in as \(name). You'll need to sign in again to watch.")
                }
            }
        } footer: {
            Text("Signs this user out of the app on this Apple TV.")
        }
    }
}
