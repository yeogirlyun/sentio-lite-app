//
//  PositionsViewModel.swift
//  Sentio
//
//  Created by BeeJay on 10/27/25.
//

import Foundation
import Combine

private struct PositionsGraphQLResponse: Codable {
    struct DataContainer: Codable {
        let positions: [Position]
    }
    
    let data: DataContainer?
}

@MainActor
final class PositionsViewModel: ObservableObject {
    @Published var positions: [Position] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var debugMode: Bool = false
    
    let endpoint: URL
    private var pollingTask: Task<Void, Never>?
    
    init(endpoint: URL = URL(string: "https://example.com/graphql")!) {
        self.endpoint = endpoint
        // Read persisted debug mode (so it survives app restarts)
        self.debugMode = UserDefaults.standard.bool(forKey: "signals.debug")
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
    
    func mockPositions() -> [Position] {
        return [
            Position(
                id: UUID().uuidString,
                symbol: Symbol(ticker: "AAPL", name: "Apple Inc.", price: 154.3),
                quantity: 10,
                price: 150.0,
                target: 155.8,
                side: "buy",
                positionIntent: "buy_to_open",
                createdAt: ISO8601DateFormatter().date(from: "2025-10-27T10:00:00Z")!,
                updatedAt: ISO8601DateFormatter().date(from: "2025-10-27T10:01:00Z")!
            ),
            Position(
                id: UUID().uuidString,
                symbol: Symbol(ticker: "TSLA", name: "Tesla, Inc.", price: 699.3),
                quantity: 5,
                price: 700.0,
                target: 720.5,
                side: "buy",
                positionIntent: "buy_to_open",
                createdAt: ISO8601DateFormatter().date(from: "2025-10-15T14:30:00Z")!,
                updatedAt: ISO8601DateFormatter().date(from: "2025-10-27T10:02:00Z")!
            )
        ]
    }
    
    func fetchOnce() async {
        isLoading = true
        errorMessage = nil
        
        // If debug mode is enabled, simulate a short network delay so UI shows loading state briefly
        if debugMode {
            do {
                try await Task.sleep(nanoseconds: 150 * 1_000_000) // 150ms
            } catch {}

            positions = mockPositions()
            isLoading = false
            return
        }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let query = """
        query {
          positions {
            id
            symbol
          }
        }
        """
        
        let bodyObject: [String: Any] = ["query": query]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyObject, options: [])
            
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                errorMessage = "HTTP error: \(http.statusCode)"
                isLoading = false
                return
            }
            
            let decoded = try JSONDecoder().decode(PositionsGraphQLResponse.self, from: data)
            positions = decoded.data?.positions ?? []
            isLoading = false
        } catch is CancellationError {
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
