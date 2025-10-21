//
//  CarRepository.swift
//  swapride
//
//  Created by GitHub Copilot on 19.10.2025.
//

import Foundation
import FirebaseFirestore

protocol CarRepository {
    func listenAll(onChange: @escaping ([Car]) -> Void) -> ListenerRegistration
    func create(_ car: Car) async throws
    func delete(id: String) async throws
}

final class FirestoreCarRepository: CarRepository {
    private let collection: CollectionReference
    
    init(db: Firestore = FirestoreManager.shared.db) {
        self.collection = db.collection(FirestoreCollections.cars.rawValue)
    }
    
    func listenAll(onChange: @escaping ([Car]) -> Void) -> ListenerRegistration {
        collection.addSnapshotListener { snapshot, error in
            guard let docs = snapshot?.documents, error == nil else {
                onChange([])
                return
            }
            let cars: [Car] = docs.compactMap { doc in
                let data = doc.data()
                guard
                    let ownerId = data["ownerId"] as? String,
                    let title = data["title"] as? String,
                    let make = data["make"] as? String,
                    let model = data["model"] as? String,
                    let yearNum = (data["year"] as? NSNumber) ?? (data["year"] as? Int).map(NSNumber.init(value:)) ,
                    let seatsNum = (data["seats"] as? NSNumber) ?? (data["seats"] as? Int).map(NSNumber.init(value:)),
                    let transmissionRaw = data["transmission"] as? String,
                    let fuelRaw = data["fuel"] as? String,
                    let location = data["location"] as? String,
                    let allowsPets = data["allowsPets"] as? Bool,
                    let isFamilyFriendly = data["isFamilyFriendly"] as? Bool
                else { return nil }
                guard let transmission = Transmission(rawValue: transmissionRaw), let fuel = FuelType(rawValue: fuelRaw) else { return nil }
                let photoURL = data["photoURL"] as? String
                let description = data["description"] as? String
                let id = (data["id"] as? String) ?? doc.documentID
                return Car(
                    id: id,
                    ownerId: ownerId,
                    title: title,
                    make: make,
                    model: model,
                    year: yearNum.intValue,
                    seats: seatsNum.intValue,
                    transmission: transmission,
                    fuel: fuel,
                    location: location,
                    allowsPets: allowsPets,
                    isFamilyFriendly: isFamilyFriendly,
                    photoURL: photoURL,
                    description: description
                )
            }
            onChange(cars)
        }
    }
    
    func create(_ car: Car) async throws {
        var data: [String: Any] = [
            "id": car.id,
            "ownerId": car.ownerId,
            "title": car.title,
            "make": car.make,
            "model": car.model,
            "year": car.year,
            "seats": car.seats,
            "transmission": car.transmission.rawValue,
            "fuel": car.fuel.rawValue,
            "location": car.location,
            "allowsPets": car.allowsPets,
            "isFamilyFriendly": car.isFamilyFriendly
        ]
        if let photoURL = car.photoURL { data["photoURL"] = photoURL }
        if let description = car.description { data["description"] = description }
        try await collection.document(car.id).setData(data, merge: false)
    }

    func delete(id: String) async throws {
        try await collection.document(id).delete()
    }
}
// Firestore Codable support
