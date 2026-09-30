import Foundation
import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var app
    @Query(sort: \PupilProfile.createdAt) private var pupils: [PupilProfile]

    private var activePupil: PupilProfile? {
        pupils.first { $0.id == app.activePupilID }
    }

    var body: some View {
        @Bindable var app = app
        Group {
            if let pupil = activePupil {
                HomeView(pupil: pupil)
                    .id(pupil.id)
            } else if pupils.isEmpty {
                WelcomeView()
            } else {
                PupilPickerView(pupils: pupils)
            }
        }
        .environment(\.appTheme, AppTheme(pupil: activePupil))
        .sheet(item: $app.pendingJoin) { details in
            NavigationStack {
                JoinClassView(prefilled: details)
            }
        }
        .onAppear {
            if activePupil == nil, pupils.count == 1 {
                app.activePupilID = pupils[0].id
            }
        }
        .task { await app.start() }
    }
}
