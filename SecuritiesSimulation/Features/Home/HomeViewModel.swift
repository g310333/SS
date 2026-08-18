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
    var stocks: [Stock]
    var isLoadingStocks: Bool
    var stocksErrorMessage: String?

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

    private let stockService: StockServicing
    private let stockGroupService: StockGroupServicing

    private static let hotCategoryTitle = "全部"

    /// Market categories shown when browsing all stocks: a static "熱門"
    /// chip followed by whatever `fetchIndustries()` resolves to.
    private var marketCategories = [hotCategoryTitle]

    /// The user's watchlist groups, fetched from `GET /stock-groups`. Each
    /// group's `stockCodes` is what `filteredStocks(for:)` matches against
    /// `allStocks` to build the watchlist grid.
    private var stockGroups: [StockGroup] = []

    /// Watchlist categories shown as chips: one per group, by name.
    private var watchlistCategories: [String] { stockGroups.map(\.name) }

    /// The unfiltered market list from the last successful `fetchStocks()`.
    /// `state.stocks` is always a filtered view over this, keyed by the
    /// selected category chip — kept separate so switching categories
    /// doesn't require a re-fetch.
    private var allStocks: [Stock] = []

    init(stockService: StockServicing, stockGroupService: StockGroupServicing) {
        self.stockService = stockService
        self.stockGroupService = stockGroupService
        state = HomeViewState(
            segment: .market,
            categories: marketCategories,
            selectedCategoryIndex: 0,
            isSearchActive: false,
            stocks: [],
            isLoadingStocks: false,
            stocksErrorMessage: nil
        )
        loadStocks()
        loadIndustries()
        loadStockGroups()
    }

    /// Fetches the industry list and, once resolved, extends
    /// `marketCategories` with each industry's name after the static "熱門"
    /// chip. Left silent on failure — the chip bar simply falls back to
    /// showing only "熱門" — since a category-list error isn't worth
    /// surfacing the same way a failed stock list is.
    private func loadIndustries() {
        Task { [weak self] in
            guard let self else { return }
            guard let industries = try? await self.stockService.fetchIndustries() else { return }
            self.marketCategories = [Self.hotCategoryTitle] + industries.map(\.industryName)
            guard self.state.segment == .market else { return }
            var newState = self.state
            newState.categories = self.marketCategories
            self.state = newState
        }
    }

    /// Fetches the user's watchlist groups and, once resolved, refreshes the
    /// watchlist chip bar (and the visible grid, if the watchlist segment is
    /// active). Left silent on failure, matching `loadIndustries()`.
    private func loadStockGroups() {
        Task { [weak self] in
            guard let self else { return }
            guard let stockGroups = try? await self.stockGroupService.fetchStockGroups() else { return }
            self.stockGroups = stockGroups
            guard self.state.segment == .watchlist else { return }
            var newState = self.state
            newState.categories = self.watchlistCategories
            newState.stocks = self.filteredStocks(for: newState)
            self.state = newState
        }
    }

    func loadStocks() {
        var loadingState = state
        loadingState.isLoadingStocks = true
        loadingState.stocksErrorMessage = nil
        state = loadingState

        Task { [weak self] in
            guard let self else { return }
            do {
                let stocks = try await self.stockService.fetchStocks()
                self.allStocks = stocks
                var newState = self.state
                newState.stocks = self.filteredStocks(for: newState)
                newState.isLoadingStocks = false
                self.state = newState
            } catch {
                var newState = self.state
                newState.isLoadingStocks = false
                newState.stocksErrorMessage = "無法載入股票資料，請稍後再試"
                self.state = newState
            }
        }
    }

    func selectSegment(_ segment: StockListSegment) {
        guard segment != state.segment else { return }
        var newState = state
        newState.segment = segment
        newState.categories = segment == .market ? marketCategories : watchlistCategories
        newState.selectedCategoryIndex = 0
        newState.stocks = filteredStocks(for: newState)
        state = newState
    }

    func selectCategory(at index: Int) {
        guard state.categories.indices.contains(index) else { return }
        var newState = state
        newState.selectedCategoryIndex = index
        newState.stocks = filteredStocks(for: newState)
        state = newState
    }

    /// Market segment: `nil` or the "熱門" chip mean no filter — every
    /// fetched stock is shown; any other category filters `allStocks` down
    /// to the stocks whose `industryName` matches the chip's title.
    ///
    /// Watchlist segment: the chip names a group, so `allStocks` is filtered
    /// down to the codes listed in that group's `stockCodes`.
    private func filteredStocks(for state: HomeViewState) -> [Stock] {
        switch state.segment {
        case .market:
            guard let category = state.selectedCategory, category != Self.hotCategoryTitle else { return allStocks }
            return allStocks.filter { $0.industryName == category }
        case .watchlist:
            guard let groupName = state.selectedCategory,
                  let group = stockGroups.first(where: { $0.name == groupName }) else { return [] }
            let codes = Set(group.stockCodes ?? [])
            return allStocks.filter { codes.contains($0.code) }
        }
    }

    func toggleSearch() {
        var newState = state
        newState.isSearchActive.toggle()
        state = newState
    }
}
