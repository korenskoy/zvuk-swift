import Foundation

/// Cursor-based pagination info.
public struct CursorPage: Codable, Hashable, Sendable {
    public let endCursor: String?
    public let hasNextPage: Bool

    public init(endCursor: String? = nil, hasNextPage: Bool = false) {
        self.endCursor = endCursor
        self.hasNextPage = hasNextPage
    }
}

/// Generic paginated result with cursor-based pagination.
public struct PaginatedResult<T: Codable & Hashable & Sendable>: Codable, Hashable, Sendable {
    public let items: [T]
    public let page: CursorPage

    public init(items: [T] = [], page: CursorPage = CursorPage()) {
        self.items = items
        self.page = page
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        items = try c.decodeArray([T].self, forKey: .items)
        page = (try? c.decodeIfPresent(CursorPage.self, forKey: .page)) ?? CursorPage()
    }

    private enum CodingKeys: String, CodingKey {
        case items, page
    }
}

/// Collection playlist (from paginated collection).
public struct CollectionPlaylist: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let description: String?
    public let image: Image?
    public let coverV1: Image?
    public let profileId: String?
    public let trackCount: Int
    public let tracks: [CollectionPlaylistTrack]

    public init(
        id: String = "",
        title: String = "",
        description: String? = nil,
        image: Image? = nil,
        coverV1: Image? = nil,
        profileId: String? = nil,
        trackCount: Int = 0,
        tracks: [CollectionPlaylistTrack] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.image = image
        self.coverV1 = coverV1
        self.profileId = profileId
        self.trackCount = trackCount
        self.tracks = tracks
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        description = try? c.decodeIfPresent(String.self, forKey: .description)
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
        coverV1 = try? c.decodeIfPresent(Image.self, forKey: .coverV1)
        trackCount = try c.decodeDefault(Int.self, forKey: .trackCount, default: 0)
        tracks = try c.decodeArray([CollectionPlaylistTrack].self, forKey: .tracks)

        // profile is nested { id }
        if let profile = try? c.decodeIfPresent([String: String].self, forKey: .profileId) {
            profileId = profile["id"]
        } else {
            profileId = nil
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, description, image, coverV1, trackCount, tracks
        case profileId = "profile"
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(image, forKey: .image)
        try c.encodeIfPresent(coverV1, forKey: .coverV1)
        try c.encode(trackCount, forKey: .trackCount)
        try c.encode(tracks, forKey: .tracks)
        if let profileId {
            try c.encode(["id": profileId], forKey: .profileId)
        }
    }
}

/// Minimal track info inside a collection playlist.
public struct CollectionPlaylistTrack: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let release: SimpleRelease?

    public init(id: String = "", release: SimpleRelease? = nil) {
        self.id = id
        self.release = release
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        release = try? c.decodeIfPresent(SimpleRelease.self, forKey: .release)
    }

    private enum CodingKeys: String, CodingKey {
        case id, release
    }
}

/// Collection release (from paginated collection).
public struct CollectionRelease: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let type: ReleaseType?
    public let mark: String?
    public let image: Image?
    public let artists: [SimpleArtist]
    public let explicit: Bool

    public init(
        id: String = "",
        title: String = "",
        type: ReleaseType? = nil,
        mark: String? = nil,
        image: Image? = nil,
        artists: [SimpleArtist] = [],
        explicit: Bool = false
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.mark = mark
        self.image = image
        self.artists = artists
        self.explicit = explicit
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        type = try? c.decodeIfPresent(ReleaseType.self, forKey: .type)
        mark = try? c.decodeIfPresent(String.self, forKey: .mark)
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
        artists = try c.decodeArray([SimpleArtist].self, forKey: .artists)
        explicit = try c.decodeDefault(Bool.self, forKey: .explicit, default: false)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, type, mark, image, artists, explicit
    }
}

/// Collection artist (from paginated collection).
public struct CollectionArtist: Codable, Hashable, Identifiable, Sendable {
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

/// Collection podcast (from paginated collection).
public struct CollectionPodcast: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let updatedDate: String?
    public let explicit: Bool
    public let mark: String?
    public let image: Image?
    public let authors: [PodcastAuthor]
    public let episodes: [CollectionPodcastEpisode]

