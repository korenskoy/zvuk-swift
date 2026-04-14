# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
