import Foundation
import SPAGCore

/// The pupil privacy notice for the School app, in child-friendly words, with a link to the full notice for grown-ups.
enum SchoolPrivacyNotice {
    static let fullNoticeURL = URL(string: "https://digitalclubhouse.org/spag-buddy/school/privacy/")!
    static var sections: [PrivacyNotice.Section] { PrivacyNotice.sections(inClass: true) }
    static var spokenText: String { PrivacyNotice.spokenText(inClass: true) }
}
