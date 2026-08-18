//
//  StockDetailViewModel.swift
//  SecuritiesSimulation
//

import Foundation
import Combine

/// Which way a stock's price moved — colors the price/change labels red for
/// up and green for down, the reverse of US convention, matching Taiwan
/// market UI expectations.
enum StockChangeDirection {
    case up
    case down
    case flat
}

/// Everything the stock detail screen renders, as one snapshot.
struct StockDetailViewState: Equatable {
    let code: String
    let name: String
    let industryName: String?
    let closingPrice: String
    let changeText: String
    let changeDirection: StockChangeDirection
    let openingPrice: String
    let highestPrice: String
    let lowestPrice: String
    let tradeVolume: String
    let tradeValue: String
    let transactionCount: String
    let updatedAt: String
}

/// Screen state for the individual stock detail screen.
///
/// Built directly from the `Stock` the user tapped on the home list — there
/// is no per-stock detail endpoint wired up yet, so this view model only
/// formats data already in hand rather than fetching anything.
@MainActor
final class StockDetailViewModel {

    let state: StockDetailViewState

    /// Watchlist groups the current stock already belongs to, resolved via
    /// `loadFavoriteStatus()`. The star button is filled whenever this is
    /// non-empty.
    @Published private(set) var favoriteGroups: Set<WatchlistGroup> = []

    private let stockGroupService: StockGroupServicing

    init(stock: Stock, stockGroupService: StockGroupServicing) {
        self.stockGroupService = stockGroupService
        state = StockDetailViewState(
            code: stock.code,
            name: stock.name,
            industryName: stock.industryName,
            closingPrice: Self.formattedPrice(stock.closingPrice),
            changeText: stock.change,
            changeDirection: Self.direction(for: stock.change),
            openingPrice: Self.formattedPrice(stock.openingPrice),
            highestPrice: Self.formattedPrice(stock.highestPrice),
            lowestPrice: Self.formattedPrice(stock.lowestPrice),
            tradeVolume: Self.formattedInteger(stock.tradeVolume),
            tradeValue: Self.formattedInteger(stock.tradeValue),
            transactionCount: Self.formattedInteger(stock.transactionCount),
            updatedAt: stock.updatedAt
        )
    }

    /// Resolves `favoriteGroups` by fetching the user's watchlist groups and
    /// keeping the ones whose `stockCodes` already include this stock.
    /// Left silent on failure — the star button simply starts empty — since
    /// a failed lookup here isn't worth surfacing as an error.
    func loadFavoriteStatus() {
        Task { [weak self] in
            guard let self else { return }
            guard let stockGroups = try? await self.stockGroupService.fetchStockGroups() else { return }
            self.favoriteGroups = Set(
                stockGroups
                    .filter { ($0.stockCodes ?? []).contains(self.state.code) }
                    .map { WatchlistGroup(id: $0.id, name: $0.name) }
            )
        }
    }

    /// Applies the group selection confirmed from the "加入自選群組" sheet.
    func updateFavoriteGroups(_ groups: Set<WatchlistGroup>) {
        favoriteGroups = groups
    }

    private static func formattedPrice(_ price: Double) -> String {
        String(format: "%.2f", price)
    }

    private static func formattedInteger(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
    }

    private static func direction(for change: String) -> StockChangeDirection {
        if change.hasPrefix("-") { return .down }
        if change.hasPrefix("+") { return .up }
        return .flat
    }
}
