//
//  ContentView.swift
//  Sentio
//
//  Created by BeeJay on 10/21/25.
//

import SwiftUI

// Define a typed tab enum for safer selection handling and clearer code.
enum Tab: Int, CaseIterable, Identifiable {
    case signals = 0
    case positions = 1
    case history = 2
    case about = 3

    var id: Int { rawValue }
}

struct ContentView: View {
    // Persist selected tab across launches using AppStorage backed by UserDefaults (stores the raw Int)
    @AppStorage("selectedTab") private var selectedTabRawValue: Int = Tab.signals.rawValue

    // Helper binding that converts the stored raw Int into the typed Tab enum for use with TabView
    private var selectedTabBinding: Binding<Tab> {
        Binding(get: {
            Tab(rawValue: selectedTabRawValue) ?? .signals
        }, set: {
            selectedTabRawValue = $0.rawValue
        })
    }

    var body: some View {
        TabView(selection: selectedTabBinding) {
            SignalsView()
                .tabItem {
                    Label("Signals", systemImage: "waveform.path.ecg")
                }
                .tag(Tab.signals)

            PositionsView()
                .tabItem {
                    Label("Positions", systemImage: "briefcase.fill")
                }
                .tag(Tab.positions)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(Tab.history)

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(Tab.about)
        }
    }
}

#Preview {
    ContentView()
}
