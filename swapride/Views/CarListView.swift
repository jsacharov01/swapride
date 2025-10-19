import SwiftUI

struct CarListView: View {
    @EnvironmentObject var appState: AppState
    @State private var query: String = ""
    
    var filtered: [Car] {
        let list = appState.carsExcludingCurrentUser()
        guard !query.isEmpty else { return list }
        return list.filter { car in
            let hay = "\(car.title) \(car.make) \(car.model) \(car.location)".lowercased()
            return hay.contains(query.lowercased())
        }
    }
    
    var body: some View {
        List {
            ForEach(filtered) { car in
                NavigationLink(destination: CarDetailView(car: car)) {
                    VStack(alignment: .leading) {
                        Text(car.title).font(.headline)
                        Text("\(car.make) \(car.model), \(car.year) • \(car.seats) míst • \(car.location)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Dostupná auta")
        .searchable(text: $query, prompt: "Hledat značku, model, město…")
        .toolbar {
            NavigationLink { CreateListingView() } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Přidat auto")
        }
    }
}
