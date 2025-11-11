//
//  ProfitSummary.swift
//  Sentio
//
//  Created by BeeJay on 11/10/25.
//

import Foundation

public struct ProfitSummary: Codable, Hashable, Identifiable {
    public let id: String
    let start_time: Date
    let end_time: Date
    let profit: Double
    let trade_count: Int
    let win_rate: Double
    let winning_trades: Int
    let losing_trades: Int
    
    init (
        id: String,
        start_time: Date,
        end_time: Date,
        profit: Double,
        trade_count: Int,
        win_rate: Double,
        winning_trades: Int,
        losing_trades: Int
    ) {
        self.id = id
        self.start_time = start_time
        self.end_time = end_time
        self.profit = profit
        self.trade_count = trade_count
        self.win_rate = win_rate
        self.winning_trades = winning_trades
        self.losing_trades = losing_trades
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case start_time
        case end_time
        case profit
        case trade_count
        case win_rate
        case winning_trades
        case losing_trades
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
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
        
        self.id = try container.decode(String.self, forKey: .id)
        self.start_time = decodeDate(.start_time)
        self.end_time = decodeDate(.end_time)
        self.profit = try container.decode(Double.self, forKey: .profit)
        self.trade_count = try container.decode(Int.self, forKey: .trade_count)
        self.win_rate = try container.decode(Double.self, forKey: .win_rate)
        self.winning_trades = try container.decode(Int.self, forKey: .winning_trades)
        self.losing_trades = try container.decode(Int.self, forKey: .losing_trades)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(start_time, forKey: .start_time)
        try container.encode(end_time, forKey: .end_time)
        try container.encode(profit, forKey: .profit)
        try container.encode(trade_count, forKey: .trade_count)
        try container.encode(win_rate, forKey: .win_rate)
        try container.encode(winning_trades, forKey: .winning_trades)
        try container.encode(losing_trades, forKey: .losing_trades)
    }
}
