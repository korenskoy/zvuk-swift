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

    /// Author names separated by commas.
    public var authorsString: String {
        if !bookAuthors.isEmpty {
            return bookAuthors.map(\.rname).joined(separator: ", ")
        }
        return authorNames.joined(separator: ", ")
    }
}
