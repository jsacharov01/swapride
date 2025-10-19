//
//  SwapModels.swift
//  swapride
//
//  Created by GitHub Copilot on 19.10.2025.
//

import Foundation

enum SwapStatus: String, Codable, CaseIterable, Identifiable {
    case pending = "Čeká se"
    case accepted = "Přijato"
    case declined = "Odmítnuto"
    case completed = "Dokončeno"
    
    var id: String { rawValue }
}

struct SwapRequest: Identifiable, Codable, Equatable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let offeredCarId: String
    let requestedCarId: String
    var startDate: Date
    var endDate: Date
    var message: String?
    var status: SwapStatus
}

struct UserProfile: Identifiable, Codable, Equatable {
    let id: String
    var displayName: String
    var photoURL: String?
    var rating: Double?
}
