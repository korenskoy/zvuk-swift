# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.4.1] - 2026-08-12

### Fixed

- `RadioStation.source` was typed `String?` while the API answers with an array of stream URLs, so `try?` swallowed the type mismatch and every station arrived without a stream — the field looked permanently empty. It is now `[String]`, with a `streamURL` convenience returning the first entry as a `URL`. All 161 stations in the catalogue carry a playable stream: HLS playlists for most, direct Icecast streams (`.mp3`, `.aacp`, extensionless) for the rest.
- `getRadioStation.graphql` selected `png` twice on `radioLogoBlack` instead of `png` and `svg`, so that logo's vector variant was always `nil` when fetched by ID.

## [0.4.0] - 2026-08-12

Coverage of the zvuk.com web client (build v8.6.2). Its GraphQL documents were
extracted from the JavaScript bundle, diffed against this package and the gap
implemented: 89 methods across 12 files, 84 new `.graphql` documents.

### Added

- **Internet radio** — `getRadioStations(limit:offset:)`, `getRadioStations(ids:)`, `getRadioStation(_:)`; new `RadioStation` and `RadioLogo` models. A content type the package did not cover at all.
- **Recently played** — `getRecentlyPlayed(limit:offset:itemTypes:isKidContent:)` over `listeningRecentV1`, with the `RecentItem` model and `RecentItemType` filter
- **Waves** — `getWaves(_:)`, `getWave(_:)`, `getWaveContent(waveId:localtime:)`, `getKidsWaveContent(...)`, `getClusterWaveContent(...)`; new `WaveInfo` and `WaveContentItem` models
- **Search suggestions** — `getSearchAutocomplete(_:limit:)`, `getPopularSearches(limit:cursor:explicit:)`, `getBlendedSearch(_:limit:)`, plus ID-only search (`searchArtistIDs`, `searchPodcastIDs`, `searchBookIDs`, `searchBookAuthorIDs`)
- **Cheap counters** — `getCollectionTracksCount()`, `getCollectionIDs()`, `getOwnPlaylistIDs()`, `getArtistLikesCount(_:)`, `getUnreadNotificationsCount(types:)`, `getNotificationsCount(types:)`, `getDynamicBlockPagesCount()`
- **Subscriptions** — `getSubscriptions(statuses:)` with `UserSubscription` / `UserSubscriptions`, exposing plan, platform and expiry
- **Artists** — short info, cursor-paginated popular tracks and releases, discography sections (albums / singles / compilations), related artists, and the full `getArtistPage(_:...)`
- **Releases & tracks** — related releases, track-lists-only, lighter payload variants, and `getTrackStreamPreviews(_:quality:encodeType:)` for previews that play without a subscription
- **Playlists** — `getPlaylistInfo`, `getPlaylistsShortInfo`, `getRelatedPlaylists`, own/profile playlist listings, and the `V1` mutations (`createPlaylistV1`, `addItemsToPlaylistV1`, `updatePlaylistV1`, `removePlaylist`) that return the affected playlist's ID
- **Collection** — `getPaginatedCollectionTracks(limit:cursor:)`, `getCollectionProfiles(limit:)`, `getProfileCollection(...)`, batch `addItemsToCollection(_:)`
- **Podcasts** — episodes, cursor-paginated episodes, by-category listing, recommendations, related shows
- **Audiobooks** — books, chapters, authors, related books/authors, recommendations; new `Chapter` and `ChapterBook` models
- **Profiles** — profiles by ID, avatars, profile podcasts and playlists, follow graph (`getFollowers`, `getFollowing`), `setProfileSettings`, recommender onboarding, and playlist migration from other services
- `API.md` — full catalogue mapping every Swift method to its GraphQL operation and variables
- `Tests/ZvukMusicTests/APIIntegrationTests.swift` — 50 tests that call each read method once against live data and check the response decodes, covering radio, waves, search suggestions, artists, releases, podcasts, audiobooks, profiles, plus an authorized-only suite for recently played, collection counters, subscriptions and paginated collection

### Changed

