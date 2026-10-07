import Foundation
import Testing

@testable import ZvukMusic

@Suite("Request")
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
}
