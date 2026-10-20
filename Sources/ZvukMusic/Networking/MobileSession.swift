import Foundation
#if canImport(Compression)
import Compression
#endif
#if canImport(CryptoKit)
import CryptoKit
#endif

/// Alternative client identity: a mobile-shaped User-Agent plus the session headers that go
/// with it, including a computed `X-Session-UID`.
///
/// Whether the edge treats these requests differently is not proven, so this is opt-in: pass a
/// profile to `ZvukClient` to send them, leave it out to keep the browser headers used before.
///
/// `instanceId` identifies the installation and must stay the same across launches. Keeping it
/// is the caller's job: this package does not own user storage.
public struct MobileClientProfile: Sendable {
    /// Installation identifier, a lowercase UUID string.
    public let instanceId: String
    /// Client identification string. It must be ASCII — see `asciiSafe(_:)`.
    public let userAgent: String

    public init(instanceId: String, userAgent: String) {
        self.instanceId = instanceId
        self.userAgent = userAgent
    }

    /// Escapes non-ASCII characters as `\uXXXX`, because a header value must stay ASCII.
    /// A device name can hold any script, so build the User-Agent through this.
    public static func asciiSafe(_ text: String) -> String {
        text.unicodeScalars.map { scalar in
            if scalar == "\t" || (scalar.value >= 0x20 && scalar.value < 0x7F) {
                return String(scalar)
            }
            return String(format: "\\u%04x", scalar.value)
        }
        .joined()
    }

    /// Headers to add to a request, with `timestamp` in whole Unix seconds.
    func headers(timestamp: Int, referer: String) -> [String: String] {
        let stamp = String(timestamp)
        return [
            "User-Agent": userAgent,
            "Referer": referer,
            "X-Timestamp": stamp,
            "X-App-Instance": instanceId,
            "X-Session-UID": MobileSessionUID.compute(
                instanceId: instanceId, timestamp: stamp, userAgent: userAgent
            ),
        ]
    }
}

/// Computes `X-Session-UID`.
///
/// Join `instanceId + timestamp + userAgent`, take SHA-256, render it as uppercase hex,
/// raw-DEFLATE that hex text, XOR the leading bytes with the instance id, then Base64-encode
/// without line breaks.
///
/// There is no secret, token or request body in this value: it is a checksum of client
/// parameters, not a signature. How the server checks it is unknown.
enum MobileSessionUID {

    static func compute(instanceId: String, timestamp: String, userAgent: String) -> String {
        let joined = instanceId + timestamp + userAgent
        let hex = sha256Hex(Data(joined.utf8))
        let deflated = rawDeflate(Data(hex.utf8))
        return xorPrefix(deflated, with: Data(instanceId.utf8)).base64EncodedString()
    }

    /// Uppercase hex: the digest is consumed as text, so its case is part of the value.
    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02X", $0) }.joined()
    }

    /// Raw DEFLATE, without a zlib or gzip wrapper.
    ///
    /// Apple's `COMPRESSION_ZLIB` is raw DEFLATE and its output matches zlib at level 6 byte
    /// for byte. `MobileSessionTests` pins that against reference bytes.
    static func rawDeflate(_ data: Data) -> Data {
        guard !data.isEmpty else { return Data() }
        // ponytail: один буфер с запасом. Вход — 64 байта hex, выход всегда меньше.
        // Для большого входа понадобился бы потоковый compression_stream.
        var destination = [UInt8](repeating: 0, count: data.count * 2 + 64)
        let written = data.withUnsafeBytes { source -> Int in
            guard let base = source.bindMemory(to: UInt8.self).baseAddress else { return 0 }
            return compression_encode_buffer(
                &destination, destination.count, base, data.count, nil, COMPRESSION_ZLIB
            )
        }
        return Data(destination[0..<written])
    }

    /// XOR of the leading bytes only; the rest is kept as is. The key is not repeated, so the
    /// tail beyond the key length passes through unchanged.
    static func xorPrefix(_ data: Data, with key: Data) -> Data {
        var result = data
        for index in 0..<min(data.count, key.count) {
            result[index] = data[index] ^ key[index]
        }
        return result
    }
}
