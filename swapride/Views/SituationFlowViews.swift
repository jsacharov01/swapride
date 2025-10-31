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
    private var today: Date { Calendar.current.startOfDay(for: Date()) }
    private func startOfDay(_ d: Date) -> Date { Calendar.current.startOfDay(for: d) }
    
    // Allow same-day search: end >= start (compare by day)
    var isValid: Bool { !destination.isEmpty && startOfDay(startDate) <= startOfDay(endDate) && peopleCount >= 1 }
    
    var body: some View {
        Form {
            Section("Kdo a kam") {
                Stepper(value: $peopleCount, in: 1...9) { Text("Počet lidí: \(peopleCount)") }
                Stepper(value: $childrenCount, in: 0...9) { Text("Počet dětí: \(childrenCount)") }
                Toggle("Bereme zvířata", isOn: $hasAnimals)
                TextField("Destinace (město/oblast)", text: $destination)
            }
            
            Section("Termín") {
                DateField(title: "Od", date: $startDate, minDate: today)
                DateField(title: "Do", date: $endDate, minDate: startOfDay(startDate))
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
        .onChange(of: startDate) { _, newStart in
            // If new start day is after current end day, snap end to the same day
            if startOfDay(newStart) > startOfDay(endDate) {
                endDate = newStart
            }
        }
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
        .onAppear {
            // Store last situation when the results screen appears
            appState.lastSituation = situation
        }
    }
}
