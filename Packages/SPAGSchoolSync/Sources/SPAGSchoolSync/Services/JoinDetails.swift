import Foundation

/// The details printed on a pupil's login card.
struct JoinDetails: Identifiable, Hashable {
    var classCode: String
    var avatarKey: String
    var pin: String

    var id: String { classCode + avatarKey }

    /// Reads `spagbuddy://join?class=ABC234&picture=fox&pin=4821` from a login card QR code.
    init?(url: URL) {
        guard url.scheme == "spagbuddy", url.host == "join",
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else { return nil }
        let value = { (name: String) in items.first { $0.name == name }?.value ?? "" }
        self.init(classCode: value("class"), avatarKey: value("picture"), pin: value("pin"))
    }

    init?(scannedText: String) {
        guard let url = URL(string: scannedText.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
        self.init(url: url)
    }

    init(classCode: String, avatarKey: String, pin: String) {
        self.classCode = classCode
        self.avatarKey = avatarKey
        self.pin = pin
    }
}
