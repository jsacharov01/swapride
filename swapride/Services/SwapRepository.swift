//
//  SwapRepository.swift
//  swapride
//
//  Created by GitHub Copilot on 19.10.2025.
//

import Foundation
import FirebaseFirestore

protocol SwapRepository {
    func listenIncoming(for userId: String, onChange: @escaping ([SwapRequest]) -> Void) -> ListenerRegistration
    func listenOutgoing(for userId: String, onChange: @escaping ([SwapRequest]) -> Void) -> ListenerRegistration
    func create(_ request: SwapRequest) async throws
    func updateStatus(id: String, status: SwapStatus) async throws
}

final class FirestoreSwapRepository: SwapRepository {
    private let collection: CollectionReference
    
    init(db: Firestore = FirestoreManager.shared.db) {
        self.collection = db.collection(FirestoreCollections.swapRequests.rawValue)
    }
    
    func listenIncoming(for userId: String, onChange: @escaping ([SwapRequest]) -> Void) -> ListenerRegistration {
        collection.whereField("toUserId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents, error == nil else { onChange([]); return }
                let reqs: [SwapRequest] = docs.compactMap { Self.map(doc: $0) }
                onChange(reqs)
            }
    }
    
    func listenOutgoing(for userId: String, onChange: @escaping ([SwapRequest]) -> Void) -> ListenerRegistration {
        collection.whereField("fromUserId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents, error == nil else { onChange([]); return }
                let reqs: [SwapRequest] = docs.compactMap { Self.map(doc: $0) }
                onChange(reqs)
            }
    }
    
    func create(_ request: SwapRequest) async throws {
        try await collection.document(request.id).setData(Self.data(from: request), merge: false)
    }
    
    func updateStatus(id: String, status: SwapStatus) async throws {
        try await collection.document(id).updateData(["status": status.rawValue])
    }
    
    private static func map(doc: DocumentSnapshot) -> SwapRequest? {
        let data = doc.data() ?? [:]
        guard
            let fromUserId = data["fromUserId"] as? String,
            let toUserId = data["toUserId"] as? String,
            let offeredCarId = data["offeredCarId"] as? String,
            let requestedCarId = data["requestedCarId"] as? String,
            let startTs = data["startDate"] as? Timestamp,
            let endTs = data["endDate"] as? Timestamp,
            let statusRaw = data["status"] as? String,
            let status = SwapStatus(rawValue: statusRaw)
        else { return nil }
        let message = data["message"] as? String
        let id = (data["id"] as? String) ?? doc.documentID
        return SwapRequest(
            id: id,
            fromUserId: fromUserId,
            toUserId: toUserId,
            offeredCarId: offeredCarId,
            requestedCarId: requestedCarId,
            startDate: startTs.dateValue(),
            endDate: endTs.dateValue(),
            message: message,
            status: status
        )
    }
    
    private static func data(from req: SwapRequest) -> [String: Any] {
        var data: [String: Any] = [
            "id": req.id,
            "fromUserId": req.fromUserId,
            "toUserId": req.toUserId,
            "offeredCarId": req.offeredCarId,
            "requestedCarId": req.requestedCarId,
            "startDate": Timestamp(date: req.startDate),
            "endDate": Timestamp(date: req.endDate),
            "status": req.status.rawValue
        ]
        if let message = req.message { data["message"] = message }
        return data
    }
}
