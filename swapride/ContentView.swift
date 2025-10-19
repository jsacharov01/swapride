//
//  ContentView.swift
//  swapride
//
//  Created by Jurij Sacharov on 19.10.2025.
//

import SwiftUI
import FirebaseAnalytics

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            // Log a simple Analytics event to verify Firebase is working
            Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
        }
    }
}

#Preview {
    ContentView()
}
