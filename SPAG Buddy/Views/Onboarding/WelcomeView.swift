import Foundation
import SwiftUI

/// First screen when there are no pupils yet. Home creates a profile on the iPad; School joins a class with a login card.
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

                    VStack(spacing: 12) {
                        EditionBadge(edition: app.edition)
                        Text("Hello! I'm SPAG Buddy.")
                            .pupilText(.largeTitle, weight: .heavy)
                            .multilineTextAlignment(.center)
                        Text(app.edition.tagline)
                            .pupilText(.title3)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(theme.secondaryText)
                    }

                    Group {
                        switch app.edition {
                        case .home:
                            NavigationLink {
                                CreateProfileView()
                            } label: {
                                Label("Let's get started", systemImage: "sparkles")
                            }
                            .buttonStyle(.big)
                        case .school:
                            NavigationLink {
                                JoinClassView()
                            } label: {
                                Label("Join my class", systemImage: "person.3.fill")
                            }
                            .buttonStyle(.big)
                        }
                    }
                    .frame(maxWidth: 480)

                    Text(app.edition.isSchool
                         ? "Your teacher will give you a card with your class code and PIN."
                         : "A grown-up can add more than one child. Each child gets their own stars and stickers.")
                        .pupilText(.footnote)
                        .foregroundStyle(theme.secondaryText)
                        .multilineTextAlignment(.center)

                    NavigationLink {
                        MyDataView()
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

#if DEBUG
#Preview("Home edition") {
    WelcomeView()
        .environment(AppModel.preview(edition: .home))
        .environment(\.appTheme, AppTheme(edition: .home))
        .modelContainer(.previewEmpty)
}

#Preview("School edition") {
    WelcomeView()
        .environment(AppModel.preview(edition: .school))
        .environment(\.appTheme, AppTheme(edition: .school))
        .modelContainer(.previewEmpty)
}
#endif
