import Foundation

/// Book author.
public struct BookAuthor: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    /// Reversed name (Last name First name).
    public let rname: String
    public let image: Image?

    public init(id: String = "", rname: String = "", image: Image? = nil) {
        self.id = id
        self.rname = rname
        self.image = image
    }

    // Разные запросы просят у автора разный набор полей — декодируем терпимо.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        rname = try c.decodeDefault(String.self, forKey: .rname, default: "")
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
    }

    private enum CodingKeys: String, CodingKey {
        case id, rname, image
    }
}

/// Brief book information.
public struct SimpleBook: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let authorNames: [String]
    public let bookAuthors: [BookAuthor]
    public let image: Image?

    public init(
        id: String = "",
        title: String = "",
        authorNames: [String] = [],
        bookAuthors: [BookAuthor] = [],
        image: Image? = nil
    ) {
        self.id = id
        self.title = title
        self.authorNames = authorNames
        self.bookAuthors = bookAuthors
        self.image = image
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        authorNames = try c.decodeArray([String].self, forKey: .authorNames)
        bookAuthors = try c.decodeArray([BookAuthor].self, forKey: .bookAuthors)
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, authorNames, bookAuthors, image
    }

    /// Author names separated by commas.
    public var authorsString: String {
        if !bookAuthors.isEmpty {
            return bookAuthors.map(\.rname).joined(separator: ", ")
        }
        return authorNames.joined(separator: ", ")
    }
}
