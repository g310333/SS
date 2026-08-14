//
//  StockModels.swift
//  SecuritiesSimulation
//

import Foundation

/// A single stock's daily quote, as returned by `GET /stocks`.
struct Stock: Decodable, Equatable {
    let code: String
    let name: String
    let date: String
    let openingPrice: Double
    let highestPrice: Double
    let lowestPrice: Double
    let closingPrice: Double
    let change: String
    let tradeVolume: Double
    let tradeValue: Double
    let transactionCount: Double
    let updatedAt: String
    let industry: String?
    let industryName: String?

    enum CodingKeys: String, CodingKey {
        case code
        case name
        case date
        case openingPrice = "opening_price"
        case highestPrice = "highest_price"
        case lowestPrice = "lowest_price"
        case closingPrice = "closing_price"
        case change
        case tradeVolume = "trade_volume"
        case tradeValue = "trade_value"
        case transactionCount = "transaction_count"
        case updatedAt = "updated_at"
        case industry
        case industryName = "industry_name"
    }
}
