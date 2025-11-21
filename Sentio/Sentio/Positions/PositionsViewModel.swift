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
        let Positions: [Position]
    }
    
    let data: DataContainer?
}

@MainActor
final class PositionsViewModel: ObservableObject {
    @Published var positions: [Position] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    let endpoint: URL
    private var pollingTask: Task<Void, Never>?
    
    init(endpoint: URL = URL(string: "http://192.168.1.28:5000/query")!) {
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
                    try await Task.sleep(nanoseconds: 15 * 1_000_000_000)
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
    
    var totalUnrealizedPnL: Double {
        positions.reduce(0.0) { total, position in
            if let currentPrice = position.symbol.price {
                let pnlPerShare = currentPrice - position.price
                return total + (pnlPerShare * position.quantity)
            } else {
                return total
            }
        }
    }
    
    func fetchOnce() async {
        isLoading = true
        errorMessage = nil
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let query = """
        query {
          Positions {
            id
            symbol {
              ticker
              name
              price
            }
            quantity
            price
            stop_loss
            take_profit
            annotation
            created_at
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
            positions = decoded.data?.Positions ?? []
            isLoading = false
        } catch is CancellationError {
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
