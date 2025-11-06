// filepath: /Users/beejay/repo/sentio/app/Sentio/Sentio/Signals/SignalsViewModel.swift

import Foundation
import Combine
import Network

// GraphQL response wrapper matching { "data": { "Signals": { "edges": [...], "total": ..., "page_info": {...} } } }
private struct SignalsGraphQLResponse: Codable {
    struct PageInfo: Codable {
        let start_cursor: String?
        let end_cursor: String?
        let has_next_page: Bool
        let has_previous_page: Bool
    }
    
    struct SignalsContainer: Codable {
        let edges: [Signal]
        let page_info: PageInfo
    }
    
    struct DataContainer: Codable {
        let Signals: SignalsContainer
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
    
    // Network monitor to check connectivity
    private let monitor = NWPathMonitor()
    private var isNetworkAvailable = true

    init(endpoint: URL = URL(string: "http://192.168.1.28:5000/query")!) {
        self.endpoint = endpoint
        
        // Start monitoring network connectivity
        startNetworkMonitoring()
    }
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkAvailable = path.status == .satisfied
            }
        }
        let queue = DispatchQueue(label: "SignalsViewModel.Network")
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
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

        // Check network availability before attempting connection
        guard isNetworkAvailable else {
            errorMessage = "Network unavailable. Enable debug mode or check connectivity."
            isLoading = false
            return
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Set timeout to prevent hanging on unconnected endpoints
        request.timeoutInterval = 10.0 // 10 second timeout

        let query = """
        query {
          Signals {
            edges {
              symbol {
                ticker
                name
                price
              }
              probability
              confidence
              metrics {
                name
                value
              }
            }
            page_info {
              start_cursor
              end_cursor
              has_next_page
              has_previous_page
            }
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
            
            let decoded = try JSONDecoder().decode(SignalsGraphQLResponse.self, from: data)
            signals = decoded.data?.Signals.edges ?? []
            isLoading = false
        } catch is CancellationError {
            // Task cancelled — treat as a graceful stop
            isLoading = false
        } catch let error as URLError where error.code == .timedOut {
            isLoading = false
            signals = []
            errorMessage = "Connection timed out. Server may be unavailable."
        } catch let error as URLError where error.code == .cannotConnectToHost {
            isLoading = false
            signals = []
            errorMessage = "Cannot connect to server. Check endpoint URL and network."
        } catch {
            isLoading = false
            signals = []
            errorMessage = error.localizedDescription
        }
    }
}
