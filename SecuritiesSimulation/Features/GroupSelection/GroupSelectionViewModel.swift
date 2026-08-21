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

    /// Invoked when `confirmSelection` fails to persist a newly checked
    /// group, so the view can surface a transient alert without dismissing.
    var onConfirmFailed: (() -> Void)?

    private let stockGroupService: StockGroupServicing
    private let stockCode: String

    /// Groups the stock already belonged to when the sheet opened —
    /// `confirmSelection` only calls `POST /stock-groups/stocks` for groups
    /// outside this set, since these are already linked server-side.
    private let initialSelectedGroupIDs: Set<Int>

    /// Groups created (and seeded with the stock) via `addGroup` this
    /// session — the create call already adds the stock server-side, so
    /// `confirmSelection` must not call `addStock` for them again.
    private var serverSeededGroupIDs: Set<Int> = []

    init(stockGroupService: StockGroupServicing, stockCode: String, selectedGroupIDs: Set<Int> = []) {
        self.stockGroupService = stockGroupService
        self.stockCode = stockCode
        self.initialSelectedGroupIDs = selectedGroupIDs
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
                self.serverSeededGroupIDs.insert(group.id)
            } catch {
                self.onAddGroupFailed?()
            }
        }
    }

    /// Persists the stock into every currently selected group that didn't
    /// already contain it — i.e. every checked group other than the ones it
    /// started in or was just created (and seeded) via `addGroup` — then
    /// reports the confirmed selection back through `completion`.
    func confirmSelection(completion: @escaping (Set<WatchlistGroup>) -> Void) {
        let groupIDsToPersist = state.selectedGroupIDs
            .subtracting(initialSelectedGroupIDs)
            .subtracting(serverSeededGroupIDs)
        let selectedGroups = Set(state.groups.filter { state.selectedGroupIDs.contains($0.id) })

        guard !groupIDsToPersist.isEmpty else {
            completion(selectedGroups)
            return
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                for groupID in groupIDsToPersist {
                    _ = try await self.stockGroupService.addStock(stockCode: self.stockCode, toGroupID: groupID)
                }
                completion(selectedGroups)
            } catch {
                self.onConfirmFailed?()
            }
        }
    }
}
