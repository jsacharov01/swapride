import SwiftUI

struct RequestsView: View {
    @EnvironmentObject var appState: AppState
    
    var incoming: [SwapRequest] { appState.requestsForCurrentUser() }
    var outgoing: [SwapRequest] { appState.requestsFromCurrentUser() }
    
    func label(for req: SwapRequest) -> String {
        guard let offered = appState.car(by: req.offeredCarId), let requested = appState.car(by: req.requestedCarId) else {
            return "Žádost"
        }
        return "\(offered.title) ↔︎ \(requested.title)"
    }
    
    var body: some View {
        List {
            Section("Příchozí") {
                if incoming.isEmpty { Text("Žádné příchozí žádosti") }
                ForEach(incoming) { req in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(label(for: req)).font(.headline)
                        Text("\(req.startDate.formatted(date: .abbreviated, time: .omitted)) – \(req.endDate.formatted(date: .abbreviated, time: .omitted))")
                            .foregroundStyle(.secondary)
                        if let message = req.message { Text("\u{201E}\(message)\u{201C}") }
                        HStack {
                            Button("Přijmout") {
                                appState.updateRequestStatus(id: req.id, status: .accepted)
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Odmítnout", role: .destructive) {
                                appState.updateRequestStatus(id: req.id, status: .declined)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            
            Section("Odeslané") {
                if outgoing.isEmpty { Text("Zatím jste nic neodeslali") }
                ForEach(outgoing) { req in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(label(for: req)).font(.headline)
                        Text(req.status.rawValue).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Žádosti")
    }
}
