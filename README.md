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
    .package(url: "https://github.com/korenskoy/zvuk-swift.git", from: "0.3.0"),
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

// Full-text search across all sections
let search = try await client.search("Metallica", limit: 10)
print("Tracks found: \(search.tracks?.page?.total ?? 0)")
print("Artists found: \(search.artists?.page?.total ?? 0)")

// Search a single section with cursor-based pagination
var cursor: String? = nil
repeat {
    let page = try await client.searchTracks("Metallica", limit: 20, cursor: cursor)
    for track in page.items {
        print("\(track.title) — \(track.artistsString)")
    }
    cursor = page.page?.cursor
} while cursor != nil

// Other per-section helpers follow the same shape:
_ = try await client.searchArtists("Metallica")
_ = try await client.searchReleases("Metallica")
_ = try await client.searchPlaylists("Metallica")
_ = try await client.searchPodcasts("Serial")
_ = try await client.searchEpisodes("Serial")
_ = try await client.searchProfiles("dj")
_ = try await client.searchBooks("Dune") // books section has no cursor
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

// Radio seeded by a release or a playlist
let releaseRadio = try await client.getRadioByRelease("14607201")
let playlistRadio = try await client.getRadioByPlaylist("123456")
```

### Internet Radio Stations

Live stations are a separate content type — a continuous stream rather than a
track list.

```swift
let stations = try await client.getRadioStations(limit: 20)
for station in stations {
    print(station.name)                  // "Европа Плюс - Россия"
    print(station.source ?? "")          // stream URL
    print(station.metaDataUrl ?? "")     // now-playing metadata feed
    print(station.logoColored?.svg ?? "")
}

let single = try await client.getRadioStation("1")
```

### Editorial Waves

Waves are server-curated streams. `localtime` is required — the server picks
different content for morning and evening listeners.

```swift
let wave = try await client.getWave("1")        // "МегаХит"
print(wave?.description ?? "")                  // "Топ российских чартов"

let items = try await client.getWaveContent(waveId: "1")
for item in items {
    print(item.track?.title ?? item.itemId, "skippable:", item.skippable)
}
```

## Recently Played

`getRecentlyPlayed` returns *entities the user opened* — albums, playlists,
artists, waves, radio stations — not individual tracks. For a track-level
history use `getListeningHistory(limit:)`.

```swift
let recent = try await client.getRecentlyPlayed(limit: 10)
for item in recent {
    print(item.type ?? .release, item.title ?? item.id, item.lastListeningDttm ?? "")
}

// Only albums and playlists
let filtered = try await client.getRecentlyPlayed(
    limit: 20,
    itemTypes: [.release, .playlist]
)
```

## Search Suggestions

```swift
// Completions for a partially typed query
let suggestions = try await client.getSearchAutocomplete("нирв")
// ["нирвана", "нирвана лучшее", "нирван", "нирванна"]

// What everyone else is searching for
let popular = try await client.getPopularSearches(limit: 10)
print(popular.queries)

// Resolve a name to an ID without fetching the whole entity
let ids = try await client.searchArtistIDs("Radiohead", limit: 1)
```

## Cheap Counters

Checking collection membership without downloading the collection:

```swift
let trackCount = try await client.getCollectionTracksCount()
let ids = try await client.getCollectionIDs()
print(ids.tracks.count, ids.releases.count, ids.artists.count)

let followers = try await client.getArtistLikesCount(["433980"])
```

## Grid (Page Layouts)

```swift
// Get the full "Popular Music" page layout
let grid = try await client.getGrid(name: GridName.popularMusic)

for section in grid.sections where section.enabled {
    print("\(section.header?.title ?? "—") (\(section.data.count) items)")

    // Load playlists from this section
    if !section.playlistIds.isEmpty {
        let playlists = try await client.getPlaylists(section.playlistIds)
    }

    // Load releases
    if !section.releaseIds.isEmpty {
        let releases = try await client.getReleases(section.releaseIds)
    }
}

// Get top-100 artist IDs
let top = try await client.getGridContent(name: GridContentName.top100Artists)
let artists = try await client.getArtists(top.ids)

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

The tables below cover the most-used methods. For the complete catalogue —
every Swift method, the GraphQL operation behind it and its variables — see
**[API.md](API.md)**.

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
| `search(_:limit:...)` | Full-text search, optional section filters and per-section cursors |
| `searchTracks(_:limit:cursor:)` | Paginated search of only tracks |
| `searchArtists(_:limit:cursor:)` | Paginated search of only artists |
| `searchReleases(_:limit:cursor:)` | Paginated search of only releases |
| `searchPlaylists(_:limit:cursor:)` | Paginated search of only playlists |
| `searchPodcasts(_:limit:cursor:)` | Paginated search of only podcasts |
| `searchEpisodes(_:limit:cursor:)` | Paginated search of only podcast episodes |
| `searchProfiles(_:limit:cursor:)` | Paginated search of only profiles |
| `searchBooks(_:limit:)` | Search only audiobooks (no cursor) |

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
| `readAllNotifications()` | Mark all notifications as read |

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

**Grid (Page Layouts):**

| Method | Description |
|--------|-------------|
| `getGrid(name:)` | Page layout with sections and item IDs |
| `getGridContent(name:)` | Flat list of content IDs (top-100, editorial) |
| `getEditorialPlaylistIds()` | Curated playlist IDs |

Available `GridName` constants for `getGrid(name:)`:

| Constant | Description |
|----------|-------------|
| `GridName.popularMusic` | Popular/Music — playlists, releases, artists, genre charts |
| `GridName.popularBooks` | Popular/Books — audiobook sections |
| `GridName.popularRadio` | Popular/Radio — radio station groups |
| `GridName.adsConfig` | Ad configuration |

