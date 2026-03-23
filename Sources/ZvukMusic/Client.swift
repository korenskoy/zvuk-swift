import Foundation

/// Zvuk Music API client.
///
/// Provides async methods for accessing the Zvuk.com music streaming API.
///
/// Example:
/// ```swift
/// // Anonymous access (limited functionality):
/// let token = try await ZvukClient.getAnonymousToken()
/// let client = ZvukClient(token: token)
///
/// // Authorized access (full functionality):
/// // 1. Log in to zvuk.com in browser
/// // 2. Open https://zvuk.com/api/tiny/profile
/// // 3. Copy the "token" field value
/// let client = ZvukClient(token: "your_token")
/// ```
public final class ZvukClient: Sendable {
    private let request: Request
    private let token: String
    private let decoder: JSONDecoder

    /// Set a callback to receive network log entries.
    public var onNetworkLog: (@Sendable (NetworkLogEntry) -> Void)? {
        get { request.onLog }
        set { request.onLog = newValue }
    }

    /// Initialize the client.
    /// - Parameters:
    ///   - token: Authorization token.
    ///   - timeout: Request timeout in seconds.
    ///   - proxyURL: Proxy server URL.
    ///   - userAgent: User-Agent string.
    ///   - rateLimit: Maximum requests per second (nil = no limit).
    public init(
        token: String,
        timeout: TimeInterval = 10.0,
        proxyURL: String? = nil,
        userAgent: String? = nil,
        rateLimit: Int? = nil
    ) {
        self.token = token
        self.decoder = JSONDecoder()

        let throttler = rateLimit.map { Throttler(rateLimit: $0) }
        self.request = Request(
            token: token,
            timeout: timeout,
            proxyURL: proxyURL,
            userAgent: userAgent,
            throttler: throttler
        )
    }

    // MARK: - Helpers

