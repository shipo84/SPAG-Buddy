import Foundation
import SwiftUI

struct WelcomeView: View {
    var showsCancel = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    BuddyView(mood: .cheering, size: 140)
                        .padding(.top, 32)

                    VStack(spacing: 8) {
                        Text("Hello! I'm SPAG Buddy.")
                            .pupilText(.largeTitle, weight: .heavy)
                            .multilineTextAlignment(.center)
                        Text("I can help you practise spelling, punctuation and grammar.")
                            .pupilText(.title3)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(theme.secondaryText)
                    }

                    VStack(spacing: 16) {
                        NavigationLink {
                            JoinClassView()
                        } label: {
                            Label("Join my class", systemImage: "person.3.fill")
                        }
                        .buttonStyle(.big)

                        NavigationLink {
                            CreateProfileView()
                        } label: {
                            Label("Practise at home", systemImage: "house.fill")
                        }
                        .buttonStyle(.big(theme.correct))
                    }
                    .frame(maxWidth: 480)

                    Text("Your teacher will give you a card with your class code and PIN.")
                        .pupilText(.footnote)
                        .foregroundStyle(theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
            }
            .screenBackground()
            .toolbar {
                if showsCancel {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environment(AppModel.preview)
}
