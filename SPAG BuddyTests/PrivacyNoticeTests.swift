import Foundation
import Testing
@testable import SPAG_Buddy

@MainActor
struct PrivacyNoticeTests {
    @Test func everyEditionSaysWhatIsKeptAndHowToDeleteIt() {
        for edition in Edition.allCases {
            let titles = PrivacyNotice.sections(for: edition).map(\.title)
            #expect(titles.contains("What SPAG Buddy knows about you"))
            #expect(titles.contains("Where it goes"))
            #expect(titles.contains("Deleting it"))
            #expect(titles.last == "Worried about something?")
        }
    }

    /// Home is strictly on-device, so its notice must never suggest a school or teacher receives anything.
    @Test func homeEditionNeverMentionsSchoolOrTeachers() {
        let text = PrivacyNotice.spokenText(for: .home).lowercased()
        #expect(!text.contains("teacher"))
        #expect(!text.contains("school"))
        #expect(!text.contains("class"))
        #expect(text.contains("stay on this ipad"))
    }

    @Test func schoolEditionExplainsWhoCanSeeAnswers() {
        let text = PrivacyNotice.spokenText(for: .school)
        #expect(text.contains("Your teacher can see your answers"))
        #expect(text.contains("Other children cannot see"))
    }

    /// Short sentences keep the notice readable for younger pupils.
    @Test func sentencesAreShort() {
        for edition in Edition.allCases {
            for section in PrivacyNotice.sections(for: edition) {
                let sentences = section.body.split(whereSeparator: { ".!?".contains($0) })
                for sentence in sentences {
                    let words = sentence.split(separator: " ").count
                    #expect(words <= 25, "\"\(sentence)\" has \(words) words")
                }
            }
        }
    }
}
