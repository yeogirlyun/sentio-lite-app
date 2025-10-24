// filepath: /Users/beejay/repo/sentio/sentio-lite-app/Sentio/Sentio/Signals/SignalWidget.swift
// A compact card-style widget used in the Signals list

import SwiftUI

struct SignalWidget: View {
    let signal: Signal

    // Track whether the metrics grid is expanded
    @State private var isExpanded: Bool = false

    private var typeLabel: String {
        // Convert raw value like "strong_buy" to an uppercase label (e.g. "STRONG BUY")
        signal.type.rawValue.replacingOccurrences(of: "_", with: " ").localizedUppercase
    }

    // Colors for the type capsule (bg, fg). Chosen to match provided colors for buys and hold,
    // and logical "danger" colors for sells.
    private var typeColors: (bg: Color, fg: Color) {
        switch signal.type {
        case .StrongBuy, .Buy:
            // background: #d4edda, text: #155724
            return (Color(red: 212/255, green: 237/255, blue: 218/255),
                    Color(red: 21/255, green: 87/255, blue: 36/255))
        case .Hold:
            // background: #e2e3e5, text: #383d41
            return (Color(red: 226/255, green: 227/255, blue: 229/255),
                    Color(red: 56/255, green: 61/255, blue: 65/255))
        case .StrongSell, .Sell:
            // chosen reasonable danger colors (Bootstrap-like): bg #f8d7da, text #721c24
            return (Color(red: 248/255, green: 215/255, blue: 218/255),
                    Color(red: 114/255, green: 28/255, blue: 36/255))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(signal.symbol.ticker)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
                .layoutPriority(1)

            // Show the full name below the ticker when available. Use a subdued
            // secondary style and keep it to a single line so widgets/lists stay compact.
            if !signal.symbol.name.isEmpty {
                Text(signal.symbol.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .layoutPriority(0)
            }
            
            Spacer().frame(height: 4)
            
            HStack {
                // Current price if available
                if let price = signal.symbol.price {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Current Price")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(String(format: "$%.2f", price))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                // Confidence score
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Confidence")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f%%", signal.confidence * 100))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            .frame(maxWidth: .infinity)

            // Expandable Technical Analysis section when metrics are available
            if !signal.metrics.isEmpty {
                Spacer().frame(height: 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: {
//                        withAnimation(.easeInOut) {
//                            isExpanded.toggle()
//                        }
                        isExpanded.toggle()
                    }) {
                        HStack(spacing: 8) {
                            Text("📈 Technical Analysis")
                                .font(.subheadline).bold()
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                    }
                    .background(Color(.secondarySystemBackground))
                    .buttonStyle(PlainButtonStyle())
                    .cornerRadius(4)

                    if isExpanded {
                        // Two-column responsive grid for metrics
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(signal.metrics, id: \.key) { metric in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(metric.key.localizedUppercase)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.2f", metric.value))
                                        .font(.subheadline).bold()
                                        .foregroundColor(typeColors.fg)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
        }
        // Ensure the card has room to display the symbol and capsule; prevents collapse in lists
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.02), lineWidth: 0.5)
        )
        // Move the type label to the card's top-right corner
        .overlay(alignment: .topTrailing) {
            let colors = typeColors
            Text(typeLabel)
                .font(.caption2).bold()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(colors.bg)
                .foregroundColor(colors.fg)
                .clipShape(Capsule())
                .padding(.top, 16)
                .padding(.trailing, 12)
        }
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 1)
    }
}

// MARK: - Preview

struct SignalWidget_Previews: PreviewProvider {
    static var previews: some View {
        let sampleMetrics: [Metric] = [Metric(key: "RSI", value: 34.2), Metric(key: "Volume", value: 1.8)]
        let sample = Signal(id: "1", symbol: Symbol(ticker: "TQQQ", name: "TQQQ", price: nil), confidence: 0.87, type: .StrongBuy, metrics: sampleMetrics)

        Group {
            SignalWidget(signal: sample)
                .padding()
                .previewLayout(.sizeThatFits)

            SignalWidget(signal: sample)
                .preferredColorScheme(.dark)
                .padding()
                .previewLayout(.sizeThatFits)
        }
    }
}