Available `GridContentName` constants for `getGridContent(name:)`:

| Constant | Description |
|----------|-------------|
| `GridContentName.top100Artists` | Top 100 artist IDs → use with `getArtists(_:)` |
| `GridContentName.top100Podcasts` | Top 100 podcast IDs → use with `getPodcasts(_:)` |
| `GridContentName.editorialPlaylists` | Editorial playlist IDs → use with `getPlaylists(_:)` |

**Synthesis:**

| Method | Description |
|--------|-------------|
| `synthesisPlaylistBuild(firstAuthorId:secondAuthorId:)` | AI playlist |
| `getSynthesisPlaylists(_:)` | Get synthesis playlists |

**Internet radio:**

| Method | Description |
|--------|-------------|
| `getRadioStations(limit:offset:)` | Station catalogue |
| `getRadioStations(ids:)` / `getRadioStation(_:)` | Stations by ID |
| `getRadioByRelease(_:limit:cursor:)` | Recommender radio seeded by a release |
| `getRadioByPlaylist(_:limit:cursor:)` | Recommender radio seeded by a playlist |

**Waves:**

| Method | Description |
|--------|-------------|
| `getWaves(_:)` / `getWave(_:)` | Wave title, description, cover |
| `getWaveContent(waveId:localtime:)` | Next batch of wave items |
| `getKidsWaveContent(waveId:localtime:waveSource:)` | Kids wave |
| `getClusterWaveContent(clusterId:first:localtime:)` | Personal-wave cluster preview |

**Recently played & counters:**

| Method | Description |
|--------|-------------|
| `getRecentlyPlayed(limit:offset:itemTypes:isKidContent:)` | Recently opened entities (not tracks) |
| `getCollectionTracksCount()` | Number of liked tracks |
| `getCollectionIDs()` | All collection IDs grouped by type |
| `getOwnPlaylistIDs()` | IDs of the user's playlists |
| `getArtistLikesCount(_:)` | Follower counts for artists |
| `getSubscriptions(statuses:)` | Active subscriptions |
| `getUnreadNotificationsCount(types:)` | Unread notification count |

**Search suggestions:**

| Method | Description |
|--------|-------------|
| `getSearchAutocomplete(_:limit:)` | Query completions |
| `getPopularSearches(limit:cursor:explicit:)` | Trending queries |
| `getBlendedSearch(_:limit:)` | Mixed relevance-ranked results (raw) |
| `searchArtistIDs(_:limit:)` and siblings | ID-only search for artists, podcasts, books, authors |

**Artists (extended):**

| Method | Description |
|--------|-------------|
| `getArtistsShortInfo(_:withLikesCount:)` | Name and cover only |
| `getArtistPopularTracks(_:limit:offset:)` | Popular tracks, offset paging |
| `getArtistPopularTracksPage(_:limit:cursor:withPreview:)` | Popular tracks, cursor paging |
| `getArtistReleasesPage(_:limit:includeTypes:excludeTypes:cursor:)` | Releases, filterable by type |
| `getArtistAlbums(_:)` / `getArtistSingles(_:)` / `getArtistCompilations(_:)` | Discography sections |
| `getRelatedArtists(_:limit:popularTracksLimit:withPopularTracks:)` | Similar artists |
| `getArtistPage(_:...)` | Everything the web artist page shows |

**Releases & tracks (extended):**

| Method | Description |
|--------|-------------|
| `getRelatedReleases(_:limit:)` | Similar releases |
| `getReleasesTracks(_:)` | Track lists only |
| `getReleasesShortInfo(_:withArtists:)` | Title, type, cover |
| `getTracksShortInfo(_:)` / `getTracksMinimalInfo(_:)` | Lighter track payloads |
| `getTrackStreamPreviews(_:quality:encodeType:)` | Preview URLs (no subscription needed) |

**Audiobooks:**

| Method | Description |
|--------|-------------|
| `getAudioBooks(_:withChapters:)` | Book cards |
| `getBookChapters(_:)` / `getChapters(_:)` / `getChapter(_:)` | Chapters |
| `getBookAuthors(_:withLikesCount:)` / `getAuthorBooks(_:limit:cursor:)` | Authors and their books |
| `getRelatedBooks(_:limit:)` / `getRelatedAuthors(_:limit:)` | Similar books and authors |
| `getBooksRecommendations(recType:first:skip:withAuthors:)` | Recommended books |

**Profiles & follows:**

| Method | Description |
|--------|-------------|
| `getProfiles(_:withPlaylists:...)` | Profiles by ID |
| `getProfilePlaylists(_:...)` / `getProfileFirstPlaylistTracks(_:limit:offset:)` | Playlists on a profile |
| `getFollowers(_:itemType:limit:cursor:)` / `getFollowing(_:limit:cursor:)` | Follow graph |
| `getRelatedProfiles(_:limit:)` | Profiles with similar taste |
| `setProfileSettings(name:description:)` | Update own profile |
| `createMigration(links:)` / `getMigrationStatus(_:)` | Import playlists from another service |

## References

This library was designed based on analysis of the [Zvuk.com](https://zvuk.com) web application and the following open-source projects:

- [zvuk-music](https://github.com/trudenboy/zvuk-music) — Python library for Zvuk API (original)
- [gozvuk](https://github.com/oklookat/gozvuk) — Unofficial Go client for Zvuk.com API
- [sberzvuk-api](https://github.com/Aiving/sberzvuk-api) — JavaScript/TypeScript library for Zvuk API

## License

MIT License
