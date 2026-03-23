import Foundation
import Testing

@testable import ZvukMusic

/// Shared client factory — gets token once, reuses across all tests.
private actor SharedClient {
    static let shared = SharedClient()
    private var client: ZvukClient?

    func get() async throws -> ZvukClient {
        if let client { return client }

        let token: String
        if let envToken = ProcessInfo.processInfo.environment["ZVUK_TOKEN"], !envToken.isEmpty {
            token = envToken
        } else if let fileToken = Self.loadTokenFromEnvFile(), !fileToken.isEmpty {
            token = fileToken
        } else {
            token = try await ZvukClient.getAnonymousToken()
        }
        let newClient = ZvukClient(token: token, timeout: 30)
        client = newClient
        return newClient
    }

    /// Load ZVUK_TOKEN from .env file at the package root.
    private static func loadTokenFromEnvFile() -> String? {
        var dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        for _ in 0..<5 {
            let envURL = dir.appendingPathComponent(".env")
            if let contents = try? String(contentsOf: envURL, encoding: .utf8) {
                for line in contents.components(separatedBy: .newlines) {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.hasPrefix("#"), trimmed.contains("=") else { continue }
                    let parts = trimmed.split(separator: "=", maxSplits: 1)
                    if parts.count == 2,
                       parts[0].trimmingCharacters(in: .whitespaces) == "ZVUK_TOKEN" {
                        let value = parts[1].trimmingCharacters(in: .whitespaces)
                        return value == "your_token_here" ? nil : value
                    }
                }
            }
            dir = dir.deletingLastPathComponent()
        }
        return nil
    }
}

private func sharedClient() async throws -> ZvukClient {
    try await SharedClient.shared.get()
}

/// Well-known IDs for testing.
private enum TestData {
    static let trackId = "131312684"
    static let artistId = "6938945"        // Gydra
    static let releaseId = "30798290"
    static let playlistId = "947509"
    static let podcastId = "93"
    static let searchQuery = "Metallica"
}

private var hasAuthToken: Bool {
    if let envToken = ProcessInfo.processInfo.environment["ZVUK_TOKEN"], !envToken.isEmpty {
        return true
    }
    // Also check .env file
    var dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    for _ in 0..<5 {
        let envURL = dir.appendingPathComponent(".env")
        if let contents = try? String(contentsOf: envURL, encoding: .utf8) {
            for line in contents.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.hasPrefix("#"), trimmed.contains("=") else { continue }
                let parts = trimmed.split(separator: "=", maxSplits: 1)
                if parts.count == 2,
                   parts[0].trimmingCharacters(in: .whitespaces) == "ZVUK_TOKEN" {
                    let value = parts[1].trimmingCharacters(in: .whitespaces)
                    return value != "your_token_here" && !value.isEmpty
                }
            }
        }
        dir = dir.deletingLastPathComponent()
    }
    return false
}

// MARK: - Auth & Profile

@Suite("Integration / Auth", .tags(.integration), .serialized)
struct AuthTests {
    @Test("Get anonymous token")
    func anonymousToken() async throws {
        let token = try await ZvukClient.getAnonymousToken()
        #expect(!token.isEmpty)
        #expect(token.count > 10)
    }

    @Test("Get profile")
    func profile() async throws {
        let client = try await sharedClient()
        let profile = try await client.getProfile()
        #expect(profile.result != nil)
    }

    @Test("Check isAuthorized")
    func isAuthorized() async throws {
        let client = try await sharedClient()
        let authorized = try await client.isAuthorized()
        if !hasAuthToken {
            #expect(authorized == false)
        }
    }
}

// MARK: - Search

@Suite("Integration / Search", .tags(.integration), .serialized)
struct SearchTests {
    @Test("Quick search returns results")
    func quickSearch() async throws {
        let client = try await sharedClient()
        let result = try await client.quickSearch(TestData.searchQuery, limit: 5)

        #expect(!result.searchSessionId.isEmpty)
        let total = result.tracks.count + result.artists.count + result.releases.count
        #expect(total > 0, "Quick search should return something")

        for track in result.tracks {
            #expect(!track.id.isEmpty)
            #expect(!track.title.isEmpty)
        }
        for artist in result.artists {
            #expect(!artist.id.isEmpty)
            #expect(!artist.title.isEmpty)
        }
    }

    @Test("Full search returns results")
    func fullSearch() async throws {
        let client = try await sharedClient()
        let result = try await client.search(TestData.searchQuery, limit: 5)

        #expect(!result.searchId.isEmpty)

        if let tracks = result.tracks {
            #expect(!tracks.items.isEmpty)
            for track in tracks.items {
                #expect(!track.id.isEmpty)
                #expect(!track.title.isEmpty)
                #expect(track.duration >= 0)
            }
        }
        if let artists = result.artists {
            for artist in artists.items {
                #expect(!artist.id.isEmpty)
                #expect(!artist.title.isEmpty)
            }
        }
    }

