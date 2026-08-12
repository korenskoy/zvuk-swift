import Foundation

// Releases and tracks: related content, light-weight variants, stream previews.
extension ZvukClient {
    /// Get releases similar to the given ones.
    /// - Parameters:
    ///   - releaseIds: Seed release IDs.
    ///   - limit: How many similar releases per seed.
    /// - Returns: Similar releases, flattened across all seeds.
    public func getRelatedReleases(_ releaseIds: [String], limit: Int = 100) async throws -> [Release] {
        let result = try await perform("getRelatedReleases", ["ids": releaseIds, "limit": limit])
        let releases = result["getReleases"] as? [[String: Any]] ?? []
        return try releases.flatMap { try decodeList(Release.self, from: $0["related"]) }
    }

    /// Get the track list of releases without the rest of the release metadata.
    /// - Parameter releaseIds: Release IDs.
    /// - Returns: Tracks, flattened across all releases.
    public func getReleasesTracks(_ releaseIds: [String]) async throws -> [Track] {
        let result = try await perform("getReleasesTracks", ["ids": releaseIds])
        let releases = result["getReleases"] as? [[String: Any]] ?? []
        return try releases.flatMap { try decodeList(Track.self, from: $0["tracks"]) }
    }

    /// Get title, type and cover of releases without their track lists.
    /// - Parameters:
    ///   - releaseIds: Release IDs.
    ///   - withArtists: Also fetch the artists of each release.
    public func getReleasesShortInfo(
        _ releaseIds: [String],
        withArtists: Bool = false
    ) async throws -> [Release] {
        let result = try await perform("getShortsReleasesInfo", ["ids": releaseIds, "withArtists": withArtists])
        return try decodeList(Release.self, from: result["getReleases"])
    }

    /// Get tracks with the same field set the web player uses.
    ///
    /// Lighter than ``getTracks(_:)`` — no lyrics body, no release credits.
    /// - Parameter trackIds: Track IDs.
    public func getTracksShortInfo(_ trackIds: [String]) async throws -> [Track] {
        let result = try await perform("getShortsTracksInfo", ["ids": trackIds])
        return try decodeList(Track.self, from: result["getTracks"])
    }

    /// Get minimal track info: title, duration, artists and release.
    /// - Parameter trackIds: Track IDs.
    public func getTracksMinimalInfo(_ trackIds: [String]) async throws -> [Track] {
        let result = try await perform("getNotFoundPageTrackInfo", ["ids": trackIds])
        return try decodeList(Track.self, from: result["getTracks"])
    }

    /// Get short preview stream URLs for tracks.
    ///
    /// Previews play without a subscription, which makes them useful for
    /// unauthorized browsing. For full playback use ``getStreamURL(_:quality:)``.
    /// - Parameters:
    ///   - trackIds: Track IDs.
    ///   - quality: Optional quality hint, passed through unchanged.
    ///   - encodeType: Optional encoding hint, passed through unchanged.
    /// - Returns: Preview URL per track ID; tracks without a preview are absent.
    public func getTrackStreamPreviews(
        _ trackIds: [String],
        quality: String? = nil,
        encodeType: String? = nil
    ) async throws -> [String: String] {
        var variables: [String: Any] = ["ids": trackIds]
        if let quality { variables["quality"] = quality }
        if let encodeType { variables["encodeType"] = encodeType }
        let result = try await perform("getTrackStreamPreview", variables)
        let contents = result["mediaContents"] as? [[String: Any]] ?? []
        var previews: [String: String] = [:]
        for track in contents {
            // Сопоставляем по id, а не по позиции: недоступные треки сервер
            // молча пропускает, и порядок перестаёт совпадать с запрошенным.
            guard let id = track["id"] as? String,
                let preview = track.value("stream", "preview") as? String
            else { continue }
            previews[id] = preview
        }
        return previews
    }
}