    private func decode<T: Decodable>(_ type: T.Type, from dict: Any) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: dict)
        return try decoder.decode(T.self, from: data)
    }

    private func decodeList<T: Decodable>(_ type: T.Type, from array: Any) throws -> [T] {
        guard let arr = array as? [Any] else { return [] }
        let filtered = arr.filter { !($0 is NSNull) }
        guard !filtered.isEmpty else { return [] }
        let data = try JSONSerialization.data(withJSONObject: filtered)
        return try decoder.decode([T].self, from: data)
    }

    // MARK: - Auth & Profile

    /// Get an anonymous token (limited access: mid quality only, no likes/collection).
    public static func getAnonymousToken() async throws -> String {
        let url = URL(string: "\(APIConstants.tinyAPIURL)/profile")!
        var request = URLRequest(url: url)
        for (key, value) in APIConstants.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue(APIConstants.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let result = json["result"] as? [String: Any],
            let token = result["token"] as? String
        else {
            throw ZvukError.network(message: "Failed to get anonymous token")
        }
        return token
    }

    /// Get the current user's profile.
    public func getProfile() async throws -> Profile {
        let data = try await request.get(url: "\(APIConstants.tinyAPIURL)/profile")
        return try decode(Profile.self, from: ["result": data as Any])
    }

    /// Check if the user is authorized (not anonymous).
    public func isAuthorized() async throws -> Bool {
        let profile = try await getProfile()
        return profile.isAuthorized
    }

    // MARK: - Search

    /// Quick search with autocomplete.
    public func quickSearch(
        _ query: String,
        limit: Int = 10,
        searchSessionId: String? = nil
    ) async throws -> QuickSearch {
        let gql = try GraphQLLoader.loadQuery("quickSearch")
        var variables: [String: Any] = ["query": query, "limit": limit]
        if let searchSessionId { variables["searchSessionId"] = searchSessionId }

        let result = try await request.graphql(
            query: gql, operationName: "quickSearch", variables: variables)
        let data = result["quickSearch"] as? [String: Any] ?? [:]
        return try decode(QuickSearch.self, from: data)
    }

    /// Full-text search with filters and pagination.
    public func search(
        _ query: String,
        limit: Int = 20,
        tracks: Bool = true,
        artists: Bool = true,
        releases: Bool = true,
        playlists: Bool = true,
        podcasts: Bool = true,
        episodes: Bool = true,
        profiles: Bool = true,
        books: Bool = true,
        trackCursor: String? = nil,
        artistCursor: String? = nil,
        releaseCursor: String? = nil,
        playlistCursor: String? = nil
    ) async throws -> Search {
        let gql = try GraphQLLoader.loadQuery("search")
        var variables: [String: Any] = [
            "query": query,
            "limit": limit,
            "withTracks": tracks,
            "withArtists": artists,
            "withReleases": releases,
            "withPlaylists": playlists,
            "withPodcasts": podcasts,
            "withEpisodes": episodes,
            "withProfiles": profiles,
            "withBooks": books,
        ]
        if let trackCursor { variables["trackCursor"] = trackCursor }
        if let artistCursor { variables["artistCursor"] = artistCursor }
        if let releaseCursor { variables["releaseCursor"] = releaseCursor }
        if let playlistCursor { variables["playlistCursor"] = playlistCursor }

        let result = try await request.graphql(
            query: gql, operationName: "search", variables: variables)
        let data = result["search"] as? [String: Any] ?? [:]
        return try decode(Search.self, from: data)
    }

    // MARK: - Tracks

    /// Get tracks by ID.
    public func getTracks(_ trackIds: [String]) async throws -> [Track] {
        let gql = try GraphQLLoader.loadQuery("getTracks")
        let result = try await request.graphql(
            query: gql, operationName: "getTracks", variables: ["ids": trackIds])
        return try decodeList(Track.self, from: result["getTracks"] as Any)
    }

    /// Get a single track by ID.
    public func getTrack(_ trackId: String) async throws -> Track? {
        let tracks = try await getTracks([trackId])
        return tracks.first
    }

    /// Get full track information with optional artists and releases.
    public func getFullTrack(
        _ trackIds: [String],
        withArtists: Bool = false,
        withReleases: Bool = false
    ) async throws -> [Track] {
        let gql = try GraphQLLoader.loadQuery("getFullTrack")
        let result = try await request.graphql(
            query: gql,
            operationName: "getFullTrack",
            variables: [
                "ids": trackIds,
                "withArtists": withArtists,
                "withReleases": withReleases,
            ]
        )
        return try decodeList(Track.self, from: result["getTracks"] as Any)
    }

    /// Get streaming URLs for tracks.
    public func getStreamURLs(_ trackIds: [String]) async throws -> [Stream] {
        let gql = try GraphQLLoader.loadQuery("getStream")
        let result = try await request.graphql(
            query: gql, operationName: "getStream", variables: ["ids": trackIds])
        guard let mediaContents = result["mediaContents"] as? [[String: Any]] else { return [] }

        var streams: [Stream] = []
        for item in mediaContents {
            if let streamData = item["stream"] as? [String: Any] {
                let stream = try decode(Stream.self, from: streamData)
                streams.append(stream)
            }
        }
        return streams
    }

    /// Get streaming URL for specified quality.
    public func getStreamURL(_ trackId: String, quality: Quality = .high) async throws -> String {
        let streams = try await getStreamURLs([trackId])
        guard let stream = streams.first else {
            throw ZvukError.qualityNotAvailable(message: "Stream URLs not available")
        }
        return try stream.getURL(quality: quality)
    }

    /// Get direct (non-DRM) stream URL via Tiny API.
    public func getDirectStreamURL(
        _ trackId: String,
        quality: StreamQuality = .high
    ) async throws -> DirectStream? {
        let result = try await request.get(
            url: "\(APIConstants.tinyAPIURL)/track/stream",
            params: ["id": trackId, "quality": quality.rawValue]
        )
        guard let result, let streamURL = result["stream"] as? String else { return nil }
        return DirectStream(stream: streamURL, quality: quality.rawValue)
    }

    // MARK: - Lyrics

    /// Get lyrics for a track.
    public func getLyrics(_ trackId: String) async throws -> Lyrics? {
        let result = try await request.get(
            url: "\(APIConstants.tinyAPIURL)/lyrics",
            params: ["track_id": trackId]
        )
        guard let result, result["lyrics"] != nil else { return nil }
        return try decode(Lyrics.self, from: result)
    }

    // MARK: - Releases

    /// Get releases by ID.
    public func getReleases(_ releaseIds: [String], relatedLimit: Int = 10) async throws
        -> [Release]
    {
        let gql = try GraphQLLoader.loadQuery("getReleases")
        let result = try await request.graphql(
            query: gql,
            operationName: "getReleases",
            variables: ["ids": releaseIds, "relatedLimit": relatedLimit]
        )
        return try decodeList(Release.self, from: result["getReleases"] as Any)
    }

    /// Get a single release by ID.
    public func getRelease(_ releaseId: String) async throws -> Release? {
        let releases = try await getReleases([releaseId])
        return releases.first
    }

    // MARK: - Artists

    /// Get artists by ID with optional related data.
    public func getArtists(
        _ artistIds: [String],
        withReleases: Bool = false,
        releasesLimit: Int = 100,
        releasesOffset: Int = 0,
        withPopularTracks: Bool = false,
        tracksLimit: Int = 100,
        tracksOffset: Int = 0,
        withRelatedArtists: Bool = false,
        relatedArtistsLimit: Int = 100,
        withDescription: Bool = false
    ) async throws -> [Artist] {
        let gql = try GraphQLLoader.loadQuery("getArtists")
        let result = try await request.graphql(
            query: gql,
            operationName: "getArtists",
            variables: [
                "ids": artistIds,
                "withReleases": withReleases,
                "releasesLimit": releasesLimit,
                "releasesOffset": releasesOffset,
                "withPopTracks": withPopularTracks,
                "tracksLimit": tracksLimit,
                "tracksOffset": tracksOffset,
                "withRelatedArtists": withRelatedArtists,
                "releatedArtistsLimit": relatedArtistsLimit,  // Typo preserved from API
                "withDescription": withDescription,
            ]
        )
        return try decodeList(Artist.self, from: result["getArtists"] as Any)
    }

    /// Get a single artist by ID.
    public func getArtist(
        _ artistId: String,
        withReleases: Bool = false,
        releasesLimit: Int = 100,
        releasesOffset: Int = 0,
        withPopularTracks: Bool = false,
        tracksLimit: Int = 100,
        tracksOffset: Int = 0,
        withRelatedArtists: Bool = false,
        relatedArtistsLimit: Int = 100,
        withDescription: Bool = false
    ) async throws -> Artist? {
        let artists = try await getArtists(
            [artistId],
            withReleases: withReleases,
            releasesLimit: releasesLimit,
            releasesOffset: releasesOffset,
            withPopularTracks: withPopularTracks,
            tracksLimit: tracksLimit,
            tracksOffset: tracksOffset,
            withRelatedArtists: withRelatedArtists,
            relatedArtistsLimit: relatedArtistsLimit,
            withDescription: withDescription
        )
        return artists.first
    }

    // MARK: - Playlists

    /// Get playlists by ID.
    public func getPlaylists(_ playlistIds: [String]) async throws -> [Playlist] {
        let gql = try GraphQLLoader.loadQuery("getPlaylists")
        let result = try await request.graphql(
            query: gql, operationName: "getPlaylists", variables: ["ids": playlistIds])
        return try decodeList(Playlist.self, from: result["getPlaylists"] as Any)
    }

    /// Get a single playlist by ID with full track details.
    ///
    /// The GraphQL `getPlaylists` query only returns track IDs.
    /// This method automatically fetches full track data via `getPlaylistTracks`.
    public func getPlaylist(_ playlistId: String) async throws -> Playlist? {
        let playlists = try await getPlaylists([playlistId])
        guard var playlist = playlists.first else { return nil }

        // getPlaylists only returns track stubs (id only) — enrich with full data
        if !playlist.tracks.isEmpty {
            let fullTracks = try await getPlaylistTracks(
                playlistId, limit: playlist.tracks.count, offset: 0)
            playlist = playlist.withTracks(fullTracks)
        }
        return playlist
    }

    /// Get brief playlist information.
    public func getShortPlaylist(_ playlistIds: [String]) async throws -> [SimplePlaylist] {
        let gql = try GraphQLLoader.loadQuery("getShortPlaylist")
        let result = try await request.graphql(
            query: gql, operationName: "getShortPlaylist", variables: ["ids": playlistIds])
        return try decodeList(SimplePlaylist.self, from: result["getPlaylists"] as Any)
    }

    /// Get playlist tracks with pagination.
    public func getPlaylistTracks(
        _ playlistId: String,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> [SimpleTrack] {
        let gql = try GraphQLLoader.loadQuery("getPlaylistTracks")
        let result = try await request.graphql(
            query: gql,
            operationName: "getPlaylistTracks",
            variables: ["id": playlistId, "limit": limit, "offset": offset]
        )
        return try decodeList(SimpleTrack.self, from: result["playlistTracks"] as Any)
    }

    /// Create a playlist.
    /// - Returns: Created playlist ID.
    public func createPlaylist(_ name: String, trackIds: [String]? = nil) async throws -> String {
        let gql = try GraphQLLoader.loadQuery("createPlaylist")
        let items: [[String: String]] =
            trackIds?.map { ["type": "track", "item_id": $0] } ?? []
        let result = try await request.graphql(
            query: gql, operationName: "createPlayList", variables: ["name": name, "items": items])
        let playlist = result["playlist"] as? [String: Any] ?? [:]
        return playlist["create"] as? String ?? ""
    }

    /// Delete a playlist.
    public func deletePlaylist(_ playlistId: String) async throws -> Bool {
        let gql = try GraphQLLoader.loadQuery("deletePlaylist")
        let result = try await request.graphql(
            query: gql, operationName: "deletePlaylist", variables: ["id": playlistId])
        let playlist = result["playlist"] as? [String: Any] ?? [:]
        return playlist["delete"] != nil
    }

    /// Rename a playlist.
    public func renamePlaylist(_ playlistId: String, newName: String) async throws -> Bool {
        let gql = try GraphQLLoader.loadQuery("renamePlaylist")
        let result = try await request.graphql(
            query: gql,
            operationName: "renamePlaylist",
            variables: ["id": playlistId, "name": newName]
        )
        let playlist = result["playlist"] as? [String: Any] ?? [:]
        return playlist["rename"] != nil
    }

    /// Add tracks to a playlist.
    public func addTracksToPlaylist(_ playlistId: String, trackIds: [String]) async throws -> Bool {
        let gql = try GraphQLLoader.loadQuery("addTracksToPlaylist")
        let items = trackIds.map { ["type": "track", "item_id": $0] }
        let result = try await request.graphql(
            query: gql,
            operationName: "addTracksToPlaylist",
            variables: ["id": playlistId, "items": items]
        )
        let playlist = result["playlist"] as? [String: Any] ?? [:]
        return playlist["addItems"] != nil
    }

    /// Update a playlist entirely.
    public func updatePlaylist(
        _ playlistId: String,
        trackIds: [String],
        name: String? = nil,
        isPublic: Bool? = nil
    ) async throws -> Bool {
        let gql = try GraphQLLoader.loadQuery("updataPlaylist")
        let items = trackIds.map { ["type": "track", "item_id": $0] }
        let variables: [String: Any] = [
            "id": playlistId,
            "items": items,
            "name": name ?? "",
            "isPublic": isPublic ?? false,
        ]
        let result = try await request.graphql(
            query: gql, operationName: "updataPlaylist", variables: variables)
        let playlist = result["playlist"] as? [String: Any] ?? [:]
        return playlist["update"] != nil
    }

    /// Change playlist visibility.
    public func setPlaylistPublic(_ playlistId: String, isPublic: Bool) async throws -> Bool {
        let gql = try GraphQLLoader.loadQuery("setPlaylistToPublic")
        let result = try await request.graphql(
            query: gql,
            operationName: "setPlaylistToPublic",
            variables: ["id": playlistId, "isPublic": isPublic]
        )
        let playlist = result["playlist"] as? [String: Any] ?? [:]
        return playlist["setPublic"] != nil
    }

    /// Create an AI-generated synthesis playlist from two authors.
    public func synthesisPlaylistBuild(
        firstAuthorId: String,
        secondAuthorId: String
    ) async throws -> SynthesisPlaylist? {
        let gql = try GraphQLLoader.loadQuery("synthesisPlaylistBuild")
        let result = try await request.graphql(
            query: gql,
            operationName: "synthesisPlaylistBuild",
            variables: ["firstAuthorId": firstAuthorId, "secondAuthorId": secondAuthorId]
        )
        guard let data = result["synthesisPlaylistBuild"] as? [String: Any] else { return nil }
        return try decode(SynthesisPlaylist.self, from: data)
    }

    /// Get synthesis playlists by ID.
    public func getSynthesisPlaylists(_ ids: [String]) async throws -> [SynthesisPlaylist] {
        let gql = try GraphQLLoader.loadQuery("synthesisPlaylist")
        let result = try await request.graphql(
            query: gql, operationName: "synthesisPlaylist", variables: ["ids": ids])
        return try decodeList(SynthesisPlaylist.self, from: result["synthesisPlaylist"] as Any)
    }

    // MARK: - Editorial / Grid Content

    /// Get grid content items from Tiny API.
    public func getGridContent(
        name: String = "editorial_playlist",
        rankerEnabled: Bool = true
    ) async throws -> [GridContentItem] {
        let result = try await request.get(
            url: "\(APIConstants.tinyAPIURL)/grid/content",
            params: [
                "name": name,
                "ranker_enabled": String(rankerEnabled),
            ]
        )
        guard let result,
            let page = result["page"] as? [String: Any],
            let data = page["data"] as? [[String: Any]]
        else { return [] }
        return try decodeList(GridContentItem.self, from: data)
    }

    /// Get editorial (curated) playlist IDs.
    public func getEditorialPlaylistIds() async throws -> [String] {
        let items = try await getGridContent(name: "editorial_playlist")
        return items.filter { $0.type == "playlist" }.map(\.id)
    }

    // MARK: - Podcasts

    /// Get podcasts by ID.
    public func getPodcasts(_ podcastIds: [String]) async throws -> [Podcast] {
        let gql = try GraphQLLoader.loadQuery("getPodcasts")
        let result = try await request.graphql(
            query: gql, operationName: "getPodcasts", variables: ["ids": podcastIds])
        return try decodeList(Podcast.self, from: result["getPodcasts"] as Any)
    }

    /// Get a single podcast by ID.
    public func getPodcast(_ podcastId: String) async throws -> Podcast? {
        let podcasts = try await getPodcasts([podcastId])
        return podcasts.first
    }

    /// Get episodes by ID.
    public func getEpisodes(_ episodeIds: [String]) async throws -> [Episode] {
        let gql = try GraphQLLoader.loadQuery("getEpisodes")
        let result = try await request.graphql(
            query: gql, operationName: "getEpisodes", variables: ["ids": episodeIds])
        return try decodeList(Episode.self, from: result["getEpisodes"] as Any)
    }

    /// Get a single episode by ID.
    public func getEpisode(_ episodeId: String) async throws -> Episode? {
        let episodes = try await getEpisodes([episodeId])
        return episodes.first
    }

    // MARK: - Collection

    /// Get the user's collection of liked items.
    public func getCollection() async throws -> Collection {
        let gql = try GraphQLLoader.loadQuery("userCollection")
        let result = try await request.graphql(
            query: gql, operationName: "userCollection", variables: [:])
        let data = result["collection"] as? [String: Any] ?? [:]
        return try decode(Collection.self, from: data)
    }

    /// Get liked tracks with sorting.
    public func getLikedTracks(
        orderBy: OrderBy = .dateAdded,
        direction: OrderDirection = .desc
    ) async throws -> [Track] {
        let gql = try GraphQLLoader.loadQuery("userTracks")
        let result = try await request.graphql(
            query: gql,
            operationName: "userTracks",
            variables: ["orderBy": orderBy.rawValue, "orderDirection": direction.rawValue]
        )
        let collection = result["collection"] as? [String: Any] ?? [:]
        return try decodeList(Track.self, from: collection["tracks"] as Any)
    }

    /// Get user's playlists from collection.
    public func getUserPlaylists() async throws -> [CollectionItem] {
        let gql = try GraphQLLoader.loadQuery("userPlaylists")
        let result = try await request.graphql(
            query: gql, operationName: "userPlaylists", variables: [:])
        let collection = result["collection"] as? [String: Any] ?? [:]
        return try decodeList(CollectionItem.self, from: collection["playlists"] as Any)
    }

    /// Get user's podcasts with pagination.
    public func getUserPaginatedPodcasts(
        cursor: String? = nil,
        count: Int = 20
    ) async throws -> [String: Any] {
        let gql = try GraphQLLoader.loadQuery("userPaginatedPodcasts")
        var variables: [String: Any] = ["count": count]
        if let cursor { variables["cursor"] = cursor }
        let result = try await request.graphql(
            query: gql, operationName: "userPaginatedPodcasts", variables: variables)
        return result["paginatedCollection"] as? [String: Any] ?? [:]
    }

    /// Get paginated collection with all item types.
    ///
    /// Returns the user's liked items with cursor-based pagination.
    /// Use boolean flags to select which types to include.
    ///
    /// ```swift
    /// let collection = try await client.getPaginatedCollection(withReleases: true, limit: 10)
    /// if let releases = collection.releases {
    ///     for release in releases.items {
    ///         print("\(release.title) — \(release.artists.map(\.title).joined(separator: ", "))")
    ///     }
    ///     if releases.page.hasNextPage {
    ///         let next = try await client.getPaginatedCollection(
    ///             withReleases: true, after: releases.page.endCursor)
    ///     }
    /// }
    /// ```
    public func getPaginatedCollection(
        limit: Int = 30,
        limitTracksOnPlaylist: Int = 3,
        after: String? = nil,
        withPlaylists: Bool = false,
        withReleases: Bool = false,
        withArtists: Bool = false,
        withPodcasts: Bool = false,
        withBooks: Bool = false,
        withEpisodes: Bool = false
    ) async throws -> PaginatedCollection {
        let gql = try GraphQLLoader.loadQuery("getPaginatedCollectionAll")
        var variables: [String: Any] = [
            "limit": limit,
            "limitTracksOnPlaylist": limitTracksOnPlaylist,
            "withPlaylists": withPlaylists,
            "withReleases": withReleases,
            "withArtists": withArtists,
            "withPodcasts": withPodcasts,
            "withBooks": withBooks,
            "withEpisodes": withEpisodes,
        ]
        if let after { variables["after"] = after }

        let result = try await request.graphql(
            query: gql,
            operationName: "getPaginatedCollectionAll",
            variables: variables
        )
        let data = result["paginatedCollection"] as? [String: Any] ?? [:]
        return try decode(PaginatedCollection.self, from: data)
    }

    /// Add an item to the collection (like).
    public func addToCollection(_ itemId: String, type: CollectionItemType) async throws -> Bool {
        let gql = try GraphQLLoader.loadQuery("addItemToCollection")
        let result = try await request.graphql(
            query: gql,
            operationName: "addItemToCollection",
            variables: ["id": itemId, "type": type.rawValue]
        )
        let collection = result["collection"] as? [String: Any] ?? [:]
        return collection["addItemV1"] != nil
    }

    /// Remove an item from the collection (unlike).
    public func removeFromCollection(_ itemId: String, type: CollectionItemType) async throws
        -> Bool
    {
        let gql = try GraphQLLoader.loadQuery("removeItemFromCollection")
        let result = try await request.graphql(
            query: gql,
            operationName: "removeItemFromCollection",
            variables: ["id": itemId, "type": type.rawValue]
        )
        let collection = result["collection"] as? [String: Any] ?? [:]
        return collection["removeItem"] != nil
    }

    // MARK: - Like / Unlike shortcuts

    public func likeTrack(_ trackId: String) async throws -> Bool {
        try await addToCollection(trackId, type: .track)
    }

    public func unlikeTrack(_ trackId: String) async throws -> Bool {
        try await removeFromCollection(trackId, type: .track)
    }

    public func likeRelease(_ releaseId: String) async throws -> Bool {
        try await addToCollection(releaseId, type: .release)
    }

    public func unlikeRelease(_ releaseId: String) async throws -> Bool {
        try await removeFromCollection(releaseId, type: .release)
    }

    public func likeArtist(_ artistId: String) async throws -> Bool {
        try await addToCollection(artistId, type: .artist)
    }

    public func unlikeArtist(_ artistId: String) async throws -> Bool {
        try await removeFromCollection(artistId, type: .artist)
    }

    public func likePlaylist(_ playlistId: String) async throws -> Bool {
        try await addToCollection(playlistId, type: .playlist)
    }

    public func unlikePlaylist(_ playlistId: String) async throws -> Bool {
        try await removeFromCollection(playlistId, type: .playlist)
    }

    public func likePodcast(_ podcastId: String) async throws -> Bool {
        try await addToCollection(podcastId, type: .podcast)
    }

    public func unlikePodcast(_ podcastId: String) async throws -> Bool {
        try await removeFromCollection(podcastId, type: .podcast)
    }

    // MARK: - Hidden items

    /// Get all hidden items.
    public func getHiddenCollection() async throws -> HiddenCollection {
        let gql = try GraphQLLoader.loadQuery("getAllHiddenCollection")
        let result = try await request.graphql(
            query: gql, operationName: "getAllHiddenCollection", variables: [:])
        let data = result["hiddenCollection"] as? [String: Any] ?? [:]
        return try decode(HiddenCollection.self, from: data)
    }

    /// Get hidden tracks.
    public func getHiddenTracks() async throws -> [CollectionItem] {
        let gql = try GraphQLLoader.loadQuery("getHiddenTracks")
        let result = try await request.graphql(
            query: gql, operationName: "getHiddenTracks", variables: [:])
        let hidden = result["hiddenCollection"] as? [String: Any] ?? [:]
        return try decodeList(CollectionItem.self, from: hidden["tracks"] as Any)
    }

    /// Hide an item.
    public func addToHidden(_ itemId: String, type: CollectionItemType) async throws -> Bool {
        let gql = try GraphQLLoader.loadQuery("addItemToHidden")
        let result = try await request.graphql(
            query: gql,
            operationName: "addItemToHidden",
            variables: ["id": itemId, "type": type.rawValue]
        )
        let hidden = result["hiddenCollection"] as? [String: Any] ?? [:]
        return hidden["addItem"] != nil
    }

    /// Remove an item from hidden.
    public func removeFromHidden(_ itemId: String, type: CollectionItemType) async throws -> Bool {
        let gql = try GraphQLLoader.loadQuery("removeItemFromHidden")
        let result = try await request.graphql(
            query: gql,
            operationName: "removeItemFromHidden",
            variables: ["id": itemId, "type": type.rawValue]
        )
        let hidden = result["hiddenCollection"] as? [String: Any] ?? [:]
        return hidden["removeItem"] != nil
    }

    /// Hide a track.
    public func hideTrack(_ trackId: String) async throws -> Bool {
        try await addToHidden(trackId, type: .track)
    }

    /// Unhide a track.
    public func unhideTrack(_ trackId: String) async throws -> Bool {
        try await removeFromHidden(trackId, type: .track)
    }

    // MARK: - Profiles

    /// Get profile followers count.
    public func getProfileFollowersCount(_ profileIds: [String]) async throws -> [Int] {
        let gql = try GraphQLLoader.loadQuery("profileFollowersCount")
        let result = try await request.graphql(
            query: gql,
            operationName: "profileFollowersCount",
            variables: ["ids": profileIds]
        )
        guard let profiles = result["profiles"] as? [[String: Any]] else { return [] }
        return profiles.map { profile in
            let data = profile["collectionItemData"] as? [String: Any] ?? [:]
            return data["likesCount"] as? Int ?? 0
        }
    }

    /// Get following count for a profile.
    public func getFollowingCount(_ profileId: String) async throws -> Int {
        let gql = try GraphQLLoader.loadQuery("followingCount")
        let result = try await request.graphql(
            query: gql, operationName: "followingCount", variables: ["id": profileId])
        let follows = result["follows"] as? [String: Any] ?? [:]
        let followings = follows["followings"] as? [String: Any] ?? [:]
        return followings["count"] as? Int ?? 0
    }

    // MARK: - History

    /// Get listening history (raw).
    public func getListeningHistoryRaw() async throws -> [[String: Any]] {
        let gql = try GraphQLLoader.loadQuery("listeningHistory")
        let result = try await request.graphql(
            query: gql, operationName: "listeningHistory", variables: [:])
        return result["listeningHistory"] as? [[String: Any]] ?? []
    }

    /// Get listening history as typed entries.
    public func getListeningHistory(limit: Int = 50) async throws -> [HistoryEntry] {
        let gql = try GraphQLLoader.loadQuery("listeningHistory")
        let result = try await request.graphql(
            query: gql, operationName: "listeningHistory", variables: ["limit": limit])
        guard let items = result["listeningHistory"] as? [[String: Any]] else { return [] }

        var entries: [HistoryEntry] = []
        for item in items {
            let dttm = item["lastListeningDttm"] as? String
            guard let mediaContent = item["mediaContent"] as? [String: Any] else { continue }
            // Only handle tracks (skip episodes)
            guard mediaContent["duration"] != nil else { continue }
            do {
                let track = try decode(SimpleTrack.self, from: mediaContent)
                entries.append(HistoryEntry(track: track, lastListeningDttm: dttm))
            } catch {
                continue
            }
        }
        return entries
    }

    /// Get listened episodes.
    public func getListenedEpisodes() async throws -> [[String: Any]] {
        let gql = try GraphQLLoader.loadQuery("listenedEpisodes")
        let result = try await request.graphql(
            query: gql, operationName: "listenedEpisodes", variables: [:])
        let playState = result["getPlayState"] as? [String: Any] ?? [:]
        return playState["episodes"] as? [[String: Any]] ?? []
    }

    /// Check for unread notifications.
    public func hasUnreadNotifications() async throws -> Bool {
        let gql = try GraphQLLoader.loadQuery("notificationsHasUnread")
        let result = try await request.graphql(
            query: gql, operationName: "notificationsHasUnread", variables: [:])
        let notification = result["notification"] as? [String: Any] ?? [:]
        return notification["hasUnread"] as? Bool ?? false
    }

    /// Get notifications feed with cursor-based pagination.
    /// - Parameters:
    ///   - types: Notification types to fetch. Defaults to all types.
    ///   - cursor: Cursor for pagination (nil for first page).
    ///   - limit: Maximum number of notifications per page.
    /// - Returns: Paginated notifications feed.
    public func getNotifications(
        types: [NotificationType] = NotificationType.all,
        cursor: String? = nil,
        limit: Int = 30
    ) async throws -> NotificationsFeed {
        let gql = try GraphQLLoader.loadQuery("getNotifications")
        var variables: [String: Any] = [
            "limit": limit,
            "availableTypes": types.map(\.rawValue),
        ]
        if let cursor { variables["cursor"] = cursor }

        let result = try await request.graphql(
            query: gql, operationName: "getNotification", variables: variables)
        let notification = result["notification"] as? [String: Any] ?? [:]
        let feed = notification["paginatedNotificationsFeed"] as? [String: Any] ?? [:]
        return try decode(NotificationsFeed.self, from: feed)
    }

    // MARK: - Recommendations

    /// Get music recommendations (dynamic block).
    ///
    /// Returns personalized recommendations including artists, releases, and playlists.
    ///
    /// ```swift
    /// let recommendations = try await client.getMusicRecommendations()
    /// for page in recommendations.pages {
    ///     for item in page.items {
    ///         switch item {
    ///         case .artist(let artist):
    ///             print("Artist: \(artist.title)")
    ///         case .release(let release):
    ///             print("Release: \(release.title)")
    ///         case .playlist(let playlist):
    ///             print("Playlist: \(playlist.title) (\(playlist.trackCount) tracks)")
    ///         case .unknown:
    ///             break
    ///         }
    ///     }
    /// }
    /// ```
    public func getMusicRecommendations(
        contentType: DynamicBlockContentType = .music,
        itemTypes: [DynamicBlockItemType] = [.artist, .release, .playlist],
        pages: [Int] = [1]
    ) async throws -> DynamicBlock {
        let gql = try GraphQLLoader.loadQuery("getMusicRecommendations")
        let result = try await request.graphql(
            query: gql,
            operationName: "getMusicRecommendations",
            variables: [
                "contentType": contentType.rawValue,
                "itemType": itemTypes.map(\.rawValue),
                "pages": pages,
            ]
        )
        let data = result["dynamicBlock"] as? [String: Any] ?? [:]
        return try decode(DynamicBlock.self, from: data)
    }

    // MARK: - Wave & Radio

    /// Get personalized wave tracks.
    /// - Parameters:
    ///   - count: Number of tracks to return (default 10).
    ///   - energy: Energy level 0.0 (calm) to 1.0 (energetic). Default 0.5.
    ///   - fun: Fun level 0.0 (sad) to 1.0 (fun). Default 0.5.
    ///   - genres: Genre filters (empty = all genres).
    ///   - language: Language filter (nil = all languages).
    ///   - instrumental: If true, returns only instrumental (no vocals).
    ///   - popularity: Popularity filter (nil = default).
    public func getPersonalWave(
        count: Int = 10,
        energy: Double = 0.5,
        fun: Double = 0.5,
        genres: [WaveGenre] = [],
        language: WaveLanguage? = nil,
        instrumental: Bool = false,
        popularity: WavePopularity? = nil
    ) async throws -> [Track] {
        let gql = try GraphQLLoader.loadQuery("getPersonalWave")

        let mood = "energy:\(energy),fun:\(`fun`)"

        var options: [String: Any] = ["mood": mood]

        if !genres.isEmpty {
            options["genre"] = genres.map { ["name": $0.rawValue, "type": "LVL1"] }
        }

        if let popularity {
            options["popular"] = popularity.rawValue
        }

        if instrumental {
            options["vocal"] = 0
        } else if let language {
            options["language"] = language.rawValue
            options["vocal"] = 1
        }

        let variables: [String: Any] = [
            "waveSrc": "AMAZME",
            "first": count,
            "options": options,
        ]

        let result = try await request.graphql(
            query: gql,
            operationName: "getPersonalWave",
            variables: variables
        )
        let data = result["personalWaveContent"] as? [Any] ?? []
        return try decodeList(Track.self, from: data)
    }

    /// Get radio (similar tracks) by artist.
    /// - Parameters:
    ///   - artistId: The artist ID.
    ///   - limit: Number of tracks per page (default 25).
    ///   - cursor: Pagination cursor (default 0).
    public func getRadioByArtist(
        _ artistId: String,
        limit: Int = 25,
        cursor: Int = 0
    ) async throws -> RadioResult {
        try await getRadioByEntity(id: artistId, type: .artist, limit: limit, cursor: cursor)
    }

    /// Get radio (similar tracks) by track.
    /// - Parameters:
    ///   - trackId: The track ID.
    ///   - limit: Number of tracks per page (default 25).
    ///   - cursor: Pagination cursor (default 0).
    public func getRadioByTrack(
        _ trackId: String,
        limit: Int = 25,
        cursor: Int = 0
    ) async throws -> RadioResult {
        try await getRadioByEntity(id: trackId, type: .track, limit: limit, cursor: cursor)
    }

    private func getRadioByEntity(
        id: String,
        type: RadioEntityType,
        limit: Int,
        cursor: Int
    ) async throws -> RadioResult {
        let gql = try GraphQLLoader.loadQuery("getRadioByEntity")
        let result = try await request.graphql(
            query: gql,
            operationName: "getRadioByEntity",
            variables: [
                "id": id,
                "type": type.rawValue,
                "limit": limit,
                "cursor": cursor,
            ]
        )
        let data = result["recommenderRadio"] as? [String: Any] ?? [:]
        return try decode(RadioResult.self, from: data)
    }

    // MARK: - Subscription

    /// Get current user's subscription info.
    public func getSubscription() async throws -> SubscriptionResult {
        guard let data = try await request.get(url: "\(APIConstants.tinyAPIURL)/subscription?app=zvooq") else {
            return SubscriptionResult()
        }
        return try decode(SubscriptionResult.self, from: data)
    }

    // MARK: - Featured Info

    /// Get feature flags and user targeting info.
    public func getFeaturedInfo() async throws -> FeaturedInfo {
        guard let data = try await request.get(url: "https://zvuk.com/api/featured/info") else {
            return FeaturedInfo()
        }
        return try decode(FeaturedInfo.self, from: data)
    }

    // MARK: - Download

    /// Download a file to the specified path.
    public func download(url: String, to filePath: String) async throws {
        try await request.download(url: url, to: filePath)
    }
}
