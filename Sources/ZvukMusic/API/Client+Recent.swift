import Foundation

// "Recently played" feed and cheap collection counters.
extension ZvukClient {
    /// Get recently played entities.
    ///
    /// Returns albums, playlists, artists, waves and radio stations the user
    /// opened — not individual tracks. For a track-level history use
    /// ``getListeningHistory(limit:)``.
    ///
    /// - Parameters:
    ///   - limit: Maximum number of entries (default 30).
    ///   - offset: Number of entries to skip.
    ///   - itemTypes: Restrict to these entity types, `nil` for all.
    ///   - isKidContent: Restrict to (or exclude) kids content, `nil` for no filter.
    public func getRecentlyPlayed(
        limit: Int = 30,
        offset: Int = 0,
        itemTypes: [RecentItemType]? = nil,
        isKidContent: Bool? = nil
    ) async throws -> [RecentItem] {
        let gql = try GraphQLLoader.loadQuery("getListeningRecent")
        var variables: [String: Any] = ["limit": limit, "offset": offset]
        if let itemTypes { variables["itemType"] = itemTypes.map(\.rawValue) }
        if let isKidContent { variables["isKidContent"] = isKidContent }
        let result = try await request.graphql(
            query: gql,
            operationName: "getListeningRecent",
            variables: variables
        )
        return try decodeList(RecentItem.self, from: result["listeningRecentV1"])
    }

    /// Get the number of tracks in the user's collection.
    ///
    /// Much cheaper than fetching the collection itself.
    public func getCollectionTracksCount() async throws -> Int {
        let result = try await perform("getCollectionCount")
        return result.value("collectionCount", "tracks") as? Int ?? 0
    }

    /// Get IDs of every item in the user's collection, grouped by content type.
    public func getCollectionIDs() async throws -> CollectionIDs {
        let result = try await perform("getCollectionIds")
        return try decode(CollectionIDs.self, from: result["collection"] as? [String: Any] ?? [:])
    }

    /// Get IDs of the user's own playlists.
    public func getOwnPlaylistIDs() async throws -> [String] {
        let result = try await perform("getPlaylistIds")
        let playlists = result.value("collection", "playlists") as? [[String: Any]] ?? []
        return playlists.compactMap { $0["id"] as? String }
    }

    /// Get how many users liked each of the given artists.
    /// - Parameter artistIds: Artist IDs.
    /// - Returns: Like counts in the same order as `artistIds`.
    public func getArtistLikesCount(_ artistIds: [String]) async throws -> [Int] {
        let result = try await perform("getLikesCount", ["ids": artistIds])
        let artists = result["getArtists"] as? [[String: Any]] ?? []
        return artists.map { artist in
            let data = artist["collectionItemData"] as? [String: Any] ?? [:]
            return data["likesCount"] as? Int ?? 0
        }
    }

    /// Get the current user's subscriptions.
    /// - Parameter statuses: Restrict to these statuses, `nil` for all.
    public func getSubscriptions(statuses: [String]? = nil) async throws -> UserSubscriptions {
        var variables: [String: Any] = [:]
        if let statuses { variables["status"] = statuses }
        let result = try await perform("getSubscriptions", variables)
        return try decode(UserSubscriptions.self, from: result["subscriptions"] as? [String: Any] ?? [:])
    }

    /// Get the number of unread notifications.
    /// - Parameter types: Restrict to these notification types, `nil` for all.
    public func getUnreadNotificationsCount(types: [NotificationType]? = nil) async throws -> Int {
        var variables: [String: Any] = [:]
        if let types { variables["availableTypes"] = types.map(\.rawValue) }
        let result = try await perform("getUnreadNotificationsCount", variables)
        return result.value("notification", "unreadCount") as? Int ?? 0
    }

    /// Get the total number of notifications of the given types.
    /// - Parameter types: Restrict to these notification types, `nil` for all.
    public func getNotificationsCount(types: [NotificationType]? = nil) async throws -> Int {
        var variables: [String: Any] = [:]
        if let types { variables["availableTypes"] = types.map(\.rawValue) }
        let result = try await perform("getNotificationsCount", variables)
        let typesCount = result.value("notification", "typesCount") as? [String: Any] ?? [:]
        return typesCount["count"] as? Int ?? 0
    }

    /// Get the number of pages in the home screen dynamic block.
    public func getDynamicBlockPagesCount() async throws -> Int {
        let result = try await perform("getDynamicBlockPagesCount")
        return result.value("dynamicBlock", "totalPages") as? Int ?? 0
    }

    /// Get listening statistics published on the given profiles.
    ///
    /// The shape of `statistics.data` varies by period, so it is returned as
    /// raw JSON.
    /// - Parameter profileIds: Profile IDs.
    public func getProfileListeningStatistics(_ profileIds: [String]) async throws -> [String: AnyCodable] {
        let result = try await perform("getMostListenedTrack", ["ids": profileIds])
        let profiles = result["profiles"] as? [[String: Any]] ?? []
        var byProfile: [String: AnyCodable] = [:]
        for profile in profiles {
            guard let id = profile["id"] as? String else { continue }
            byProfile[id] = AnyCodable(profile["userStatistics"] ?? NSNull())
        }
        return byProfile
    }
}
