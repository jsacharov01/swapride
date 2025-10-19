//
//  Car.swift
//  swapride
//
//  Created by GitHub Copilot on 19.10.2025.
//

import Foundation

enum Transmission: String, CaseIterable, Codable, Identifiable {
    case manual = "Manuální"
    case automatic = "Automatická"
    
    var id: String { rawValue }
}

enum FuelType: String, CaseIterable, Codable, Identifiable {
    case petrol = "Benzín"
    case diesel = "Nafta"
    case electric = "Elektro"
    case hybrid = "Hybrid"
    
    var id: String { rawValue }
}

struct Car: Identifiable, Codable, Equatable {
    let id: String
    var ownerId: String
    var title: String
    var make: String
    var model: String
    var year: Int
    var seats: Int
    var transmission: Transmission
    var fuel: FuelType
    var location: String
    var allowsPets: Bool
    var isFamilyFriendly: Bool
    var photoURL: String?
    var description: String?
}