- Every method that accepts a `cursor` now returns `PaginatedResult` instead of a bare array — `getArtistAlbums`/`Singles`/`Compilations`/`Discography`, `getAuthorBooks`, `getProfilePlaylists`, `getProfilePodcasts`, `getFollowers`, `getFollowing`. They previously dropped the page info they had already fetched, so page 2 was unreachable.
- `getTrackStreamPreviews` matches previews to tracks by ID rather than by position; `getTrackStreamPreview.graphql` now selects `id`. The server silently omits unavailable tracks, which shifted every later preview onto the wrong track.
- `RecentItem` no longer carries the raw `mediaContent` payload: `AnyCodable.encode` drops nested arrays and objects, so it did not survive a re-encode, and hashing it stringified the whole subtree on every comparison.
- `Podcast.episodes` is gone for the same reasons, and because it never held anything usable: each query selects a different shape behind that key (`{ id }`, `{ publicationDate }`, or full episode data), so no consumer could rely on it. Episodes come from `getPodcastEpisodes` / `getPaginatedEpisodes`.
- `getUnreadNotificationsCount` / `getNotificationsCount` take `[NotificationType]` instead of `[String]`.
- `RadioEntityType` gained `.release` and `.playlist` (both verified against the server)
- New `EpisodeOrder` enum (`.newest` / `.oldest`) replaces the string `order:` parameter on `getPaginatedEpisodes` — the `OrderType` values are lower-case words, not `ASC`/`DESC`
- `getBooksRecommendations` and `getPodcastsRecommendations` now default `recType` to the working values `BOOK` / `PODCAST`
- `BookAuthor` and `SimpleBook` now decode leniently, so partial selection sets no longer throw
- API methods moved out of `Client.swift` into `Sources/ZvukMusic/API/*.swift` extensions; `request`, `decode` and `decodeList` became internal to allow this
- Response keys are no longer recursively camel-cased in `Request`: the decoder's `.convertFromSnakeCase` handles it at decode time, cutting a full parse-and-rebuild pass over every response. GraphQL documents that select the schema's snake_case containers now alias them (`pageInfo: page_info`, `hiddenCollection: hidden_collection`) so dictionary navigation stays camelCase.
- `Track.lyrics` is `Bool?` instead of `AnyCodable?` — the API sends only `true`/`null` there, and `AnyCodable`'s reflection-based equality stringified the value on every `Track` comparison.
- `Stream.isExpired` parses through cached `Date.ISO8601FormatStyle`s instead of allocating up to two `ISO8601DateFormatter`s per call.
- `GraphQLLoader`'s query cache is a `Mutex` instead of `nonisolated(unsafe)` + `NSLock`, making its thread safety compiler-checked.
- Bot-protection sniffing runs only when a response fails to parse as JSON. It used to copy every response body into a `String` and then into a lowercased second copy before parsing, on the successful path too.

### Fixed

- `Request.onLog` was read by in-flight requests on background executors while `ZvukClient.onNetworkLog` could assign it from another thread with no synchronization — a data race hidden by the `@unchecked Sendable` annotation. The property is now guarded by the same lock as the request headers.

- Cursor pagination on `getArtistPopularTracksPage` always reported `hasNextPage: false` with a `nil` cursor: the helper looks for `pageInfo`, but the wire key was `page_info` — the queries now alias it.
- A response whose body contained the words "bot activity" — a track or playlist title would do — was rejected as bot protection even when it parsed as valid JSON.
- `Profile.isAuthorized` always answered `false`: it read `isAnonymous`, a field the Tiny API does not send — the real signal is `is_registered`. `ZvukClient.isAuthorized()` therefore reported every authorized account as anonymous. An explicit `isAnonymous` still wins when a caller sets it.
- `Subscription`, `PaymentDetails`, `SubscriptionResult` and `FeaturedInfo` declared snake_case coding keys while the pipeline delivered camelCase, so `isTrial`, `isRecurrent`, `paymentDetails`, `planId`, `planPrice`, `servicesAvailable`, `isSuspended` and `closedBanners` silently decoded to their defaults on every response. With key conversion moved into the decoder they decode correctly.

### Notes

