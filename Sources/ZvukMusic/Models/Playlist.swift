import Foundation

/// Playlist item.
public struct PlaylistItem: Codable, Hashable, Sendable {
    public let type: String
    public let itemId: String

    public init(type: String = "track", itemId: String = "") {
        self.type = type
        self.itemId = itemId
    }
}

/// Brief playlist information.
public struct SimplePlaylist: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let isPublic: Bool
    public let description: String?
    public let duration: Int
    public let image: Image?

    public init(
        id: String = "",
        title: String = "",
        isPublic: Bool = true,
        description: String? = nil,
        duration: Int = 0,
        image: Image? = nil
    ) {
        self.id = id
        self.title = title
        self.isPublic = isPublic
        self.description = description
        self.duration = duration
        self.image = image
    }
}

/// Full playlist information.
public struct Playlist: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let userId: String?
    public let isPublic: Bool
    public let isDeleted: Bool
    public let shared: Bool
    public let branded: Bool
    public let description: String?
    public let duration: Int
    public let image: Image?
    public let updated: String?
    public let searchTitle: String?
    public let tracks: [SimpleTrack]

    public init(
        id: String = "",
        title: String = "",
        userId: String? = nil,
        isPublic: Bool = true,
        isDeleted: Bool = false,
        shared: Bool = false,
        branded: Bool = false,
        description: String? = nil,
        duration: Int = 0,
        image: Image? = nil,
        updated: String? = nil,
        searchTitle: String? = nil,
        tracks: [SimpleTrack] = []
    ) {
        self.id = id
        self.title = title
        self.userId = userId
        self.isPublic = isPublic
        self.isDeleted = isDeleted
        self.shared = shared
        self.branded = branded
        self.description = description
        self.duration = duration
        self.image = image
        self.updated = updated
        self.searchTitle = searchTitle
        self.tracks = tracks
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        userId = try? c.decodeIfPresent(String.self, forKey: .userId)
        isPublic = try c.decodeDefault(Bool.self, forKey: .isPublic, default: true)
        isDeleted = try c.decodeDefault(Bool.self, forKey: .isDeleted, default: false)
        shared = try c.decodeDefault(Bool.self, forKey: .shared, default: false)
        branded = try c.decodeDefault(Bool.self, forKey: .branded, default: false)
        description = try? c.decodeIfPresent(String.self, forKey: .description)
        duration = try c.decodeDefault(Int.self, forKey: .duration, default: 0)
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
        updated = try? c.decodeIfPresent(String.self, forKey: .updated)
        searchTitle = try? c.decodeIfPresent(String.self, forKey: .searchTitle)
        tracks = try c.decodeArray([SimpleTrack].self, forKey: .tracks)
    }

    /// Return a copy with full track data replacing the stub-only tracks.
    public func withTracks(_ fullTracks: [SimpleTrack]) -> Playlist {
        Playlist(
            id: id, title: title, userId: userId, isPublic: isPublic,
            isDeleted: isDeleted, shared: shared, branded: branded,
            description: description, duration: duration, image: image,
            updated: updated, searchTitle: searchTitle, tracks: fullTracks
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, userId, isPublic, isDeleted, shared, branded
        case description, duration, image, updated, searchTitle, tracks
    }
}

/// Playlist author (for synthesis playlists).
public struct PlaylistAuthor: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let image: Image?
    public let matches: Double?

    public init(id: String = "", name: String = "", image: Image? = nil, matches: Double? = nil) {
        self.id = id
        self.name = name
        self.image = image
        self.matches = matches
    }
}

/// AI-generated synthesis playlist from two authors.
public struct SynthesisPlaylist: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let tracks: [SimpleTrack]
    public let authors: [PlaylistAuthor]

    public init(id: String = "", tracks: [SimpleTrack] = [], authors: [PlaylistAuthor] = []) {
        self.id = id
        self.tracks = tracks
        self.authors = authors
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        tracks = try c.decodeArray([SimpleTrack].self, forKey: .tracks)
        authors = try c.decodeArray([PlaylistAuthor].self, forKey: .authors)
    }

    private enum CodingKeys: String, CodingKey {
        case id, tracks, authors
    }
}
