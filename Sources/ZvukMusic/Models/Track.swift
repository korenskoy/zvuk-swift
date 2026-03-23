import Foundation

/// Brief track information.
public struct SimpleTrack: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let duration: Int
    public let explicit: Bool
    public let artists: [SimpleArtist]
    public let release: SimpleRelease?

    public init(
        id: String = "",
        title: String = "",
        duration: Int = 0,
        explicit: Bool = false,
        artists: [SimpleArtist] = [],
        release: SimpleRelease? = nil
    ) {
        self.id = id
        self.title = title
        self.duration = duration
        self.explicit = explicit
        self.artists = artists
        self.release = release
    }

    /// Duration in MM:SS format.
    public var durationString: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Artist names separated by commas.
    public var artistsString: String {
        artists.map(\.title).joined(separator: ", ")
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        duration = try c.decodeDefault(Int.self, forKey: .duration, default: 0)
        explicit = try c.decodeDefault(Bool.self, forKey: .explicit, default: false)
        artists = try c.decodeArray([SimpleArtist].self, forKey: .artists)
        release = try? c.decodeIfPresent(SimpleRelease.self, forKey: .release)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, duration, explicit, artists, release
    }
}

/// Full track information.
public struct Track: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let searchTitle: String?
    public let position: Int?
    public let duration: Int
    public let availability: Int
    public let artistTemplate: String?
    public let condition: String?
    public let explicit: Bool
    public let lyrics: AnyCodable?
    public let zchan: String?
    public let hasFlac: Bool
    public let artistNames: [String]
    public let credits: String?
    public let genres: [Genre]
    public let artists: [SimpleArtist]
    public let release: SimpleRelease?
    public let collectionItemData: CollectionItem?

    public init(
        id: String = "",
        title: String = "",
        searchTitle: String? = nil,
        position: Int? = nil,
        duration: Int = 0,
        availability: Int = 0,
        artistTemplate: String? = nil,
        condition: String? = nil,
        explicit: Bool = false,
        lyrics: AnyCodable? = nil,
        zchan: String? = nil,
        hasFlac: Bool = false,
        artistNames: [String] = [],
        credits: String? = nil,
        genres: [Genre] = [],
        artists: [SimpleArtist] = [],
        release: SimpleRelease? = nil,
        collectionItemData: CollectionItem? = nil
    ) {
        self.id = id
        self.title = title
        self.searchTitle = searchTitle
        self.position = position
        self.duration = duration
        self.availability = availability
        self.artistTemplate = artistTemplate
        self.condition = condition
        self.explicit = explicit
        self.lyrics = lyrics
        self.zchan = zchan
        self.hasFlac = hasFlac
        self.artistNames = artistNames
        self.credits = credits
        self.genres = genres
        self.artists = artists
        self.release = release
        self.collectionItemData = collectionItemData
    }

    /// Duration in MM:SS format.
    public var durationString: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Artist names separated by commas.
    public var artistsString: String {
        if !artists.isEmpty {
            return artists.map(\.title).joined(separator: ", ")
        }
        return artistNames.joined(separator: ", ")
    }

    /// Cover image URL.
    public func getCoverURL(size: Int = 300) -> String {
        release?.image?.getURL(width: size, height: size) ?? ""
    }

    /// Whether the track is liked.
    public var isLiked: Bool {
        collectionItemData?.isLiked ?? false
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        searchTitle = try? c.decodeIfPresent(String.self, forKey: .searchTitle)
        position = try? c.decodeIfPresent(Int.self, forKey: .position)
        duration = try c.decodeDefault(Int.self, forKey: .duration, default: 0)
        availability = try c.decodeDefault(Int.self, forKey: .availability, default: 0)
        artistTemplate = try? c.decodeIfPresent(String.self, forKey: .artistTemplate)
        condition = try? c.decodeIfPresent(String.self, forKey: .condition)
        explicit = try c.decodeDefault(Bool.self, forKey: .explicit, default: false)
        lyrics = try? c.decodeIfPresent(AnyCodable.self, forKey: .lyrics)
        zchan = try? c.decodeIfPresent(String.self, forKey: .zchan)
        hasFlac = try c.decodeDefault(Bool.self, forKey: .hasFlac, default: false)
        artistNames = try c.decodeArray([String].self, forKey: .artistNames)
        credits = try? c.decodeIfPresent(String.self, forKey: .credits)
        genres = try c.decodeArray([Genre].self, forKey: .genres)
        artists = try c.decodeArray([SimpleArtist].self, forKey: .artists)
        release = try? c.decodeIfPresent(SimpleRelease.self, forKey: .release)
        collectionItemData = try? c.decodeIfPresent(CollectionItem.self, forKey: .collectionItemData)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, searchTitle, position, duration, availability, artistTemplate
        case condition, explicit, lyrics, zchan, hasFlac, artistNames, credits
        case genres, artists, release, collectionItemData
    }
}