- `listeningRecentV1` is **not** a replacement for `listeningHistory` — its union has no `Track` member. It lists entities the user opened. Track-level history still comes from `getListeningHistory(limit:)`.
- The web client's four `getRadioBy*` documents and ten `getSearch*` documents duplicate queries this package already had; they are intentionally not bundled. See API.md for the reasoning.
- `Resources/Mutations/createPlaylist.graphql` now holds the web client's `createV1` mutation; the previous contents moved to `createPlaylistLegacy.graphql`, which still backs `createPlaylist(_:trackIds:)`.
- `getRadioByPlaylist(_:)` is exposed because the schema accepts `PLAYLIST`, but the server answers with an empty track list for every playlist tried. Treat an empty result as expected.
- `search` requires authorization: with an anonymous token it returns `data.search: null` and no error.
- State-changing endpoints (playlist `V1` mutations, batch collection add, `setProfileSettings`, recommender onboarding, migration) are implemented but **not** covered by tests and have not been executed. Every read endpoint is exercised against the live API.

## [0.3.0] - 2026-04-14

### Fixed

- **Search section filters** — the `tracks`/`artists`/`releases`/`playlists`/`podcasts`/`episodes`/`profiles`/`books` parameters on `search(...)` were silently ignored by the server because variables were sent as `withTracks`, `withArtists`, etc. while the GraphQL query declared them as `$tracks`, `$artists`, etc. Disabled sections were always returned regardless.
- **Search cursors** — `artistCursor`, `releaseCursor`, and `playlistCursor` parameters were sent under the wrong names and silently dropped on the server. Renamed to match the GraphQL query: `artistsCursor`, `releasesCursor`, `playlistsCursor`.
- **`SimpleEpisode` dropped fields** — `availability` and `podcast` were fetched by the `search` query but discarded during decoding. Both are now exposed on the model.

### Added

- `searchTracks(_:limit:cursor:)`, `searchArtists(...)`, `searchReleases(...)`, `searchPlaylists(...)`, `searchPodcasts(...)`, `searchEpisodes(...)`, `searchProfiles(...)`, `searchBooks(_:limit:)` — per-section search helpers with cursor-based pagination
- `episodesCursor`, `profilesCursor`, `podcastsCursor` parameters on `search(...)` to round out pagination coverage matching the GraphQL query

## [0.2.0] - 2026-03-26

### Added

- **Personal Wave** — `getPersonalWave()` with mood (energy/fun), genre, language, vocal, and popularity filters
- **Radio by Artist** — `getRadioByArtist(_:limit:cursor:)` with cursor-based pagination
- **Radio by Track** — `getRadioByTrack(_:limit:cursor:)` with cursor-based pagination
- **Subscription Info** — `getSubscription()` REST endpoint returning plan details, expiration, payment info
- **Feature Flags** — `getFeaturedInfo()` REST endpoint returning feature flags, country, and device targeting
- **Grid Page Layouts** — `getGrid(name:)` REST endpoint returning full page structure with sections and content IDs
- **Grid Content Lists** — `getGridContent(name:)` REST endpoint returning flat lists of typed IDs (top-100, editorial)
- **Grid Name Constants** — `GridName` and `GridContentName` enums with documented known values
- New models: `RadioResult`, `Subscription`, `SubscriptionResult`, `PaymentDetails`, `FeaturedInfo`, `GridPage`, `GridSection`, `GridSectionHeader`, `GridSectionContent`, `GridContentPage`
- New enums: `WaveGenre` (11 genres), `WaveLanguage`, `WavePopularity`, `RadioEntityType`
- Convenience helpers on `GridPage` (`sections(ofType:)`, `itemIds(ofType:)`) and `GridSection` (`playlistIds`, `releaseIds`, `artistIds`)

### Changed

- `getGridContent(name:)` now returns `GridContentPage` instead of `[GridContentItem]`
- `getEditorialPlaylistIds()` updated to use the new `GridContentPage` return type

## [0.1.0] - 2026-03-20

### Added

- Initial release
- Authentication (anonymous token, authorized token)
- Search (quick search, full-text search)
- Tracks (get, stream URL, direct stream, download, lyrics)
- Artists (get with releases, popular tracks, related artists)
- Releases (get with tracks)
- Playlists (CRUD, tracks, visibility)
- Podcasts and episodes
- Books and chapters
- Collection management (likes, hidden tracks)
- Paginated collection with cursor-based pagination
- Notifications feed with filtering and pagination
- Music recommendations (dynamic blocks)
- Listening history
- Profile and social (followers, following)
- Synthesis playlists (AI-generated)
- Editorial content (grid content)
- Rate limiting and proxy support
- Comprehensive error handling
