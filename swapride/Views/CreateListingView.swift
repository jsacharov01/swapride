import SwiftUI

struct CreateListingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = CreateListingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section("Základní informace") {
                TextField("Název nabídky (např. Rodinné kombi)", text: $vm.title)
                TextField("Značka", text: $vm.make)
                TextField("Model", text: $vm.model)
                Stepper(value: $vm.year, in: 1980...Calendar.current.component(.year, from: Date())) {
                    Text("Rok výroby: \(vm.year)")
                }
                Stepper(value: $vm.seats, in: 2...9) {
                    Text("Počet míst: \(vm.seats)")
                }
                Picker("Převodovka", selection: $vm.transmission) {
                    ForEach(Transmission.allCases) { t in Text(t.rawValue).tag(t) }
                }
                Picker("Palivo", selection: $vm.fuel) {
                    ForEach(FuelType.allCases) { f in Text(f.rawValue).tag(f) }
                }
                TextField("Lokalita (město)", text: $vm.location)
            }
            
            Section("Popis") {
                TextField("Krátký popis (volitelné)", text: $vm.description, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }
            
            Section("Preferenční parametry") {
                Toggle("Povolena zvířata", isOn: $vm.allowsPets)
                Toggle("Vhodné pro rodiny (dětské sedačky, kufr, atd.)", isOn: $vm.isFamilyFriendly)
            }
            
            Section {
                Button {
                    if let car = vm.buildCar(ownerId: appState.currentUser.id) {
                        appState.addCar(car)
                        dismiss()
                    }
                } label: {
                    Label("Uložit nabídku", systemImage: "checkmark.circle.fill")
                }
                .disabled(vm.buildCar(ownerId: appState.currentUser.id) == nil)
            }
        }
        .navigationTitle("Přidat auto")
    }
}
