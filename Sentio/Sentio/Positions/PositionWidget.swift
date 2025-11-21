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
            
            Text(String(format: "%.0f shares @ $%.2f", position.quantity, position.price))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .layoutPriority(0)
        }
    }
    
    @ViewBuilder
    private var pnlSection: some View {
        if let pnl = position.unrealizedPnL {
            Spacer()
            
            Text(pnl, format: .currency(code: "USD"))
                .font(.headline)
                .bold()
                .foregroundColor(pnl >= 0 ? Color.profit : Color.loss)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }
}
