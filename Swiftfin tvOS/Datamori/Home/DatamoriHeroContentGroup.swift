//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

/// Top of the Datamori Home screen.
///
/// The newest addition fills the hero (backdrop + title logo). Continue
/// Watching sits inside the hero, directly under it, and takes initial focus,
/// so it is never pushed below the fold.
struct DatamoriHeroContentGroup: ContentGroup {

    let id = "datamori-hero"
    let viewModel: DatamoriHeroViewModel

    var _shouldBeResolved: Bool {
        viewModel.hasContent
    }

    init() {
        self.viewModel = DatamoriHeroViewModel()
    }

    @ContentBuilder
    func body(with viewModel: DatamoriHeroViewModel) -> some View {
        HeroView(viewModel: viewModel)
            .preference(key: ContentGroupCustomizationKey.self, value: .ignoreSafeAreaTop)
    }

    // MARK: - View

    private struct HeroView: View {

        @Environment(\.frameForParentView)
        private var frameForParentView

        @ObservedObject
        var viewModel: DatamoriHeroViewModel

        @Router
        private var router

        @Namespace
        private var heroScope

        private var parentHeight: CGFloat {
            let height = frameForParentView[.scrollView, default: .zero].frame.height
            return height > 0 ? height : 1080
        }

        private var newest: BaseItemDto? {
            viewModel.newestViewModel.elements.elements.first?.snapshot
        }

        @ContentBuilder
        var body: some View {
            VStack(alignment: .leading, spacing: 40) {
                if let newest {
                    heroInfo(for: newest)
                        .frame(height: parentHeight * (viewModel.hasResumeItems ? 0.48 : 0.62), alignment: .bottom)
                }

                if viewModel.hasResumeItems {
                    PosterHStackLibrarySection(
                        viewModel: viewModel.resumeGroup.viewModel,
                        group: viewModel.resumeGroup
                    )
                    // Continue Watching takes initial focus when present.
                    .prefersDefaultFocus(true, in: heroScope)
                }
            }
            .focusScope(heroScope)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(alignment: .top) {
                if let newest {
                    backdrop(for: newest)
                }
            }
        }

        // MARK: Hero info

        @ContentBuilder
        private func heroInfo(for item: BaseItemDto) -> some View {
            VStack(alignment: .leading, spacing: 18) {
                Text("Newest addition")
                    .datamoriLabel(.caption, weight: .medium)
                    .foregroundStyle(Datamori.red)

                ImageView(
                    item.imageSource(
                        .logo,
                        itemID: item.id,
                        environment: ImageSourceOptions(maxHeight: 160)
                    )
                )
                .image { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 640, maxHeight: 160, alignment: .leading)
                }
                .placeholder { _ in
                    EmptyView()
                }
                .failure {
                    Text(item.displayTitle)
                        .datamoriLabel(.title, weight: .thin)
                        .foregroundStyle(Datamori.primaryText)
                        .lineLimit(2)
                }
                .frame(maxHeight: 160, alignment: .bottomLeading)

                if let overview = item.overview?.datamoriPlainText, overview.isNotEmpty {
                    Text(overview)
                        .font(.callout)
                        .foregroundStyle(Datamori.secondaryText)
                        .lineLimit(2)
                        .frame(maxWidth: 1000, alignment: .leading)
                }

                // Only when there's nothing to resume: then VIEW is the first
                // focus below the tab bar. With resume items, Continue
                // Watching is the first focus instead (the newest addition is
                // still reachable in Recently Added).
                if !viewModel.hasResumeItems {
                    Button {
                        router.route(to: .item(item: item))
                    } label: {
                        Text("View")
                            .datamoriLabel(.callout, weight: .medium)
                    }
                    .buttonStyle(.datamori)
                    .prefersDefaultFocus(true, in: heroScope)
                }
            }
            .edgePadding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Full-width section: moving down from the tab bar lands here
            // (on VIEW) rather than skipping to the first row.
            .focusSection()
        }

        // MARK: Backdrop

        @ContentBuilder
        private func backdrop(for item: BaseItemDto) -> some View {
            ImageView(item.imageSources(for: .landscape, environment: .init(viewContext: .isBackdrop)))
                .image { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                .placeholder { _ in
                    Color.clear
                }
                .failure {
                    Color.clear
                }
                .frame(height: parentHeight * 0.85)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay {
                    // Fade into the ink page: bottom and left edges.
                    ZStack {
                        LinearGradient(
                            colors: [Datamori.ink.opacity(0), Datamori.ink.opacity(0.6), Datamori.ink],
                            startPoint: .init(x: 0.5, y: 0.35),
                            endPoint: .bottom
                        )
                        LinearGradient(
                            colors: [Datamori.ink.opacity(0.85), Datamori.ink.opacity(0)],
                            startPoint: .leading,
                            endPoint: .init(x: 0.65, y: 0.5)
                        )
                    }
                }
                .ignoresSafeArea()
                .accessibilityHidden(true)
        }
    }
}

// MARK: - View model

final class DatamoriHeroViewModel: ViewModel, WithRefresh {

    struct Background: WithRefresh {

        let viewModel: DatamoriHeroViewModel

        func refresh() {
            Task { await refresh() }
        }

        func refresh() async {
            async let resume: Void = viewModel.resumeGroup.viewModel.background.refresh()
            async let newest: Void = viewModel.newestViewModel.background.refresh()
            _ = await (resume, newest)
        }
    }

    let resumeGroup: PosterGroup<ResumeItemsLibrary>
    let newestViewModel: PagingLibraryViewModel<RecentlyAddedLibrary>

    var background: Background {
        get { Background(viewModel: self) }
        set {}
    }

    var hasResumeItems: Bool {
        resumeGroup.viewModel.elements.isNotEmpty
    }

    var hasContent: Bool {
        hasResumeItems || newestViewModel.elements.isNotEmpty
    }

    override init() {
        self.resumeGroup = PosterGroup(
            id: "datamori-continue-watching",
            library: ResumeItemsLibrary(mediaTypes: [.video]),
            displayTitle: "Continue Watching",
            posterDisplayType: .landscape,
            posterSize: .medium,
            // No header button, so focus goes straight to the first card.
            environment: .init(isHeaderButtonEnabled: false, viewContext: .isInResume)
        )
        self.newestViewModel = PagingLibraryViewModel(library: RecentlyAddedLibrary(), pageSize: 1)
        super.init()

        resumeGroup.viewModel
            .objectWillChange
            .merge(with: newestViewModel.objectWillChange)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func refresh() {
        Task { await refresh() }
    }

    func refresh() async {
        async let resume: Void = resumeGroup.viewModel.refresh()
        async let newest: Void = newestViewModel.refresh()
        _ = await (resume, newest)
    }
}

// MARK: - Overview text

extension String {

    /// Overview text with HTML tags and entities removed.
    var datamoriPlainText: String {
        var text = replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let entities = ["&amp;": "&", "&quot;": "\"", "&#39;": "'", "&apos;": "'", "&lt;": "<", "&gt;": ">", "&nbsp;": " "]
        for (entity, value) in entities {
            text = text.replacing(entity, with: value)
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
