//
//  ProfitsView.swift
//  Sentio
//
//  Created by BeeJay on 11/6/25.
//

import SwiftUI
import InfiniteScroll

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
                    
                    Text(item.start_time, style: .date)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .layoutPriority(0)
                    
                    Text(detailedLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .layoutPriority(0)
                }
                
                Spacer()
                
                Text(String(format: "%@%.2f", item.profit >= 0 ? "+$" : "-$", abs(item.profit)))
                    .font(.headline)
                    .bold()
                    .foregroundColor(item.profit >= 0 ? .green : .red)
            }
            
            Divider()
            .padding(.vertical, 2)
            
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
                            date = item.start_time
                            isSheetPresented = true
                        }
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 1)
                        .padding(.horizontal)
                        .onAppear {
                            let shouldLoadMore = vm.data.last == item && vm.hasNextPage()
                            if shouldLoadMore {
                                print("Appeared item: \(item)")
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
                Text($date.wrappedValue, style: .date)
                    .padding()
            }
            .toolbar {
                NavigationLink {
                    Text("another view")
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
                                date = newDate
                                isSheetPresented = true
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
