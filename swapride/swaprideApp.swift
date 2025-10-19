//
//  swaprideApp.swift
//  swapride
//
//  Created by Jurij Sacharov on 19.10.2025.
//

import SwiftUI
import Firebase

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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
