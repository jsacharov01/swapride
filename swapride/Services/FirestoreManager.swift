//
//  FirestoreManager.swift
//  swapride
//
//  Created by GitHub Copilot on 19.10.2025.
//

import Foundation
import Firebase
import FirebaseFirestore

enum FirestoreCollections: String {
    case cars
    case swapRequests
}

final class FirestoreManager {
    static let shared = FirestoreManager()
    let db: Firestore
    
    private init() {
        // Assumes FirebaseApp.configure() already called in AppDelegate
    let settings = FirestoreSettings()
    // Enable persistent local cache using the modern API
    settings.cacheSettings = PersistentCacheSettings()
        let db = Firestore.firestore()
        db.settings = settings
        self.db = db
    }
}
