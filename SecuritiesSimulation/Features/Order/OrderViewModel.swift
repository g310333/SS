//
//  OrderViewModel.swift
//  SecuritiesSimulation
//

import Foundation
import Combine

/// Which unit the order is placed in: odd-lot orders trade in individual
/// shares, whole-lot orders trade in board lots of 1,000 shares.
enum OrderLotType: Int, CaseIterable {
    case oddLot
    case wholeLot

    var title: String {
        switch self {
        case .oddLot: return "零股"
        case .wholeLot: return "整張"
        }
    }

    var quantityLabel: String {
        switch self {
        case .oddLot: return "股數（股）"
        case .wholeLot: return "股數（張）"
        }
    }

    var quantityPlaceholder: String {
        switch self {
        case .oddLot: return "請輸入股數"
        case .wholeLot: return "請輸入張數"
        }
    }

    /// Shares per unit of quantity — 1 for odd-lot, 1,000 per board lot for
    /// whole-lot.
    var sharesPerUnit: Double {
        switch self {
        case .oddLot: return 1
        case .wholeLot: return 1000
        }
    }
}

/// Everything the order screen renders, as one snapshot.
struct OrderViewState: Equatable {
    let stockCode: String
    let stockName: String
    var lotType: OrderLotType
    var price: String
    var quantity: String
    var isSubmitting: Bool = false

    /// `nil` whenever `price`/`quantity` aren't both valid positive
    /// numbers — the submit button is disabled in that case.
    var estimatedAmount: Double? {
        guard let priceValue = Double(price), priceValue > 0,
              let quantityValue = Double(quantity), quantityValue > 0 else { return nil }
        return priceValue * quantityValue * lotType.sharesPerUnit
    }

    var isSubmitEnabled: Bool { estimatedAmount != nil && !isSubmitting }
}

/// Screen state for the "模擬下單" order screen pushed from the stock detail
/// screen's bottom bar.
///
/// `price`/`quantity` are entered in the unit the user is thinking in — 張
/// for whole-lot orders, 股 for odd-lot — while `POST /trades/buy` always
/// wants a share count, so `submitOrder()` multiplies whole-lot quantities
/// by `OrderLotType.sharesPerUnit` (1,000) before sending.
@MainActor
final class OrderViewModel {

    @Published private(set) var state: OrderViewState

    /// Invoked once `submitOrder()` succeeds, with the trade as confirmed
    /// by the server.
    var onOrderSubmitted: ((BuyTradeResult) -> Void)?

    /// Invoked when `submitOrder()` fails, so the view can surface a
    /// transient alert without losing the entered inputs.
    var onOrderFailed: (() -> Void)?

    private let tradeService: TradeServicing

    init(stock: Stock, tradeService: TradeServicing) {
        self.tradeService = tradeService
        state = OrderViewState(
            stockCode: stock.code,
            stockName: stock.name,
            lotType: .wholeLot,
            price: String(format: "%.2f", stock.closingPrice),
            quantity: ""
        )
    }

    func selectLotType(_ lotType: OrderLotType) {
        guard lotType != state.lotType else { return }
        var newState = state
        newState.lotType = lotType
        newState.quantity = ""
        state = newState
    }

    func updatePrice(_ price: String) {
        var newState = state
        newState.price = price
        state = newState
    }

    func updateQuantity(_ quantity: String) {
        var newState = state
        newState.quantity = quantity
        state = newState
    }

    func submitOrder() {
        guard state.isSubmitEnabled, let enteredQuantity = Double(state.quantity), enteredQuantity > 0 else { return }
        let shareQuantity = Int(enteredQuantity * state.lotType.sharesPerUnit)

        var submittingState = state
        submittingState.isSubmitting = true
        state = submittingState

        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await self.tradeService.buy(stockCode: self.state.stockCode, quantity: shareQuantity)
                var newState = self.state
                newState.isSubmitting = false
                self.state = newState
                self.onOrderSubmitted?(result)
            } catch {
                var newState = self.state
                newState.isSubmitting = false
                self.state = newState
                self.onOrderFailed?()
            }
        }
    }
}
