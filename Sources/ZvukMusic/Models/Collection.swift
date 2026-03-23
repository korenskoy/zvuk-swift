import Foundation

/// Collection item (like/hidden metadata).
public struct CollectionItem: Codable, Hashable, Sendable {
    public let id: String?
    public let userId: String?
    public let itemStatus: CollectionItemStatus?
    public let lastModified: String?
    public let collectionLastModified: String?
    public let likesCount: Int?

    public init(
        id: String? = nil,
        userId: String? = nil,
        itemStatus: CollectionItemStatus? = nil,
        lastModified: String? = nil,
        collectionLastModified: String? = nil,
        likesCount: Int? = nil
    ) {
        self.id = id
        self.userId = userId
        self.itemStatus = itemStatus
        self.lastModified = lastModified
        self.collectionLastModified = collectionLastModified
        self.likesCount = likesCount
    }

    /// Whether the item is liked.
    public var isLiked: Bool {
        itemStatus == .liked
    }
}

/// User's collection of liked items.
public struct Collection: Codable, Hashable, Sendable {
    public let artists: [CollectionItem]
    public let episodes: [CollectionItem]
    public let podcasts: [CollectionItem]
    public let playlists: [CollectionItem]
    public let synthesisPlaylists: [CollectionItem]
    public let profiles: [CollectionItem]
    public let releases: [CollectionItem]
    public let tracks: [CollectionItem]

    public init(
        artists: [CollectionItem] = [],
        episodes: [CollectionItem] = [],
        podcasts: [CollectionItem] = [],
        playlists: [CollectionItem] = [],
        synthesisPlaylists: [CollectionItem] = [],
        profiles: [CollectionItem] = [],
        releases: [CollectionItem] = [],
        tracks: [CollectionItem] = []
    ) {
        self.artists = artists
        self.episodes = episodes
        self.podcasts = podcasts
        self.playlists = playlists
        self.synthesisPlaylists = synthesisPlaylists
        self.profiles = profiles
        self.releases = releases
        self.tracks = tracks
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        artists = try c.decodeArray([CollectionItem].self, forKey: .artists)
        episodes = try c.decodeArray([CollectionItem].self, forKey: .episodes)
        podcasts = try c.decodeArray([CollectionItem].self, forKey: .podcasts)
        playlists = try c.decodeArray([CollectionItem].self, forKey: .playlists)
        synthesisPlaylists = try c.decodeArray([CollectionItem].self, forKey: .synthesisPlaylists)
        profiles = try c.decodeArray([CollectionItem].self, forKey: .profiles)
        releases = try c.decodeArray([CollectionItem].self, forKey: .releases)
        tracks = try c.decodeArray([CollectionItem].self, forKey: .tracks)
    }

    private enum CodingKeys: String, CodingKey {
        case artists, episodes, podcasts, playlists, synthesisPlaylists
        case profiles, releases, tracks
    }
}

/// Hidden items collection.
public struct HiddenCollection: Codable, Hashable, Sendable {
    public let tracks: [CollectionItem]
    public let artists: [CollectionItem]

    public init(tracks: [CollectionItem] = [], artists: [CollectionItem] = []) {
        self.tracks = tracks
        self.artists = artists
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tracks = try c.decodeArray([CollectionItem].self, forKey: .tracks)
        artists = try c.decodeArray([CollectionItem].self, forKey: .artists)
    }

    private enum CodingKeys: String, CodingKey {
        case tracks, artists
    }
}