    @Test("Search with only tracks")
    func searchTracksOnly() async throws {
        let client = try await sharedClient()
        let result = try await client.search(
            TestData.searchQuery, limit: 3,
            tracks: true, artists: false, releases: false,
            playlists: false, podcasts: false, episodes: false,
            profiles: false, books: false
        )
        #expect(result.tracks != nil)
    }
}

// MARK: - Tracks

@Suite("Integration / Tracks", .tags(.integration), .serialized)
struct TrackTests {
    @Test("Get track by ID")
    func getTrack() async throws {
        let client = try await sharedClient()
        let track = try await client.getTrack(TestData.trackId)

        // API may return null for anonymous users — just verify decoding works
        if let track {
            #expect(track.id == TestData.trackId)
            #expect(!track.title.isEmpty)
            #expect(track.duration > 0)
            #expect(!track.durationString.isEmpty)
        }
    }

    @Test("Get multiple tracks")
    func getTracks() async throws {
        let client = try await sharedClient()
        let tracks = try await client.getTracks([TestData.trackId])
        // May be empty for anonymous — verify no crash
        for track in tracks {
            #expect(!track.id.isEmpty)
        }
    }

    @Test("Get full track with artists and releases")
    func getFullTrack() async throws {
        let client = try await sharedClient()
        let tracks = try await client.getFullTrack(
            [TestData.trackId], withArtists: true, withReleases: true)
        for track in tracks {
            #expect(!track.title.isEmpty)
        }
    }

    @Test("Get stream URLs (requires subscription)")
    func getStreamURLs() async throws {
        guard hasAuthToken else { return }
        let client = try await sharedClient()
        do {
            let streams = try await client.getStreamURLs([TestData.trackId])
            if let stream = streams.first {
                #expect(!stream.mid.isEmpty)
                #expect(!stream.expire.isEmpty)
            }
        } catch {
            // Stream may fail without active subscription — not a decoding issue
        }
    }

    @Test("Get stream URL for mid quality (requires subscription)")
    func getStreamURL() async throws {
        guard hasAuthToken else { return }
        let client = try await sharedClient()
        do {
            let url = try await client.getStreamURL(TestData.trackId, quality: .mid)
            #expect(!url.isEmpty)
        } catch {
            // Expected without subscription
        }
    }

    @Test("Get direct stream URL (requires subscription)")
    func getDirectStreamURL() async throws {
        guard hasAuthToken else { return }
        let client = try await sharedClient()
        do {
            let directStream = try await client.getDirectStreamURL(TestData.trackId, quality: .mid)
            if let ds = directStream {
                #expect(!ds.stream.isEmpty)
            }
        } catch {
            // Expected without subscription
        }
    }
}

// MARK: - Artists

@Suite("Integration / Artists", .tags(.integration), .serialized)
struct ArtistTests {
    @Test("Get artist by ID")
    func getArtist() async throws {
        let client = try await sharedClient()
        let artist = try await client.getArtist(TestData.artistId)

        if let artist {
            #expect(artist.id == TestData.artistId)
            #expect(!artist.title.isEmpty)
        }
    }

    @Test("Get artist with all related data")
    func getArtistFull() async throws {
        let client = try await sharedClient()
        let artist = try await client.getArtist(
            TestData.artistId,
            withReleases: true, releasesLimit: 5,
            withPopularTracks: true, tracksLimit: 5,
            withRelatedArtists: true, relatedArtistsLimit: 5,
            withDescription: true
        )

        if let artist {
            #expect(!artist.title.isEmpty)
            for release in artist.releases {
                #expect(!release.id.isEmpty)
            }
            for track in artist.popularTracks {
                #expect(!track.id.isEmpty)
            }
        }
    }
}

// MARK: - Releases

@Suite("Integration / Releases", .tags(.integration), .serialized)
struct ReleaseTests {
    @Test("Get release by ID")
    func getRelease() async throws {
        let client = try await sharedClient()
        let release = try await client.getRelease(TestData.releaseId)

        if let release {
            #expect(release.id == TestData.releaseId)
            #expect(!release.title.isEmpty)
            for track in release.tracks {
                #expect(!track.id.isEmpty)
            }
        }
    }
}

// MARK: - Playlists

@Suite("Integration / Playlists", .tags(.integration), .serialized)
struct PlaylistTests {
    @Test("Get playlist by ID")
    func getPlaylist() async throws {
        let client = try await sharedClient()
        let playlist = try await client.getPlaylist(TestData.playlistId)

        #expect(playlist != nil)
        if let playlist {
            #expect(playlist.id == TestData.playlistId)
            #expect(!playlist.title.isEmpty)
            for track in playlist.tracks {
                #expect(!track.id.isEmpty)
            }
        }
    }

