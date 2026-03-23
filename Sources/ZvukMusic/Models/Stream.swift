import Foundation

/// Streaming URLs for different qualities.
public struct StreamUrls: Codable, Hashable, Sendable {
    /// 128kbps MP3 URL (always available).
    public let mid: String
    /// 320kbps MP3 URL (requires subscription).
    public let high: String?
    /// FLAC URL with DRM (requires subscription).
    public let flacdrm: String?

    public init(mid: String = "", high: String? = nil, flacdrm: String? = nil) {
        self.mid = mid
        self.high = high
        self.flacdrm = flacdrm
    }

    /// Get URL for the specified quality.
    public func getURL(quality: Quality = .high) throws -> String {
        switch quality {
        case .flac:
            guard let flacdrm else {
                throw ZvukError.subscriptionRequired(message: "FLAC quality requires subscription")
            }
            return flacdrm
        case .high:
            guard let high else {
                throw ZvukError.subscriptionRequired(
                    message: "High quality (320kbps) requires subscription")
            }
            return high
        case .mid:
            guard !mid.isEmpty else {
                throw ZvukError.qualityNotAvailable(message: "Mid quality URL not available")
            }
            return mid
        }
    }

    /// Get the best available quality and its URL.
    public var bestAvailable: (quality: Quality, url: String) {
        if let flacdrm { return (.flac, flacdrm) }
        if let high { return (.high, high) }
        return (.mid, mid)
    }
}

/// Stream information with expiration time.
public struct Stream: Codable, Hashable, Sendable {
    /// Expiration time (ISO 8601).
    public let expire: String
    /// Seconds until expiration.
    public let expireDelta: Int
    /// 128kbps MP3 URL.
    public let mid: String
    /// 320kbps MP3 URL.
    public let high: String?
    /// FLAC URL with DRM.
    public let flacdrm: String?

    public init(
        expire: String = "",
        expireDelta: Int = 0,
        mid: String = "",
        high: String? = nil,
        flacdrm: String? = nil
    ) {
        self.expire = expire
        self.expireDelta = expireDelta
        self.mid = mid
        self.high = high
        self.flacdrm = flacdrm
    }

    /// Whether the stream URL has expired.
    public var isExpired: Bool {
        guard !expire.isEmpty else { return true }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let expireDate = formatter.date(from: expire)
            ?? ISO8601DateFormatter().date(from: expire)
        else {
            return true
        }
        return Date() > expireDate
    }

    /// Get URL for the specified quality.
    public func getURL(quality: Quality = .high) throws -> String {
        let urls = StreamUrls(mid: mid, high: high, flacdrm: flacdrm)
        return try urls.getURL(quality: quality)
    }

    /// Get the best available quality and its URL.
    public var bestAvailable: (quality: Quality, url: String) {
        let urls = StreamUrls(mid: mid, high: high, flacdrm: flacdrm)
        return urls.bestAvailable
    }
}

/// Direct (non-DRM) stream URL from Tiny API.
public struct DirectStream: Codable, Hashable, Sendable {
    /// Direct stream URL.
    public let stream: String
    /// Requested quality.
    public let quality: String?

    public init(stream: String = "", quality: String? = nil) {
        self.stream = stream
        self.quality = quality
    }
}
