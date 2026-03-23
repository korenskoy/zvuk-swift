import Foundation

/// Result from recommender radio (wave by artist or track).
public struct RadioResult: Codable, Hashable, Sendable {
    /// Cursor for pagination. Pass this value as `cursor` to get the next page.
    public let cursor: Int
    /// Tracks in this page.
    public let tracks: [Track]

    public init(cursor: Int = 0, tracks: [Track] = []) {
        self.cursor = cursor
        self.tracks = tracks
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        cursor = try c.decodeDefault(Int.self, forKey: .cursor, default: 0)
        tracks = try c.decodeArray([Track].self, forKey: .tracks)
    }

    private enum CodingKeys: String, CodingKey {
        case cursor, tracks
    }
}
