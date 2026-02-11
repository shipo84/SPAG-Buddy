//
//  SPAG_BuddyApp.swift
//  SPAG Buddy
//
//  Created by Nathan Shipston on 22/04/2025.
//

import SwiftUI

@main
struct SPAG_BuddyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light) // Ensure consistent appearance
                .environment(\.dynamicTypeSize, .medium) // Ensure text doesn't get too large
        }
    }
}
