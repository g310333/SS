//
//  TradeError.swift
//  SecuritiesSimulation
//

import Foundation

/// Trade-domain errors surfaced to the Order feature. Networking details
/// (HTTP status codes, transport/decoding failures) are translated into
/// these cases by `TradeService` and must not leak any further up.
enum TradeError: Error {
    case serviceUnavailable
    case unexpected
}
