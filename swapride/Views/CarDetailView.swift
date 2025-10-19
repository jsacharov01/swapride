import SwiftUI

struct CarDetailView: View {
    @EnvironmentObject var appState: AppState
    let car: Car
    
    @State private var myCarId: String?
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var message: String = ""
    @State private var showConfirm: Bool = false
    
    var myCars: [Car] {
        appState.carsOfCurrentUser()
    }
    
    var canRequest: Bool {
        if car.ownerId == appState.currentUser.id { return false }
        guard let myCarId else { return false }
        return !myCarId.isEmpty && startDate < endDate
    }
    
    var body: some View {
        Form {
            Section("Auto") {
                Text(car.title).font(.headline)
                Text("\(car.make) \(car.model) • \(car.year)")
                Text("\(car.seats) míst • \(car.transmission.rawValue) • \(car.fuel.rawValue)")
                Text("Lokalita: \(car.location)")
                if let desc = car.description, !desc.isEmpty {
                    Text(desc).foregroundStyle(.secondary)
                }
            }
            
            Section("Nabídnout k výměně") {
                Picker("Moje auto", selection: $myCarId) {
                    Text("Vyberte auto").tag(Optional<String>.none)
                    ForEach(myCars) { c in
                        Text(c.title).tag(Optional<String>(c.id))
                    }
                }
                DatePicker("Od", selection: $startDate, displayedComponents: .date)
                DatePicker("Do", selection: $endDate, in: startDate..., displayedComponents: .date)
                TextField("Zpráva (volitelné)", text: $message)
            }
            
            Section {
                Button {
                    showConfirm = true
                } label: {
                    Label("Poslat žádost o výměnu", systemImage: "paperplane.fill")
                }
                .disabled(!canRequest)
            }
        }
        .navigationTitle(car.title)
        .alert("Odeslat žádost?", isPresented: $showConfirm) {
            Button("Zrušit", role: .cancel) {}
            Button("Odeslat", role: .none) {
                guard let myCarId else { return }
                appState.createSwapRequest(
                    offeredCarId: myCarId,
                    requestedCarId: car.id,
                    startDate: startDate,
                    endDate: endDate,
                    message: message.isEmpty ? nil : message
                )
            }
        } message: {
            Text("Příjemce uvidí detaily a může žádost přijmout nebo odmítnout.")
        }
    }
}
