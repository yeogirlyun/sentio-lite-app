// filepath: /Users/beejay/repo/sentio/app/Sentio/Sentio/Signals/SignalsViewModel.swift

import Foundation
import Combine

// Minimal GraphQL response wrapper matching { "data": { "signals": [...] } }
private struct SignalsGraphQLResponse: Codable {
    struct DataContainer: Codable {
        let signals: [Signal]
    }
    let data: DataContainer?
}

@MainActor
final class SignalsViewModel: ObservableObject {
    @Published var signals: [Signal] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Debug mode allows returning local mock data when the network (GraphQL) is unavailable.
    @Published var debugMode: Bool = false

    // Under-spec: use a configurable endpoint. Replace with your real GraphQL endpoint.
    let endpoint: URL

    // Polling task that repeatedly fetches every 60 seconds
    private var pollingTask: Task<Void, Never>?

    init(endpoint: URL = URL(string: "https://example.com/graphql")!) {
        self.endpoint = endpoint
        // Read persisted debug mode (so it survives app restarts)
        self.debugMode = UserDefaults.standard.bool(forKey: "signals.debug")
    }

    /// Persist and apply debug mode.
    func setDebugMode(_ enabled: Bool) {
        debugMode = enabled
        UserDefaults.standard.set(enabled, forKey: "signals.debug")
    }

    func startPolling() {
        // If already polling, keep it
        guard pollingTask == nil else { return }

        pollingTask = Task { [weak self] in
            // Quick initial fetch
            await self?.fetchOnce()

            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 60 * 1_000_000_000) // 60s
                } catch {
                    // Task cancelled
                    break
                }
                await self?.fetchOnce()
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    /// Simple mock data provider used when `debugMode` is enabled.
    private func mockSignals() -> [Signal] {
        let sampleMetrics1: [Metric] = [
            Metric(key: "RSI (14)", value: 34.2),
            Metric(key: "BB Proximity", value: 0.95),
            Metric(key: "Volume Ratio", value: 1.8)
        ]

        let sampleMetrics2: [Metric] = [
            Metric(key: "RSI (14)", value: 62.1),
            Metric(key: "Rotation Δ", value: 0.34),
            Metric(key: "Volume Ratio", value: 0.9)
        ]

        return [
            Signal(id: "tqqq", symbol: Symbol(ticker: "TQQQ", name: "ProShares Ultra QQQ", price: 102.2), confidence: 0.87, type: .StrongBuy, metrics: sampleMetrics1),
            Signal(id: "spy", symbol: Symbol(ticker: "SPY", name: "SPDR S&P 500 ETF Trust", price: 603.05), confidence: 0.42, type: .Hold, metrics: sampleMetrics2),
            Signal(id: "qqq", symbol: Symbol(ticker: "QQQ", name: "Invesco QQQ Trust", price: nil), confidence: 0.65, type: .Buy, metrics: sampleMetrics1),
            Signal(id: "aapl", symbol: Symbol(ticker: "AAPL", name: "Apple Inc.", price: nil), confidence: 0.33, type: .Sell, metrics: sampleMetrics2)
        ]
    }

    /// Performs a single network fetch of signals
    func fetchOnce() async {
        isLoading = true
        errorMessage = nil

        // If debug mode is enabled, short-circuit and display local mock data.
        if debugMode {
            // Simulate a short network delay so UI shows loading state briefly
            do {
                try await Task.sleep(nanoseconds: 150 * 1_000_000) // 150ms
            } catch {}

            signals = mockSignals()
            isLoading = false
            return
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let query = """
        query {
          signals {
            id
            symbol
            confidence
            type
            metrics {
              key
              value
            }
          }
        }
        """

        let bodyObject: [String: Any] = ["query": query]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyObject, options: [])

            let (data, response) = try await URLSession.shared.data(for: request)
            // Optional: check HTTP status
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                errorMessage = "HTTP error: \(http.statusCode)"
                isLoading = false
                return
            }

            let decoded = try JSONDecoder().decode(SignalsGraphQLResponse.self, from: data)
            signals = decoded.data?.signals ?? []
            isLoading = false
        } catch is CancellationError {
            // Task cancelled — treat as a graceful stop
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
