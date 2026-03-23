import Foundation

/// Notification type.
public enum NotificationType: String, Codable, Sendable {
    case newRelease = "NEW_RELEASE"
    case newPodcastEpisode = "NEW_PODCAST_EPISODE"
    case newBook = "NEW_BOOK"
    case newProfilePlaylist = "NEW_PROFILE_PLAYLIST"
    case playlistTracksAdded = "PLAYLIST_TRACKS_ADDED"
    case playlistLiked = "PLAYLIST_LIKED"

    /// All available notification types.
    public static let all: [NotificationType] = [
        .newRelease, .newPodcastEpisode, .newBook,
        .newProfilePlaylist, .playlistTracksAdded, .playlistLiked,
    ]
}

/// Notification feed page info for cursor-based pagination.
public struct NotificationPageInfo: Codable, Hashable, Sendable {
    public let cursor: String?
    public let hasNextPage: Bool

    public init(cursor: String? = nil, hasNextPage: Bool = false) {
        self.cursor = cursor
        self.hasNextPage = hasNextPage
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        cursor = try? c.decodeIfPresent(String.self, forKey: .cursor)
        hasNextPage = try c.decodeDefault(Bool.self, forKey: .hasNextPage, default: false)
    }

    private enum CodingKeys: String, CodingKey {
        case cursor, hasNextPage
    }
}

/// Notification author (artist context for NewRelease).
public struct NotificationArtistAuthor: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let image: Image?
    public let mark: String?

    public init(id: String = "", title: String = "", image: Image? = nil, mark: String? = nil) {
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

/// Notification release.
public struct NotificationRelease: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let type: String?
    public let artists: [NotificationArtistAuthor]
    public let mark: String?
    public let childParam: String?
    public let explicit: Bool
    public let image: Image?

    public init(
        id: String = "",
        title: String = "",
        type: String? = nil,
        artists: [NotificationArtistAuthor] = [],
        mark: String? = nil,
        childParam: String? = nil,
        explicit: Bool = false,
        image: Image? = nil
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.artists = artists
        self.mark = mark
        self.childParam = childParam
        self.explicit = explicit
        self.image = image
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        type = try? c.decodeIfPresent(String.self, forKey: .type)
        artists = try c.decodeArray([NotificationArtistAuthor].self, forKey: .artists)
        mark = try? c.decodeIfPresent(String.self, forKey: .mark)
        childParam = try? c.decodeIfPresent(String.self, forKey: .childParam)
        explicit = try c.decodeDefault(Bool.self, forKey: .explicit, default: false)
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, type, artists, mark, childParam, explicit, image
    }
}

/// Book author in notification context (with optional mark).
public struct NotificationBookAuthor: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let rname: String
    public let image: Image?
    public let mark: String?

    public init(id: String = "", rname: String = "", image: Image? = nil, mark: String? = nil) {
        self.id = id
        self.rname = rname
        self.image = image
        self.mark = mark
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        rname = try c.decodeDefault(String.self, forKey: .rname, default: "")
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
        mark = try? c.decodeIfPresent(String.self, forKey: .mark)
    }

    private enum CodingKeys: String, CodingKey {
        case id, rname, image, mark
    }
}

/// Notification book.
public struct NotificationBook: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let mark: String?
    public let explicit: Bool
    public let image: Image?
    public let bookAuthors: [NotificationBookAuthor]

    public init(
        id: String = "",
        title: String = "",
        mark: String? = nil,
        explicit: Bool = false,
        image: Image? = nil,
        bookAuthors: [NotificationBookAuthor] = []
    ) {
        self.id = id
        self.title = title
        self.mark = mark
        self.explicit = explicit
        self.image = image
        self.bookAuthors = bookAuthors
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        mark = try? c.decodeIfPresent(String.self, forKey: .mark)
        explicit = try c.decodeDefault(Bool.self, forKey: .explicit, default: false)
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
        bookAuthors = try c.decodeArray([NotificationBookAuthor].self, forKey: .bookAuthors)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, mark, explicit, image, bookAuthors
    }
}

