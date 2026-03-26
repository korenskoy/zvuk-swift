# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
