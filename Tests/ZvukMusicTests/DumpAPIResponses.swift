import Foundation
import Testing

@testable import ZvukMusic

/// Calls every major API endpoint and saves raw JSON responses
/// to `zvuk-api-responses/` for documentation.
/// Uses quickSearch to discover valid IDs first.
@Suite("Dump API Responses", .tags(.integration), .serialized)
struct DumpAPIResponses {

    private let outputDir: String = {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("zvuk-api-responses").path
    }()

    private func makeClient() async throws -> ZvukClient {
        let token: String
        if let env = ProcessInfo.processInfo.environment["ZVUK_TOKEN"], !env.isEmpty {
            token = env
        } else {
            var dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            var found: String?
            for _ in 0..<5 {
                let envURL = dir.appendingPathComponent(".env")
                if let contents = try? String(contentsOf: envURL, encoding: .utf8) {
                    for line in contents.components(separatedBy: .newlines) {
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.hasPrefix("#"), trimmed.contains("=") else { continue }
                        let parts = trimmed.split(separator: "=", maxSplits: 1)
                        if parts.count == 2, parts[0].trimmingCharacters(in: .whitespaces) == "ZVUK_TOKEN" {
                            let v = parts[1].trimmingCharacters(in: .whitespaces)
                            if v != "your_token_here" && !v.isEmpty { found = v }
                        }
                    }
                }
                dir = dir.deletingLastPathComponent()
            }
            if let found {
                token = found
            } else {
                token = try await ZvukClient.getAnonymousToken()
            }
        }
        return ZvukClient(token: token, timeout: 30)
    }

    /// Capture raw responseBody from the network call.
    private func withCapture(
        client: ZvukClient,
        name: String,
        action: () async throws -> Void
    ) async throws {
        let captured = CapturedBody()
        let oldLog = client.onNetworkLog
        client.onNetworkLog = { entry in
            if let body = entry.responseBody {
                captured.set(body)
            }
            oldLog?(entry)
        }
        defer { client.onNetworkLog = oldLog }

        try await action()

        if let body = captured.value {
            try saveJSON(body, name: name)
        }
    }

    private func saveJSON(_ raw: String, name: String) throws {
        try FileManager.default.createDirectory(
            atPath: outputDir, withIntermediateDirectories: true)
        let path = (outputDir as NSString).appendingPathComponent("\(name).json")
        if let data = raw.data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: data),
           let pretty = try? JSONSerialization.data(
            withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])
        {
            try pretty.write(to: URL(fileURLWithPath: path))
        } else {
            try raw.write(toFile: path, atomically: true, encoding: .utf8)
        }
    }

    // MARK: - All-in-one dump

    @Test("Dump all endpoints")
    func dumpAll() async throws {
        let client = try await makeClient()

        // 1) Discover real IDs via quickSearch
        let qs = try await client.quickSearch("Metallica", limit: 10)
        let trackId = qs.tracks.first?.id ?? "53431597"
        let artistId = qs.artists.first?.id ?? "754367"
        let releaseId = qs.tracks.first?.release?.id ?? "6062701"

        // Save quickSearch itself
        try await withCapture(client: client, name: "quickSearch") {
            _ = try await client.quickSearch("Metallica", limit: 5)
        }

        // 2) Search (full)
        try await withCapture(client: client, name: "search") {
            _ = try await client.search("Metallica", limit: 3)
        }

        // 3) getTracks
        try await withCapture(client: client, name: "getTracks") {
            _ = try await client.getTracks([trackId])
        }

        // 4) getFullTrack
        try await withCapture(client: client, name: "getFullTrack") {
            _ = try await client.getFullTrack([trackId], withArtists: true, withReleases: true)
        }

        // 5) getArtist (with all related data)
        try await withCapture(client: client, name: "getArtists") {
            _ = try await client.getArtist(
                artistId,
                withReleases: true, releasesLimit: 3,
                withPopularTracks: true, tracksLimit: 3,
                withRelatedArtists: true, relatedArtistsLimit: 3,
                withDescription: true
            )
        }

        // 6) getRelease
        try await withCapture(client: client, name: "getReleases") {
            _ = try await client.getRelease(releaseId)
        }

        // 7) getStream
        try await withCapture(client: client, name: "getStream") {
            _ = try? await client.getStreamURLs([trackId])
        }

        // 8) getLyrics
        try await withCapture(client: client, name: "getLyrics") {
            _ = try await client.getLyrics(trackId)
        }

        // 9) getPlaylist — use editorial playlist IDs
        let editorialIds = try await client.getEditorialPlaylistIds()
        let playlistId = editorialIds.first ?? "947509"

        try await withCapture(client: client, name: "getPlaylists") {
            _ = try await client.getPlaylist(playlistId)
        }

        // 10) getShortPlaylist
        try await withCapture(client: client, name: "getShortPlaylist") {
            _ = try await client.getShortPlaylist([playlistId])
        }

        // 11) getPlaylistTracks
        try await withCapture(client: client, name: "getPlaylistTracks") {
            _ = try await client.getPlaylistTracks(playlistId, limit: 5, offset: 0)
        }

        // 12) getPodcast
        try await withCapture(client: client, name: "getPodcasts") {
            _ = try await client.getPodcast("93")
        }

        // 13) userCollection
        try await withCapture(client: client, name: "userCollection") {
            _ = try await client.getCollection()
        }

        // 14) getEditorialPlaylistIds
        try await withCapture(client: client, name: "getEditorialPlaylistIds") {
            _ = try await client.getEditorialPlaylistIds()
        }

        // 15) getGridContent
        try await withCapture(client: client, name: "getGridContent") {
            _ = try await client.getGridContent(name: "editorial_playlist")
        }

        // 16) getProfile
        try await withCapture(client: client, name: "getProfile") {
            _ = try await client.getProfile()
        }

        // Print summary
        let files = (try? FileManager.default.contentsOfDirectory(atPath: outputDir)) ?? []
        print("Saved \(files.count) response files to zvuk-api-responses/")
        for f in files.sorted() {
            let size = (try? FileManager.default.attributesOfItem(
                atPath: (outputDir as NSString).appendingPathComponent(f)
            )[.size] as? Int) ?? 0
            print("  \(f) (\(size) bytes)")
        }
    }
}

// Thread-safe capture helper
private final class CapturedBody: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: String?

    var value: String? {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    func set(_ v: String) {
        lock.lock()
        _value = v
        lock.unlock()
    }
}
