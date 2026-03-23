import Foundation

/// Featured info with feature flags and user targeting.
public struct FeaturedInfo: Codable, Hashable, Sendable {
    /// Dismissed banner IDs.
    public let closedBanners: [String]
    /// Feature flags and targeting segments (e.g. "feature:hls2_enable_web", "country:SE").
    public let targets: [String]

    public init(closedBanners: [String] = [], targets: [String] = []) {
        self.closedBanners = closedBanners
        self.targets = targets
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        closedBanners = try c.decodeArray([String].self, forKey: .closedBanners)
        targets = try c.decodeArray([String].self, forKey: .targets)
    }

    private enum CodingKeys: String, CodingKey {
        case closedBanners = "closed_banners"
        case targets
    }

    // MARK: - Convenience

    /// All feature flags (entries starting with "feature:").
    public var features: [String] {
        targets.compactMap { $0.hasPrefix("feature:") ? String($0.dropFirst(8)) : nil }
    }

    /// Check if a specific feature flag is enabled.
    public func hasFeature(_ name: String) -> Bool {
        targets.contains("feature:\(name)")
    }

    /// User's country code (e.g. "SE", "RU").
    public var country: String? {
        targets.first { $0.hasPrefix("country:") }.map { String($0.dropFirst(8)) }
    }

    /// Device targets (e.g. "all", "web").
    public var devices: [String] {
        targets.compactMap { $0.hasPrefix("device:") ? String($0.dropFirst(7)) : nil }
    }
}
