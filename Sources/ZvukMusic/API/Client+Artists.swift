import Foundation

// Artist pages, discography and related artists.
extension ZvukClient {
    /// Get just the name and cover of artists.
    ///
    /// The lightest artist query available — use it to render lists without
    /// pulling discography and biography.
    /// - Parameters:
    ///   - artistIds: Artist IDs.
    ///   - withLikesCount: Also fetch how many users follow each artist.
    public func getArtistsShortInfo(
        _ artistIds: [String],
        withLikesCount: Bool = false
    ) async throws -> [Artist] {
        let result = try await perform("getArtistsShortInfo", ["ids": artistIds, "withlikesCount": withLikesCount])
        return try decodeList(Artist.self, from: result["getArtists"])
    }

    /// Get artists together with cover art of their most popular releases.
    /// - Parameters:
    ///   - artistIds: Artist IDs.
    ///   - trackImagesLimit: How many track covers to include per artist.
    public func getArtistsShortInfoWithImages(
        _ artistIds: [String],
        trackImagesLimit: Int = 2
    ) async throws -> [Artist] {
        let result = try await perform(
            "getArtistsShortInfoWithImages",
            ["ids": artistIds, "limitTracksImages": trackImagesLimit]
        )
        return try decodeList(Artist.self, from: result["getArtists"])
    }

    /// Get an artist's most popular tracks, offset-paginated.
    /// - Parameters:
    ///   - artistId: Artist ID.
    ///   - limit: Number of tracks.
    ///   - offset: Number of tracks to skip.
    public func getArtistPopularTracks(
        _ artistId: String,
        limit: Int = 10,
        offset: Int = 0
    ) async throws -> [Track] {
        let result = try await perform("getArtistPopularTracks", ["ids": [artistId], "limit": limit, "offset": offset])
        let artists = result["getArtists"] as? [[String: Any]] ?? []
        return try decodeList(Track.self, from: artists.first?["popularTracks"])
    }

    /// Get an artist's most popular tracks, cursor-paginated.
    ///
    /// Preferred over ``getArtistPopularTracks(_:limit:offset:)`` for endless
    /// scrolling: the cursor stays stable while the chart underneath changes.
    /// - Parameters:
    ///   - artistId: Artist ID.
    ///   - limit: Page size.
    ///   - cursor: Cursor from a previous page, `nil` for the first page.
    ///   - withPreview: Also fetch release dates for preview rendering.
    public func getArtistPopularTracksPage(
        _ artistId: String,
        limit: Int = 10,
        cursor: String? = nil,
        withPreview: Bool = false
    ) async throws -> PaginatedResult<Track> {
        var variables: [String: Any] = ["ids": [artistId], "limit": limit, "withPreview": withPreview]
        if let cursor { variables["cursor"] = cursor }
        let result = try await perform("getArtistCursorPopularTracks", variables)
        let artists = result["getArtists"] as? [[String: Any]] ?? []
        let page = artists.first?["getCursorPopularTracks"] as? [String: Any] ?? [:]
        return try paginated(Track.self, from: page, itemsKey: "tracks")
    }

    /// Get an artist's releases, cursor-paginated and filterable by type.
    /// - Parameters:
    ///   - artistId: Artist ID.
    ///   - limit: Page size.
    ///   - includeTypes: Keep only these release types, e.g. `["album"]`.
    ///   - excludeTypes: Drop these release types.
    ///   - cursor: Cursor from a previous page, `nil` for the first page.
    public func getArtistReleasesPage(
        _ artistId: String,
        limit: Int = 12,
        includeTypes: [String]? = nil,
        excludeTypes: [String]? = nil,
        cursor: String? = nil
    ) async throws -> PaginatedResult<Release> {
        var variables: [String: Any] = ["ids": [artistId], "limit": limit]
        if let includeTypes { variables["includeTypes"] = includeTypes }
        if let excludeTypes { variables["excludeTypes"] = excludeTypes }
        if let cursor { variables["cursor"] = cursor }
        let result = try await perform("getArtistReleases", variables)
        let artists = result["getArtists"] as? [[String: Any]] ?? []
        let page = artists.first?["releasesPage"] as? [String: Any] ?? [:]
        return try paginated(Release.self, from: page, itemsKey: "releases", pageInfoKey: "pageInfo")
    }

