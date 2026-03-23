import Foundation

/// Track lyrics.
public struct Lyrics: Codable, Hashable, Sendable {
    /// Lyrics text (LRC format or plain text).
    public let lyrics: String
    /// Lyrics type string (subtitle=LRC, lyrics=plain).
    public let type: String?
    /// Optional translation text.
    public let translation: String?

    public init(lyrics: String = "", type: String? = nil, translation: String? = nil) {
        self.lyrics = lyrics
        self.type = type
        self.translation = translation
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lyrics = (try? c.decodeIfPresent(String.self, forKey: .lyrics)) ?? ""
        type = try? c.decodeIfPresent(String.self, forKey: .type)
        translation = try? c.decodeIfPresent(String.self, forKey: .translation)
    }

    private enum CodingKeys: String, CodingKey {
        case lyrics, type, translation
    }

    /// Lyrics type as enum.
    public var lyricsType: LyricsType? {
        guard let type else { return nil }
        return LyricsType(rawValue: type)
    }

    /// Whether lyrics are time-synced (LRC format).
    public var isSynced: Bool {
        lyricsType == .subtitle
    }
}
