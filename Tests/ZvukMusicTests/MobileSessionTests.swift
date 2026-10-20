import Foundation
import Testing

@testable import ZvukMusic

/// Pins `X-Session-UID` to its reference bytes, produced by raw DEFLATE at zlib level 6.
/// A mismatch here means the value we send has drifted from the format the server expects.
@Suite("MobileSession")
struct MobileSessionTests {

    private let instanceId = "11111111-2222-3333-4444-555555555555"
    private let timestamp = "1700000000"
    private let userAgent = "Client|1.0|Test Device"

    @Test func computesReferenceUID() {
        let uid = MobileSessionUID.compute(
            instanceId: instanceId, timestamp: timestamp, userAgent: userAgent
        )
        #expect(uid == "NPDwMLEBOTLtp3ARYrKzV8yikZ9tQNCEqPaD7BSvXxpvcP3mA4EnlCDLpLzfi9vju6R+")
    }

    /// Hex must be uppercase: the digest is consumed as text, so its case is part of the value.
    @Test func hexIsUppercase() {
        let hex = MobileSessionUID.sha256Hex(Data("zvuk".utf8))
        #expect(hex == hex.uppercased())
        #expect(hex.count == 64)
    }

    /// Raw DEFLATE carries no zlib header: a zlib stream would start with 0x78.
    @Test func deflateHasNoZlibWrapper() {
        let hex = MobileSessionUID.sha256Hex(Data((instanceId + timestamp + userAgent).utf8))
        let deflated = MobileSessionUID.rawDeflate(Data(hex.utf8))
        #expect(deflated.count == 51)
        #expect(deflated.prefix(4) == Data([0x05, 0xC1, 0xC1, 0x01]))
        #expect(deflated.first != 0x78)
    }

    /// The XOR stops at the shorter input instead of repeating the key.
    @Test func xorCoversPrefixOnly() {
        let data = Data([0xFF, 0xFF, 0xFF, 0xFF])
        let result = MobileSessionUID.xorPrefix(data, with: Data([0x0F, 0x0F]))
        #expect(result == Data([0xF0, 0xF0, 0xFF, 0xFF]))
    }

    /// A different timestamp must produce a different UID, otherwise the value is not covering it.
    @Test func uidDependsOnTimestamp() {
        let first = MobileSessionUID.compute(
            instanceId: instanceId, timestamp: timestamp, userAgent: userAgent
        )
        let second = MobileSessionUID.compute(
            instanceId: instanceId, timestamp: "1700000001", userAgent: userAgent
        )
        #expect(first != second)
    }

    /// Header values must stay ASCII, so a Cyrillic device name is escaped rather than sent raw.
    @Test func userAgentEscapesNonASCII() {
        let agent = MobileClientProfile.asciiSafe("Client|1.0|Яндекс Phone")
        #expect(agent == "Client|1.0|\\u042f\\u043d\\u0434\\u0435\\u043a\\u0441 Phone")
        #expect(agent.allSatisfy { $0.isASCII })
    }

    @Test func profileBuildsAllHeaders() {
        let profile = MobileClientProfile(instanceId: instanceId, userAgent: userAgent)
        let headers = profile.headers(timestamp: 1_700_000_000, referer: "https://zvuk.com/")
        #expect(headers["User-Agent"] == userAgent)
        #expect(headers["Referer"] == "https://zvuk.com/")
        #expect(headers["X-Timestamp"] == timestamp)
        #expect(headers["X-App-Instance"] == instanceId)
        #expect(headers["X-Session-UID"]?.isEmpty == false)
    }
}
