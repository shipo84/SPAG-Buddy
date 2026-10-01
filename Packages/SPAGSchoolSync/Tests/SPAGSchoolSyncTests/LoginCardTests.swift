import Foundation
import Testing
@testable import SPAGSchoolSync

@MainActor
struct LoginCardTests {
    @Test func readsTheLoginCardQRCode() throws {
        let details = try #require(JoinDetails(scannedText: " spagbuddy://join?class=ABC234&picture=fox&pin=4821\n"))
        #expect(details == JoinDetails(classCode: "ABC234", avatarKey: "fox", pin: "4821"))
    }

    @Test func ignoresOtherCodes() {
        #expect(JoinDetails(scannedText: "https://example.com/join?class=ABC234") == nil)
        #expect(JoinDetails(scannedText: "spagbuddy://settings") == nil)
        #expect(JoinDetails(scannedText: "") == nil)
    }

    @Test func privacyNoticeLinksToTheSchoolNotice() {
        #expect(SchoolPrivacyNotice.fullNoticeURL.absoluteString == "https://digitalclubhouse.org/spag-buddy/school/privacy/")
    }
}
