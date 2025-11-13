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
    let stopLoss: Double?
    let takeProfit: Double?
    let annotation: String?
    let createdAt: Date
    let profit: Double
    let duration: UInt

    // Convenience initializer for programmatic creation
    init(
        id: String = UUID().uuidString,
        symbol: Symbol,
        signal: Signal? = nil,
        quantity: Double,
        price: Double,
        stopLoss: Double? = nil,
        takeProfit: Double? = nil,
        annotation: String? = nil,
        createdAt: Date = Date(),
        profit: Double = 0.0,
        duration: UInt = 0
    ) {
        self.id = id
        self.symbol = symbol
        self.signal = signal
        self.quantity = quantity
        self.price = price
        self.stopLoss = stopLoss
        self.takeProfit = takeProfit
        self.annotation = annotation
        self.createdAt = createdAt
        self.profit = profit
        self.duration = duration
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
        case stopLoss = "stop_loss"
        case takeProfit = "take_profit"
        case annotation
        case createdAt = "created_at"
        case profit
        case duration
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
        stopLoss = decodeDoubleIfPresent(.stopLoss)
        takeProfit = decodeDoubleIfPresent(.takeProfit)
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
        
        profit = decodeDoubleIfPresent(.profit) ?? 0.0
        if let durationUInt = try? container.decode(UInt.self, forKey: .duration) {
            duration = durationUInt
        } else if let durationInt = try? container.decode(Int.self, forKey: .duration) {
            duration = UInt(durationInt)
        } else if let durationStr = try? container.decode(String.self, forKey: .duration), let parsed = UInt(durationStr) {
            duration = parsed
        } else {
            duration = 0
        }
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
        try container.encodeIfPresent(stopLoss, forKey: .stopLoss)
        try container.encodeIfPresent(takeProfit, forKey: .takeProfit)
        try container.encodeIfPresent(annotation, forKey: .annotation)

        // Encode dates as ISO8601 strings for readability
        let iso = ISO8601DateFormatter()
        try container.encode(iso.string(from: createdAt), forKey: .createdAt)
        
        try container.encode(profit, forKey: .profit)
        try container.encode(duration, forKey: .duration)
    }
}
