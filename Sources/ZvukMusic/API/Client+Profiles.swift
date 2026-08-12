import Foundation

// Other users' profiles, follow graph and account-level settings.
extension ZvukClient {
    /// Get profiles by ID.
    /// - Parameters:
    ///   - profileIds: Profile IDs.
    ///   - withPlaylists: Also fetch the profile's playlists.
    ///   - playlistCount: How many playlists to fetch.
    ///   - playlistTracksLimit: How many tracks to preview per playlist.
    ///   - playlistTracksOffset: How many tracks to skip per playlist.
    public func getProfiles(
        _ profileIds: [String],
        withPlaylists: Bool = false,
        playlistCount: Int = 0,
        playlistTracksLimit: Int = 10,
        playlistTracksOffset: Int = 0
    ) async throws -> [SimpleProfile] {
        let result = try await perform("getProfiles", [
            "ids": profileIds,
            "withPlaylists": withPlaylists,
            "countPlaylists": playlistCount,
            "playlistTracksLimit": playlistTracksLimit,
            "playlistTracksOffset": playlistTracksOffset,
        ])
        return try decodeList(SimpleProfile.self, from: result["profiles"])
    }

    /// Get just a profile's avatar.
    /// - Parameter profileId: Profile ID.
    public func getProfileImage(_ profileId: String) async throws -> Image? {
        let result = try await perform("getProfileImage", ["id": profileId])
        let profiles = result["profiles"] as? [[String: Any]] ?? []
        guard let image = profiles.first?["image"] as? [String: Any] else { return nil }
        return try decode(Image.self, from: image)
    }

    /// Get podcasts a profile has in its collection.
    /// - Parameters:
    ///   - profileIds: Profile IDs.
    ///   - limit: Page size.
    ///   - cursor: Cursor from a previous page, `nil` for the first page.
    ///   - withTotal: Also fetch the total count.
    public func getProfilePodcasts(
        _ profileIds: [String],
        limit: Int = 30,
        cursor: String? = nil,
        withTotal: Bool = false
    ) async throws -> PaginatedResult<Podcast> {
        var variables: [String: Any] = ["ids": profileIds, "limit": limit, "withTotal": withTotal]
        if let cursor { variables["cursor"] = cursor }
        let result = try await perform("getProfilePodcasts", variables)
        let profiles = result["profiles"] as? [[String: Any]] ?? []
        let page = (profiles.first ?? [:]).object("paginatedCollection", "podcasts")
        return try paginated(Podcast.self, from: page, itemsKey: "items", pageInfoKey: "page")
    }

    /// Get profiles with similar taste.
    /// - Parameters:
    ///   - profileIds: Seed profile IDs.
    ///   - limit: How many profiles to return.
    public func getRelatedProfiles(_ profileIds: [String], limit: Int = 12) async throws -> [SimpleProfile] {
        let result = try await perform("getProfileRelated", ["ids": profileIds, "limit": limit])
        return try decodeList(SimpleProfile.self, from: result["profiles"])
    }

    /// Get followers of a profile, artist or other followable entity.
    /// - Parameters:
    ///   - id: Entity ID.
    ///   - itemType: A `FollowItemType` value, `profile` by default.
    ///   - limit: Page size.
    ///   - cursor: Cursor from a previous page, `nil` for the first page.
    public func getFollowers(
        _ id: String,
        itemType: String = "profile",
        limit: Int = 100,
        cursor: String? = nil
    ) async throws -> PaginatedResult<SimpleProfile> {
        var variables: [String: Any] = ["id": id, "itemType": itemType, "followersLimit": limit]
        if let cursor { variables["cursor"] = cursor }
        let result = try await perform("followers", variables)
        let page = result.object("follows", "followers")
        return try paginated(SimpleProfile.self, from: page, itemsKey: "items", pageInfoKey: "page")
    }

    /// Get profiles that the given profiles follow.
    /// - Parameters:
    ///   - profileIds: Profile IDs.
    ///   - limit: Page size.
    ///   - cursor: Cursor from a previous page, `nil` for the first page.
    public func getFollowing(
        _ profileIds: [String],
        limit: Int = 30,
        cursor: String? = nil
    ) async throws -> PaginatedResult<SimpleProfile> {
        var variables: [String: Any] = ["id": profileIds, "followingLimit": limit]
        if let cursor { variables["cursor"] = cursor }
        let result = try await perform("following", variables)
        let profiles = result["profiles"] as? [[String: Any]] ?? []
        let page = (profiles.first ?? [:]).object("paginatedCollection", "profiles")
        return try paginated(SimpleProfile.self, from: page, itemsKey: "items", pageInfoKey: "page")
    }

    /// Update the current user's public profile.
    /// - Parameters:
    ///   - name: New display name, `nil` to leave unchanged.
    ///   - description: New bio, `nil` to leave unchanged.
    /// - Returns: Whether the server reported success.
    @discardableResult
    public func setProfileSettings(name: String? = nil, description: String? = nil) async throws -> Bool {
        var variables: [String: Any] = [:]
        if let name { variables["name"] = name }
        if let description { variables["description"] = description }
        let result = try await perform("setProfileSettings", variables)
        return result.value("profile", "update") != nil
    }

    /// Get the active recommendation campaign for this account.
    ///
    /// Drives the onboarding flow that asks new users to pick favourite
    /// artists. Shape varies by campaign, so it is returned raw.
    public func getRecommendationProfile() async throws -> AnyCodable {
        let result = try await perform("getRecommendationProfile")
        return AnyCodable(result["recommendationProfile"] ?? NSNull())
    }

    /// Submit the artists chosen during recommender onboarding.
    /// - Parameter artistIds: Artist IDs the user picked.
    /// - Returns: Whether the server reported success.
    @discardableResult
    public func submitRecommenderOnboarding(_ artistIds: [String]) async throws -> Bool {
        let result = try await perform("RecommenderOnboardingRequest", ["ids": artistIds])
        return result.value("recommenderOnboarding", "chooseOnboarding") != nil
    }

    /// Start importing playlists from another streaming service.
    /// - Parameter links: Public playlist URLs to import.
    /// - Returns: Raw migration descriptor, including the IDs to poll with
    ///   ``getMigrationStatus(_:)``.
    public func createMigration(links: [String]) async throws -> AnyCodable {
        let result = try await perform("createMigration", ["links": links])
        return AnyCodable(result.value("migration", "createMigration") ?? NSNull())
    }

    /// Check how far along a playlist import is.
    /// - Parameter migrationIds: IDs returned by ``createMigration(links:)``.
    public func getMigrationStatus(_ migrationIds: [Int]) async throws -> AnyCodable {
        let result = try await perform("migrationStatus", ["migrationIds": migrationIds])
        return AnyCodable(result.value("migration", "migrationStatus") ?? NSNull())
    }
}
