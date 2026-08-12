import Foundation

/// Short description of a wave (editorial or personal radio stream).
public struct WaveInfo: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let description: String?
    public let image: Image?

    public init(id: String = "", title: String = "", description: String? = nil, image: Image? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.image = image
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        description = try? c.decodeIfPresent(String.self, forKey: .description)
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, description, image
    }
}

/// One item of a wave stream.
///
/// A wave is not a plain track list: the server decides what comes next and
/// whether the listener is allowed to skip it.
public struct WaveContentItem: Codable, Hashable, Sendable {
    /// ID of the underlying entity.
    public let itemId: String
    /// Entity kind, e.g. `track`.
    public let itemType: String
    /// ID of the compilation this item was drawn from.
    public let compilationId: String?
    /// Position in the stream.
    public let sequence: Int
    /// Whether the listener may skip this item.
    public let skippable: Bool
    /// The track itself, when `itemType` is `track`.
    public let track: Track?

    public init(
        itemId: String = "",
        itemType: String = "",
        compilationId: String? = nil,
        sequence: Int = 0,
        skippable: Bool = true,
        track: Track? = nil
    ) {
        self.itemId = itemId
        self.itemType = itemType
        self.compilationId = compilationId
        self.sequence = sequence
        self.skippable = skippable
        self.track = track
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        itemId = try c.decodeDefault(String.self, forKey: .itemId, default: "")
        itemType = try c.decodeDefault(String.self, forKey: .itemType, default: "")
        compilationId = try? c.decodeIfPresent(String.self, forKey: .compilationId)
        sequence = try c.decodeDefault(Int.self, forKey: .sequence, default: 0)
        skippable = try c.decodeDefault(Bool.self, forKey: .skippable, default: true)
        track = try? c.decodeIfPresent(Track.self, forKey: .track)
    }

    private enum CodingKeys: String, CodingKey {
        case itemId, itemType, compilationId, sequence, skippable
        case track = "content"
    }
}

/// A page of popular search queries.
public struct PopularSearches: Codable, Hashable, Sendable {
    /// Opaque cursor for the next page.
    public let cursor: String?
    /// The queries themselves.
    public let queries: [String]

    public init(cursor: String? = nil, queries: [String] = []) {
        self.cursor = cursor
        self.queries = queries
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        cursor = try? c.decodeIfPresent(String.self, forKey: .cursor)
        struct Item: Decodable { let text: String? }
        queries = (try? c.decodeArray([Item].self, forKey: .items))?.compactMap(\.text) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        struct Item: Encodable { let text: String }
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(cursor, forKey: .cursor)
        try c.encode(queries.map { Item(text: $0) }, forKey: .items)
    }

    private enum CodingKeys: String, CodingKey {
        case cursor, items
    }
}
