//
//  CreateListingViewModel.swift
//  swapride
//
//  Created by GitHub Copilot on 19.10.2025.
//

import Foundation
import Combine

@MainActor
final class CreateListingViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var make: String = ""
    @Published var model: String = ""
    @Published var year: Int = Calendar.current.component(.year, from: Date())
    @Published var seats: Int = 5
    @Published var transmission: Transmission = .manual
    @Published var fuel: FuelType = .petrol
    @Published var location: String = ""
    @Published var description: String = ""
    @Published var allowsPets: Bool = false
    @Published var isFamilyFriendly: Bool = true
    
    func buildCar(ownerId: String) -> Car? {
        guard !title.isEmpty, !make.isEmpty, !model.isEmpty, !location.isEmpty else { return nil }
        return Car(
            id: UUID().uuidString,
            ownerId: ownerId,
            title: title,
            make: make,
            model: model,
            year: year,
            seats: seats,
            transmission: transmission,
            fuel: fuel,
            location: location,
            allowsPets: allowsPets,
            isFamilyFriendly: isFamilyFriendly,
            photoURL: nil,
            description: description.isEmpty ? nil : description
        )
    }
}
