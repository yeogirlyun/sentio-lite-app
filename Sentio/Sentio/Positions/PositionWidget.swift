//
//  PositionWidget.swift
//  Sentio
//
//  Created by BeeJay on 10/27/25.
//

import SwiftUI

struct PositionWidget: View {
    let position: Position

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading) {
                    Text(position.symbol.ticker)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .layoutPriority(1)
                    
                    if !position.symbol.name.isEmpty {
                        Text(String(format: "%.0f shares @ $%.2f", position.quantity, position.price))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .layoutPriority(0)
                    }
                }
                
                Spacer()
                
                if let pnl = position.unrealizedPnL {
                    Text(String(format: "%@%.2f", pnl >= 0 ? "+$" : "-$", abs(pnl)))
                        .font(.headline)
                        .bold()
                        .foregroundColor(pnl >= 0
                            ? Color(red: 21/255, green: 87/255, blue: 36/255)
                            : .red
                        )
                }
            }
            
            if let pnlPercent = position.unrealizedPnLPercent {
                Spacer().frame(height: 4)
                
                Text(String(format: "Entry Date: %@ • Approaching profit target (%@%.2f%% of $%.2f%%)",
                    position.createdAt.formatted(date: .omitted, time: .shortened),
                    pnlPercent > 0 ? "+" : "-", abs(pnlPercent),
                    position.target != nil ? (position.target! - position.price) / position.price * 100 : 0
                ))
                .font(.caption)
                .foregroundColor(.secondary)
                .layoutPriority(0)
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
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 1)
    }
}
