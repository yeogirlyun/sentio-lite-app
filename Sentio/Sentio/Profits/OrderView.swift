//
//  OrderView.swift
//  Sentio
//
//  Created by BeeJay on 11/12/25.
//

import SwiftUI

struct OrderView: View {
    let order: Position
    let dateFormatter = DateFormatter()
    
    init(order: Position) {
        self.order = order
        
        let nyTimeZone = TimeZone(identifier: "America/New_York")!
        self.dateFormatter.timeZone = nyTimeZone
        self.dateFormatter.dateFormat = "h:mm a"
    }
    
    var body: some View {
        LazyVStack(alignment: .leading) {
            // define order open time: createdAt - duration * minutes
            let openTime = Calendar.current.date(byAdding: .minute, value: Int(order.duration) * -1, to: order.createdAt)!
            let entryPrice = order.profit.isZero ? 0 : (order.price - (order.profit / Double(order.quantity)))
            
            let durationText = order.duration < 391
                ? String(format: "%@ - %@ ET (%d min)",
                         dateFormatter.string(from: openTime),
                         dateFormatter.string(from: order.createdAt),
                         order.duration)
                : String(format: "Closed at %@", dateFormatter.string(from: order.createdAt))
            
            Text(durationText)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(order.symbol.ticker)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .layoutPriority(1)
                    
                    Text(String(format: "%.0f shares • $%.2f → $%.2f",
                                order.quantity,
                                entryPrice,
                                order.price))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .layoutPriority(0)
                }
                
                Spacer()
                
                Text(order.profit, format: .currency(code: "USD"))
                    .font(.headline)
                    .bold()
                    .foregroundColor(order.profit >= 0 ? Color.profit : Color.loss)
            }
        }
    }
}
