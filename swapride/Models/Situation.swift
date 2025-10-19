//
//  Situation.swift
//  swapride
//
//  Created by GitHub Copilot on 19.10.2025.
//

import Foundation

enum TripType: String, CaseIterable, Identifiable, Codable {
    case business = "Business"
    case family = "Rodina"
    case friends = "Kamarádi"
    
    var id: String { rawValue }
}

struct Situation: Identifiable, Codable, Equatable {
    let id: String
    var peopleCount: Int
    var childrenCount: Int
    var hasAnimals: Bool
    var destination: String
    var startDate: Date
    var endDate: Date
    var tripType: TripType
}
