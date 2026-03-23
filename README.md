# ZvukMusic

Swift library for the [Zvuk.com](https://zvuk.com) music streaming API.

**Based on [zvuk-music](https://github.com/trudenboy/zvuk-music) Python library.**

> **Disclaimer:** This library is not affiliated with or endorsed by Zvuk.com.

> [!IMPORTANT]
> You must have a zvuk.com account and paid subscription to use this library.

## Requirements

- macOS 15+
- Swift 6.0+

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/trudenboy/zvuk-swift.git", from: "0.1.0"),
]
```

Or in Xcode: **File → Add Package Dependencies** and paste the repository URL.

## Quick Start

### Anonymous Access

```swift
import ZvukMusic

// Get an anonymous token (limited functionality)
let token = try await ZvukClient.getAnonymousToken()
let client = ZvukClient(token: token)

// Search
let results = try await client.quickSearch("Metallica")
for track in results.tracks {
    print("\(track.title) - \(track.artistsString)")
}
```

### Authorized Access

For full functionality (high quality, likes, playlists) you need an authorized user token:

1. Log in to [zvuk.com](https://zvuk.com) in your browser
2. Open https://zvuk.com/api/tiny/profile
3. Copy the `token` field value

```swift
import ZvukMusic

let client = ZvukClient(token: "your_token")

// Get artist info
if let artist = try await client.getArtist(
    "754367",
    withPopularTracks: true
) {
    print(artist.title)
    for track in artist.popularTracks {
        print("  - \(track.title)")
    }
}
```

## Usage Examples

### Search

```swift
// Quick search (autocomplete)
let quick = try await client.quickSearch("Nothing Else Matters", limit: 5)

// Full-text search
let search = try await client.search("Metallica", limit: 10)
print("Tracks found: \(search.tracks?.page?.total ?? 0)")
print("Artists found: \(search.artists?.page?.total ?? 0)")
```

### Tracks

```swift
// Get a track
if let track = try await client.getTrack("5896627") {
    print("\(track.title) (\(track.durationString))")
}

// Get stream URL
let url = try await client.getStreamURL("5896627", quality: .high)
print("Stream URL: \(url)")

// Download track
try await client.download(url: url, to: "track.mp3")
```

### Playlists

```swift
// Create a playlist
let playlistId = try await client.createPlaylist("My Playlist", trackIds: ["5896627", "5896628"])

// Add tracks
_ = try await client.addTracksToPlaylist(playlistId, trackIds: ["5896629"])

// Get playlist
if let playlist = try await client.getPlaylist(playlistId) {
    for track in playlist.tracks {
        print("  - \(track.title)")
    }
}

// Delete playlist
_ = try await client.deletePlaylist(playlistId)
```

### Collection (Likes)

```swift
// Like a track
_ = try await client.likeTrack("5896627")

// Get liked tracks
let liked = try await client.getLikedTracks(orderBy: .dateAdded, direction: .desc)
for track in liked {
    print("\(track.title) - \(track.artistsString)")
}

// Unlike
_ = try await client.unlikeTrack("5896627")
```

### Artists and Releases

```swift
// Artist info
if let artist = try await client.getArtist(
    "754367",
    withReleases: true,
    withPopularTracks: true,
    withRelatedArtists: true
) {
    print("Artist: \(artist.title)")
    print("Releases: \(artist.releases.count)")
    print("Popular tracks: \(artist.popularTracks.count)")
}

// Get a release
if let release = try await client.getRelease("12345") {
    print("Album: \(release.title) (\(release.year ?? 0))")
    for track in release.tracks {
        print("  \(track.title)")
    }
}
```

## Audio Quality

| Quality | Bitrate | Subscription required |
|---------|---------|----------------------|
| `.mid` | 128kbps MP3 | No |
| `.high` | 320kbps MP3 | Yes |
| `.flac` | FLAC | Yes |

```swift
do {
    let url = try await client.getStreamURL("5896627", quality: .high)
} catch let error as ZvukError {
    switch error {
    case .subscriptionRequired:
        // Fallback to mid quality
        let url = try await client.getStreamURL("5896627", quality: .mid)
    default:
        throw error
    }
}
```

## Direct Streaming (non-DRM)

```swift
if let stream = try await client.getDirectStreamURL("5896627", quality: .high) {
    print("Direct URL: \(stream.stream)")
}
```

## Lyrics

```swift
if let lyrics = try await client.getLyrics("5896627") {
    print(lyrics.lyrics)
    print("Synced: \(lyrics.isSynced)")
}
```

## Notifications

```swift
// Get notifications feed
let feed = try await client.getNotifications(limit: 15)

for notification in feed.notifications {
    print("[\(notification.createdAt)]")
    switch notification.body {
    case .newRelease(let author, let release):
        print("New release: \(release.title) by \(author.title)")
    case .newPodcastEpisode(let episode):
        print("New episode: \(episode.title)")
    case .newBook(let author, let book):
        print("New book: \(book.title) by \(author.rname)")
    case .newProfilePlaylist(let author, let playlist):
        print("New playlist: \(playlist.title) by \(author.name)")
    case .playlistTracksAdded(let author, let playlist, let count):
        print("\(author.name) added \(count) tracks to \(playlist.title)")
    case .playlistLiked(let author, let playlist):
        print("\(author.name) liked \(playlist.title)")
    case .unknown(let typename):
        print("Unknown notification: \(typename)")
    }
}

// Pagination
if feed.pageInfo.hasNextPage, let cursor = feed.pageInfo.cursor {
    let nextPage = try await client.getNotifications(cursor: cursor, limit: 15)
}

// Filter by type
let releasesOnly = try await client.getNotifications(types: [.newRelease])

// Check for unread
let hasUnread = try await client.hasUnreadNotifications()
```

## Recommendations

```swift
// Get personalized music recommendations
let recommendations = try await client.getMusicRecommendations()

for page in recommendations.pages {
    for item in page.items {
        switch item {
        case .artist(let artist):
            print("Artist: \(artist.title)")
        case .release(let release):
            print("Release: \(release.title)")
        case .playlist(let playlist):
            print("Playlist: \(playlist.title) (\(playlist.trackCount) tracks)")
            for track in playlist.tracks {
                print("  - \(track.title) by \(track.artistsString)")
            }
        case .unknown:
            break
        }
    }
}

// Request specific pages
let page2 = try await client.getMusicRecommendations(pages: [2])

// Filter by item type
let artistsOnly = try await client.getMusicRecommendations(
    itemTypes: [.artist]
)
```

## Wave & Radio

```swift
// Personal wave with mood settings
let tracks = try await client.getPersonalWave(
    count: 10,
    energy: 0.8,       // 0.0 (calm) ... 1.0 (energetic)
    fun: 0.5,          // 0.0 (sad) ... 1.0 (fun)
    genres: [.electronic, .rock],
    language: .russian,
    popularity: .popular
)
for track in tracks {
    print("\(track.title) — \(track.artistsString)")
}

// Instrumental only (no vocals)
let instrumental = try await client.getPersonalWave(
    energy: 0.3,
    fun: 0.7,
    instrumental: true
)

// Radio by artist (similar tracks)
let radio = try await client.getRadioByArtist("754367")
print("Tracks: \(radio.tracks.count), cursor: \(radio.cursor)")

// Pagination
let nextPage = try await client.getRadioByArtist("754367", cursor: radio.cursor)

// Radio by track
let trackRadio = try await client.getRadioByTrack("5896627")
```

## Subscription

```swift
let sub = try await client.getSubscription()
if let subscription = sub.subscription {
    print("Status: \(subscription.status)")
    print("Plan: \(subscription.title)")
    print("Price: \(subscription.planPrice)")
    print("Expires: \(subscription.expirationDate)")
    print("Premium: \(subscription.hasPremium)")
}
```

## Feature Flags

```swift
let info = try await client.getFeaturedInfo()

// Check a specific flag
if info.hasFeature("hls2_enable_web") {
    print("HLS v2 enabled")
}

// User's country
print("Country: \(info.country ?? "unknown")")

// All feature flags
for feature in info.features {
    print("  - \(feature)")
}
```

## Error Handling

```swift
do {
    let track = try await client.getTrack("123456789")
} catch let error as ZvukError {
    switch error {
    case .notFound:
        print("Track not found")
    case .unauthorized:
        print("Invalid token")
    case .botDetected:
        print("API blocked the request (bot protection)")
    case .rateLimited(_, let retryAfter):
        print("Rate limited, retry after \(retryAfter ?? 0)s")
    case .subscriptionRequired:
        print("Subscription required")
    default:
        print("Error: \(error.localizedDescription)")
    }
}
```

## Configuration

```swift
let client = ZvukClient(
    token: "your_token",
    timeout: 15.0,                          // Request timeout (default: 10s)
    proxyURL: "http://proxy:8080",           // Optional proxy
    userAgent: "MyApp/1.0",                  // Custom User-Agent
    rateLimit: 5                             // Max requests/second
)
```

## API Reference

### ZvukClient

All methods are `async throws`.

**Auth & Profile:**

| Method | Description |
|--------|-------------|
| `getAnonymousToken()` | Get anonymous token (static) |
| `getProfile()` | User profile |
| `isAuthorized()` | Check authorization |

**Search:**

| Method | Description |
|--------|-------------|
| `quickSearch(_:limit:)` | Quick search (autocomplete) |
| `search(_:limit:...)` | Full-text search with filters |

**Tracks & Streaming:**

| Method | Description |
|--------|-------------|
| `getTrack(_:)` | Get a track |
| `getTracks(_:)` | Get multiple tracks |
| `getFullTrack(_:withArtists:withReleases:)` | Track with full details |
| `getStreamURL(_:quality:)` | Stream URL |
| `getStreamURLs(_:)` | Multiple stream URLs |
| `getDirectStreamURL(_:quality:)` | Direct (non-DRM) stream URL |
| `getLyrics(_:)` | Track lyrics |

**Artists & Releases:**

| Method | Description |
|--------|-------------|
| `getArtist(_:...)` | Artist with releases, tracks, related |
| `getArtists(_:...)` | Multiple artists |
| `getRelease(_:)` | Release (album/single) |
| `getReleases(_:relatedLimit:)` | Multiple releases |

**Playlists:**

| Method | Description |
|--------|-------------|
| `getPlaylist(_:)` | Get playlist |
| `getPlaylists(_:)` | Multiple playlists |
| `getShortPlaylist(_:)` | Brief playlist info |
| `getPlaylistTracks(_:limit:offset:)` | Playlist tracks |
| `createPlaylist(_:trackIds:)` | Create playlist |
| `renamePlaylist(_:newName:)` | Rename |
| `addTracksToPlaylist(_:trackIds:)` | Add tracks |
| `updatePlaylist(_:trackIds:name:isPublic:)` | Update playlist |
| `setPlaylistPublic(_:isPublic:)` | Change visibility |
| `deletePlaylist(_:)` | Delete playlist |

**Podcasts:**

| Method | Description |
|--------|-------------|
| `getPodcast(_:)` | Get podcast |
| `getPodcasts(_:)` | Multiple podcasts |
| `getEpisode(_:)` | Get episode |
| `getEpisodes(_:)` | Multiple episodes |

**Collection (Likes):**

| Method | Description |
|--------|-------------|
| `getCollection()` | User collection |
| `getLikedTracks(orderBy:direction:)` | Liked tracks |
| `getUserPlaylists()` | User playlists |
| `getPaginatedCollection(...)` | Paginated collection (all types) |
| `likeTrack(_:)` / `unlikeTrack(_:)` | Like / unlike track |
| `likeRelease(_:)` / `unlikeRelease(_:)` | Like / unlike release |
| `likeArtist(_:)` / `unlikeArtist(_:)` | Like / unlike artist |
| `likePlaylist(_:)` / `unlikePlaylist(_:)` | Like / unlike playlist |
| `likePodcast(_:)` / `unlikePodcast(_:)` | Like / unlike podcast |

**Hidden Collection:**

| Method | Description |
|--------|-------------|
| `getHiddenCollection()` | Hidden items |
| `getHiddenTracks()` | Hidden tracks |
| `hideTrack(_:)` / `unhideTrack(_:)` | Hide / unhide track |

**Profiles & Social:**

| Method | Description |
|--------|-------------|
| `getProfileFollowersCount(_:)` | Follower counts |
| `getFollowingCount(_:)` | Following count |
| `hasUnreadNotifications()` | Unread notifications |
| `getNotifications(types:cursor:limit:)` | Notifications feed with pagination |

**History:**

| Method | Description |
|--------|-------------|
| `getListeningHistory(limit:)` | Listening history |
| `getListenedEpisodes()` | Listened episodes |

**Recommendations:**

| Method | Description |
|--------|-------------|
| `getMusicRecommendations(contentType:itemTypes:pages:)` | Personalized recommendations |

**Wave & Radio:**

| Method | Description |
|--------|-------------|
| `getPersonalWave(count:energy:fun:genres:language:instrumental:popularity:)` | Personal wave |
| `getRadioByArtist(_:limit:cursor:)` | Radio by artist |
| `getRadioByTrack(_:limit:cursor:)` | Radio by track |

**Subscription & Configuration:**

| Method | Description |
|--------|-------------|
| `getSubscription()` | Subscription info |
| `getFeaturedInfo()` | Feature flags and targeting |

**Editorial:**

| Method | Description |
|--------|-------------|
| `getGridContent(name:rankerEnabled:)` | Grid content |
| `getEditorialPlaylistIds()` | Curated playlist IDs |

**Synthesis:**

| Method | Description |
|--------|-------------|
| `synthesisPlaylistBuild(firstAuthorId:secondAuthorId:)` | AI playlist |
| `getSynthesisPlaylists(_:)` | Get synthesis playlists |

## References

This library was designed based on analysis of the [Zvuk.com](https://zvuk.com) web application and the following open-source projects:

- [zvuk-music](https://github.com/trudenboy/zvuk-music) — Python library for Zvuk API (original)
- [gozvuk](https://github.com/oklookat/gozvuk) — Unofficial Go client for Zvuk.com API
- [sberzvuk-api](https://github.com/Aiving/sberzvuk-api) — JavaScript/TypeScript library for Zvuk API

## License

MIT License
