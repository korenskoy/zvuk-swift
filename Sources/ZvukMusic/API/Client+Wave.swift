import Foundation

// Editorial and personal waves.
extension ZvukClient {
    /// Get short info about waves by ID.
    ///
    /// Wave IDs are stable and small: `1` is "МегаХит", for example. IDs also
    /// appear in ``RecentItem`` entries of type ``RecentItemType/editorialWave``.
    /// - Parameter waveIds: Wave IDs.
    public func getWaves(_ waveIds: [String]) async throws -> [WaveInfo] {
        let result = try await perform("getWavesShortInfo", ["ids": waveIds])
        return try decodeList(WaveInfo.self, from: result.value("wave", "waves"))
    }

    /// Get a single wave by ID.
    public func getWave(_ waveId: String) async throws -> WaveInfo? {
        try await getWaves([waveId]).first
    }

    /// Get the next batch of content for a wave.
    ///
    /// The server picks the items; `localtime` is required and influences the
    /// selection (morning and evening waves differ).
    /// - Parameters:
    ///   - waveId: Wave ID, see ``getWaves(_:)``.
    ///   - localtime: The listener's local time, defaults to now.
    public func getWaveContent(
        waveId: String,
        localtime: Date = Date()
    ) async throws -> [WaveContentItem] {
        let result = try await perform("waveContent", [
            "contentInput": [
            "waveId": waveId,
            "localtime": localtime.ISO8601Format(),
            ]
        ])
        return try decodeList(WaveContentItem.self, from: result.value("wave", "waveContent"))
    }

    /// Get content of a kids wave.
    /// - Parameters:
    ///   - waveId: Wave ID.
    ///   - localtime: The listener's local time, defaults to now.
    ///   - waveSource: Optional `WaveSource` value, passed through unchanged.
    public func getKidsWaveContent(
        waveId: String,
        localtime: Date = Date(),
        waveSource: String? = nil
    ) async throws -> [Track] {
        let gql = try GraphQLLoader.loadQuery("kidsWaveContent")
        var variables: [String: Any] = [
            "contentInput": [
                "waveId": waveId,
                "localtime": localtime.ISO8601Format(),
            ]
        ]
        if let waveSource { variables["waveSrc"] = waveSource }
        let result = try await request.graphql(
            query: gql, operationName: "kidsWaveContent", variables: variables)
        return try decodeList(Track.self, from: result["kidsWaveContent"])
    }

    /// Get tracks of a personal-wave cluster.
    ///
    /// Clusters group the personal wave by mood/genre; the web player uses them
    /// to preview what a cluster sounds like before switching to it.
    /// - Parameters:
    ///   - clusterId: Cluster number.
    ///   - first: How many tracks to fetch.
    ///   - localtime: The listener's local time, defaults to now.
    public func getClusterWaveContent(
        clusterId: Int,
        first: Int = 1,
        localtime: Date = Date()
    ) async throws -> [Track] {
        let result = try await perform("getClusterWaveContentShortInfo", [
            "clusterId": clusterId,
            "first": first,
            "contentInput": ["localtime": localtime.ISO8601Format()],
        ])
        return try decodeList(Track.self, from: result["byClusterWaveContent"])
    }
}
