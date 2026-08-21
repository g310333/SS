//
//  StockError.swift
//  SecuritiesSimulation
//

import Foundation

/// Stock-domain errors surfaced to the Home feature. Networking details
/// (HTTP status codes, transport/decoding failures) are translated into
/// these cases by `StockService` and must not leak any further up.
enum StockError: Error {
    case serviceUnavailable
    case unexpected
}
