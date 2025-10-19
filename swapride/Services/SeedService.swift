//
//  SeedService.swift
//  swapride
//
//  Created by GitHub Copilot on 19.10.2025.
//

import Foundation

final class SeedService {
    static let shared = SeedService()
    private let key = "didSeedFirestore"
    private init() {}
    
    func seedIfNeeded(appState: AppState) {
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        // Vytvoř pár záznamů, pokud v kolekci nejsou (spolehneme se na listeners, že nasypou data do appState.cars)
        // Alespoň přidejme jedno auto pro currentUser, pokud nemá žádné auto v cloudu
        let myCars = appState.cars.filter { $0.ownerId == appState.currentUser.id }
        if myCars.isEmpty {
            let car = Car(
                id: UUID().uuidString,
                ownerId: appState.currentUser.id,
                title: "Moje kombi",
                make: "Škoda",
                model: "Octavia",
                year: 2020,
                seats: 5,
                transmission: .automatic,
                fuel: .petrol,
                location: "Praha",
                allowsPets: true,
                isFamilyFriendly: true,
                photoURL: nil,
                description: "Základní seed auto"
            )
            appState.addCar(car)
        }
        UserDefaults.standard.set(true, forKey: key)
    }
}
