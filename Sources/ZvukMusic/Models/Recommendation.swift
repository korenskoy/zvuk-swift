import Foundation

/// Content type for dynamic block recommendations.
public enum DynamicBlockContentType: String, Codable, Sendable {
    case music = "Music"
}

/// Item type filter for dynamic block recommendations.
public enum DynamicBlockItemType: String, Codable, Sendable {
    case artist = "Artist"
    case release = "Release"
    case playlist = "Playlist"
}

/// A recommendation item from a dynamic block.
///
/// Items are differentiated by `__typename` and can be an artist, release, or playlist.
public enum RecommendationItem: Codable, Hashable, Sendable {
    case artist(RecommendationArtist)
    case release(RecommendationRelease)
    case playlist(RecommendationPlaylist)
    case unknown

    private enum TypenameKey: String, CodingKey {
        case typename = "__typename"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: TypenameKey.self)
        let typename = (try? container.decode(String.self, forKey: .typename)) ?? ""

        let singleContainer = try decoder.singleValueContainer()
        switch typename {
        case "Artist":
            self = .artist(try singleContainer.decode(RecommendationArtist.self))
        case "Release":
            self = .release(try singleContainer.decode(RecommendationRelease.self))
        case "Playlist":
            self = .playlist(try singleContainer.decode(RecommendationPlaylist.self))
        default:
            self = .unknown
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .artist(let v): try container.encode(v)
        case .release(let v): try container.encode(v)
        case .playlist(let v): try container.encode(v)
        case .unknown: try container.encodeNil()
        }
    }
}

/// Recommended artist.
public struct RecommendationArtist: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let image: Image?
    public let mark: String?

    public init(
        id: String = "",
        title: String = "",
        image: Image? = nil,
        mark: String? = nil
    ) {
        self.id = id
        self.title = title
        self.image = image
        self.mark = mark
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
        mark = try? c.decodeIfPresent(String.self, forKey: .mark)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, image, mark
    }
}

/// Recommended release.
public struct RecommendationRelease: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let artists: [SimpleArtist]
    public let image: Image?
    public let mark: String?

    public init(
        id: String = "",
        title: String = "",
        artists: [SimpleArtist] = [],
        image: Image? = nil,
        mark: String? = nil
    ) {
        self.id = id
        self.title = title
        self.artists = artists
        self.image = image
        self.mark = mark
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        artists = try c.decodeArray([SimpleArtist].self, forKey: .artists)
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
        mark = try? c.decodeIfPresent(String.self, forKey: .mark)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, artists, image, mark
    }
}

/// Recommended playlist with preview tracks.
public struct RecommendationPlaylist: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let duration: Int
    public let trackCount: Int
    public let tracks: [Track]

    public init(
        id: String = "",
        title: String = "",
        duration: Int = 0,
        trackCount: Int = 0,
        tracks: [Track] = []
    ) {
        self.id = id
        self.title = title
        self.duration = duration
        self.trackCount = trackCount
        self.tracks = tracks
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        duration = try c.decodeDefault(Int.self, forKey: .duration, default: 0)
        trackCount = try c.decodeDefault(Int.self, forKey: .trackCount, default: 0)
        tracks = try c.decodeArray([Track].self, forKey: .tracks)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, duration, trackCount, tracks
    }
}

/// A page of recommendation items.
public struct DynamicBlockPage: Codable, Hashable, Sendable {
    public let page: Int
    public let items: [RecommendationItem]

    public init(page: Int = 1, items: [RecommendationItem] = []) {
        self.page = page
        self.items = items
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        page = try c.decodeDefault(Int.self, forKey: .page, default: 1)
        items = try c.decodeArray([RecommendationItem].self, forKey: .items)
    }

    private enum CodingKeys: String, CodingKey {
        case page, items
    }
}

/// Dynamic block with paginated recommendation items.
public struct DynamicBlock: Codable, Hashable, Sendable {
    public let totalPages: Int
    public let pages: [DynamicBlockPage]

    public init(totalPages: Int = 0, pages: [DynamicBlockPage] = []) {
        self.totalPages = totalPages
        self.pages = pages
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalPages = try c.decodeDefault(Int.self, forKey: .totalPages, default: 0)
        pages = try c.decodeArray([DynamicBlockPage].self, forKey: .pages)
    }

    private enum CodingKeys: String, CodingKey {
        case totalPages, pages
    }
}
