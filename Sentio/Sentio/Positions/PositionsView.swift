//
//  PositionsView.swift
//  Sentio
//
//  Created by BeeJay on 10/21/25.
//

import SwiftUI

struct PositionsView: View {
    @StateObject private var vm = PositionsViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var headerHeight: CGFloat = 140
    
    @ViewBuilder
    private var shimmerView: some View {
        List(0..<6, id: \.self) { _ in
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    // Title skeleton
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 14)
                        .frame(maxWidth: .infinity)

                    // Subtitle/id skeleton
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.25))
                        .frame(height: 12)
                        .frame(width: 120)
                }
                Spacer()
                // Value skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 20)
            }
            .padding(.vertical, 6)
            .shimmer(true)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await vm.fetchOnce()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var errorView: some View {
        VStack(spacing: 8) {
            Text("Failed to load signals")
                .font(.headline)
            Text(vm.errorMessage ?? "Unknown error")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Retry") {
                Task { await vm.fetchOnce() }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    @ViewBuilder
    private var unrealizedPnLView: some View {
        VStack(spacing: 4) {
            Text("Total Unrealized PnL")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(String(format: "%@%.2f", vm.totalUnrealizedPnL >= 0 ? "+$" : "-$", abs(vm.totalUnrealizedPnL)))
                .font(.largeTitle)
                .bold()
                .foregroundColor(vm.totalUnrealizedPnL >= 0
                    ? Color(red: 21/255, green: 87/255, blue: 36/255)
                    : .red
                )
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List(vm.positions) { position in
            PositionWidget(position: position)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(.init(top: 4, leading: 8, bottom: 8, trailing: 8))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable {
            await vm.fetchOnce()
        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var body: some View {
            NavigationStack {
                ZStack(alignment: .top) {
                    // Main content is padded from the top so it sits below the header.
                    Group {
                        if vm.isLoading && vm.positions.isEmpty {
                            shimmerView
                        } else if let _ = vm.errorMessage, vm.positions.isEmpty {
                            errorView
                        } else {
                            VStack {
//                                unrealizedPnLView
                                contentView
                            }
                        }
                    }
                    // Use the measured header height as top padding so content starts below the header.
                    .padding(.top, headerHeight)

                    // Header pinned to the top and respecting safe area so it doesn't overlap the status bar.
                    HeaderView(title: "Positions", description: "Currently active positions")
                        .onPreferenceChange(HeaderHeightKey.self) { headerHeight = $0 }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .toolbar(.hidden, for: .navigationBar)
            }
            .navigationBarHidden(true)
            .onChange(of: scenePhase) {
                // Use the updated scenePhase value from the environment inside this zero-parameter closure
                if scenePhase == .active {
                    vm.startPolling()
                } else {
                    vm.stopPolling()
                }
            }
            .onAppear {
                if scenePhase == .active {
                    vm.startPolling()
                }
            }
            .onDisappear {
                // Stop polling when view disappears to avoid unnecessary requests
                vm.stopPolling()
            }
        }
}

#Preview {
    PositionsView()
}
