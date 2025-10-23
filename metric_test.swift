import Foundation

// Standalone copy of Metric for a quick runtime test
struct Metric: Codable, Hashable {
    let key: String
    let value: Double

    private enum CodingKeys: String, CodingKey {
        case key
        case value
    }

    init(key: String, value: Double) {
        self.key = key
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)

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
        try container.encode(key, forKey: .key)
        try container.encode(value, forKey: .value)
    }
}

let json = """
[
  { "key": "a", "value": 1.23 },
  { "key": "b", "value": 2 },
  { "key": "c", "value": "3.45" },
  { "key": "d", "value": "not_a_number" }
]
"""

let data = Data(json.utf8)
let decoder = JSONDecoder()
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

if let metrics = try? decoder.decode([Metric].self, from: data) {
    print("Decoded metrics:")
    for m in metrics {
        print("- key=\(m.key) value=\(m.value)")
    }

    if let out = try? encoder.encode(metrics), let outStr = String(data: out, encoding: .utf8) {
        print("\nRe-encoded JSON:\n\(outStr)")
    } else {
        print("Failed to encode metrics")
    }
} else {
    print("Decoding failed")
}
