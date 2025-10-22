// filepath: /Users/beejay/repo/sentio/app/Sentio/Sentio/Signals/Signal.swift
// Model for a Signal

import Foundation

enum SignalType: String, Codable, CaseIterable, Hashable {
    case StrongSell = "strong_sell"
    case Sell = "sell"
    case Hold = "hold"
    case Buy = "buy"
    case StrongBuy = "strong_buy"
}

struct Metric: Codable, Hashable {
    let key: String
    let value: String
}

struct Signal: Identifiable, Codable, Hashable {
    let id: String
    let symbol: String
    let confidence: Double
    let type: SignalType
    let metrics: [Metric]

    // Custom Codable implementation to allow decoding older data that may not include `metrics`.
    private enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case confidence
        case type
        case metrics
    }

    init(id: String, symbol: String, confidence: Double, type: SignalType, metrics: [Metric] = []) {
        self.id = id
        self.symbol = symbol
        self.confidence = confidence
        self.type = type
        self.metrics = metrics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        symbol = try container.decode(String.self, forKey: .symbol)
        confidence = try container.decode(Double.self, forKey: .confidence)
        type = try container.decode(SignalType.self, forKey: .type)
        metrics = try container.decodeIfPresent([Metric].self, forKey: .metrics) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(symbol, forKey: .symbol)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(type, forKey: .type)
        try container.encode(metrics, forKey: .metrics)
    }
}
