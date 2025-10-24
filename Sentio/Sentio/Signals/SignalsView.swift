// filepath: /Users/beejay/repo/sentio/app/Sentio/Sentio/Signals/SignalsView.swift
//
//  SignalsView.swift
//  Sentio
//
//  Created by BeeJay on 10/21/25.
//

import SwiftUI

// MARK: - Shimmer modifier
struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if reduceMotion {
                        // No moving shimmer when Reduce Motion is enabled; keep the view unchanged
                        Color.clear
                    } else {
                        GeometryReader { geo in
                            // Moving gradient that acts as the shimmer
                            let gradient = LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.0), Color.white.opacity(0.6), Color.white.opacity(0.0)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )

                            Rectangle()
                                .fill(gradient)
                                .rotationEffect(.degrees(30))
                                .frame(width: geo.size.width * 1.6, height: geo.size.height * 2)
                                .offset(x: phase * geo.size.width * 2)
                                .blendMode(.plusLighter)
                        }
                    }
                }
                .clipped()
                .allowsHitTesting(false)
            )
            .onAppear {
                // animate the phase from -1 to 1 repeatedly when allowed
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                    phase = 1.0
                }
            }
    }
}

extension View {
    /// Apply shimmer when `active` is true.
    func shimmer(_ active: Bool) -> some View {
        Group {
            if active {
                modifier(Shimmer())
            } else {
                self
            }
        }
    }
}

struct SignalsView: View {
    @StateObject private var vm = SignalsViewModel()
    @Environment(\.scenePhase) private var scenePhase
    // Start with a reasonable default so the header offset is correct before measurement
    @State private var headerHeight: CGFloat = 140

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Main content is padded from the top so it sits below the header.
                VStack(spacing: 0) {
                    Group {
                        if vm.isLoading && vm.signals.isEmpty {
                            // Show skeleton list with shimmer while loading
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
                        } else if let error = vm.errorMessage, vm.signals.isEmpty {
                            VStack(spacing: 8) {
                                Text("Failed to load signals")
                                    .font(.headline)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Button("Retry") {
                                    Task { await vm.fetchOnce() }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        } else {
                            // Use availability checks so we can call .scrollContentBackground on iOS 16+
                            if #available(iOS 16.0, *) {
                                List(vm.signals) { signal in
                                    SignalWidget(signal: signal)
                                        .padding(.vertical, 4)
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                }
                                .listStyle(.plain)
                                .scrollContentBackground(.hidden)
                                .refreshable {
                                    await vm.fetchOnce()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                List(vm.signals) { signal in
                                    SignalWidget(signal: signal)
                                        .padding(.vertical, 4)
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                }
                                .listStyle(.plain)
                                .refreshable {
                                    await vm.fetchOnce()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }
                // Use the measured header height as top padding so content starts below the header.
                .padding(.top, headerHeight)

                // Header pinned to the top and respecting safe area so it doesn't overlap the status bar.
                HeaderView(title: "Signals", description: "Live signal data and metrics")
                    .onPreferenceChange(HeaderHeightKey.self) { headerHeight = $0 }
                    // Small debug toggle button pinned inside the header at top-right.
                    .overlay(alignment: .topTrailing) {
                        HStack {
                            Button {
                                let new = !vm.debugMode
                                vm.setDebugMode(new)
                                Task { await vm.fetchOnce() }
                            } label: {
                                Text(vm.debugMode ? "DEBUG ON" : "Debug")
                                    .font(.caption2).bold()
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(vm.debugMode ? Color.green.opacity(0.16) : Color.gray.opacity(0.10))
                                    .foregroundColor(vm.debugMode ? Color.green : Color.primary)
                                    .clipShape(Capsule())
                            }
                            .accessibilityLabel(vm.debugMode ? "Disable debug mode" : "Enable debug mode")
                        }
                        .padding(.top, 8)
                        .padding(.trailing, 16)
                    }
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
    SignalsView()
}