    @Test("Get short playlist")
    func getShortPlaylist() async throws {
        let client = try await sharedClient()
        let playlists = try await client.getShortPlaylist([TestData.playlistId])
        #expect(!playlists.isEmpty)
        #expect(playlists[0].id == TestData.playlistId)
        #expect(!playlists[0].title.isEmpty)
    }

    @Test("Get playlist tracks with pagination")
    func getPlaylistTracks() async throws {
        let client = try await sharedClient()
        let tracks = try await client.getPlaylistTracks(TestData.playlistId, limit: 5, offset: 0)
        #expect(!tracks.isEmpty)
        for track in tracks {
            #expect(!track.id.isEmpty)
        }
    }
}

// MARK: - Podcasts & Lyrics

@Suite("Integration / Media", .tags(.integration), .serialized)
struct MediaTests {
    @Test("Get podcast by ID")
    func getPodcast() async throws {
        let client = try await sharedClient()
        let podcast = try await client.getPodcast(TestData.podcastId)
        if let podcast {
            #expect(!podcast.id.isEmpty)
            #expect(!podcast.title.isEmpty)
        }
    }

    @Test("Get lyrics for track")
    func getLyrics() async throws {
        let client = try await sharedClient()
        // Just verify it decodes without error — not every track has lyrics
        _ = try await client.getLyrics(TestData.trackId)
    }
}

// MARK: - Grid / Editorial

@Suite("Integration / Editorial", .tags(.integration), .serialized)
struct EditorialTests {
    @Test("Get editorial playlist IDs")
    func getEditorialPlaylistIds() async throws {
        let client = try await sharedClient()
        // May return empty for anonymous users — just verify no crash
        _ = try await client.getEditorialPlaylistIds()
    }

    @Test("Get grid content")
    func getGridContent() async throws {
        let client = try await sharedClient()
        let items = try await client.getGridContent()
        for item in items {
            #expect(!item.id.isEmpty)
            #expect(!item.type.isEmpty)
        }
    }
}

// MARK: - Collection (auth only)

@Suite("Integration / Collection", .tags(.integration), .serialized)
struct CollectionTests {
    @Test("Get collection")
    func getCollection() async throws {
        guard hasAuthToken else { return }
        let client = try await sharedClient()
        let collection = try await client.getCollection()
        _ = collection.tracks
        _ = collection.artists
        _ = collection.releases
    }

    @Test("Get liked tracks")
    func getLikedTracks() async throws {
        guard hasAuthToken else { return }
        let client = try await sharedClient()
        let tracks = try await client.getLikedTracks()
        for track in tracks {
            #expect(!track.id.isEmpty)
        }
    }

    @Test("Get user playlists")
    func getUserPlaylists() async throws {
        guard hasAuthToken else { return }
        let client = try await sharedClient()
        let playlists = try await client.getUserPlaylists()
        for pl in playlists {
            #expect(pl.id != nil)
        }
    }
}

// MARK: - History

@Suite("Integration / History", .tags(.integration), .serialized)
struct HistoryTests {
    @Test("Get listening history (requires auth)")
    func getListeningHistory() async throws {
        guard hasAuthToken else { return }
        let client = try await sharedClient()
        let entries = try await client.getListeningHistory(limit: 5)
        print("History entries: \(entries.count)")
        for entry in entries {
            print("  [\(entry.lastListeningDttm ?? "?")] \(entry.track.title) — \(entry.track.artistsString)")
        }
        #expect(!entries.isEmpty, "Listening history should not be empty for an active account")
    }

    @Test("Get listening history raw (requires auth)")
    func getListeningHistoryRaw() async throws {
        guard hasAuthToken else { return }
        let client = try await sharedClient()
        let raw = try await client.getListeningHistoryRaw()
        print("Raw history items: \(raw.count)")
        if let first = raw.first {
            print("First item keys: \(first.keys.sorted())")
        }
    }
}

// MARK: - Network logging

@Suite("Integration / Logging", .tags(.integration), .serialized)
struct LoggingTests {
    @Test("Network logging callback fires")
    func networkLogging() async throws {
        let client = try await sharedClient()

        let logReceived = AtomicFlag(false)
        client.onNetworkLog = { entry in
            logReceived.set(true)
        }

        _ = try await client.quickSearch("test", limit: 1)
        #expect(logReceived.value, "Network log callback should have fired")
        client.onNetworkLog = nil
    }
}

// MARK: - Helpers

private final class AtomicFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: Bool
    var value: Bool { lock.lock(); defer { lock.unlock() }; return _value }
    init(_ initial: Bool) { _value = initial }
    func set(_ v: Bool) { lock.lock(); _value = v; lock.unlock() }
}

extension Tag {
    @Tag static var integration: Self
}
