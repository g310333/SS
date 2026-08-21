//
//  StockGroupModels.swift
//  SecuritiesSimulation
//

import Foundation

/// A user-created watchlist group, as returned by `GET /stock-groups` and
/// `POST /stock-groups`. `stockCodes` is only present on the `POST`
/// response — `GET` doesn't return it — so it's optional rather than
/// defaulted, to keep a missing key distinguishable from an empty list.
struct StockGroup: Decodable, Equatable {
    let id: Int
    let name: String
    let createdAt: String
    let stockCodes: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt = "created_at"
        case stockCodes = "stock_codes"
    }
}

/// Request body for `POST /stock-groups`: creates a group seeded with one
/// stock.
struct CreateStockGroupRequest: Encodable {
    let name: String
    let stockCode: String

    enum CodingKeys: String, CodingKey {
        case name
        case stockCode = "stock_code"
    }
}

/// Request body for `POST /stock-groups/stocks`: adds one stock to an
/// existing group.
struct AddStockToGroupRequest: Encodable {
    let groupID: Int
    let stockCode: String

    enum CodingKeys: String, CodingKey {
        case groupID = "group_id"
        case stockCode = "stock_code"
    }
}