    public init(
        id: String = "",
        title: String = "",
        updatedDate: String? = nil,
        explicit: Bool = false,
        mark: String? = nil,
        image: Image? = nil,
        authors: [PodcastAuthor] = [],
        episodes: [CollectionPodcastEpisode] = []
    ) {
        self.id = id
        self.title = title
        self.updatedDate = updatedDate
        self.explicit = explicit
        self.mark = mark
        self.image = image
        self.authors = authors
        self.episodes = episodes
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        updatedDate = try? c.decodeIfPresent(String.self, forKey: .updatedDate)
        explicit = try c.decodeDefault(Bool.self, forKey: .explicit, default: false)
        mark = try? c.decodeIfPresent(String.self, forKey: .mark)
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
        authors = try c.decodeArray([PodcastAuthor].self, forKey: .authors)
        episodes = try c.decodeArray([CollectionPodcastEpisode].self, forKey: .episodes)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, updatedDate, explicit, mark, image, authors, episodes
    }
}

/// Minimal episode info inside a collection podcast.
public struct CollectionPodcastEpisode: Codable, Hashable, Sendable {
    public let publicationDate: String?

    public init(publicationDate: String? = nil) {
        self.publicationDate = publicationDate
    }
}

/// Collection episode (from paginated collection).
public struct CollectionEpisode: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let explicit: Bool
    public let mark: String?
    public let image: Image?
    public let podcast: CollectionEpisodePodcast?
    public let publicationDate: String?

    public init(
        id: String = "",
        title: String = "",
        explicit: Bool = false,
        mark: String? = nil,
        image: Image? = nil,
        podcast: CollectionEpisodePodcast? = nil,
        publicationDate: String? = nil
    ) {
        self.id = id
        self.title = title
        self.explicit = explicit
        self.mark = mark
        self.image = image
        self.podcast = podcast
        self.publicationDate = publicationDate
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        explicit = try c.decodeDefault(Bool.self, forKey: .explicit, default: false)
        mark = try? c.decodeIfPresent(String.self, forKey: .mark)
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
        podcast = try? c.decodeIfPresent(CollectionEpisodePodcast.self, forKey: .podcast)
        publicationDate = try? c.decodeIfPresent(String.self, forKey: .publicationDate)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, explicit, mark, image, podcast, publicationDate
    }
}

/// Minimal podcast info inside a collection episode.
public struct CollectionEpisodePodcast: Codable, Hashable, Sendable {
    public let updatedDate: String?
    public let authors: [PodcastAuthor]

    public init(updatedDate: String? = nil, authors: [PodcastAuthor] = []) {
        self.updatedDate = updatedDate
        self.authors = authors
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        updatedDate = try? c.decodeIfPresent(String.self, forKey: .updatedDate)
        authors = try c.decodeArray([PodcastAuthor].self, forKey: .authors)
    }

    private enum CodingKeys: String, CodingKey {
        case updatedDate, authors
    }
}

/// Collection book (from paginated collection).
public struct CollectionBook: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let bookAuthors: [BookAuthor]
    public let image: Image?
    public let mark: String?
    public let explicit: Bool

    public init(
        id: String = "",
        title: String = "",
        bookAuthors: [BookAuthor] = [],
        image: Image? = nil,
        mark: String? = nil,
        explicit: Bool = false
    ) {
        self.id = id
        self.title = title
        self.bookAuthors = bookAuthors
        self.image = image
        self.mark = mark
        self.explicit = explicit
    }

    /// Author names separated by commas.
    public var authorsString: String {
        bookAuthors.map(\.rname).joined(separator: ", ")
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        bookAuthors = try c.decodeArray([BookAuthor].self, forKey: .bookAuthors)
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
        mark = try? c.decodeIfPresent(String.self, forKey: .mark)
        explicit = try c.decodeDefault(Bool.self, forKey: .explicit, default: false)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, bookAuthors, image, mark, explicit
    }
}

/// Full paginated collection with all item types.
public struct PaginatedCollection: Codable, Hashable, Sendable {
    public let playlists: PaginatedResult<CollectionPlaylist>?
    public let releases: PaginatedResult<CollectionRelease>?
    public let artists: PaginatedResult<CollectionArtist>?
    public let podcasts: PaginatedResult<CollectionPodcast>?
    public let episodes: PaginatedResult<CollectionEpisode>?
    public let books: PaginatedResult<CollectionBook>?

    public init(
        playlists: PaginatedResult<CollectionPlaylist>? = nil,
        releases: PaginatedResult<CollectionRelease>? = nil,
        artists: PaginatedResult<CollectionArtist>? = nil,
        podcasts: PaginatedResult<CollectionPodcast>? = nil,
        episodes: PaginatedResult<CollectionEpisode>? = nil,
        books: PaginatedResult<CollectionBook>? = nil
    ) {
        self.playlists = playlists
        self.releases = releases
        self.artists = artists
        self.podcasts = podcasts
        self.episodes = episodes
        self.books = books
    }
}
