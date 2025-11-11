//
//  ViewModel.swift
//  Sentio
//
//  Created by BeeJay on 11/7/25.
//

import Foundation

private struct ProfitsGraphQLResponse: Codable {
    struct DataContainer: Codable {
        let Profits: ProfitsConnection
    }
    
    struct ProfitsConnection: Codable {
        let edges: [ProfitSummary]
        let page_info: PageInfo
    }
    
    let data: DataContainer?
}

@Observable
@MainActor
class ViewModel {
    let endpoint: URL
    
    var data: [ProfitSummary] = []
    var isLoading: Bool = false
    var page: PageInfo?
    var error: Error?
    
    init(endpoint: URL = URL(string: "http://192.168.1.28:5000/query")!) {
        self.endpoint = endpoint
    }
    
    func hasNextPage() -> Bool {
        return page?.HasNextPage ?? true
    }
    
    func refresh() async {
        page = nil
        Task {
            await loadMore()
        }
    }
    
    func loadMore(after: String? = nil, limit: Int = 20) async {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let query = """
        query {
            Profits(interval: D1, after: \(after != nil ? "\"\(after!)\"" : "null"), first: \(limit)) {
              edges {
                id,
                start_time,
                end_time,
                profit,
                trade_count,
                win_rate,
                winning_trades,
                losing_trades
              }
              page_info {
                start_cursor,
                end_cursor,
                has_next_page,
                has_previous_page
              }
            }
        }
        """
        
        let bodyObject: [String: Any] = ["query": query]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyObject, options: [])
            let (responseData, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                print("HTTP error: \(http.statusCode)")
                error = NSError(domain: "", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(http.statusCode)"])
                isLoading = false
                return
            }
            
            print("Response Data: \(String(data: responseData, encoding: .utf8) ?? "N/A")")
            
            let decoded = try JSONDecoder().decode(ProfitsGraphQLResponse.self, from: responseData)
            if after == nil {
                print("Refreshing data")
                data = []
            }

            data.append(contentsOf: decoded.data?.Profits.edges ?? [])
            page = decoded.data?.Profits.page_info
            isLoading = false
        } catch is CancellationError {
            isLoading = false
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
            isLoading = false
        } catch {
            isLoading = false
        }
    }
}
