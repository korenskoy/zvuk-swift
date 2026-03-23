import Foundation

/// Pagination information.
public struct Page: Codable, Hashable, Sendable {
    public let total: Int?
    public let prev: Int?
    public let next: Int?
    public let cursor: String?

    public init(total: Int? = nil, prev: Int? = nil, next: Int? = nil, cursor: String? = nil) {
        self.total = total
        self.prev = prev
        self.next = next
        self.cursor = cursor
    }

    /// Whether there is a next page.
    public var hasNext: Bool {
        next != nil || cursor != nil
    }

    /// Whether there is a previous page.
    public var hasPrev: Bool {
        prev != nil
    }
}

/// Generic search result container.
public struct SearchResult<T: Codable & Hashable & Sendable>: Codable, Hashable, Sendable {
    public let page: Page?
    public let score: Double
    public let items: [T]

    public init(page: Page? = nil, score: Double = 0.0, items: [T] = []) {
        self.page = page
        self.score = score
        self.items = items
    }
}

/// Full-text search results.
public struct Search: Codable, Hashable, Sendable {
    public let searchId: String
    public let tracks: SearchResult<SimpleTrack>?
    public let artists: SearchResult<SimpleArtist>?
    public let releases: SearchResult<SimpleRelease>?
    public let playlists: SearchResult<SimplePlaylist>?
    public let profiles: SearchResult<SimpleProfile>?
    public let books: SearchResult<SimpleBook>?
    public let episodes: SearchResult<SimpleEpisode>?
    public let podcasts: SearchResult<SimplePodcast>?

    public init(
        searchId: String = "",
        tracks: SearchResult<SimpleTrack>? = nil,
        artists: SearchResult<SimpleArtist>? = nil,
        releases: SearchResult<SimpleRelease>? = nil,
        playlists: SearchResult<SimplePlaylist>? = nil,
        profiles: SearchResult<SimpleProfile>? = nil,
        books: SearchResult<SimpleBook>? = nil,
        episodes: SearchResult<SimpleEpisode>? = nil,
        podcasts: SearchResult<SimplePodcast>? = nil
    ) {
        self.searchId = searchId
        self.tracks = tracks
        self.artists = artists
        self.releases = releases
        self.playlists = playlists
        self.profiles = profiles
        self.books = books
        self.episodes = episodes
        self.podcasts = podcasts
    }
}

/// Quick search / autocomplete results.
///
/// The API returns a `content` array with mixed types differentiated by `__typename`.
/// Custom decoding separates them into typed arrays.
public struct QuickSearch: Codable, Hashable, Sendable {
    public let searchSessionId: String
    public let tracks: [SimpleTrack]
    public let artists: [SimpleArtist]
    public let releases: [SimpleRelease]
    public let playlists: [SimplePlaylist]
    public let profiles: [SimpleProfile]
    public let books: [SimpleBook]
    public let episodes: [SimpleEpisode]
    public let podcasts: [SimplePodcast]

    public init(
        searchSessionId: String = "",
        tracks: [SimpleTrack] = [],
        artists: [SimpleArtist] = [],
        releases: [SimpleRelease] = [],
        playlists: [SimplePlaylist] = [],
        profiles: [SimpleProfile] = [],
        books: [SimpleBook] = [],
        episodes: [SimpleEpisode] = [],
        podcasts: [SimplePodcast] = []
    ) {
        self.searchSessionId = searchSessionId
        self.tracks = tracks
        self.artists = artists
        self.releases = releases
        self.playlists = playlists
        self.profiles = profiles
        self.books = books
        self.episodes = episodes
        self.podcasts = podcasts
    }

