//
//  HomeViewModel.swift
//  SecuritiesSimulation
//

import Foundation
import Combine

/// Which stock list the home screen is showing: the full market or the
/// user's watchlist. Each has its own category bar underneath it.
enum StockListSegment: Int, CaseIterable {
    case market
    case watchlist

    var title: String {
        switch self {
        case .market: return "全部股票"
        case .watchlist: return "自選"
        }
    }
}

/// Everything the home screen renders, as one snapshot.
///
/// Kept as a single struct — rather than several independent `@Published`
/// properties — so the view always observes a consistent combination of
/// segment, categories, and selected index. Publishing them separately let
/// the category bar see a new `categories` array paired with a
/// `selectedCategoryIndex` left over from the previous segment.
struct HomeViewState: Equatable {
    var segment: StockListSegment
    var categories: [String]
    var selectedCategoryIndex: Int
    var isSearchActive: Bool

    var selectedCategory: String? {
        categories.indices.contains(selectedCategoryIndex) ? categories[selectedCategoryIndex] : nil
    }
}

/// Screen state for the home / market overview screen.
///
/// Owns the selected segment (全部股票 / 自選), the category list shown
/// beneath it (which differs per segment), and whether inline search is
/// active. Category and segment data are mocked locally for now — no
/// service dependency yet. Should a data source be needed later, it should
/// be injected here through a protocol, not reached into directly by the
/// view controller.
@MainActor
final class HomeViewModel {

    @Published private(set) var state: HomeViewState

    /// Main market categories shown when browsing all stocks.
    private let marketCategories = ["熱門", "上市", "上櫃", "權值股", "電子", "金融", "傳產"]

    /// User-defined groups shown when browsing the watchlist.
    private let watchlistCategories = ["全部自選", "自訂群組 1", "自訂群組 2"]

    init() {
        state = HomeViewState(
            segment: .market,
            categories: marketCategories,
            selectedCategoryIndex: 0,
            isSearchActive: false
        )
    }

    func selectSegment(_ segment: StockListSegment) {
        guard segment != state.segment else { return }
        var newState = state
        newState.segment = segment
        newState.categories = segment == .market ? marketCategories : watchlistCategories
        newState.selectedCategoryIndex = 0
        state = newState
    }

    func selectCategory(at index: Int) {
        guard state.categories.indices.contains(index) else { return }
        var newState = state
        newState.selectedCategoryIndex = index
        state = newState
    }

    func toggleSearch() {
        var newState = state
        newState.isSearchActive.toggle()
        state = newState
    }
}
