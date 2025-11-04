//
//  Position.swift
//  Sentio
//
//  Created by BeeJay on 10/27/25.
//

import Foundation

struct Position: Identifiable, Codable, Hashable {
    let id: String
    let symbol: Symbol
    let signal: Signal?
    let quantity: Double
    let price: Double
    let target: Double?
    let side: String
    let positionIntent: String
    let annotation: String?
    let createdAt: Date
    let updatedAt: Date

    // Convenience initializer for programmatic creation
    init(
        id: String = UUID().uuidString,
        symbol: Symbol,
        signal: Signal? = nil,
        quantity: Double,
        price: Double,
        target: Double? = nil,
        side: String = "",
        positionIntent: String = "",
        annotation: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.symbol = symbol
        self.signal = signal
        self.quantity = quantity
        self.price = price
        self.target = target
        self.side = side
        self.positionIntent = positionIntent
        self.annotation = annotation
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Computed properties useful for UI and summaries
    var currentPrice: Double? {
        return symbol.price
    }

    var unrealizedPnL: Double? {
        guard let current = currentPrice else { return nil }
        return (current - price) * quantity
    }

    var unrealizedPnLPercent: Double? {
        guard price != 0, let current = currentPrice else { return nil }
        return ((current - price) / price) * 100.0
    }

    // MARK: - Codable support (resilient)
    private enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case signal
        case quantity
        case price
        case target
        case side
        case positionIntent = "position_intent"
        case annotation
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // id - prefer String, otherwise try Int/UUID
        if let s = try? container.decode(String.self, forKey: .id) {
            id = s
        } else if let i = try? container.decode(Int.self, forKey: .id) {
            id = String(i)
        } else if let uuid = try? container.decode(UUID.self, forKey: .id) {
            id = uuid.uuidString
        } else {
            // generate fallback id if missing
            id = UUID().uuidString
        }

        // symbol: accept nested Symbol or a ticker string
        if let nestedSymbol = try? container.decode(Symbol.self, forKey: .symbol) {
            symbol = nestedSymbol
        } else if let ticker = try? container.decode(String.self, forKey: .symbol) {
            symbol = Symbol(ticker: ticker, name: "", price: nil)
        } else {
            // fallback placeholder symbol
            symbol = Symbol(ticker: "", name: "", price: nil)
        }

        // signal: optional - accept nested Signal or string id; leave nil if absent
        if let nestedSignal = try? container.decode(Signal.self, forKey: .signal) {
            signal = nestedSignal
        } else {
            signal = nil
        }

        // quantity: support Int, Double, or String
        if let d = try? container.decode(Double.self, forKey: .quantity) {
            quantity = d
        } else if let i = try? container.decode(Int.self, forKey: .quantity) {
            quantity = Double(i)
        } else if let s = try? container.decode(String.self, forKey: .quantity), let parsed = Double(s) {
            quantity = parsed
        } else {
            quantity = 0.0
        }

        // price and target: support Double or String or Int
        func decodeDoubleIfPresent(_ key: CodingKeys) -> Double? {
            if let d = try? container.decode(Double.self, forKey: key) { return d }
            if let i = try? container.decode(Int.self, forKey: key) { return Double(i) }
            if let s = try? container.decode(String.self, forKey: key), let parsed = Double(s) { return parsed }
            return nil
        }

        price = decodeDoubleIfPresent(.price) ?? 0.0
        target = decodeDoubleIfPresent(.target)

        // side & positionIntent - tolerate different key naming
        if let s = try? container.decode(String.self, forKey: .side) {
            side = s
        } else {
            side = ""
        }

        if let pi = try? container.decode(String.self, forKey: .positionIntent) {
            positionIntent = pi
        } else if let piAlt = try? container.decodeIfPresent(String.self, forKey: .annotation) {
            // no-op; keep normal annotation decoding later
            positionIntent = piAlt
        } else {
            positionIntent = ""
        }

        annotation = try? container.decodeIfPresent(String.self, forKey: .annotation)

        // Dates: accept Int (epoch seconds), Double (epoch), or ISO8601 strings. Fall back to Date().
        func decodeDate(_ key: CodingKeys) -> Date {
            if let doubleEpoch = try? container.decode(Double.self, forKey: key) {
                return Date(timeIntervalSince1970: doubleEpoch)
            }
            if let intEpoch = try? container.decode(Int.self, forKey: key) {
                return Date(timeIntervalSince1970: TimeInterval(intEpoch))
            }
            if let str = try? container.decode(String.self, forKey: key) {
                // Try ISO8601 first
                if let iso = ISO8601DateFormatter().date(from: str) { return iso }
                // Try RFC3339 / custom formats
                let f = DateFormatter()
                f.locale = Locale(identifier: "en_US_POSIX")
                f.dateFormat = "yyyy-MM-dd HH:mm:ss"
                if let d = f.date(from: str) { return d }
            }
            return Date()
        }

        createdAt = decodeDate(.createdAt)
        updatedAt = decodeDate(.updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        // Preserve legacy shape: encode symbol as ticker string
        try container.encode(symbol.ticker, forKey: .symbol)
        // Encode signal as id if present
        if let s = signal {
            try container.encode(s, forKey: .signal)
        }
        // Numeric values
        try container.encode(quantity, forKey: .quantity)
        try container.encode(price, forKey: .price)
        try container.encodeIfPresent(target, forKey: .target)
        try container.encode(side, forKey: .side)
        try container.encode(positionIntent, forKey: .positionIntent)
        try container.encodeIfPresent(annotation, forKey: .annotation)

        // Encode dates as ISO8601 strings for readability
        let iso = ISO8601DateFormatter()
        try container.encode(iso.string(from: createdAt), forKey: .createdAt)
        try container.encode(iso.string(from: updatedAt), forKey: .updatedAt)
    }
}
