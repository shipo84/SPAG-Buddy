import Foundation
import Testing
@testable import SPAG_Buddy

@MainActor
struct PrivacyNoticeTests {
    @Test func everyVersionSaysWhatIsKeptAndHowToDeleteIt() {
        for inClass in [nil, true, false] as [Bool?] {
            let titles = PrivacyNotice.sections(inClass: inClass).map(\.title)
            #expect(titles.contains("What SPAG Buddy knows about you"))
            #expect(titles.contains("Where it goes"))
            #expect(titles.contains("Deleting it"))
            #expect(titles.last == "Worried about something?")
        }
    }

    @Test func homeVersionNeverMentionsTeachers() {
        let text = PrivacyNotice.spokenText(inClass: false)
        #expect(!text.contains("teacher can see"))
        #expect(text.contains("stay on this iPad"))
    }

    @Test func classVersionExplainsWhoCanSeeAnswers() {
        let text = PrivacyNotice.spokenText(inClass: true)
        #expect(text.contains("Your teacher can see your answers"))
        #expect(text.contains("Other children cannot see"))
    }

    /// Short sentences keep the notice readable for younger pupils.
    @Test func sentencesAreShort() {
        for inClass in [nil, true, false] as [Bool?] {
            for section in PrivacyNotice.sections(inClass: inClass) {
                let sentences = section.body.split(whereSeparator: { ".!?".contains($0) })
                for sentence in sentences {
                    let words = sentence.split(separator: " ").count
                    #expect(words <= 25, "\"\(sentence)\" has \(words) words")
                }
            }
        }
    }
}
