//
//  PositionsView.swift
//  Sentio
//
//  Created by BeeJay on 10/21/25.
//

import SwiftUI

struct PositionsView: View {
    var body: some View {
        NavigationStack {
            // Main content placed directly; header will be injected into the top safe area to match SignalsView
            Text("Positions")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Positions")
                .navigationBarTitleDisplayMode(.inline)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarHidden(true)
        .safeAreaInset(edge: .top) {
            HeaderView(title: "Positions", description: "Your open positions and summaries")
        }
    }
}

#Preview {
    PositionsView()
}
