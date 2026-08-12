import Foundation

// Podcasts: episodes, categories, recommendations and related shows.
extension ZvukClient {
    /// Get every episode of the given podcasts.
    /// - Parameter podcastIds: Podcast IDs.
    /// - Returns: Episodes, flattened across all podcasts.
    public func getPodcastEpisodes(_ podcastIds: [String]) async throws -> [Episode] {
        let result = try await perform("getPodcastEpisodes", ["ids": podcastIds])
        let podcasts = result["getPodcasts"] as? [[String: Any]] ?? []
        return try podcasts.flatMap { try decodeList(Episode.self, from: $0["episodes"]) }
    }

    /// Get episodes of one podcast, cursor-paginated.
    /// - Parameters:
    ///   - podcastId: Podcast ID.
    ///   - limit: Page size.
    ///   - cursor: Cursor from a previous page, `nil` for the first page.
    ///   - order: Sort order, newest first by default.
    public func getPaginatedEpisodes(
        _ podcastId: String,
        limit: Int = 30,
        cursor: String? = nil,
        order: EpisodeOrder = .newest
    ) async throws -> PaginatedResult<Episode> {
        var variables: [String: Any] = ["ids": podcastId, "limit": limit, "order": order.rawValue]
        if let cursor { variables["cursor"] = cursor }
        let result = try await perform("getPaginatedEpisodes", variables)
        let page = result["getPaginatedEpisodes"] as? [String: Any] ?? [:]
        return try paginated(Episode.self, from: page, itemsKey: "episodes", pageInfoKey: "pageInfo")
    }

    /// Get podcasts belonging to the given catalogue categories.
    /// - Parameters:
    ///   - categoryIds: Category IDs.
    ///   - first: Page size from the start.
    ///   - last: Page size from the end.
    ///   - startCursor: Cursor to page forward from.
    ///   - endCursor: Cursor to page backward from.
    ///   - sortBy: A `SortByEnum` value, passed through unchanged.
    public func getPodcastsByCategory(
        _ categoryIds: [String],
        first: Int? = nil,
        last: Int? = nil,
        startCursor: String? = nil,
        endCursor: String? = nil,
        sortBy: String? = nil
    ) async throws -> [Podcast] {
        var variables: [String: Any] = ["ids": categoryIds]
        if let first { variables["first"] = first }
        if let last { variables["last"] = last }
        if let startCursor { variables["startCursor"] = startCursor }
        if let endCursor { variables["endCursor"] = endCursor }
        if let sortBy { variables["sortBy"] = sortBy }
        let result = try await perform("getPodcastsByCategoryIds", variables)
        return try decodeList(Podcast.self, from: result.value("getPodcastsByCategoryIds", "items"))
    }

    /// Get recommended podcasts.
    /// - Parameters:
    ///   - recType: A `RecPodcastTypeEnum` value naming the recommendation slot.
    ///     `PODCAST` is the only value the web client sends; the enum may hold
    ///     others, so this stays a `String`.
    ///   - first: How many podcasts to fetch.
    ///   - skip: How many to skip.
    public func getPodcastsRecommendations(
        recType: String = "PODCAST",
        first: Int = 10,
        skip: Int = 0
    ) async throws -> [Podcast] {
        let result = try await perform("getPodcastsRecommendations", ["first": first, "recType": recType, "skip": skip])
        return try decodeList(Podcast.self, from: result.value("recommendation", "podcasts"))
    }

    /// Get podcast metadata without episode lists.
    /// - Parameter podcastIds: Podcast IDs.
    public func getPodcastsShortInfo(_ podcastIds: [String]) async throws -> [Podcast] {
        let result = try await perform("getCommonPodcasts", ["ids": podcastIds])
        return try decodeList(Podcast.self, from: result["getPodcasts"])
    }

    /// Get podcasts similar to the given one.
    /// - Parameters:
    ///   - podcastId: Seed podcast ID.
    ///   - limit: How many podcasts to return.
    public func getRelatedPodcasts(_ podcastId: String, limit: Int = 10) async throws -> [Podcast] {
        let result = try await perform("getRelatedPodcasts", ["id": podcastId, "limitPodcasts": limit])
        return try decodeList(Podcast.self, from: result["relatedPodcasts"])
    }
}