    // Custom coding to handle mixed `content` array from API
    enum CodingKeys: String, CodingKey {
        case searchSessionId
        case content
        case tracks, artists, releases, playlists, profiles, books, episodes, podcasts
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(searchSessionId, forKey: .searchSessionId)
        try container.encode(tracks, forKey: .tracks)
        try container.encode(artists, forKey: .artists)
        try container.encode(releases, forKey: .releases)
        try container.encode(playlists, forKey: .playlists)
        try container.encode(profiles, forKey: .profiles)
        try container.encode(books, forKey: .books)
        try container.encode(episodes, forKey: .episodes)
        try container.encode(podcasts, forKey: .podcasts)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.searchSessionId = (try? container.decode(String.self, forKey: .searchSessionId)) ?? ""

        // Try mixed content array first (API format)
        if let contentItems = try? container.decode([QuickSearchContentItem].self, forKey: .content)
        {
            var tracks: [SimpleTrack] = []
            var artists: [SimpleArtist] = []
            var releases: [SimpleRelease] = []
            var playlists: [SimplePlaylist] = []
            var profiles: [SimpleProfile] = []
            var books: [SimpleBook] = []
            var episodes: [SimpleEpisode] = []
            var podcasts: [SimplePodcast] = []

            for item in contentItems {
                switch item {
                case .track(let v): tracks.append(v)
                case .artist(let v): artists.append(v)
                case .release(let v): releases.append(v)
                case .playlist(let v): playlists.append(v)
                case .profile(let v): profiles.append(v)
                case .book(let v): books.append(v)
                case .episode(let v): episodes.append(v)
                case .podcast(let v): podcasts.append(v)
                case .unknown: break
                }
            }

            self.tracks = tracks
            self.artists = artists
            self.releases = releases
            self.playlists = playlists
            self.profiles = profiles
            self.books = books
            self.episodes = episodes
            self.podcasts = podcasts
        } else {
            // Fallback: separate typed arrays
            self.tracks = (try? container.decode([SimpleTrack].self, forKey: .tracks)) ?? []
            self.artists = (try? container.decode([SimpleArtist].self, forKey: .artists)) ?? []
            self.releases = (try? container.decode([SimpleRelease].self, forKey: .releases)) ?? []
            self.playlists =
                (try? container.decode([SimplePlaylist].self, forKey: .playlists)) ?? []
            self.profiles = (try? container.decode([SimpleProfile].self, forKey: .profiles)) ?? []
            self.books = (try? container.decode([SimpleBook].self, forKey: .books)) ?? []
            self.episodes = (try? container.decode([SimpleEpisode].self, forKey: .episodes)) ?? []
            self.podcasts = (try? container.decode([SimplePodcast].self, forKey: .podcasts)) ?? []
        }
    }
}

/// Internal enum for decoding mixed `content` array in QuickSearch.
enum QuickSearchContentItem: Decodable {
    case track(SimpleTrack)
    case artist(SimpleArtist)
    case release(SimpleRelease)
    case playlist(SimplePlaylist)
    case profile(SimpleProfile)
    case book(SimpleBook)
    case episode(SimpleEpisode)
    case podcast(SimplePodcast)
    case unknown

    private enum TypenameKey: String, CodingKey {
        case typename = "__typename"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: TypenameKey.self)
        let typename = (try? container.decode(String.self, forKey: .typename)) ?? ""

        let singleContainer = try decoder.singleValueContainer()
        switch typename {
        case "Track":
            self = .track(try singleContainer.decode(SimpleTrack.self))
        case "Artist":
            self = .artist(try singleContainer.decode(SimpleArtist.self))
        case "Release":
            self = .release(try singleContainer.decode(SimpleRelease.self))
        case "Playlist":
            self = .playlist(try singleContainer.decode(SimplePlaylist.self))
        case "Profile":
            self = .profile(try singleContainer.decode(SimpleProfile.self))
        case "Book":
            self = .book(try singleContainer.decode(SimpleBook.self))
        case "Episode":
            self = .episode(try singleContainer.decode(SimpleEpisode.self))
        case "Podcast":
            self = .podcast(try singleContainer.decode(SimplePodcast.self))
        default:
            self = .unknown
        }
    }
}
