//
//  Symbol.swift
//  Sentio
//
//  Created by BeeJay on 10/23/25.
//

struct Symbol: Codable, Hashable {
    let ticker: String
    let name: String
    let price: Double?

    // Explicit initializer for convenience
    init(ticker: String, name: String, price: Double? = nil) {
        self.ticker = ticker
        self.name = name
        self.price = price
    }

    // Support multiple possible coding key names from external JSON (e.g. "symbol" or "ticker")
    private enum CodingKeys: String, CodingKey {
        case ticker
        case name
        case price
        case symbol // alternate key name some backends use
    }

    // Custom decoding to handle either "ticker" or "symbol" and price as string or number
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Ticker: prefer explicit "ticker", fall back to "symbol"
        if let t = try? container.decode(String.self, forKey: .ticker) {
            self.ticker = t
        } else if let s = try? container.decode(String.self, forKey: .symbol) {
            self.ticker = s
        } else {
            let context = DecodingError.Context(codingPath: [CodingKeys.ticker], debugDescription: "Missing ticker/symbol key")
            throw DecodingError.keyNotFound(CodingKeys.ticker, context)
        }

        // Name: optional, default to empty string if absent
        self.name = (try? container.decode(String.self, forKey: .name)) ?? ""

        // Price: try Double first, then String that can be converted to Double
        if let doublePrice = try? container.decodeIfPresent(Double.self, forKey: .price) {
            self.price = doublePrice
        } else if let strPrice = try? container.decodeIfPresent(String.self, forKey: .price), let d = Double(strPrice) {
            self.price = d
        } else {
            self.price = nil
        }
    }

    // Custom encoding: always encode as "ticker", "name", and encode price only if present
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ticker, forKey: .ticker)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(price, forKey: .price)
    }
}
