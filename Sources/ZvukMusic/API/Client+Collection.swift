import Foundation

// Collection reads: paginated liked tracks, followed profiles, the profile
// screen snapshot, and batch adds.
extension ZvukClient {
    /// Get liked tracks, cursor-paginated.
    ///
    /// Distinct from ``getPaginatedCollection(type:limit:cursor:orderBy:orderDirection:)``:
    /// this is the tracks-only feed the web player pages through while playing
    /// "My tracks", and it returns full track objects rather than IDs.
    /// - Parameters:
    ///   - limit: Page size.
    ///   - cursor: Cursor from a previous page, `nil` for the first page.
    public func getPaginatedCollectionTracks(
        limit: Int = 30,
        cursor: String? = nil
    ) async throws -> PaginatedResult<Track> {
        var variables: [String: Any] = ["limit": limit]
        if let cursor { variables["after"] = cursor }
        let result = try await perform("getPaginatedCollection", variables)
        let page = result.value("paginatedCollection", "tracks") as? [String: Any] ?? [:]
        return try paginated(Track.self, from: page, itemsKey: "items", pageInfoKey: "page")
    }

    /// Get profiles the user follows.
    /// - Parameter limit: Maximum number of profiles.
    public func getCollectionProfiles(limit: Int = 1000) async throws -> [SimpleProfile] {
        let result = try await perform("getPaginatedCollectionProfiles", ["limit": limit])
        let page = result.value("paginatedCollection", "profiles") as? [String: Any] ?? [:]
        return try decodeList(SimpleProfile.self, from: page["items"])
    }

    /// Get a compact snapshot of the user's collection for the profile screen.
    ///
    /// One request instead of three: liked artists (with similar-artist
    /// suggestions), liked tracks and playlists.
    /// - Parameters:
    ///   - limit: How many items per section.
    ///   - relatedArtistsLimit: How many similar artists to suggest.
    ///   - trackPreviewLimit: How many tracks to preview per playlist.
    ///   - uniqueReleases: Only use one cover per release.
    public func getProfileCollection(
        limit: Int = 10,
        relatedArtistsLimit: Int = 10,
        trackPreviewLimit: Int = 4,
        uniqueReleases: Bool = false
    ) async throws -> ProfileCollection {
        let result = try await perform("getProfileCollection", [
            "limit": limit,
            "relatedArtistsLimit": relatedArtistsLimit,
            "limitTracks": trackPreviewLimit,
            "uniqueReleases": uniqueReleases,
        ])
        let collection = result["collection"] as? [String: Any] ?? [:]
        return ProfileCollection(
            artists: try decodeList(Artist.self, from: collection["artists"]),
            tracks: try decodeList(Track.self, from: collection["tracks"]),
            playlists: try decodeList(Playlist.self, from: collection["playlists"])
        )
    }

    /// Add several items of mixed types to the collection in one request.
    ///
    /// The single-item ``addToCollection(_:type:)`` needs one round trip per
    /// item; this takes the whole batch.
    /// - Parameter items: Item ID paired with its content type.
    /// - Returns: Whether the server reported success.
    @discardableResult
    public func addItemsToCollection(_ items: [(id: String, type: CollectionItemType)]) async throws -> Bool {
        let gql = try GraphQLLoader.loadQuery("AddItemsToCollection")
        let payload = items.map { ["id": $0.id, "type": $0.type.rawValue] }
        let result = try await request.graphql(
            query: gql, operationName: "AddItemsToCollection", variables: ["items": payload])
        return result.succeeded("collection", "addItems")
    }
}
