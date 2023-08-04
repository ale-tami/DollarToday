//
//  DollarTodayWidget.swift
//  DollarTodayWidget
//
//  Created by Alejandro Cesar Tami on 22/05/2023.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
  
    typealias Entry = DollarTodayEntry
        
    private let priceFetcher = PriceFetcher()
    
    func placeholder(in context: Context) -> Entry {
        return DollarTodayEntry(date: Date(),
                                sell: 0,
                                buy: 0,
                                count: 0)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DollarTodayEntry) -> Void) {
        completion(DollarTodayEntry(date: Date(),
                                    sell: 0,
                                    buy: 0,
                                    count: 0))
      
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DollarTodayEntry>) -> Void) {
        
        let date = Date()
        let futureDate = Calendar.current.date(byAdding: .minute, value: 15, to: date)!

        priceFetcher.getValues { dollarBlue, count in
            completion(Timeline(entries: [
                DollarTodayEntry(date: Date(),
                                 sell: Float(dollarBlue?.dollar.sell ?? 0),
                                 buy: Float(dollarBlue?.dollar.buy ?? 0),
                                 count: count)
            ], policy: .after(futureDate)))
            
        }
    }
}


struct DummyEntry: TimelineEntry {
    let date: Date
    let timesFetched: Int
}

class PriceFetcher {
    private let url = "https://api.bluelytics.com.ar/v2/latest"
    var timesFetched = 0
    var timer: Timer!
    
    func getValues(completion: @escaping (DollarBlue?, Int) -> Void) {
        guard let url = URL(string: url) else {
            completion(nil, 0)
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            self?.timesFetched += 1
            guard let data = data else {
                completion(nil, 0)
                return
            }
            do {
                let dollar = try JSONDecoder().decode(DollarBlue.self, from: data)
                DispatchQueue.main.async {
                    completion(dollar, self?.timesFetched ?? 0)
                }
            } catch {
                print("Fetching dollar value failed")
            }
        }.resume()
    }
}

struct DollarTodayEntry: TimelineEntry {
    let date: Date
    let sell: Float
    let buy: Float
    let count: Int
}

struct DollarBlue: Codable {
    var dollar: Dollar
    
    enum CodingKeys: String, CodingKey {
        case dollar = "blue"
    }
}
struct Dollar: Codable {
    var sell: Double
    var buy: Double
    
    enum CodingKeys: String, CodingKey {
        case sell = "value_sell"
        case buy = "value_buy"
    }
}

class DollarViewModel: ObservableObject {
    @Published var dollarSell: Double = 0
    private var fetcher: PriceFetcher

    init(fetcher: PriceFetcher) {
        self.fetcher = fetcher
        startFetching()
    }

    private func startFetching() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            self.fetcher.getValues { [weak self] dollar, _ in
                print("executed")
                guard let dollar = dollar else { return }
                self?.dollarSell = dollar.dollar.sell
            }
        }
    }
}

struct DollarTodayWidgetEntryView : View {
    var entry: DollarTodayEntry
    
    var body: some View {
        ZStack {
            Image("dolar")
                .padding(.bottom, 45.0)
            VStack(alignment: .center, spacing: 0) {
                Text(String(format: "Dólar Blue",  entry.sell))
                    .font(.bold(.system(size: 16))())
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                Text(String(format: "$%.2f",  entry.sell))
                    .font(.bold(.system(size: 36))())
                    .foregroundColor(.white)
                    .shadow(radius: 5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("DarkBlue").opacity(0.4))
        }
    }
}

@main
struct DollarTodayWidget: Widget {
    let kind: String = "DollarTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DollarTodayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Dólarware")
        .description("Widget que muestra la cotización del dólar.")
        .supportedFamilies([
                    .systemSmall,
                    .systemMedium,
                    .systemLarge,
                ])
    }
}
