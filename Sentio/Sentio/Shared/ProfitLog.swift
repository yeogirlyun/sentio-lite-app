//
//  ProfitLog.swift
//  Sentio
//
//  Created by BeeJay on 11/11/25.
//

import Foundation

struct ProfitLog: Codable, Identifiable, Hashable {
    let time: Date
    let equity: Double
    let invested: Double
    let running_positions: Int
    
    var id: Date {
        return time
    }
    
    private enum CodingKeys: String, CodingKey {
        case time
        case equity
        case invested
        case running_positions
    }
    
    init(time: Date, equity: Double, invested: Double, running_positions: Int) {
        self.time = time
        self.equity = equity
        self.invested = invested
        self.running_positions = running_positions
    }
    
    init(from decoder: Decoder) throws {
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
        
        time = decodeDate(.time)
        equity = try container.decode(Double.self, forKey: .equity)
        invested = try container.decode(Double.self, forKey: .invested)
        running_positions = try container.decode(Int.self, forKey: .running_positions)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(time, forKey: .time)
        try container.encode(equity, forKey: .equity)
        try container.encode(invested, forKey: .invested)
        try container.encode(running_positions, forKey: .running_positions)
    }
}