/// Notification episode.
public struct NotificationEpisode: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let duration: Int
    public let publicationDate: String?
    public let trackId: String?
    public let explicit: Bool
    public let mark: String?
    public let childParam: String?
    public let image: Image?
    public let podcast: NotificationPodcast?

    public init(
        id: String = "",
        title: String = "",
        duration: Int = 0,
        publicationDate: String? = nil,
        trackId: String? = nil,
        explicit: Bool = false,
        mark: String? = nil,
        childParam: String? = nil,
        image: Image? = nil,
        podcast: NotificationPodcast? = nil
    ) {
        self.id = id
        self.title = title
        self.duration = duration
        self.publicationDate = publicationDate
        self.trackId = trackId
        self.explicit = explicit
        self.mark = mark
        self.childParam = childParam
        self.image = image
        self.podcast = podcast
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        duration = try c.decodeDefault(Int.self, forKey: .duration, default: 0)
        publicationDate = try? c.decodeIfPresent(String.self, forKey: .publicationDate)
        trackId = try? c.decodeIfPresent(String.self, forKey: .trackId)
        explicit = try c.decodeDefault(Bool.self, forKey: .explicit, default: false)
        mark = try? c.decodeIfPresent(String.self, forKey: .mark)
        childParam = try? c.decodeIfPresent(String.self, forKey: .childParam)
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
        podcast = try? c.decodeIfPresent(NotificationPodcast.self, forKey: .podcast)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, duration, publicationDate, trackId
        case explicit, mark, childParam, image, podcast
    }
}

