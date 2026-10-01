import Foundation
import SwiftUI

/// First screen when there are no pupils yet. Creates a profile that lives only on this iPad.
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

                    VStack(spacing: 12) {
                        Label(AppInfo.name, systemImage: "house.fill")
                            .pupilText(.caption, weight: .bold)
                            .foregroundStyle(theme.onPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(theme.primary, in: Capsule())
                        Text("Hello! I'm SPAG Buddy.")
                            .pupilText(.largeTitle, weight: .heavy)
                            .multilineTextAlignment(.center)
                        Text(AppInfo.tagline)
                            .pupilText(.title3)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(theme.secondaryText)
                    }

                    NavigationLink {
                        CreateProfileView()
                    } label: {
                        Label("Let's get started", systemImage: "sparkles")
                    }
                    .buttonStyle(.big)
                    .frame(maxWidth: 480)

                    Text("A grown-up can add more than one child. Each child gets their own stars and stickers.")
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
#Preview {
    WelcomeView()
        .environment(AppModel.preview)
        .modelContainer(.previewEmpty)
}
#endif
