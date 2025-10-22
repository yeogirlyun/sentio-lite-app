//
//  AboutView.swift
//  Sentio
//
//  Created by BeeJay on 10/21/25.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationStack {
            // Main content; header is injected into the top safe area to match other tabs
            VStack(spacing: 12) {
                Text("Sentio")
                    .font(.title)
                Text("Version 1.0")
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarHidden(true)
        .safeAreaInset(edge: .top) {
            HeaderView(title: "About", description: "App information and credits")
        }
    }
}

#Preview {
    AboutView()
}
