import SwiftUI

struct CarDetailView: View {
    @EnvironmentObject var appState: AppState
    let car: Car
    
    @State private var myCarId: String?
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var message: String = ""
    @State private var showConfirm: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var isPerformingAction: Bool = false
    @State private var showRequestSent: Bool = false
    @State private var showRequestFailed: Bool = false
    @State private var requestErrorMessage: String = "Žádost se nepodařilo odeslat. Zkuste to prosím znovu."
    @State private var showValidationAlert: Bool = false
    @State private var validationMessage: String = ""
    @State private var attemptedSubmit: Bool = false
    @State private var showPermissionTip: Bool = false
    // Date field sheets handled inside reusable components
    @Environment(\.dismiss) private var dismiss
    
    var myCars: [Car] {
        appState.carsOfCurrentUser()
    }
    
    private var isOwner: Bool { car.ownerId == appState.currentUser.id }
    private func startOfDay(_ date: Date) -> Date { Calendar.current.startOfDay(for: date) }
    private var today: Date { startOfDay(Date()) }
    private var minEndDate: Date { startOfDay(startDate) }
    private var hasInvalidDates: Bool { startOfDay(endDate) < startOfDay(startDate) }

    private func validationError() -> String? {
        if isOwner { return nil } // request UI hidden for owners anyway
        if myCars.isEmpty {
            return "Nejprve přidejte své auto, abyste mohli poslat žádost."
        }
        guard let myCarId, !myCarId.isEmpty else {
            return "Vyberte své auto pro výměnu."
        }
        if hasInvalidDates {
            return "Koncové datum musí být stejné nebo pozdější než počáteční."
        }
        return nil
    }
    
    var canRequest: Bool {
        if isOwner { return false }
        guard let myCarId else { return false }
    // Allow same-day swaps as valid (end >= start)
    return !myCarId.isEmpty && startOfDay(startDate) <= startOfDay(endDate)
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
            
            if !isOwner {
                Section("Nabídnout k výměně") {
                    if myCars.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nemáte přidané žádné auto.")
                                .foregroundStyle(.secondary)
                            NavigationLink("Přidat auto") {
                                CreateListingView()
                            }
                        }
                    } else {
                        Picker("Moje auto", selection: $myCarId) {
                            Text("Vyberte auto").tag(Optional<String>.none)
                            ForEach(myCars) { c in
                                Text(c.title).tag(Optional<String>(c.id))
                            }
                        }
                        if myCarId == nil || (myCarId ?? "").isEmpty {
                            Text("Vyberte své auto pro výměnu.")
                                .font(.footnote)
                                .foregroundStyle(attemptedSubmit ? .red : .secondary)
                        }
                        DateField(title: "Od", date: $startDate, minDate: today)
                        DateField(title: "Do", date: $endDate, minDate: minEndDate)
                        if attemptedSubmit && hasInvalidDates {
                            Text("Koncové datum musí být stejné nebo pozdější než počáteční.")
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                        TextField("Zpráva (volitelné)", text: $message)
                    }
                }
            }
            
            Section {
                if isOwner {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Smazat toto auto", systemImage: "trash")
                    }
                } else {
                    Button {
                        attemptedSubmit = true
                        if let error = validationError() {
                            validationMessage = error
                            showValidationAlert = true
                        } else {
                            showConfirm = true
                        }
                    } label: {
                        Label("Poslat žádost o výměnu", systemImage: "paperplane.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(canRequest ? .accentColor : .gray)
                    .opacity(isPerformingAction ? 0.6 : 1)
                    .disabled(isPerformingAction)

                    if showPermissionTip {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Tip", systemImage: "info.circle")
                                .font(.footnote.weight(.semibold))
                            Text("Nabízené auto musí patřit vašemu účtu a koncové datum nesmí být dřívější než počáteční. Stejný den je v pořádku.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .navigationTitle(car.title)
        .navigationBarTitleDisplayMode(.inline)
    // date selection handled via DateField sheets
        .alert("Odeslat žádost?", isPresented: $showConfirm) {
            Button("Zrušit", role: .cancel) {}
            Button("Odeslat", role: .none) {
                guard let myCarId else { return }
                isPerformingAction = true
                Task { @MainActor in
                    do {
                        try await appState.createSwapRequest(
                            offeredCarId: myCarId,
                            requestedCarId: car.id,
                            startDate: startDate,
                            endDate: endDate,
                            message: message.isEmpty ? nil : message,
                            toUserId: car.ownerId
                        )
                        showRequestSent = true
                    } catch {
                        // Připrav uživatelsky přívětivou zprávu
                        let nsErr = error as NSError
                        if nsErr.domain == "FIRFirestoreErrorDomain", nsErr.code == 7 {
                            requestErrorMessage = "Chybí oprávnění pro odeslání žádosti. Zkontrolujte prosím, že nabízíte vlastní auto a termíny jsou platné."
                            showPermissionTip = true
                        } else {
                            requestErrorMessage = "Žádost se nepodařilo odeslat. Zkuste to prosím znovu."
                            showPermissionTip = false
                        }
                        showRequestFailed = true
                    }
                    isPerformingAction = false
                }
            }
        } message: {
            Text("Příjemce uvidí detaily a může žádost přijmout nebo odmítnout.")
        }
        .alert("Smazat auto?", isPresented: $showDeleteConfirm) {
            Button("Zrušit", role: .cancel) {}
            Button("Smazat", role: .destructive) {
                isPerformingAction = true
                appState.deleteCar(id: car.id)
                isPerformingAction = false
                dismiss()
            }
        } message: {
            Text("Tuto akci nelze vrátit zpět.")
        }
        .alert("Nelze odeslat žádost", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(validationMessage)
        }
        .alert("Žádost odeslána", isPresented: $showRequestSent) {
            Button("OK", role: .cancel) {
                // Po potvrzení přesměruj na seznam žádostí a zavři detail auta
                appState.selectedTab = .requests
                dismiss()
            }
        } message: {
            Text("Vaše žádost byla odeslána adresátovi.")
        }
        .alert("Odeslání se nezdařilo", isPresented: $showRequestFailed) {
            Button("OK", role: .cancel) {
                // Zůstaň na obrazovce a pokračuj v editaci žádosti
            }
        } message: {
            Text(requestErrorMessage)
        }
        .onReceive(appState.$cars) { _ in
            // If exactly one car is available later, preselect it
            if myCarId == nil, myCars.count == 1 {
                myCarId = myCars.first?.id
            }
            // If previously selected car is no longer present, clear selection
            if let sel = myCarId, !myCars.contains(where: { $0.id == sel }) {
                myCarId = nil
            }
        }
        .onAppear {
            // Preselect user's only car to reduce friction
            if myCarId == nil, myCars.count == 1 {
                myCarId = myCars.first?.id
            }
            // Ensure endDate is not before startDate on first show
            if startOfDay(endDate) < startOfDay(startDate) {
                endDate = minEndDate
            }
        }
        .onChange(of: startDate) { _, newStart in
            // Keep endDate in a valid range when start changes; allow same-day
            if startOfDay(endDate) < startOfDay(newStart) {
                endDate = startOfDay(newStart)
            }
            showPermissionTip = false
        }
        .onChange(of: endDate) { _, _ in
            showPermissionTip = false
        }
        .onChange(of: myCarId) { _, _ in
            showPermissionTip = false
        }
    }
}
