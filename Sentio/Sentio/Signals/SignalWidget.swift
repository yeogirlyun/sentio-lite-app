// filepath: /Users/beejay/repo/sentio/sentio-lite-app/Sentio/Sentio/Signals/SignalWidget.swift
// A compact card-style widget used in the Signals list

import SwiftUI

struct SignalWidget: View {
    let signal: Signal

    // Track whether the metrics grid is expanded
    @State private var isExpanded: Bool = false
    
    private var probabilityColor: Color {
        switch signal.probability {
            // #DC143C
            case 0.0..<0.2:
                return Color(red: 220/255, green: 20/255, blue: 60/255)
            // #F75270
            case 0.2..<0.4:
                return Color(red: 247/255, green: 82/255, blue: 112/255)
            // #FDEBD0
            case 0.4..<0.6:
            return .gray.opacity(0.67)
            // #3E5F44
            case 0.6...0.8:
                return Color(red: 62/255, green: 95/255, blue: 68/255)
            // #5E936C
            case 0.8...1.0:
                return Color(red: 94/255, green: 147/255, blue: 108/255)
            default:
                return .gray
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var priceSection: some View {
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
    }

    @ViewBuilder
    private var confidenceSection: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("Confidence")
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(String(format: "%.0f%%", signal.confidence * 100))
                .font(.headline)
                .foregroundColor(.primary.opacity(signal.confidence >= 0.67 ? 1.0 : 0.75))
        }
    }

    @ViewBuilder
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(signal.metrics, id: \.name) { metric in
                metricCell(metric)
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    @ViewBuilder
    private func metricCell(_ metric: Metric) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(metric.name.localizedUppercase)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(String(format: "%.2f", metric.value))
                .font(.subheadline).bold()
//                .foregroundColor(typeColors.fg)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
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
                priceSection
                Spacer()
                confidenceSection
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
                        metricsGrid
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
            Text(signal.probability >= 0.5 ? "▲" : "▼")
                .font(.caption2).bold()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(probabilityColor)
                .foregroundColor(.white)
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
        let sampleMetrics: [Metric] = [Metric(name: "RSI", value: 34.2), Metric(name: "Volume", value: 1.8)]
        let sample = Signal(symbol: Symbol(ticker: "TQQQ", name: "TQQQ", price: nil), probability: 0.6, confidence: 0.87, type: .StrongBuy, metrics: sampleMetrics)

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
