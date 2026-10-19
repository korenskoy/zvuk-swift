import Foundation
import Testing

@testable import ZvukMusic

/// Serves a canned 418 challenge until `blockedResponses` is exhausted, then JSON.
final class BotBlockStub: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var blockedResponses = 0
    nonisolated(unsafe) static var apiRequests: [Date] = []

    static func reset(blocked: Int) {
        blockedResponses = blocked
        apiRequests = []
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        let url = request.url!
        var status = 200
        var body = Data(#"{"result": "ok"}"#.utf8)

        // The warm-up hits the site root; only API paths count as blocked attempts.
        if url.path.count > 1 {
            Self.apiRequests.append(Date())
            if Self.blockedResponses > 0 {
                Self.blockedResponses -= 1
                status = 418
                body = Data("<!doctype html><html><body>Ошибка доступа</body></html>".utf8)
            }
        }

        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }
}

@Suite("Request", .serialized)
struct RequestTests {

    private let html = Data("<!doctype html><html lang=ru><head><title>Error</title></head><body>blocked</body></html>".utf8)
    private let json = Data(#"{"message": "boom"}"#.utf8)

    @Test func botBlockDetection() {
        #expect(Request.isBotBlock(statusCode: 418, data: html))
        #expect(Request.isBotBlock(statusCode: 418, data: json))
        #expect(Request.isBotBlock(statusCode: 503, data: html))
        #expect(!Request.isBotBlock(statusCode: 404, data: html))
        #expect(!Request.isBotBlock(statusCode: 500, data: json))
        #expect(!Request.isBotBlock(statusCode: 401, data: Data()))
    }

    /// A blocked request is replayed only after a pause — replaying at once hits the same
    /// rate limit, which is what the block turned out to be.
    @Test func waitsBeforeReplayingBlockedRequest() async throws {
        Request.botRetryDelays = [0.2, 0.2, 0.2]
        defer { Request.botRetryDelays = [2, 10, 30] }
        BotBlockStub.reset(blocked: 1)
        let request = Request(protocolClasses: [BotBlockStub.self])

        let result = try await request.get(url: "https://zvuk.com/api/tiny/grid", params: ["name": "main"])

        #expect(result?["result"] as? String == "ok")
        #expect(BotBlockStub.apiRequests.count == 2)
        let gap = BotBlockStub.apiRequests[1].timeIntervalSince(BotBlockStub.apiRequests[0])
        #expect(gap >= Request.botRetryDelays[0])
    }

    /// A caller with a faster alternative opts out and fails immediately.
    @Test func skipsRetryWhenCallerOptsOut() async {
        BotBlockStub.reset(blocked: 99)
        let request = Request(protocolClasses: [BotBlockStub.self])

        await #expect(throws: ZvukError.self) {
            _ = try await request.get(url: "https://zvuk.com/api/tiny/track/stream", retryOnBlock: false)
        }
        #expect(BotBlockStub.apiRequests.count == 1)
    }

    /// Retries are finite: an endpoint that stays blocked still throws.
    @Test func givesUpWhenBlockPersists() async {
        Request.botRetryDelays = [0.05, 0.05, 0.05]
        defer { Request.botRetryDelays = [2, 10, 30] }
        BotBlockStub.reset(blocked: 99)
        let request = Request(protocolClasses: [BotBlockStub.self])

        await #expect(throws: ZvukError.self) {
            _ = try await request.get(url: "https://zvuk.com/api/featured/info")
        }
        #expect(BotBlockStub.apiRequests.count == Request.botRetryDelays.count + 1)
    }
}
