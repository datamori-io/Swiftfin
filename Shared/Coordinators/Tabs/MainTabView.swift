//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import FactoryKit
import JellyfinAPI
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

// TODO: fix weird tvOS icon rendering
struct MainTabView: View {

    #if os(tvOS)
    @Default(.Customization.tabBarPlacement)
    private var tabBarPlacement
    #endif

    @InjectedObject(\.userSessionManager)
    private var userSessionManager

    @StateObject
    private var tabCoordinator: TabCoordinator

    init() {
        _tabCoordinator = StateObject(wrappedValue: Self.defaultTabCoordinator)
    }

    private static var defaultTabCoordinator: TabCoordinator {
        #if os(iOS)
        TabCoordinator {
            TabItem.contentGroup(provider: DefaultContentGroupProvider())
            TabItem.search
            TabItem.media
        }
        #else
        TabCoordinator {
            // Datamori: top tab bar. Search and Settings are icon-only at the end.
            TabItem.contentGroup(provider: DatamoriHomeProvider())
            TabItem.datamoriLibrary(title: "Movies", libraryName: "Movies", systemImage: "film")
            TabItem.datamoriLibrary(title: "Shows", libraryName: "Shows", systemImage: "tv")
            TabItem.datamoriLibrary(title: "Anime", libraryName: "Anime", systemImage: "sparkles.tv")
            TabItem.search
            TabItem.settings
        }
        #endif
    }

    private func routePendingDeepLink(_ deepLink: DeepLink?) {
        guard let deepLink else { return }

        Task { @MainActor in
            let route = deepLink.route()
            await tabCoordinator.route(to: route)
        }
    }

    @ContentBuilder
    private func tabRoot(_ tab: TabCoordinator.TabData) -> some View {
        NavigationInjectionView(coordinator: tab.coordinator) {
            tab.item
                .content
                .withViewContext(.isTabRoot)
                #if os(iOS)
                .if(tabCoordinator.tabs.first?.item.id == tab.item.id) { view in
                    view.topBarTrailing {
                        FirstTabSettingsBarButton()
                    }
                }
                #endif
        }
        .environmentObject(tabCoordinator)
        .environment(\.tabItemSelected, tab.publisher)
    }

    @ContentBuilder
    private func tabView() -> some View {
        TabView(selection: $tabCoordinator.selectedTabID) {
            ForEach(tabCoordinator.tabs, id: \.item.id) { tab in
                Tab(
                    value: tab.item.id,
                    role: tab.item.id == TabItem.search.id ? .search : nil
                ) {
                    #if os(tvOS)
                    GeometryReader { _ in
                        tabRoot(tab)
                    }
                    .trackingFrame(for: .tabView)
                    #else
                    tabRoot(tab)
                    #endif
                } label: {
                    #if os(tvOS)
                    if TabItem.datamoriIconOnlyTabIDs.contains(tab.item.id) {
                        Label(tab.item.displayTitle, systemImage: tab.item.systemImage)
                            .labelStyle(.iconOnly)
                    } else {
                        Text(tab.item.displayTitle.uppercased())
                    }
                    #else
                    Label(
                        tab.item.displayTitle,
                        systemImage: tab.item.systemImage
                    )
                    .symbolRenderingMode(.monochrome)
                    #endif
                }
            }
        }
    }

    @ContentBuilder
    private func tabContent() -> some View {
        #if os(tvOS)
        // Datamori: always a top tab bar (the sidebar hid off-screen and
        // made it easy to sign out by accident).
        tabView()
            .tabViewStyle(.tabBarOnly)
        #else
        tabView()
            .tabViewStyle(.sidebarAdaptable)
        #endif
    }

    @ContentBuilder
    var body: some View {
        tabContent()
            .onChange(of: userSessionManager.pendingDeepLink) {
                routePendingDeepLink(userSessionManager.consumePendingDeepLink())
            }
            .onReceive(userSessionManager.routePublisher) { route in
                Task { @MainActor in
                    await tabCoordinator.route(to: route)
                }
            }
        #if os(tvOS)
        // Datamori: no focused-poster colour tint; DatamoriBackground shows instead.
        #endif
    }
}

#if os(iOS)
private struct FirstTabSettingsBarButton: View {

    @Injected(\.currentUserSession)
    private var userSession

    @Router
    private var router

    @ContentBuilder
    var body: some View {
        if router.isRootOfPath,
           let userSession {
            SettingsBarButton(userSession: userSession) {
                router.route(to: .settings)
            }
        }
    }
}
#endif