    /// Get an artist's albums.
    public func getArtistAlbums(
        _ artistId: String,
        limit: Int = 100,
        cursor: String? = nil
    ) async throws -> PaginatedResult<Release> {
        try await discography(
            "artistAlbumsWithProfile", section: "albums",
            artistId: artistId, limit: limit, cursor: cursor
        )
    }

    /// Get an artist's singles and EPs.
    public func getArtistSingles(
        _ artistId: String,
        limit: Int = 100,
        cursor: String? = nil
    ) async throws -> PaginatedResult<Release> {
        try await discography(
            "artistSinglesWithProfile", section: "singles",
            artistId: artistId, limit: limit, cursor: cursor
        )
    }

    /// Get compilations the artist appears on.
    public func getArtistCompilations(
        _ artistId: String,
        limit: Int = 100,
        cursor: String? = nil
    ) async throws -> PaginatedResult<Release> {
        try await discography(
            "artistCompilationsWithProfile", section: "compilations",
            artistId: artistId, limit: limit, cursor: cursor
        )
    }

    /// Get an artist's full discography, unfiltered.
    public func getArtistDiscography(
        _ artistId: String,
        limit: Int = 100,
        cursor: String? = nil
    ) async throws -> PaginatedResult<Release> {
        try await discography(
            "artistReleasesWithProfile", section: "releases",
            artistId: artistId, limit: limit, cursor: cursor
        )
    }

    private func discography(
        _ operation: String,
        section: String,
        artistId: String,
        limit: Int,
        cursor: String?
    ) async throws -> PaginatedResult<Release> {
        var variables: [String: Any] = ["ids": [artistId], "limit": limit]
        if let cursor { variables["cursor"] = cursor }
        let result = try await perform(operation, variables)
        let artists = result["getArtists"] as? [[String: Any]] ?? []
        let bucket = (artists.first ?? [:]).object("discography", section)
        return try paginated(Release.self, from: bucket, itemsKey: "releases")
    }

    /// Get artists similar to the given one, with their popular tracks.
    /// - Parameters:
    ///   - artistId: Seed artist ID.
    ///   - limit: How many similar artists to return.
    ///   - popularTracksLimit: How many popular tracks to include per artist.
    ///   - withPopularTracks: Set to `false` to skip track fetching entirely.
    public func getRelatedArtists(
        _ artistId: String,
        limit: Int = 10,
        popularTracksLimit: Int = 5,
        withPopularTracks: Bool = true
    ) async throws -> [Artist] {
        let result = try await perform("getRelatedArtists", [
            "id": artistId,
            "limitArtists": limit,
            "withPopularTrackArtist": withPopularTracks,
            "limitPopularTracks": popularTracksLimit,
        ])
        return try decodeList(Artist.self, from: result["relatedArtists"])
    }

    /// Get artists similar to the given one, names and covers only.
    /// - Parameters:
    ///   - artistId: Seed artist ID.
    ///   - limit: How many similar artists to return.
    public func getRelatedArtistsSimple(_ artistId: String, limit: Int = 10) async throws -> [Artist] {
        let result = try await perform("getRelatedArtistsSimple", ["id": artistId, "limitArtists": limit])
        return try decodeList(Artist.self, from: result["relatedArtists"])
    }

    /// Get everything the web artist page shows, in one request.
    ///
    /// A wider alternative to ``getArtists(_:withReleases:releasesLimit:releasesOffset:withPopularTracks:tracksLimit:tracksOffset:withRelatedArtists:relatedArtistsLimit:withDescription:)``:
    /// it also returns follower counts and popular releases.
    /// - Parameters:
    ///   - artistIds: Artist IDs.
    ///   - withLikesCount: Include follower counts.
    ///   - withRelatedArtists: Include similar artists.
    ///   - withPopularTracks: Include popular tracks.
    ///   - withPopularReleases: Include popular releases.
    public func getArtistPage(
        _ artistIds: [String],
        withLikesCount: Bool = false,
        withRelatedArtists: Bool = false,
        withPopularTracks: Bool = false,
        withPopularReleases: Bool = false
    ) async throws -> [Artist] {
        let result = try await perform("artist", [
            "ids": artistIds,
            "withlikesCount": withLikesCount,
            "withRelatedArtists": withRelatedArtists,
            "withPopularTracks": withPopularTracks,
            "withPopularReleases": withPopularReleases,
        ])
        return try decodeList(Artist.self, from: result["getArtists"])
    }
}
