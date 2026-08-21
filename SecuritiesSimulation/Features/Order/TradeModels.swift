//
//  TradeModels.swift
//  SecuritiesSimulation
//

import Foundation

/// Request body for `POST /trades/buy`. `quantity` is always in shares —
/// whole-lot ("整張") orders must be pre-multiplied by 1,000 before being
/// placed here; odd-lot ("零股") orders are sent as-is.
struct BuyTradeRequest: Encodable {
    let stockCode: String
    let quantity: Int

    enum CodingKeys: String, CodingKey {
        case stockCode = "stock_code"
        case quantity
    }
}

/// Response from `POST /trades/buy`: the executed trade plus the account's
/// resulting cash balance and holding size for the stock.
struct BuyTradeResult: Decodable, Equatable {
    let stockCode: String
    let quantity: Int
    let boardLots: Int
    let oddLotShares: Int
    let price: Double
    let totalAmount: Double
    let cashBalance: Double
    let holdingQuantity: Int

    enum CodingKeys: String, CodingKey {
        case stockCode = "stock_code"
        case quantity
        case boardLots = "board_lots"
        case oddLotShares = "odd_lot_shares"
        case price
        case totalAmount = "total_amount"
        case cashBalance = "cash_balance"
        case holdingQuantity = "holding_quantity"
    }
}
