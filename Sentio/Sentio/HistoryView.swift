//
//  HistoryView.swift
//  Sentio
//
//  Created by BeeJay on 10/21/25.
//

import SwiftUI

struct HistoryView: View {
    var body: some View {
        NavigationStack {
            // Main content; header is injected into the top safe area to match SignalsView
            Text("History")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("History")
                .navigationBarTitleDisplayMode(.inline)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarHidden(true)
        .safeAreaInset(edge: .top) {
            HeaderView(title: "History", description: "Past activity and logs")
        }
    }
}

#Preview {
    HistoryView()
}
