//
//  GroupSelectionViewModel.swift
//  SecuritiesSimulation
//

import Foundation
import Combine

/// A user-defined watchlist group a stock can belong to. `id` mirrors the
/// server-assigned `StockGroup.id`.
struct WatchlistGroup: Hashable {
    let id: Int
    var name: String
}

/// Everything the group-selection sheet renders, as one snapshot.
struct GroupSelectionViewState: Equatable {
    var groups: [WatchlistGroup]
    var selectedGroupIDs: Set<Int>
    var isLoading: Bool
    var errorMessage: String?

    var isConfirmEnabled: Bool { !selectedGroupIDs.isEmpty }
}

/// Screen state for the "加入自選群組" sheet presented from the stock detail
/// screen's star button.
///
/// Loads the user's groups from `GET /stock-groups` on init, and creates new
/// ones via `POST /stock-groups`, seeded with `stockCode` — the API creates
/// a group and adds the stock to it in one call, so there's no separate
/// "add stock to group" step for a freshly created group.
@MainActor
final class GroupSelectionViewModel {

    @Published private(set) var state: GroupSelectionViewState

    /// Invoked when `addGroup` fails, so the view can surface a transient
    /// alert without disturbing the rest of the sheet's state.
    var onAddGroupFailed: (() -> Void)?

    private let stockGroupService: StockGroupServicing
    private let stockCode: String

    init(stockGroupService: StockGroupServicing, stockCode: String, selectedGroupIDs: Set<Int> = []) {
        self.stockGroupService = stockGroupService
        self.stockCode = stockCode
        state = GroupSelectionViewState(groups: [], selectedGroupIDs: selectedGroupIDs, isLoading: true, errorMessage: nil)
        loadGroups()
    }

    func loadGroups() {
        var loadingState = state
        loadingState.isLoading = true
        loadingState.errorMessage = nil
        state = loadingState

        Task { [weak self] in
            guard let self else { return }
            do {
                let stockGroups = try await self.stockGroupService.fetchStockGroups()
                var newState = self.state
                newState.groups = stockGroups.map { WatchlistGroup(id: $0.id, name: $0.name) }
                newState.isLoading = false
                self.state = newState
            } catch {
                var newState = self.state
                newState.isLoading = false
                newState.errorMessage = "無法載入群組，請稍後再試"
                self.state = newState
            }
        }
    }

    func toggleGroup(id: Int) {
        var newState = state
        if newState.selectedGroupIDs.contains(id) {
            newState.selectedGroupIDs.remove(id)
        } else {
            newState.selectedGroupIDs.insert(id)
        }
        state = newState
    }

    /// Ignores blank names and names that already exist (case-insensitive),
    /// otherwise creates the group on the server — seeded with `stockCode`
    /// — and selects it once the response comes back.
    func addGroup(name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        guard !state.groups.contains(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) else { return }

        Task { [weak self] in
            guard let self else { return }
            do {
                let stockGroup = try await self.stockGroupService.createStockGroup(name: trimmedName, stockCode: self.stockCode)
                var newState = self.state
                let group = WatchlistGroup(id: stockGroup.id, name: stockGroup.name)
                newState.groups.append(group)
                newState.selectedGroupIDs.insert(group.id)
                self.state = newState
            } catch {
                self.onAddGroupFailed?()
            }
        }
    }
}
