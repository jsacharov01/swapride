import SwiftUI

struct CreateSituationView: View {
    @EnvironmentObject var appState: AppState
    @State private var peopleCount: Int = 2
    @State private var childrenCount: Int = 0
    @State private var hasAnimals: Bool = false
    @State private var destination: String = "Praha"
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var tripType: TripType = .friends
    
    var isValid: Bool { !destination.isEmpty && startDate < endDate && peopleCount >= 1 }
    
    var body: some View {
        Form {
            Section("Kdo a kam") {
                Stepper(value: $peopleCount, in: 1...9) { Text("Počet lidí: \(peopleCount)") }
                Stepper(value: $childrenCount, in: 0...9) { Text("Počet dětí: \(childrenCount)") }
                Toggle("Bereme zvířata", isOn: $hasAnimals)
                TextField("Destinace (město/oblast)", text: $destination)
            }
            
            Section("Termín") {
                DatePicker("Od", selection: $startDate, displayedComponents: .date)
                DatePicker("Do", selection: $endDate, in: startDate..., displayedComponents: .date)
            }
            
            Section("Typ výletu") {
                Picker("Typ", selection: $tripType) {
                    ForEach(TripType.allCases) { t in Text(t.rawValue).tag(t) }
                }
                .pickerStyle(.segmented)
            }
            
            Section {
                NavigationLink {
                    let situation = Situation(
                        id: UUID().uuidString,
                        peopleCount: peopleCount,
                        childrenCount: childrenCount,
                        hasAnimals: hasAnimals,
                        destination: destination,
                        startDate: startDate,
                        endDate: endDate,
                        tripType: tripType
                    )
                    SituationResultsView(situation: situation)
                } label: {
                    Label("Najít vhodná auta", systemImage: "magnifyingglass")
                }
                .disabled(!isValid)
            }
        }
        .navigationTitle("Moje situace")
    }
}

struct SituationResultsView: View {
    @EnvironmentObject var appState: AppState
    let situation: Situation
    
    var matches: [Car] {
        appState.matchingCars(for: situation)
    }
    
    var body: some View {
        List {
            if matches.isEmpty {
                Text("Nenašli jsme žádná auta pro zadanou situaci.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(matches) { car in
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
        }
        .navigationTitle("Výsledky")
        .toolbar {
            if let last = appState.lastSituation {
                Text(last.tripType.rawValue).foregroundStyle(.secondary)
            }
        }
    }
}
