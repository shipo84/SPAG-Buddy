import Foundation
import SwiftUI

struct WelcomeView: View {
    var showsCancel = false
    @Environment(AppModel.self) private var app
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
                            if let classServices = app.classServices {
                                classServices.makeJoinClassView()
                            } else {
                                ClassJoinUnavailableView()
                            }
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

                    NavigationLink {
                        MyDataView(inClass: nil)
                    } label: {
                        Label("What happens to my answers?", systemImage: "lock.shield.fill")
                            .pupilText(.callout, weight: .semibold)
                    }
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
