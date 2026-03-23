import Foundation

/// Audio quality for GraphQL DRM-wrapped streaming.
/// For direct (non-DRM) streaming via Tiny API, use ``StreamQuality`` instead.
public enum Quality: String, Codable, Sendable {
    /// 128kbps MP3, always available
    case mid = "mid"
    /// 320kbps MP3, requires subscription
    case high = "high"
    /// FLAC with DRM, requires subscription
    case flac = "flacdrm"
}

/// Release type.
public enum ReleaseType: String, Codable, Sendable {
    case album
    case single
    case ep
    case compilation
}

/// Collection item type.
public enum CollectionItemType: String, Codable, Sendable {
    case track
    case release
    case artist
    case podcast
    case episode
    case playlist
    case profile
}

/// Collection item status.
public enum CollectionItemStatus: String, Codable, Sendable {
    case liked
}

/// Sort by field.
public enum OrderBy: String, Codable, Sendable {
    case alphabet
    case artist
    case dateAdded
}

/// Sort direction.
public enum OrderDirection: String, Codable, Sendable {
    case asc
    case desc
}

/// GraphQL entity type.
public enum Typename: String, Codable, Sendable {
    case artist = "Artist"
    case track = "Track"
    case release = "Release"
    case playlist = "Playlist"
    case episode = "Episode"
    case podcast = "Podcast"
    case profile = "Profile"
    case book = "Book"
    case chapter = "Chapter"
}

/// Direct stream quality (non-DRM) for Tiny API.
/// For GraphQL DRM-wrapped streaming, use ``Quality`` instead.
public enum StreamQuality: String, Codable, Sendable {
    case mid
    case high
    case flac
}

/// Lyrics format type.
public enum LyricsType: String, Codable, Sendable {
    case subtitle
    case lyrics
}

/// Background type.
public enum BackgroundType: String, Codable, Sendable {
    case image
}

/// Wave genre for personal wave filtering.
public enum WaveGenre: String, Codable, Sendable {
    case classical = "classical"
    case ambient = "easy_listening_ambient"
    case electronic = "electronic"
    case folk = "folk_world_country"
    case hipHop = "hip_hop"
    case indie = "indie"
    case instrumental = "instrumental_acoustic"
    case metal = "metal"
    case pop = "pop"
    case rock = "rock"
    case soundtrack = "soundtrack"
}

/// Wave language filter.
public enum WaveLanguage: String, Codable, Sendable {
    case foreign = "foreign"
    case russian = "russian"
}

/// Wave popularity filter.
public enum WavePopularity: Int, Codable, Sendable {
    /// Less popular / rare tracks.
    case rare = 0
    /// Most popular tracks.
    case popular = 1
}

/// Radio entity type for recommender radio.
public enum RadioEntityType: String, Codable, Sendable {
    case artist = "ARTIST"
    case track = "TRACK"
}
