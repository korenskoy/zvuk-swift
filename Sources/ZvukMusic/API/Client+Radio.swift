import Foundation

// Internet radio stations and recommender radio by release / playlist.
//
// The web client ships four near-identical operations (`getRadioByTrack`,
// `getRadioByArtistTracks`, `getRadioByRelease`, `getRadioByPlaylist`) that
// differ only in the value passed for `$type`. They are all served here by the
// single `getRadioByEntity` query already bundled with the package.
extension ZvukClient {
    /// Get the list of internet radio stations.
    /// - Parameters:
    ///   - limit: Number of stations to return.
    ///   - offset: Number of stations to skip.
    /// - Returns: Stations in catalogue order.
    public func getRadioStations(limit: Int = 30, offset: Int = 0) async throws -> [RadioStation] {
        let result = try await perform("getRadioStationsList", ["limit": limit, "offset": offset])
        return try decodeList(RadioStation.self, from: result["radioStations"])
    }

    /// Get specific radio stations by ID.
    /// - Parameter stationIds: Station IDs.
    public func getRadioStations(ids stationIds: [String]) async throws -> [RadioStation] {
        let result = try await perform("getRadioStation", ["ids": stationIds])
        return try decodeList(RadioStation.self, from: result["getRadioStations"])
    }

    /// Get a single radio station by ID.
    /// - Parameter stationId: Station ID.
    public func getRadioStation(_ stationId: String) async throws -> RadioStation? {
        try await getRadioStations(ids: [stationId]).first
    }

    /// Get radio (similar tracks) seeded by a release.
    /// - Parameters:
    ///   - releaseId: The release ID.
    ///   - limit: Number of tracks per page (default 25).
    ///   - cursor: Pagination cursor (default 0).
    public func getRadioByRelease(
        _ releaseId: String,
        limit: Int = 25,
        cursor: Int = 0
    ) async throws -> RadioResult {
        try await getRadioByEntity(id: releaseId, type: .release, limit: limit, cursor: cursor)
    }

    /// Get radio (similar tracks) seeded by a playlist.
    ///
    /// - Warning: The server accepts `PLAYLIST` as an entity type but, as of
    ///   web build v8.6.2, answers with an empty track list and `cursor: 0` for
    ///   every playlist tried — editorial and user-made alike. The method is
    ///   here because the API exposes it; treat an empty result as expected.
    ///
    /// - Parameters:
    ///   - playlistId: The playlist ID.
    ///   - limit: Number of tracks per page (default 25).
    ///   - cursor: Pagination cursor (default 0).
    public func getRadioByPlaylist(
        _ playlistId: String,
        limit: Int = 25,
        cursor: Int = 0
    ) async throws -> RadioResult {
        try await getRadioByEntity(id: playlistId, type: .playlist, limit: limit, cursor: cursor)
    }
}
