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
    private var unrealizedPnLView: some View {
        VStack(spacing: 4) {
            Text("Total Unrealized PnL")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(vm.totalUnrealizedPnL, format: .currency(code: "USD"))
                .font(.largeTitle)
                .bold()
                .foregroundColor(vm.totalUnrealizedPnL >= 0
                    ? Color(red: 21/255, green: 87/255, blue: 36/255)
                    : .red
                )
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(12)
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
            
            if vm.positions.isEmpty {
                Text("No open positions")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                unrealizedPnLView
                
                List(vm.positions) { position in
                    PositionWidget(position: position)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.white))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.black.opacity(0.02), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 1)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Positions")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarHidden(false)
        .refreshable { await vm.fetchOnce() }
        .onChange(of: scenePhase) {            
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
            vm.stopPolling()
        }
    }
}

#Preview {
    PositionsView()
}
