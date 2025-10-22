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

    // Under-spec: use a configurable endpoint. Replace with your real GraphQL endpoint.
    let endpoint: URL

    // Polling task that repeatedly fetches every 60 seconds
    private var pollingTask: Task<Void, Never>?

    init(endpoint: URL = URL(string: "https://example.com/graphql")!) {
        self.endpoint = endpoint
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

    /// Performs a single network fetch of signals
    func fetchOnce() async {
        isLoading = true
        errorMessage = nil

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
