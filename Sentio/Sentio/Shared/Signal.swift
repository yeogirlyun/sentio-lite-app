//
//  Signal.swift
//  Sentio
//
//  Created by BeeJay on 10/27/25.
//

import Foundation

enum SignalType: String, Codable, CaseIterable, Hashable {
    case StrongSell = "strong_sell"
    case Sell = "sell"
    case Hold = "hold"
    case Buy = "buy"
    case StrongBuy = "strong_buy"
}

struct Metric: Codable, Hashable {
    let name: String
    let value: Double

    // Provide resilient decoding for `value` which may have been stored as
    // Double, Int, or String in older payloads. Encode always as Double.
    private enum CodingKeys: String, CodingKey {
        case name
        case value
    }

    init(name: String, value: Double) {
        self.name = name
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)

        // Try decoding as Double, then Int, then String -> Double. Fall back to 0.0 if all fail.
        if let doubleValue = try? container.decode(Double.self, forKey: .value) {
            value = doubleValue
        } else if let intValue = try? container.decode(Int.self, forKey: .value) {
            value = Double(intValue)
        } else if let strValue = try? container.decode(String.self, forKey: .value), let parsed = Double(strValue) {
            value = parsed
        } else {
            value = 0.0
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(value, forKey: .value)
    }
}

struct Signal: Identifiable, Codable, Hashable {
    let id: String
    let symbol: Symbol
    let confidence: Double
    let type: SignalType
    let metrics: [Metric]

    // Custom Codable implementation to allow decoding older data that may not include `metrics`,
    // and to accept `symbol` as either a String ticker or a nested Symbol object.
    private enum CodingKeys: String, CodingKey {
        case symbol
        case confidence
        case type
        case metrics
    }

    init(symbol: Symbol, confidence: Double, type: SignalType, metrics: [Metric] = []) {
        self.id = symbol.ticker
        self.symbol = symbol
        self.confidence = confidence
        self.type = type
        self.metrics = metrics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode symbol: accept either a full Symbol object or a plain ticker String.
        if let nestedSymbol = try? container.decode(Symbol.self, forKey: .symbol) {
            symbol = nestedSymbol
        } else if let ticker = try? container.decode(String.self, forKey: .symbol) {
            symbol = Symbol(ticker: ticker, name: "", price: nil)
        } else {
            let context = DecodingError.Context(codingPath: [CodingKeys.symbol], debugDescription: "Missing or invalid symbol")
            throw DecodingError.keyNotFound(CodingKeys.symbol, context)
        }

        id = symbol.ticker
        confidence = try container.decode(Double.self, forKey: .confidence)
        // Type is optional; if missing, default to .Hold
        type = (try? container.decode(SignalType.self, forKey: .type)) ?? .Hold
        metrics = try container.decodeIfPresent([Metric].self, forKey: .metrics) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Preserve legacy shape by encoding `symbol` as the ticker string
        try container.encode(symbol.ticker, forKey: .symbol)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(type, forKey: .type)
        try container.encode(metrics, forKey: .metrics)
    }
}
