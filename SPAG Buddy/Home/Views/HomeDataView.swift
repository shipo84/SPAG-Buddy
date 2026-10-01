import Foundation
import SwiftUI

/// "Where is my child's data?" in plain English for parents. It has no web links, so it can also be shown before the grown-ups gate.
struct HomeDataView: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(theme.correct)
                        .accessibilityHidden(true)
                    Text(HomeDataNotice.headline)
                        .pupilText(.title2, weight: .heavy)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .card()

                ForEach(HomeDataNotice.sections) { section in
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: section.symbol)
                            .font(.title2)
                            .foregroundStyle(theme.primary)
                            .frame(width: 36)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.title)
                                .pupilText(.headline, weight: .bold)
                                .accessibilityAddTraits(.isHeader)
                            Text(section.body)
                                .pupilText(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .card()
                }
            }
            .padding(24)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .screenBackground()
        .navigationTitle("Where is my child's data?")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        HomeDataView()
    }
}
