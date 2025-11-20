//
//  ProfitDetailsView.swift
//  Sentio
//
//  Created by BeeJay on 11/13/25.
//

import SwiftUI
import Charts

struct ProfitDetailsView: View {
    var date: Date
    var log: ProfitLogGraphQLResponse.OrderLog?
    
    init(date: Date, log: ProfitLogGraphQLResponse.OrderLog?) {
        self.date = date
        self.log = log
    }
    
    @ViewBuilder
    private var tradeSummary: some View {
        if let trades = log?.profit.trade_count,
           let pnl = log?.profit.profit {
            HStack(alignment: .center) {
                let winRate = log?.profit.win_rate ?? 0
                let wins = log?.profit.winning_trades ?? 0
                let losses = log?.profit.losing_trades ?? 0
                let avgPnL = trades > 0 ? pnl / Double(trades) : 0
                
                VStack(alignment: .center, spacing: 4) {
                    Text("\(trades)")
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .bold()
                    
                    Text(trades == 1 ? "trade" : "trades")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.vertical, 8)
                .padding(.leading, 16)
                
                Divider()
                
                VStack(alignment: .center, spacing: 4) {
                    Text(String(format: "%.0f%%", winRate * 100))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .bold()
                    
                    Text("\(wins)W • \(losses)L")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.vertical, 8)
                
                Divider()
                
                VStack(alignment: .center, spacing: 4) {
                    Text(avgPnL, format: .currency(code: "USD"))
                        .foregroundColor(avgPnL >= 0 ? .green : .red)
                        .lineLimit(1)
                        .bold()
                    
                    Text("Avg PnL")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.vertical, 8)
                
                Divider()
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text(pnl, format: .currency(code: "USD"))
                        .foregroundColor(pnl >= 0 ? .green : .red)
                        .lineLimit(1)
                        .bold()
                    
                    Text("Total PnL")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.vertical, 8)
                .padding(.trailing, 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.06))
            .cornerRadius(8)
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var chartContent: some View {
        if let logData = log?.log, !logData.isEmpty {
            Chart {
                ForEach(logData) { entry in
                    LineMark(
                        x: .value("Time", entry.time),
                        y: .value("Equity", entry.equity)
                    )
                    .foregroundStyle(Color.green)
                }
            }
            .frame(height: 200)
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(
                        format: .dateTime.hour().minute()
                    )
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private var equitySummary: some View {
        if let logData = log?.log, !logData.isEmpty {
            VStack(alignment: .leading) {
                if let maxEquity = logData.max(by: { $0.equity < $1.equity })?.equity,
                   let minEquity = logData.min(by: { $0.equity < $1.equity })?.equity {
                    HStack {
                        Text("Peak Equity:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(maxEquity, format: .currency(code: "USD"))
                            .font(.caption)
                            .bold()
                    }
                    
                    HStack {
                        Text("Lowest Equity:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(minEquity, format: .currency(code: "USD"))
                            .font(.caption)
                            .bold()
                    }
                }
                
                if let maxInvested = logData.max(by: { $0.invested < $1.invested })?.invested {
                    HStack {
                        Text("Max Invested:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(maxInvested, format: .currency(code: "USD"))
                            .font(.caption)
                            .bold()
                    }
                }
                
                if let orders = log?.orders,
                   let maxProfit = orders.max(by: { $0.profit < $1.profit })?.profit,
                   let maxLoss = orders.min(by: { $0.profit < $1.profit })?.profit {
                    HStack {
                        Text("Max Profit:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(maxProfit, format: .currency(code: "USD"))
                            .font(.caption)
                            .bold()
                    }
                    
                    HStack {
                        Text("Max Loss:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(maxLoss * -1, format: .currency(code: "USD"))
                            .font(.caption)
                            .bold()
                    }
                }
            }
            .padding()
            .background(Color.aliceBlue)
            .cornerRadius(8)
            .padding()
        }
    }
    
    @ViewBuilder
    private var orderList: some View {
        if let orders = log?.orders, !orders.isEmpty {
            ForEach(orders, id: \.self) { order in
                OrderView(order: order)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                Divider()
            }
        }
    }
    
    var body: some View {
        Text(date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year()))
            .font(.headline)
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .center)
        
        Divider()
        
        tradeSummary
        
        chartContent
        equitySummary
        
        orderList
    }
}
