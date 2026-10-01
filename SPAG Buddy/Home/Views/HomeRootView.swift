import Foundation
import SwiftData
import SwiftUI

/// Entry point for SPAG Buddy Home: parent set-up, then "Who is practising?", then the shared practice screens.
struct HomeRootView: View {
    @Environment(AppModel.self) private var app
    @Query(sort: \PupilProfile.createdAt) private var children: [PupilProfile]
    @AppStorage("homeSetupComplete") private var setupComplete = false
    @State private var showingGrownUps = false

    private var activeChild: PupilProfile? {
        children.first { $0.id == app.activePupilID }
    }

    var body: some View {
        Group {
            if children.isEmpty || !setupComplete {
                HomeSetupView(onFinish: finishSetup)
            } else if let child = activeChild {
                HomeView(pupil: child)
                    .id(child.id)
            } else {
                HomePickerView(children: children)
            }
        }
        .environment(\.appTheme, AppTheme(pupil: activeChild))
        .environment(\.openGrownUps, OpenGrownUpsAction { showingGrownUps = true })
        // Presented from the root so it stays open when the active child is removed.
        .sheet(isPresented: $showingGrownUps) {
            GrownUpGateView {
                GrownUpsView()
            }
            .environment(\.appTheme, AppTheme())
        }
        .onAppear(perform: selectOnlyChild)
        .onChange(of: children.isEmpty) { _, isEmpty in
            if isEmpty { setupComplete = false }
        }
    }

    private func finishSetup() {
        setupComplete = true
        selectOnlyChild()
    }

    private func selectOnlyChild() {
        if setupComplete, activeChild == nil, children.count == 1 {
            app.activePupilID = children[0].id
        }
    }
}

/// Opens the gated grown-ups area. Only SPAG Buddy Home provides it.
struct OpenGrownUpsAction {
    var action: () -> Void

    func callAsFunction() { action() }
}

private struct OpenGrownUpsKey: EnvironmentKey {
    static let defaultValue: OpenGrownUpsAction? = nil
}

extension EnvironmentValues {
    var openGrownUps: OpenGrownUpsAction? {
        get { self[OpenGrownUpsKey.self] }
        set { self[OpenGrownUpsKey.self] = newValue }
    }
}
