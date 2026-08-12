import Foundation

// Audiobooks, their chapters and authors.
extension ZvukClient {
    /// Get full audiobook cards.
    /// - Parameters:
    ///   - bookIds: Book IDs.
    ///   - withChapters: Also fetch the chapter list.
    public func getAudioBooks(
        _ bookIds: [String],
        withChapters: Bool = false
    ) async throws -> [SimpleBook] {
        let result = try await perform("getAudioBook", ["ids": bookIds, "withChapters": withChapters])
        return try decodeList(SimpleBook.self, from: result["getBooks"])
    }

    /// Get a single audiobook by ID.
    public func getAudioBook(_ bookId: String, withChapters: Bool = false) async throws -> SimpleBook? {
        try await getAudioBooks([bookId], withChapters: withChapters).first
    }

    /// Get audiobook cards without the catalogue metadata (age limits, BISAC genres).
    /// - Parameters:
    ///   - bookIds: Book IDs.
    ///   - withChapters: Also fetch the chapter list.
    public func getAudioBooksShortInfo(
        _ bookIds: [String],
        withChapters: Bool = false
    ) async throws -> [SimpleBook] {
        let result = try await perform("getCommonAudioBook", ["ids": bookIds, "withChapters": withChapters])
        return try decodeList(SimpleBook.self, from: result["getBooks"])
    }

    /// Resolve which book a chapter belongs to.
    ///
    /// Needed when a deep link points at a chapter but the UI has to open the
    /// book page.
    /// - Parameter chapterId: Chapter ID.
    public func getBookIdByChapter(_ chapterId: String) async throws -> String? {
        let result = try await perform("getAudioBookIdByChapter", ["id": chapterId])
        let chapters = result["getChapters"] as? [[String: Any]] ?? []
        let book = chapters.first?["book"] as? [String: Any]
        return book?["id"] as? String
    }

    /// Get the chapter list of audiobooks.
    /// - Parameter bookIds: Book IDs.
    /// - Returns: Chapters, flattened across all books.
    public func getBookChapters(_ bookIds: [String]) async throws -> [Chapter] {
        let result = try await perform("getBookChapters", ["ids": bookIds])
        let books = result["getBooks"] as? [[String: Any]] ?? []
        return try books.flatMap { try decodeList(Chapter.self, from: $0["chapters"]) }
    }

    /// Get chapters by ID.
    /// - Parameter chapterIds: Chapter IDs.
    public func getChapters(_ chapterIds: [String]) async throws -> [Chapter] {
        let result = try await perform("getChaptersById", ["ids": chapterIds])
        return try decodeList(Chapter.self, from: result["getChapters"])
    }

    /// Get a single chapter by ID.
    public func getChapter(_ chapterId: String) async throws -> Chapter? {
        let result = try await perform("getChapter", ["id": chapterId])
        return try decodeList(Chapter.self, from: result["getChapters"]).first
    }

    /// Get book authors by ID.
    /// - Parameters:
    ///   - authorIds: Author IDs.
    ///   - withLikesCount: Also fetch follower counts.
    public func getBookAuthors(
        _ authorIds: [String],
        withLikesCount: Bool = false
    ) async throws -> [BookAuthor] {
        let result = try await perform("getBookAuthors", ["ids": authorIds, "withLikesCount": withLikesCount])
        return try decodeList(BookAuthor.self, from: result["getBookAuthors"])
    }

    /// Get an author's books, cursor-paginated.
    /// - Parameters:
    ///   - authorIds: Author IDs.
    ///   - limit: Page size.
    ///   - cursor: Cursor from a previous page, `nil` for the first page.
    /// - Returns: One page of the first author's books.
    public func getAuthorBooks(
        _ authorIds: [String],
        limit: Int = 100,
        cursor: String? = nil
    ) async throws -> PaginatedResult<SimpleBook> {
        var variables: [String: Any] = ["ids": authorIds, "limit": limit]
        if let cursor { variables["cursor"] = cursor }
        let result = try await perform("getCursorBooks", variables)
        let authors = result["getBookAuthors"] as? [[String: Any]] ?? []
        let page = (authors.first ?? [:])["getAuthorsCursorBooks"] as? [String: Any] ?? [:]
        return try paginated(SimpleBook.self, from: page, itemsKey: "books")
    }

    /// Get recommended audiobooks.
    /// - Parameters:
    ///   - recType: A `RecBookTypeEnum` value naming the recommendation slot.
    ///     `BOOK` is the only value the web client sends; the enum may hold
    ///     others, so this stays a `String`.
    ///   - first: How many books to fetch.
    ///   - skip: How many to skip.
    ///   - withAuthors: Also fetch recommended authors.
    public func getBooksRecommendations(
        recType: String = "BOOK",
        first: Int = 10,
        skip: Int = 0,
        withAuthors: Bool = false
    ) async throws -> [SimpleBook] {
        let result = try await perform(
            "getBooksRecommendations",
            ["first": first, "recType": recType, "skip": skip, "withAuthors": withAuthors]
        )
        return try decodeList(SimpleBook.self, from: result.value("recommendation", "books"))
    }

    /// Get books similar to the given one.
    /// - Parameters:
    ///   - bookId: Seed book ID.
    ///   - limit: How many books to return.
    public func getRelatedBooks(_ bookId: String, limit: Int = 10) async throws -> [SimpleBook] {
        let result = try await perform("getRelatedBooks", ["id": bookId, "limitBooks": limit])
        return try decodeList(SimpleBook.self, from: result["getBooks"])
    }

    /// Get authors similar to the given one.
    /// - Parameters:
    ///   - authorId: Seed author ID.
    ///   - limit: How many authors to return.
    public func getRelatedAuthors(_ authorId: String, limit: Int = 10) async throws -> [BookAuthor] {
        let result = try await perform("getRelatedAuthors", ["id": authorId, "limitAuthors": limit])
        return try decodeList(BookAuthor.self, from: result["getBookAuthors"])
    }
}
