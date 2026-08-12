import Foundation

// Playlist reading and the newer `V1` mutations used by the web client.
//
// The `V1` mutations return the affected playlist's ID instead of a bare
// boolean, which is what makes ``createPlaylistV1(name:trackIds:)`` preferable
// when the caller needs to navigate to the playlist it just created. The older
// ``createPlaylist(_:trackIds:)`` and friends remain available.
extension ZvukClient {
    /// Get full playlist metadata plus a preview of its covers.
    /// - Parameters:
    ///   - playlistIds: Playlist IDs.
    ///   - coverCount: How many release covers to build the collage from.
    ///   - uniqueReleases: Only use one cover per release.
    public func getPlaylistInfo(
        _ playlistIds: [String],
        coverCount: Int = 3,
        uniqueReleases: Bool = true
    ) async throws -> [Playlist] {
        let result = try await perform(
            "getPlaylistInfo",
            ["ids": playlistIds, "first": coverCount, "uniqueReleases": uniqueReleases]
        )
        return try decodeList(Playlist.self, from: result["playlists"])
    }

    /// Get playlist titles and covers, optionally with track lists.
    /// - Parameters:
    ///   - playlistIds: Playlist IDs.
    ///   - withTracks: Also fetch the tracks.
    public func getPlaylistsShortInfo(
        _ playlistIds: [String],
        withTracks: Bool = false
    ) async throws -> [Playlist] {
        let result = try await perform("getPlaylistsShortInfo", ["ids": playlistIds, "withTracks": withTracks])
        return try decodeList(Playlist.self, from: result["playlists"])
    }

    /// Get playlists similar to the given one.
    /// - Parameters:
    ///   - playlistId: Seed playlist ID.
    ///   - limit: How many playlists to return.
    public func getRelatedPlaylists(_ playlistId: String, limit: Int = 30) async throws -> [Playlist] {
        let result = try await perform("getRelatedPlaylists", ["id": playlistId, "limit": limit])
        return try decodeList(Playlist.self, from: result["relatedPlaylists"])
    }

    /// Get the current user's own playlists, cursor-paginated.
    /// - Parameters:
    ///   - limit: Page size.
    ///   - cursor: Cursor from a previous page, `nil` for the first page.
    public func getOwnPlaylists(
        limit: Int = 6,
        cursor: String? = nil
    ) async throws -> PaginatedResult<Playlist> {
        try await ownPlaylists("getUserPlaylist", limit: limit, cursor: cursor)
    }

    /// Get the current user's own playlists, titles and IDs only.
    /// - Parameters:
    ///   - limit: Page size.
    ///   - cursor: Cursor from a previous page, `nil` for the first page.
    public func getOwnPlaylistsShortInfo(
        limit: Int = 6,
        cursor: String? = nil
    ) async throws -> PaginatedResult<Playlist> {
        try await ownPlaylists("getProfilesShortPlaylistsInfo", limit: limit, cursor: cursor)
    }

    private func ownPlaylists(
        _ operation: String,
        limit: Int,
        cursor: String?
    ) async throws -> PaginatedResult<Playlist> {
        var variables: [String: Any] = ["limit": limit]
        if let cursor { variables["offset"] = cursor }
        let result = try await perform(operation, variables)
        let page = result.value("getUserPlaylists", "paginated") as? [String: Any] ?? [:]
        return try paginated(Playlist.self, from: page, itemsKey: "playlists", pageInfoKey: "page")
    }

    /// Get playlists published on someone else's profile.
    /// - Parameters:
    ///   - profileIds: Profile IDs.
    ///   - limit: Page size.
    ///   - trackPreviewLimit: How many tracks to preview per playlist.
    ///   - uniqueReleases: Only use one cover per release.
    ///   - cursor: Cursor from a previous page, `nil` for the first page.
    public func getProfilePlaylists(
        _ profileIds: [String],
        limit: Int = 1,
        trackPreviewLimit: Int = 3,
        uniqueReleases: Bool = true,
        cursor: String? = nil
    ) async throws -> PaginatedResult<Playlist> {
        var variables: [String: Any] = [
            "ids": profileIds,
            "limit": limit,
            "limitTracks": trackPreviewLimit,
            "uniqueReleases": uniqueReleases,
        ]
        if let cursor { variables["after"] = cursor }
        let result = try await perform("getPlaylistsProfile", variables)
        let profiles = result["profiles"] as? [[String: Any]] ?? []
        let page = (profiles.first ?? [:]).object("playlistsV1", "paginated")
        return try paginated(Playlist.self, from: page, itemsKey: "playlists", pageInfoKey: "page")
    }

