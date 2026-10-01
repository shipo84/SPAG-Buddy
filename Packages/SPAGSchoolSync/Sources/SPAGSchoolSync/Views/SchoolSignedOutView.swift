import Foundation
import SPAGCore
import SwiftUI

/// What the School app shows when nobody is signed in. There is no home-practice profile:
/// the privacy notice comes first on a new iPad, then "Join your class".
struct SchoolSignedOutView: View {
    @Bindable var classServices: SchoolClassServices

    var body: some View {
        NavigationStack {
            if classServices.hasSeenPrivacyNotice {
                JoinClassView()
            } else {
                SchoolPrivacyNoticeView {
                    classServices.hasSeenPrivacyNotice = true
                }
            }
        }
    }
}
