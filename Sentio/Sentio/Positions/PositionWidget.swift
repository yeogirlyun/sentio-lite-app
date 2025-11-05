//
//  PositionWidget.swift
//  Sentio
//
//  Created by BeeJay on 10/27/25.
//

import SwiftUI

struct PositionWidget: View {
    let position: Position
    
    @ViewBuilder
    private var tickerSection: some View {
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
    }
    
    @ViewBuilder
    private var pnlSection: some View {
        if let pnl = position.unrealizedPnL {
            Spacer()
            
            Text(String(format: "%@%.2f", pnl >= 0 ? "+$" : "-$", abs(pnl)))
                .font(.headline)
                .bold()
                .foregroundColor(pnl >= 0
                    ? Color(red: 21/255, green: 87/255, blue: 36/255)
                    : .red
                )
        }
    }
    
    @ViewBuilder
    private var annotationSection: some View {
        let baseAnnotation = String(format: "Entry Date: %@", position.createdAt.formatted(date: .omitted, time: .shortened))
        let annotation = if let note = position.annotation, !note.isEmpty {
            baseAnnotation + " • " + note
        } else {
            baseAnnotation
        }
        
        Spacer().frame(height: 4)
        Text(annotation)
            .font(.caption)
            .foregroundColor(.secondary)
            .layoutPriority(0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                tickerSection
                pnlSection
            }
            
            annotationSection
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
