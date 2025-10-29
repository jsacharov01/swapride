//
//  AppState.swift
//  swapride
//
//  Created by GitHub Copilot on 19.10.2025.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class AppState: ObservableObject {
    // Simulated signed-in user (TODO: replace with Firebase Auth)
    @Published var currentUser: UserProfile = .init(id: "user_1", displayName: "Jurij", photoURL: nil, rating: 4.9) {
        didSet {
            // If the authenticated user changed, reattach swap listeners for the new user id
            if oldValue.id != currentUser.id {
                reattachSwapListenersForCurrentUser()
            }
        }
    }
    
    @Published private(set) var cars: [Car] = []
    @Published private(set) var swapRequests: [SwapRequest] = []
    @Published var lastSituation: Situation?
    // Loading states
    @Published private(set) var isLoadingCars: Bool = true
    @Published private(set) var isLoadingSwaps: Bool = true
    
    // Repositories
    private var carRepo: CarRepository
    private var swapRepo: SwapRepository
    private var carListener: ListenerRegistration?
    private var incomingListener: ListenerRegistration?
    private var outgoingListener: ListenerRegistration?
    private var incomingHasLoaded: Bool = false
    private var outgoingHasLoaded: Bool = false
    
    init(
        carRepo: CarRepository,
        swapRepo: SwapRepository
    ) {
        self.carRepo = carRepo
        self.swapRepo = swapRepo
        attachListeners()
    }

    convenience init() {
        self.init(
            carRepo: FirestoreCarRepository(),
            swapRepo: FirestoreSwapRepository()
        )
    }
    
    
    
    private func attachListeners() {
        // Cars
        carListener?.remove()
        carListener = carRepo.listenAll { [weak self] cars in
            Task { @MainActor in
                self?.cars = cars
                self?.isLoadingCars = false
            }
        }
        // Swaps (incoming/outgoing) for current user
        attachSwapListeners(for: currentUser.id)
    }

    private func reattachSwapListenersForCurrentUser() {
        // Reset loading state and listeners when user changes
        incomingListener?.remove()
        outgoingListener?.remove()
        incomingHasLoaded = false
        outgoingHasLoaded = false
        isLoadingSwaps = true
        // Clear existing requests to avoid mixing users' data
        swapRequests = []
        attachSwapListeners(for: currentUser.id)
    }

    private func attachSwapListeners(for userId: String) {
        // Swaps (incoming)
        incomingListener?.remove()
        incomingListener = swapRepo.listenIncoming(for: userId) { [weak self] reqs in
            Task { @MainActor in
                guard let self = self else { return }
                let outgoing = self.swapRequests.filter { $0.fromUserId == self.currentUser.id }
                self.swapRequests = self.mergeUniqueById(outgoing + reqs)
                self.incomingHasLoaded = true
                self.updateSwapsLoadingState()
            }
        }
        // Swaps (outgoing)
        outgoingListener?.remove()
        outgoingListener = swapRepo.listenOutgoing(for: userId) { [weak self] reqs in
            Task { @MainActor in
                guard let self = self else { return }
                let incoming = self.swapRequests.filter { $0.toUserId == self.currentUser.id }
                self.swapRequests = self.mergeUniqueById(reqs + incoming)
                self.outgoingHasLoaded = true
                self.updateSwapsLoadingState()
            }
        }
    }

    private func mergeUniqueById(_ items: [SwapRequest]) -> [SwapRequest] {
        var seen: Set<String> = []
        var result: [SwapRequest] = []
        for it in items {
            if !seen.contains(it.id) {
                seen.insert(it.id)
                result.append(it)
            }
        }
        return result
    }

    private func updateSwapsLoadingState() {
        isLoadingSwaps = !(incomingHasLoaded && outgoingHasLoaded)
    }
    
    // MARK: - Cars
    func addCar(_ car: Car) {
        Task {
            try? await carRepo.create(car)
        }
    }

    func deleteCar(id: String) {
        Task {
            try? await carRepo.delete(id: id)
        }
    }
    
    func carsExcludingCurrentUser() -> [Car] {
        cars.filter { $0.ownerId != currentUser.id }
    }
    
    func carsOfCurrentUser() -> [Car] {
        cars.filter { $0.ownerId == currentUser.id }
    }
    
    func car(by id: String) -> Car? {
        cars.first { $0.id == id }
    }
    
    // MARK: - Situations / Matching
    func matchingCars(for situation: Situation) -> [Car] {
        // Basic rules:
        // - seats >= peopleCount
        // - if childrenCount > 0 or tripType == .family => prefer isFamilyFriendly
        // - if hasAnimals => requires allowsPets
        // For MVP, simple filter + lightweight sort by best fit
        let base = carsExcludingCurrentUser().filter { car in
            guard car.seats >= situation.peopleCount else { return false }
            if situation.hasAnimals && !car.allowsPets { return false }
            if (situation.childrenCount > 0 || situation.tripType == .family) && !car.isFamilyFriendly { return false }
            return true
        }
        return base.sorted { a, b in
            score(car: a, situation: situation) > score(car: b, situation: situation)
        }
    }
    
    private func score(car: Car, situation: Situation) -> Int {
        var s = 0
        if car.seats >= situation.peopleCount { s += 2 }
        if situation.hasAnimals && car.allowsPets { s += 2 }
        if (situation.childrenCount > 0 || situation.tripType == .family) && car.isFamilyFriendly { s += 2 }
        // Heuristics by trip type
        switch situation.tripType {
        case .business:
            if car.make.lowercased().contains("bmw") || car.make.lowercased().contains("mercedes") || car.make.lowercased().contains("audi") { s += 1 }
        case .friends:
            if car.seats >= 5 { s += 1 }
        case .family:
            if car.seats >= 5 { s += 1 }
        }
        return s
    }
    
    // MARK: - Swaps
    func createSwapRequest(offeredCarId: String, requestedCarId: String, startDate: Date, endDate: Date, message: String?) {
        let toUserId = car(by: requestedCarId)?.ownerId ?? ""
        let request = SwapRequest(
            id: UUID().uuidString,
            fromUserId: currentUser.id,
            toUserId: toUserId,
            offeredCarId: offeredCarId,
            requestedCarId: requestedCarId,
            startDate: startDate,
            endDate: endDate,
            message: message,
            status: .pending
        )
        Task {
            try? await swapRepo.create(request)
        }
    }
    
    func requestsForCurrentUser() -> [SwapRequest] {
        swapRequests.filter { $0.toUserId == currentUser.id }
    }
    
    func requestsFromCurrentUser() -> [SwapRequest] {
        swapRequests.filter { $0.fromUserId == currentUser.id }
    }
    
    func updateRequestStatus(id: String, status: SwapStatus) {
        Task {
            try? await swapRepo.updateStatus(id: id, status: status)
        }
    }
}
