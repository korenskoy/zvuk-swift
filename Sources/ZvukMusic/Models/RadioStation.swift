import Foundation

/// Logo of a radio station in two formats.
public struct RadioLogo: Codable, Hashable, Sendable {
    /// Vector version URL.
    public let svg: String?
    /// Raster version URL.
    public let png: String?

    public init(svg: String? = nil, png: String? = nil) {
        self.svg = svg
        self.png = png
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        svg = try? c.decodeIfPresent(String.self, forKey: .svg)
        png = try? c.decodeIfPresent(String.self, forKey: .png)
    }

    private enum CodingKeys: String, CodingKey {
        case svg, png
    }
}

/// Internet radio station.
///
/// Radio stations are a separate content type: they are not backed by a track
/// list but by a continuous stream described by ``metaDataUrl``.
public struct RadioStation: Codable, Hashable, Identifiable, Sendable {
    /// Station ID.
    public let id: String
    /// Display name, e.g. "Европа Плюс - Россия".
    public let name: String
    /// Colored logo.
    public let logoColored: RadioLogo?
    /// Monochrome logo for light backgrounds.
    public let logoBlack: RadioLogo?
    /// Monochrome logo for dark backgrounds.
    public let logoWhite: RadioLogo?
    /// URL serving currently-playing metadata for the stream.
    public let metaDataUrl: String?
    /// HLS playlist URLs for the stream, in server order.
    ///
    /// Every station observed carries exactly one; ``streamURL`` takes the first.
    public let source: [String]

    public init(
        id: String = "",
        name: String = "",
        logoColored: RadioLogo? = nil,
        logoBlack: RadioLogo? = nil,
        logoWhite: RadioLogo? = nil,
        metaDataUrl: String? = nil,
        source: [String] = []
    ) {
        self.id = id
        self.name = name
        self.logoColored = logoColored
        self.logoBlack = logoBlack
        self.logoWhite = logoWhite
        self.metaDataUrl = metaDataUrl
        self.source = source
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        name = try c.decodeDefault(String.self, forKey: .name, default: "")
        logoColored = try? c.decodeIfPresent(RadioLogo.self, forKey: .logoColored)
        logoBlack = try? c.decodeIfPresent(RadioLogo.self, forKey: .logoBlack)
        logoWhite = try? c.decodeIfPresent(RadioLogo.self, forKey: .logoWhite)
        metaDataUrl = try? c.decodeIfPresent(String.self, forKey: .metaDataUrl)
        source = try c.decodeArray([String].self, forKey: .source)
    }

    /// The station's stream, ready to hand to a player.
    public var streamURL: URL? {
        source.first.flatMap(URL.init(string:))
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, metaDataUrl, source
        case logoColored = "radioLogoColored"
        case logoBlack = "radioLogoBlack"
        case logoWhite = "radioLogoWhite"
    }
}
