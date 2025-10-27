//
//  Shimmer.swift
//  Sentio
//
//  Created by BeeJay on 10/27/25.
//

import SwiftUI

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
