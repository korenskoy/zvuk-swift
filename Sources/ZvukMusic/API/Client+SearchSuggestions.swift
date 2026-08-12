import Foundation

// Search suggestions and ID-only search variants.
//
// Full per-section search (tracks, artists, releases, …) already exists on
// ``ZvukClient`` via `searchTracks`, `searchArtists` and friends; the web
// client's `getSearchTracks`-style operations are the same queries under
// different names and are deliberately not duplicated here.
extension ZvukClient {
    /// Get query completions for a partially typed search string.
    /// - Parameters:
    ///   - query: What the user typed so far.
    ///   - limit: Maximum number of suggestions.
    /// - Returns: Suggested query strings, e.g. "нирвана", "нирвана лучшее".
    public func getSearchAutocomplete(_ query: String, limit: Int = 5) async throws -> [String] {
        let result = try await perform("getSearchAutocomplete", ["query": query, "limit": limit])
        return result.value("searchAutocomplete", "content") as? [String] ?? []
    }

    /// Get what other users are searching for right now.
    /// - Parameters:
    ///   - limit: Maximum number of queries.
    ///   - cursor: Cursor from a previous page, `nil` for the first page.
    ///   - explicit: Whether to include explicit results, `nil` to use the account default.
    public func getPopularSearches(
        limit: Int = 10,
        cursor: String? = nil,
        explicit: Bool? = nil
    ) async throws -> PopularSearches {
        var variables: [String: Any] = ["limit": limit]
        if let cursor { variables["cursor"] = cursor }
        if let explicit { variables["explicit"] = explicit }
        let result = try await perform("getPopularSearches", variables)
        return try decode(PopularSearches.self, from: result["popularSearches"] as? [String: Any] ?? [:])
    }

    /// Search across all content types at once, ranked by relevance.
    ///
    /// Unlike ``search(_:limit:)`` this returns a single mixed list plus the
    /// per-vertical scores the ranker used, which is what the web search page
    /// renders. The payload mixes eight entity types, so it is returned raw.
    /// - Parameters:
    ///   - query: Search string.
    ///   - limit: Maximum number of results.
    public func getBlendedSearch(_ query: String, limit: Int = 100) async throws -> AnyCodable {
        let result = try await perform("getBlendedSearch", ["query": query, "limit": limit])
        return AnyCodable(result["blendedSearch"] ?? NSNull())
    }

    /// Search for artist IDs only.
    ///
    /// Cheaper than ``searchArtists(_:limit:cursor:)`` when the caller just
    /// needs to resolve a name to an ID.
    public func searchArtistIDs(_ query: String, limit: Int = 1) async throws -> [String] {
        try await searchIDs(operation: "getSearchArtistIds", section: "artists", query: query, limit: limit)
    }

    /// Search for podcast IDs only.
    public func searchPodcastIDs(_ query: String, limit: Int = 1) async throws -> [String] {
        try await searchIDs(operation: "getSearchPodcastIds", section: "podcasts", query: query, limit: limit)
    }

    /// Search for book IDs only.
    public func searchBookIDs(_ query: String, limit: Int = 1) async throws -> [String] {
        try await searchIDs(operation: "getSearchBookIds", section: "books", query: query, limit: limit)
    }

    /// Search for book-author IDs only.
    public func searchBookAuthorIDs(_ query: String, limit: Int = 1) async throws -> [String] {
        try await searchIDs(operation: "getSearchAuthorIds", section: "bookAuthors", query: query, limit: limit)
    }

    private func searchIDs(
        operation: String,
        section: String,
        query: String,
        limit: Int
    ) async throws -> [String] {
        let result = try await perform(operation, ["query": query, "limit": limit])
        let items = result.value("search", section, "items") as? [[String: Any]] ?? []
        return items.compactMap { $0["id"] as? String }
    }
}
