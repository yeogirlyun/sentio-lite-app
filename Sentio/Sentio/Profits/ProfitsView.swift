//
//  ProfitsView.swift
//  Sentio
//
//  Created by BeeJay on 11/6/25.
//

import SwiftUI
import Charts

struct ProfitsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var interval = 1
    @State private var vm = ViewModel()
    @State private var date: Date = Date()
    @State private var isSheetPresented: Bool = false
    
    let dateRange: ClosedRange<Date> = {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? TimeZone.current
        
        let startComponents = DateComponents(year: 2021, month: 1, day: 1)
        return calendar.date(from:startComponents)!...Date()
    }()
    
    @ViewBuilder
    private func ProfitsListView(_ item: ProfitSummary) -> some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    let label = item.trade_count == 1 ? "1 trade" : "\(item.trade_count) trades"
                    let detailedLabel = item.win_rate > 0 ? label + String(format: " • %.0f%% win rate", item.win_rate * 100) : label
                    
                    Text(item.start_time.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year()))
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(detailedLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text(String(format: "%@%.2f", item.profit >= 0 ? "+$" : "-$", abs(item.profit)))
                    .font(.headline)
                    .bold()
                    .foregroundColor(item.profit >= 0 ? .green : .red)
            }
            
            Divider().padding(.vertical, 2)
            
            Text(String(format: "%d wins / %d losses", item.winning_trades, item.losing_trades))
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .layoutPriority(0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack {
                    ForEach(vm.data, id: \.self) { item in
                        ProfitsListView(item)
                            .onTapGesture {
                                Task {
                                    vm.isLoading = true
                                    await vm.getOrderLog(dt: item.start_time)
                                    date = item.start_time
                                    isSheetPresented = true
                                    vm.isLoading = false
                                }
                            }
                            .background(Color.primary.opacity(0.06))
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 1)
                            .padding(.horizontal)
                            .onAppear {
                                let shouldLoadMore = vm.data.last == item && vm.hasNextPage()
                                if shouldLoadMore {
                                    Task {
                                        await vm.loadMore()
                                    }
                                }
                            }
                    }
                    
                    if vm.isLoading {
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity)
                            .padding()
//                    } else if !vm.hasNextPage() {
//                        Text("End of content")
//                            .foregroundStyle(.secondary)
//                            .frame(maxWidth: .infinity)
//                            .padding()
                    }
                }
            }
            .refreshable { await vm.refresh() }
            .navigationTitle("Profits History")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isSheetPresented) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        Spacer().frame(height: 8)
                        
                        Text(date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year()))
                            .font(.headline)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Divider()
                        
                        HStack(alignment: .center) {
                            let trades = vm.log?.profit.trade_count ?? 0
                            let pnl = vm.log?.profit.profit ?? 0
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
                                let winRate = vm.log?.profit.win_rate ?? 0
                                let wins = vm.log?.profit.winning_trades ?? 0
                                let losses = vm.log?.profit.losing_trades ?? 0
                                
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
                    .frame(maxWidth: .infinity)
                    
                    if let logData = vm.log?.log, !logData.isEmpty {
                        VStack(alignment: .leading) {
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
                            
                            Divider()
                            
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
                                
//                                let orders = vm.log?.orders ?? []
//                                let maxProfit = orders.max(by: { $0.profit < $1.profit })?.profit ?? 0
//                                print("Max Profit: \(maxProfit)")

//                                if let maxProfit = self.log?.profit.profit.max,
//                                   let minProfit = logData.min(by: { $0.profit < $1.profit })?.profit {
//                                    HStack {
//                                        Text("Max Profit:")
//                                            .font(.caption)
//                                            .foregroundColor(.secondary)
//                                        Spacer()
//                                        Text(maxProfit, format: .currency(code: "USD"))
//                                            .font(.caption)
//                                            .bold()
//                                    }
//                                    
//                                    HStack {
//                                        Text("Max Loss:")
//                                            .font(.caption)
//                                            .foregroundColor(.secondary)
//                                        Spacer()
//                                        Text(minProfit, format: .currency(code: "USD"))
//                                            .font(.caption)
//                                            .bold()
//                                    }
//                                }
                            }
                            .padding()
                        }
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(8)
                        .padding()
                    } else {
                        Text("No trade data available")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                    
                    if let orders = vm.log?.orders, !orders.isEmpty {
                        ForEach(orders, id: \.self) { order in
                            OrderView(order: order)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            Divider()
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .toolbar {
                NavigationLink {
                    Text("Symbol Filter")
                } label: {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption)
                }
                
                NavigationLink {
                    DatePicker("Select Date", selection: $date, in: dateRange, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .onChange(of: date) { oldDate, newDate in
                            let beforeDay = Calendar.current.component(.day, from: oldDate)
                            let afterDay = Calendar.current.component(.day, from: newDate)
                            if beforeDay != afterDay {
                                Task {
                                    await vm.getOrderLog(dt: newDate)
                                    date = newDate
                                    isSheetPresented = true
                                }
                            }
                        }
                    .navigationTitle("Select Date")
                    .toolbar {
                        Button("Today") {
                            date = Date()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } label: {
                    Image(systemName: "calendar")
                        .font(.caption)
                }
            }
        }
        .navigationBarHidden(false)
        .onAppear {
            if vm.data.isEmpty {
                Task {
                    await vm.refresh()
                }
            }
        }
    }
}

#Preview {
    ProfitsView()
}
