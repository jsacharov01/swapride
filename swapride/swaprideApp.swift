//
//  swaprideApp.swift
//  swapride
//
//  Created by Jurij Sacharov on 19.10.2025.
//

import SwiftUI
import Firebase
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    // Enable Firebase debug logging for development
    FirebaseConfiguration.shared.setLoggerLevel(.debug)
    FirebaseApp.configure()

    return true
  }
}

@main
struct swaprideApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @StateObject private var appState = AppState()
  @StateObject private var auth = AuthService()
    
    var body: some Scene {
        WindowGroup {
      Group {
        if auth.user == nil {
          AuthView()
        } else {
          MainTabView()
        }
      }
      .environmentObject(appState)
      .environmentObject(auth)
      .onChange(of: auth.user) { _, user in
        // map Firebase user to AppState user profile (minimal)
        if let u = user {
          appState.currentUser = UserProfile(id: u.uid, displayName: u.displayName ?? (u.email ?? "Uživatel"), photoURL: u.photoURL?.absoluteString, rating: 4.8)
        }
      }
      .onAppear {
        // Seed initial data into Firestore once per install/session for demo
        SeedService.shared.seedIfNeeded(appState: appState)
      }
        }
    }
}