/// Notification podcast (brief, nested inside episode).
public struct NotificationPodcast: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let image: Image?
    public let mark: String?

    public init(id: String = "", title: String = "", image: Image? = nil, mark: String? = nil) {
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

/// Profile author in notification context (for playlist notifications).
public struct NotificationProfileAuthor: Codable, Hashable, Identifiable, Sendable {
    public let typename: String?
    public let id: String
    public let name: String
    public let image: Image?

    public init(typename: String? = nil, id: String = "", name: String = "", image: Image? = nil) {
        self.typename = typename
        self.id = id
        self.name = name
        self.image = image
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        typename = try? c.decodeIfPresent(String.self, forKey: .typename)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        name = try c.decodeDefault(String.self, forKey: .name, default: "")
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
    }

    private enum CodingKeys: String, CodingKey {
        case typename = "__typename"
        case id, name, image
    }
}

/// Notification playlist track (brief, with release image).
public struct NotificationPlaylistTrack: Codable, Hashable, Sendable {
    public let release: NotificationPlaylistTrackRelease?

    public init(release: NotificationPlaylistTrackRelease? = nil) {
        self.release = release
    }
}

/// Release info inside a notification playlist track.
public struct NotificationPlaylistTrackRelease: Codable, Hashable, Sendable {
    public let title: String
    public let image: Image?

    public init(title: String = "", image: Image? = nil) {
        self.title = title
        self.image = image
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
    }

    private enum CodingKeys: String, CodingKey {
        case title, image
    }
}

/// Notification playlist.
public struct NotificationPlaylist: Codable, Hashable, Identifiable, Sendable {
    public let typename: String?
    public let id: String
    public let title: String
    public let trackCount: Int
    public let tracks: [NotificationPlaylistTrack]
    public let coverV1: Image?
    public let image: NotificationPlaylistImage?

    public init(
        typename: String? = nil,
        id: String = "",
        title: String = "",
        trackCount: Int = 0,
        tracks: [NotificationPlaylistTrack] = [],
        coverV1: Image? = nil,
        image: NotificationPlaylistImage? = nil
    ) {
        self.typename = typename
        self.id = id
        self.title = title
        self.trackCount = trackCount
        self.tracks = tracks
        self.coverV1 = coverV1
        self.image = image
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        typename = try? c.decodeIfPresent(String.self, forKey: .typename)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        trackCount = try c.decodeDefault(Int.self, forKey: .trackCount, default: 0)
        tracks = try c.decodeArray([NotificationPlaylistTrack].self, forKey: .tracks)
        coverV1 = try? c.decodeIfPresent(Image.self, forKey: .coverV1)
        image = try? c.decodeIfPresent(NotificationPlaylistImage.self, forKey: .image)
    }

    private enum CodingKeys: String, CodingKey {
        case typename = "__typename"
        case id, title, trackCount, tracks, coverV1, image
    }
}

/// Notification playlist image (extended with picUrlBig).
public struct NotificationPlaylistImage: Codable, Hashable, Sendable {
    public let src: String
    public let picUrlBig: String?

    public init(src: String = "", picUrlBig: String? = nil) {
        self.src = src
        self.picUrlBig = picUrlBig
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        src = try c.decodeDefault(String.self, forKey: .src, default: "")
        picUrlBig = try? c.decodeIfPresent(String.self, forKey: .picUrlBig)
    }

    private enum CodingKeys: String, CodingKey {
        case src, picUrlBig
    }
}

/// Notification body — a union type dispatched by `__typename`.
public enum NotificationBody: Codable, Hashable, Sendable {
    case newRelease(author: NotificationArtistAuthor, release: NotificationRelease)
    case newPodcastEpisode(episode: NotificationEpisode)
    case newBook(author: NotificationBookAuthor, book: NotificationBook)
    case newProfilePlaylist(author: NotificationProfileAuthor, playlist: NotificationPlaylist)
    case playlistTracksAdded(
        author: NotificationProfileAuthor, playlist: NotificationPlaylist, addedTracksCount: Int)
    case playlistLiked(author: NotificationProfileAuthor, playlist: NotificationPlaylist)
    case unknown(typename: String)

    /// The `__typename` value from GraphQL.
    public var typename: String {
        switch self {
        case .newRelease: "NewRelease"
        case .newPodcastEpisode: "NewPodcastEpisode"
        case .newBook: "NewBook"
        case .newProfilePlaylist: "NewProfilePlaylist"
        case .playlistTracksAdded: "PlaylistTracksAdded"
        case .playlistLiked: "PlaylistLiked"
        case .unknown(let typename): typename
        }
    }

    private enum CodingKeys: String, CodingKey {
        case typename = "__typename"
        case author, release, episode, book, playlist, addedTracksCount
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let typename = try c.decodeDefault(String.self, forKey: .typename, default: "")

        switch typename {
        case "NewRelease":
            let author = try c.decode(NotificationArtistAuthor.self, forKey: .author)
            let release = try c.decode(NotificationRelease.self, forKey: .release)
            self = .newRelease(author: author, release: release)
        case "NewPodcastEpisode":
            let episode = try c.decode(NotificationEpisode.self, forKey: .episode)
            self = .newPodcastEpisode(episode: episode)
        case "NewBook":
            let author = try c.decode(NotificationBookAuthor.self, forKey: .author)
            let book = try c.decode(NotificationBook.self, forKey: .book)
            self = .newBook(author: author, book: book)
        case "NewProfilePlaylist":
            let author = try c.decode(NotificationProfileAuthor.self, forKey: .author)
            let playlist = try c.decode(NotificationPlaylist.self, forKey: .playlist)
            self = .newProfilePlaylist(author: author, playlist: playlist)
        case "PlaylistTracksAdded":
            let author = try c.decode(NotificationProfileAuthor.self, forKey: .author)
            let playlist = try c.decode(NotificationPlaylist.self, forKey: .playlist)
            let count = try c.decodeDefault(Int.self, forKey: .addedTracksCount, default: 0)
            self = .playlistTracksAdded(author: author, playlist: playlist, addedTracksCount: count)
        case "PlaylistLiked":
            let author = try c.decode(NotificationProfileAuthor.self, forKey: .author)
            let playlist = try c.decode(NotificationPlaylist.self, forKey: .playlist)
            self = .playlistLiked(author: author, playlist: playlist)
        default:
            self = .unknown(typename: typename)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(typename, forKey: .typename)
        switch self {
        case .newRelease(let author, let release):
            try c.encode(author, forKey: .author)
            try c.encode(release, forKey: .release)
        case .newPodcastEpisode(let episode):
            try c.encode(episode, forKey: .episode)
        case .newBook(let author, let book):
            try c.encode(author, forKey: .author)
            try c.encode(book, forKey: .book)
        case .newProfilePlaylist(let author, let playlist):
            try c.encode(author, forKey: .author)
            try c.encode(playlist, forKey: .playlist)
        case .playlistTracksAdded(let author, let playlist, let count):
            try c.encode(author, forKey: .author)
            try c.encode(playlist, forKey: .playlist)
            try c.encode(count, forKey: .addedTracksCount)
        case .playlistLiked(let author, let playlist):
            try c.encode(author, forKey: .author)
            try c.encode(playlist, forKey: .playlist)
        case .unknown:
            break
        }
    }
}

/// A single notification entry.
public struct ZvukNotification: Codable, Hashable, Sendable {
    public let createdAt: String
    public let body: NotificationBody

    public init(createdAt: String = "", body: NotificationBody = .unknown(typename: "")) {
        self.createdAt = createdAt
        self.body = body
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        createdAt = try c.decodeDefault(String.self, forKey: .createdAt, default: "")
        body = try c.decode(NotificationBody.self, forKey: .body)
    }

    private enum CodingKeys: String, CodingKey {
        case createdAt, body
    }
}

/// Paginated notifications feed response.
public struct NotificationsFeed: Codable, Hashable, Sendable {
    public let pageInfo: NotificationPageInfo
    public let notifications: [ZvukNotification]

    public init(
        pageInfo: NotificationPageInfo = NotificationPageInfo(),
        notifications: [ZvukNotification] = []
    ) {
        self.pageInfo = pageInfo
        self.notifications = notifications
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        pageInfo = (try? c.decode(NotificationPageInfo.self, forKey: .pageInfo))
            ?? NotificationPageInfo()
        notifications = try c.decodeArray([ZvukNotification].self, forKey: .notifications)
    }

    private enum CodingKeys: String, CodingKey {
        case pageInfo, notifications
    }
}