    /// Get tracks of the first playlist on a profile.
    ///
    /// Used by the web client to preview a profile without a second round trip.
    /// - Parameters:
    ///   - profileIds: Profile IDs.
    ///   - limit: How many tracks to fetch.
    ///   - offset: How many tracks to skip.
    public func getProfileFirstPlaylistTracks(
        _ profileIds: [String],
        limit: Int = 10,
        offset: Int = 0
    ) async throws -> [Track] {
        let result = try await perform("getProfileFirstPlaylistTracks", [
            "ids": profileIds,
            "playlistTracksLimit": limit,
            "playlistTracksOffset": offset,
        ])
        let playlists = profilePlaylistDictionaries(from: result)
        return try playlists.flatMap { try decodeList(Track.self, from: $0["tracks"]) }
    }

    /// Playlists on a profile sit three objects deep, under a page wrapper.
    private func profilePlaylistDictionaries(from result: [String: Any]) -> [[String: Any]] {
        let profiles = result["profiles"] as? [[String: Any]] ?? []
        return profiles.flatMap { profile in
            profile.object("playlistsV1", "paginated")["playlists"] as? [[String: Any]] ?? []
        }
    }

    // MARK: - Mutations (V1)

    /// Create a playlist and get its ID back.
    /// - Parameters:
    ///   - name: Playlist name.
    ///   - trackIds: Tracks to seed it with.
    /// - Returns: The new playlist's ID.
    public func createPlaylistV1(name: String, trackIds: [String] = []) async throws -> String {
        let result = try await perform("createPlaylist", ["name": name, "items": Self.playlistItems(trackIds)])
        return Self.playlistId(from: result, field: "createV1")
    }

    /// Append tracks to a playlist.
    /// - Parameters:
    ///   - playlistId: Playlist ID.
    ///   - trackIds: Tracks to append.
    /// - Returns: The playlist's ID.
    @discardableResult
    public func addItemsToPlaylistV1(_ playlistId: String, trackIds: [String]) async throws -> String {
        let result = try await perform("addItems", ["id": playlistId, "items": Self.playlistItems(trackIds)])
        return Self.playlistId(from: result, field: "addItemsV1")
    }

    /// Replace a playlist's name, visibility and contents in one call.
    /// - Parameters:
    ///   - playlistId: Playlist ID.
    ///   - name: New name.
    ///   - isPublic: Whether the playlist is publicly visible.
    ///   - trackIds: The complete new track list — this replaces, not appends.
    /// - Returns: The playlist's ID.
    @discardableResult
    public func updatePlaylistV1(
        _ playlistId: String,
        name: String,
        isPublic: Bool,
        trackIds: [String] = []
    ) async throws -> String {
        let result = try await perform("updatePlaylist", [
            "id": playlistId,
            "name": name,
            "isPublic": isPublic,
            "items": Self.playlistItems(trackIds),
        ])
        return Self.playlistId(from: result, field: "updateV1")
    }

    /// Delete a playlist.
    /// - Parameter playlistId: Playlist ID.
    /// - Returns: Whether the server reported success.
    @discardableResult
    public func removePlaylist(_ playlistId: String) async throws -> Bool {
        let result = try await perform("removePlaylist", ["id": playlistId])
        return result.succeeded("playlist", "delete")
    }

    /// All three `V1` mutations answer with `{ playlist: { <field>: { id } } }`.
    private static func playlistId(from result: [String: Any], field: String) -> String {
        result.object("playlist", field)["id"] as? String ?? ""
    }
}
