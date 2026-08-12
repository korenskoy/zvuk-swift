import Foundation

/// One entry of the "recently played" feed.
///
/// The underlying GraphQL field returns a union of eleven unrelated types
/// (`Artist`, `Release`, `Playlist`, `Podcast`, `Book`, `RadioStation`,
/// `PersonalWave`, `EditorialWave`, `FavoriteTracks`, `RadioArtist`,
/// `RadioTrack`). Rather than eleven near-empty models, this type exposes the
/// fields every member shares.
///
/// Note that the feed contains *entities the user opened*, not individual
/// tracks — for a track-level history use ``ZvukClient/getListeningHistory(limit:)``.
public struct RecentItem: Codable, Hashable, Sendable {
    /// When the item was last listened to, ISO-8601.
    public let lastListeningDttm: String?
    /// Raw `__typename` as returned by the API.
    public let typename: String
    /// Which union member this entry is, `nil` for a type the API added since.
    public var type: RecentItemType? { RecentItemType(rawValue: typename) }
    /// Entity ID.
    public let id: String
    /// Display name: `title`, or `name` for radio stations, or the wave title.
    public let title: String?
    /// Cover art, when the entity has one.
    public let image: Image?

    public init(
        lastListeningDttm: String? = nil,
        typename: String = "",
        id: String = "",
        title: String? = nil,
        image: Image? = nil
    ) {
        self.lastListeningDttm = lastListeningDttm
        self.typename = typename
        self.id = id
        self.title = title
        self.image = image
    }

    public init(from decoder: Decoder) throws {
        let outer = try decoder.container(keyedBy: OuterKeys.self)
        lastListeningDttm = try? outer.decodeIfPresent(String.self, forKey: .lastListeningDttm)

        guard let content = try? outer.nestedContainer(keyedBy: ContentKeys.self, forKey: .mediaContent) else {
            typename = ""
            id = ""
            title = nil
            image = nil
            return
        }
        typename = try content.decodeDefault(String.self, forKey: .typename, default: "")
        id = try content.decodeDefault(String.self, forKey: .id, default: "")

        // EditorialWave прячет название и обложку внутри вложенного `wave`.
        let wave = try? content.nestedContainer(keyedBy: WaveKeys.self, forKey: .wave)
        let ownTitle = (try? content.decodeIfPresent(String.self, forKey: .title))
            ?? (try? content.decodeIfPresent(String.self, forKey: .name))
            ?? nil
        title = ownTitle ?? (try? wave?.decodeIfPresent(String.self, forKey: .title)) ?? nil
        image = (try? content.decodeIfPresent(Image.self, forKey: .image))
            ?? (try? wave?.decodeIfPresent(Image.self, forKey: .image))
            ?? nil
    }

    public func encode(to encoder: Encoder) throws {
        var outer = encoder.container(keyedBy: OuterKeys.self)
        try outer.encodeIfPresent(lastListeningDttm, forKey: .lastListeningDttm)
        var content = outer.nestedContainer(keyedBy: ContentKeys.self, forKey: .mediaContent)
        try content.encode(typename, forKey: .typename)
        try content.encode(id, forKey: .id)
        try content.encodeIfPresent(title, forKey: .title)
        try content.encodeIfPresent(image, forKey: .image)
    }

    private enum OuterKeys: String, CodingKey {
        case lastListeningDttm, mediaContent
    }

    private enum ContentKeys: String, CodingKey {
        case id, title, name, image, wave
        case typename = "__typename"
    }

    private enum WaveKeys: String, CodingKey {
        case title, image
    }
}

/// IDs of everything in the user's collection, grouped by content type.
///
/// A cheap alternative to fetching the collection itself when only membership
/// checks are needed.
public struct CollectionIDs: Codable, Hashable, Sendable {
    public let tracks: [String]
    public let releases: [String]
    public let artists: [String]
    public let playlists: [String]
    public let podcasts: [String]
    public let episodes: [String]
    public let books: [String]
    public let bookAuthors: [String]
    public let chapters: [String]
    public let profiles: [String]

    public init(
        tracks: [String] = [],
        releases: [String] = [],
        artists: [String] = [],
        playlists: [String] = [],
        podcasts: [String] = [],
        episodes: [String] = [],
        books: [String] = [],
        bookAuthors: [String] = [],
        chapters: [String] = [],
        profiles: [String] = []
    ) {
        self.tracks = tracks
        self.releases = releases
        self.artists = artists
        self.playlists = playlists
        self.podcasts = podcasts
        self.episodes = episodes
        self.books = books
        self.bookAuthors = bookAuthors
        self.chapters = chapters
        self.profiles = profiles
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func ids(_ key: CodingKeys) -> [String] {
            struct Item: Decodable { let id: String? }
            let items = (try? c.decodeArray([Item].self, forKey: key)) ?? []
            return items.compactMap(\.id)
        }
        tracks = ids(.tracks)
        releases = ids(.releases)
        artists = ids(.artists)
        playlists = ids(.playlists)
        podcasts = ids(.podcasts)
        episodes = ids(.episodes)
        books = ids(.books)
        bookAuthors = ids(.bookAuthors)
        chapters = ids(.chapters)
        profiles = ids(.profiles)
    }

    private enum CodingKeys: String, CodingKey {
        case tracks, releases, artists, playlists, podcasts, episodes, books, bookAuthors, chapters, profiles
    }
}
