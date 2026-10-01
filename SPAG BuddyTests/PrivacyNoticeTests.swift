import Foundation
import Testing
@testable import SPAG_Buddy

@MainActor
struct PrivacyNoticeTests {
    @Test func saysWhatIsKeptAndHowToDeleteIt() {
        let titles = PrivacyNotice.sections.map(\.title)
        #expect(titles.contains("What SPAG Buddy knows about you"))
        #expect(titles.contains("Where it goes"))
        #expect(titles.contains("Deleting it"))
        #expect(titles.last == "Worried about something?")
    }

    /// Home is strictly on-device, so the notice must never suggest a school or teacher receives anything.
    @Test func neverMentionsSchoolOrTeachers() {
        let text = PrivacyNotice.spokenText.lowercased()
        #expect(!text.contains("teacher"))
        #expect(!text.contains("school"))
        #expect(!text.contains("class"))
        #expect(text.contains("stay on this ipad"))
    }

    /// Short sentences keep the notice readable for younger pupils.
    @Test func sentencesAreShort() {
        for section in PrivacyNotice.sections {
            let sentences = section.body.split(whereSeparator: { ".!?".contains($0) })
            for sentence in sentences {
                let words = sentence.split(separator: " ").count
                #expect(words <= 25, "\"\(sentence)\" has \(words) words")
            }
        }
    }
}
