import Foundation

/// Brief release information.
public struct SimpleRelease: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let date: String?
    public let type: ReleaseType?
    public let image: Image?
    public let explicit: Bool
    public let artists: [SimpleArtist]

    public init(
        id: String = "",
        title: String = "",
        date: String? = nil,
        type: ReleaseType? = nil,
        image: Image? = nil,
        explicit: Bool = false,
        artists: [SimpleArtist] = []
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.type = type
        self.image = image
        self.explicit = explicit
        self.artists = artists
    }

    /// Release year extracted from date string.
    public var year: Int? {
        guard let date, date.count >= 4 else { return nil }
        return Int(date.prefix(4))
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        date = try? c.decodeIfPresent(String.self, forKey: .date)
        type = try? c.decodeIfPresent(ReleaseType.self, forKey: .type)
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
        explicit = try c.decodeDefault(Bool.self, forKey: .explicit, default: false)
        artists = try c.decodeArray([SimpleArtist].self, forKey: .artists)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, date, type, image, explicit, artists
    }
}

/// Full release information.
public struct Release: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let searchTitle: String?
    public let date: String?
    public let type: ReleaseType?
    public let image: Image?
    public let explicit: Bool
    public let availability: Int
    public let artistTemplate: String?
    public let genres: [Genre]
    public let label: Label?
    public let artists: [SimpleArtist]
    public let tracks: [SimpleTrack]
    public let related: [SimpleRelease]
    public let collectionItemData: CollectionItem?

    public init(
        id: String = "",
        title: String = "",
        searchTitle: String? = nil,
        date: String? = nil,
        type: ReleaseType? = nil,
        image: Image? = nil,
        explicit: Bool = false,
        availability: Int = 0,
        artistTemplate: String? = nil,
        genres: [Genre] = [],
        label: Label? = nil,
        artists: [SimpleArtist] = [],
        tracks: [SimpleTrack] = [],
        related: [SimpleRelease] = [],
        collectionItemData: CollectionItem? = nil
    ) {
        self.id = id
        self.title = title
        self.searchTitle = searchTitle
        self.date = date
        self.type = type
        self.image = image
        self.explicit = explicit
        self.availability = availability
        self.artistTemplate = artistTemplate
        self.genres = genres
        self.label = label
        self.artists = artists
        self.tracks = tracks
        self.related = related
        self.collectionItemData = collectionItemData
    }

    /// Release year extracted from date string.
    public var year: Int? {
        guard let date, date.count >= 4 else { return nil }
        return Int(date.prefix(4))
    }

    /// Cover image URL.
    public func getCoverURL(size: Int = 300) -> String {
        image?.getURL(width: size, height: size) ?? ""
    }

    /// Whether the release is liked.
    public var isLiked: Bool {
        collectionItemData?.isLiked ?? false
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        searchTitle = try? c.decodeIfPresent(String.self, forKey: .searchTitle)
        date = try? c.decodeIfPresent(String.self, forKey: .date)
        type = try? c.decodeIfPresent(ReleaseType.self, forKey: .type)
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
        explicit = try c.decodeDefault(Bool.self, forKey: .explicit, default: false)
        availability = try c.decodeDefault(Int.self, forKey: .availability, default: 0)
        artistTemplate = try? c.decodeIfPresent(String.self, forKey: .artistTemplate)
        genres = try c.decodeArray([Genre].self, forKey: .genres)
        label = try? c.decodeIfPresent(Label.self, forKey: .label)
        artists = try c.decodeArray([SimpleArtist].self, forKey: .artists)
        tracks = try c.decodeArray([SimpleTrack].self, forKey: .tracks)
        related = try c.decodeArray([SimpleRelease].self, forKey: .related)
        collectionItemData = try? c.decodeIfPresent(CollectionItem.self, forKey: .collectionItemData)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, searchTitle, date, type, image, explicit, availability
        case artistTemplate, genres, label, artists, tracks, related, collectionItemData
    }
}
