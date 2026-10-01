import Foundation
import SwiftUI

/// Shown for "Join my class" in an app without class features.
struct ClassJoinUnavailableView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                BuddySays(text: "Joining a class is not set up on this iPad yet. Ask your teacher.", mood: .thinking)
            }
            .padding(24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .screenBackground()
        .navigationTitle("Join my class")
        .navigationBarTitleDisplayMode(.inline)
    }
}
