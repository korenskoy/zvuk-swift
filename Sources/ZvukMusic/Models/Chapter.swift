import Foundation

/// The book a chapter belongs to.
public struct ChapterBook: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let explicit: Bool

    public init(id: String = "", title: String = "", explicit: Bool = false) {
        self.id = id
        self.title = title
        self.explicit = explicit
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        explicit = try c.decodeDefault(Bool.self, forKey: .explicit, default: false)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, explicit
    }
}

/// One chapter of an audiobook — the playable unit, analogous to a track.
public struct Chapter: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    /// Length in seconds.
    public let duration: Int
    /// Position within the book, 1-based.
    public let position: Int
    /// Whether the chapter is playable for this account.
    public let availability: Int?
    public let image: Image?
    /// The parent book.
    public let book: ChapterBook?
    public let bookAuthors: [BookAuthor]

    public init(
        id: String = "",
        title: String = "",
        duration: Int = 0,
        position: Int = 0,
        availability: Int? = nil,
        image: Image? = nil,
        book: ChapterBook? = nil,
        bookAuthors: [BookAuthor] = []
    ) {
        self.id = id
        self.title = title
        self.duration = duration
        self.position = position
        self.availability = availability
        self.image = image
        self.book = book
        self.bookAuthors = bookAuthors
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        duration = try c.decodeDefault(Int.self, forKey: .duration, default: 0)
        position = try c.decodeDefault(Int.self, forKey: .position, default: 0)
        availability = try? c.decodeIfPresent(Int.self, forKey: .availability)
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
        book = try? c.decodeIfPresent(ChapterBook.self, forKey: .book)
        bookAuthors = try c.decodeArray([BookAuthor].self, forKey: .bookAuthors)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, duration, position, availability, image, book, bookAuthors
    }

    /// Author names separated by commas.
    public var authorsString: String {
        bookAuthors.map(\.rname).joined(separator: ", ")
    }
}
