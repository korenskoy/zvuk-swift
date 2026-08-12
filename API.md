# ZvukMusic API Reference

Complete catalogue of the GraphQL operations this package speaks and the Swift
methods that wrap them.

The operations were recovered from the zvuk.com web client (build **v8.6.2**) by
extracting the pre-compiled GraphQL documents embedded in its JavaScript bundle.
Zvuk publishes no API documentation and its schema has introspection disabled,
so every request shape here comes from that extraction plus live verification.

**Transport.** `POST https://zvuk.com/api/v1/graphql`, token in the
`X-Auth-Token` header. A realistic `User-Agent` is mandatory — without one the
WAF answers with an HTML error page instead of JSON. Requests must be issued
**sequentially**; the API is unofficial and parallel bursts attract attention.

**Authorization.** An anonymous token (`ZvukClient.getAnonymousToken()`) reaches
public catalogue data only. Search, collection, history and streaming above
128 kbps all require a real account token.

**Verification status.** Every read endpoint listed below is called once against the live API by
`Tests/ZvukMusicTests/APIIntegrationTests.swift` (50 tests, all passing) to
confirm the response decodes into its model. Endpoints that mutate state — playlist `V1` mutations, collection
batch-add, `setProfileSettings`, recommender onboarding, migration — are **not**
covered by tests and have not been executed.

---

## Method index

### Core client (pre-existing)

| Swift method | Returns | GraphQL operation | Description |
|---|---|---|---|
| `getAnonymousToken` | `String` | — | Get an anonymous token (limited access: mid quality only, no likes/collection). |
| `getProfile` | `Profile` | — | Get the current user's profile. |
| `isAuthorized` | `Bool` | — | Check if the user is authorized (not anonymous). |
| `quickSearch` | `QuickSearch` | `quickSearch` | Quick search with autocomplete. |
| `search` | `Search` | `search` | Full-text search with filters and pagination. |
| `searchTracks` | `SearchResult<SimpleTrack>` | — | Search only tracks. Supports cursor-based pagination. |
| `searchArtists` | `SearchResult<SimpleArtist>` | — | Search only artists. Supports cursor-based pagination. |
| `searchReleases` | `SearchResult<SimpleRelease>` | — | Search only releases. Supports cursor-based pagination. |
| `searchPlaylists` | `SearchResult<SimplePlaylist>` | — | Search only playlists. Supports cursor-based pagination. |
| `searchPodcasts` | `SearchResult<SimplePodcast>` | — | Search only podcasts. Supports cursor-based pagination. |
| `searchEpisodes` | `SearchResult<SimpleEpisode>` | — | Search only podcast episodes. Supports cursor-based pagination. |
| `searchProfiles` | `SearchResult<SimpleProfile>` | — | Search only profiles. Supports cursor-based pagination. |
| `searchBooks` | `SearchResult<SimpleBook>` | — | Search only books. |
| `getTracks` | `[Track]` | `getTracks` | Get tracks by ID. |
| `getTrack` | `Track?` | — | Get a single track by ID. |
| `getFullTrack` | `[Track]` | `getFullTrack` | Get full track information with optional artists and releases. |
| `getStreamURLs` | `[Stream]` | `getStream` | Get streaming URLs for tracks. |
| `getStreamURL` | `String` | — | Get streaming URL for specified quality. |
| `getDirectStreamURL` | `DirectStream?` | — | Get direct (non-DRM) stream URL via Tiny API. |
| `getLyrics` | `Lyrics?` | — | Get lyrics for a track. |
| `getReleases` | `[Release]` | `getReleases` | Get releases by ID. |
| `getRelease` | `Release?` | — | Get a single release by ID. |
| `getArtists` | `[Artist]` | `getArtists` | Get artists by ID with optional related data. |
| `getArtist` | `Artist?` | — | Get a single artist by ID. |
| `getPlaylists` | `[Playlist]` | `getPlaylists` | Get playlists by ID. |
| `getPlaylist` | `Playlist?` | — | Get a single playlist by ID with full track details. |
| `getShortPlaylist` | `[SimplePlaylist]` | `getShortPlaylist` | Get brief playlist information. |
| `getPlaylistTracks` | `[SimpleTrack]` | `getPlaylistTracks` | Get playlist tracks with pagination. |
| `createPlaylist` | `String` | `createPlaylistLegacy` | Create a playlist. |
| `deletePlaylist` | `Bool` | `deletePlaylist` | Delete a playlist. |
| `renamePlaylist` | `Bool` | `renamePlaylist` | Rename a playlist. |
| `addTracksToPlaylist` | `Bool` | `addTracksToPlaylist` | Add tracks to a playlist. |
| `updatePlaylist` | `Bool` | `updataPlaylist` | Update a playlist entirely. |
| `setPlaylistPublic` | `Bool` | `setPlaylistToPublic` | Change playlist visibility. |
| `synthesisPlaylistBuild` | `SynthesisPlaylist?` | `synthesisPlaylistBuild` | Create an AI-generated synthesis playlist from two authors. |
| `getSynthesisPlaylists` | `[SynthesisPlaylist]` | `synthesisPlaylist` | Get synthesis playlists by ID. |
| `getEditorialPlaylistIds` | `[String]` | — | Get editorial (curated) playlist IDs. |
| `getPodcasts` | `[Podcast]` | `getPodcasts` | Get podcasts by ID. |
| `getPodcast` | `Podcast?` | — | Get a single podcast by ID. |
| `getEpisodes` | `[Episode]` | `getEpisodes` | Get episodes by ID. |
| `getEpisode` | `Episode?` | — | Get a single episode by ID. |
| `getCollection` | `Collection` | `userCollection` | Get the user's collection of liked items. |
| `getLikedTracks` | `[Track]` | `userTracks` | Get liked tracks with sorting. |
| `getUserPlaylists` | `[CollectionItem]` | `userPlaylists` | Get user's playlists from collection. |
| `getUserPaginatedPodcasts` | `[String: Any]` | `userPaginatedPodcasts` | Get user's podcasts with pagination. |
| `getPaginatedCollection` | `PaginatedCollection` | `getPaginatedCollectionAll` | Get paginated collection with all item types. |
| `addToCollection` | `Bool` | `addItemToCollection` | Add an item to the collection (like). |
| `removeFromCollection` | `Bool` | `removeItemFromCollection` | Remove an item from the collection (unlike). |
| `likeTrack` | `Bool` | — |  |
| `unlikeTrack` | `Bool` | — |  |
| `likeRelease` | `Bool` | — |  |
| `unlikeRelease` | `Bool` | — |  |
| `likeArtist` | `Bool` | — |  |
| `unlikeArtist` | `Bool` | — |  |
| `likePlaylist` | `Bool` | — |  |
| `unlikePlaylist` | `Bool` | — |  |
| `likePodcast` | `Bool` | — |  |
| `unlikePodcast` | `Bool` | — |  |
| `getHiddenCollection` | `HiddenCollection` | `getAllHiddenCollection` | Get all hidden items. |
| `getHiddenTracks` | `[CollectionItem]` | `getHiddenTracks` | Get hidden tracks. |
| `addToHidden` | `Bool` | `addItemToHidden` | Hide an item. |
| `removeFromHidden` | `Bool` | `removeItemFromHidden` | Remove an item from hidden. |
| `hideTrack` | `Bool` | — | Hide a track. |
| `unhideTrack` | `Bool` | — | Unhide a track. |
| `getProfileFollowersCount` | `[Int]` | `profileFollowersCount` | Get profile followers count. |
| `getFollowingCount` | `Int` | `followingCount` | Get following count for a profile. |
| `getListeningHistoryRaw` | `[[String: Any]]` | `listeningHistory` | Get listening history (raw). |
| `getListeningHistory` | `[HistoryEntry]` | `listeningHistory` | Get listening history as typed entries. |
| `getListenedEpisodes` | `[[String: Any]]` | `listenedEpisodes` | Get listened episodes. |
| `hasUnreadNotifications` | `Bool` | `notificationsHasUnread` | Check for unread notifications. |
| `readAllNotifications` | `` | `readAllNotifications` | Mark all notifications as read. |
| `getNotifications` | `NotificationsFeed` | `getNotifications` | Get notifications feed with cursor-based pagination. |
| `getMusicRecommendations` | `DynamicBlock` | `getMusicRecommendations` | Get music recommendations (dynamic block). |
| `getPersonalWave` | `[Track]` | `getPersonalWave` | Get personalized wave tracks. |
| `getRadioByArtist` | `RadioResult` | — | Get radio (similar tracks) by artist. |
| `getRadioByTrack` | `RadioResult` | — | Get radio (similar tracks) by track. |
| `getSubscription` | `SubscriptionResult` | — | Get current user's subscription info. |
| `getGrid` | `GridPage` | — | Get a grid page layout (sections with content IDs). |
| `getGridContent` | `GridContentPage` | — | Get grid content items (e.g. top-100 artist/podcast IDs). |
| `getFeaturedInfo` | `FeaturedInfo` | — | Get feature flags and user targeting info. |
| `download` | `` | — | Download a file to the specified path. |

### Internet radio & recommender radio

| Swift method | Returns | GraphQL operation | Description |
|---|---|---|---|
| `getRadioStations` | `[RadioStation]` | `getRadioStationsList` | Get the list of internet radio stations. |
| `getRadioStations` | `[RadioStation]` | `getRadioStation` | Get specific radio stations by ID. |
| `getRadioStation` | `RadioStation?` | — | Get a single radio station by ID. |
| `getRadioByRelease` | `RadioResult` | — | Get radio (similar tracks) seeded by a release. |
| `getRadioByPlaylist` | `RadioResult` | — | Get radio (similar tracks) seeded by a playlist. |

### Waves

| Swift method | Returns | GraphQL operation | Description |
|---|---|---|---|
| `getWaves` | `[WaveInfo]` | `getWavesShortInfo` | Get short info about waves by ID. |
| `getWave` | `WaveInfo?` | — | Get a single wave by ID. |
| `getWaveContent` | `[WaveContentItem]` | `waveContent` | Get the next batch of content for a wave. |
| `getKidsWaveContent` | `[Track]` | `kidsWaveContent` | Get content of a kids wave. |
| `getClusterWaveContent` | `[Track]` | `getClusterWaveContentShortInfo` | Get tracks of a personal-wave cluster. |

### Recently played, counters & subscriptions

| Swift method | Returns | GraphQL operation | Description |
|---|---|---|---|
| `getRecentlyPlayed` | `[RecentItem]` | `getListeningRecent` | Get recently played entities. |
| `getCollectionTracksCount` | `Int` | `getCollectionCount` | Get the number of tracks in the user's collection. |
| `getCollectionIDs` | `CollectionIDs` | `getCollectionIds` | Get IDs of every item in the user's collection, grouped by content type. |
| `getOwnPlaylistIDs` | `[String]` | `getPlaylistIds` | Get IDs of the user's own playlists. |
| `getArtistLikesCount` | `[Int]` | `getLikesCount` | Get how many users liked each of the given artists. |
| `getSubscriptions` | `UserSubscriptions` | `getSubscriptions` | Get the current user's subscriptions. |
| `getUnreadNotificationsCount` | `Int` | `getUnreadNotificationsCount` | Get the number of unread notifications. |
| `getNotificationsCount` | `Int` | `getNotificationsCount` | Get the total number of notifications of the given types. |
| `getDynamicBlockPagesCount` | `Int` | `getDynamicBlockPagesCount` | Get the number of pages in the home screen dynamic block. |
| `getProfileListeningStatistics` | `[String: AnyCodable]` | `getMostListenedTrack` | Get listening statistics published on the given profiles. |

### Search suggestions

| Swift method | Returns | GraphQL operation | Description |
|---|---|---|---|
| `getSearchAutocomplete` | `[String]` | `getSearchAutocomplete` | Get query completions for a partially typed search string. |
| `getPopularSearches` | `PopularSearches` | `getPopularSearches` | Get what other users are searching for right now. |
| `getBlendedSearch` | `AnyCodable` | `getBlendedSearch` | Search across all content types at once, ranked by relevance. |
| `searchArtistIDs` | `[String]` | — | Search for artist IDs only. |
| `searchPodcastIDs` | `[String]` | — | Search for podcast IDs only. |
| `searchBookIDs` | `[String]` | — | Search for book IDs only. |
| `searchBookAuthorIDs` | `[String]` | — | Search for book-author IDs only. |

### Artists

| Swift method | Returns | GraphQL operation | Description |
|---|---|---|---|
| `getArtistsShortInfo` | `[Artist]` | `getArtistsShortInfo` | Get just the name and cover of artists. |
| `getArtistsShortInfoWithImages` | `[Artist]` | — | Get artists together with cover art of their most popular releases. |
| `getArtistPopularTracks` | `[Track]` | `getArtistPopularTracks` | Get an artist's most popular tracks, offset-paginated. |
| `getArtistPopularTracksPage` | `PaginatedResult<Track>` | `getArtistCursorPopularTracks` | Get an artist's most popular tracks, cursor-paginated. |
| `getArtistReleasesPage` | `PaginatedResult<Release>` | `getArtistReleases` | Get an artist's releases, cursor-paginated and filterable by type. |
| `getArtistAlbums` | `PaginatedResult<Release>` | — | Get an artist's albums. |
| `getArtistSingles` | `PaginatedResult<Release>` | — | Get an artist's singles and EPs. |
| `getArtistCompilations` | `PaginatedResult<Release>` | — | Get compilations the artist appears on. |
| `getArtistDiscography` | `PaginatedResult<Release>` | — | Get an artist's full discography, unfiltered. |
| `getRelatedArtists` | `[Artist]` | `getRelatedArtists` | Get artists similar to the given one, with their popular tracks. |
| `getRelatedArtistsSimple` | `[Artist]` | `getRelatedArtistsSimple` | Get artists similar to the given one, names and covers only. |
| `getArtistPage` | `[Artist]` | `artist` | Get everything the web artist page shows, in one request. |

### Releases & tracks

| Swift method | Returns | GraphQL operation | Description |
|---|---|---|---|
| `getRelatedReleases` | `[Release]` | `getRelatedReleases` | Get releases similar to the given ones. |
| `getReleasesTracks` | `[Track]` | `getReleasesTracks` | Get the track list of releases without the rest of the release metadata. |
| `getReleasesShortInfo` | `[Release]` | `getShortsReleasesInfo` | Get title, type and cover of releases without their track lists. |
| `getTracksShortInfo` | `[Track]` | `getShortsTracksInfo` | Get tracks with the same field set the web player uses. |
| `getTracksMinimalInfo` | `[Track]` | `getNotFoundPageTrackInfo` | Get minimal track info: title, duration, artists and release. |
| `getTrackStreamPreviews` | `[String: String]` | `getTrackStreamPreview` | Get short preview stream URLs for tracks. |

### Playlists

| Swift method | Returns | GraphQL operation | Description |
|---|---|---|---|
| `getPlaylistInfo` | `[Playlist]` | — | Get full playlist metadata plus a preview of its covers. |
| `getPlaylistsShortInfo` | `[Playlist]` | `getPlaylistsShortInfo` | Get playlist titles and covers, optionally with track lists. |
| `getRelatedPlaylists` | `[Playlist]` | `getRelatedPlaylists` | Get playlists similar to the given one. |
| `getOwnPlaylists` | `PaginatedResult<Playlist>` | `getUserPlaylist` | Get the current user's own playlists, cursor-paginated. |
| `getOwnPlaylistsShortInfo` | `PaginatedResult<Playlist>` | `getProfilesShortPlaylistsInfo` | Get the current user's own playlists, titles and IDs only. |
| `getProfilePlaylists` | `PaginatedResult<Playlist>` | `getPlaylistsProfile` | Get playlists published on someone else's profile. |
| `getProfileFirstPlaylistTracks` | `[Track]` | `getProfileFirstPlaylistTracks` | Get tracks of the first playlist on a profile. |
| `createPlaylistV1` | `String` | `createPlaylist` | Create a playlist and get its ID back. |
| `addItemsToPlaylistV1` | `String` | `addItems` | Append tracks to a playlist. |
| `updatePlaylistV1` | `String` | `updatePlaylist` | Replace a playlist's name, visibility and contents in one call. |
| `removePlaylist` | `Bool` | `removePlaylist` | Delete a playlist. |

### Collection

| Swift method | Returns | GraphQL operation | Description |
|---|---|---|---|
| `getPaginatedCollectionTracks` | `PaginatedResult<Track>` | `getPaginatedCollection` | Get liked tracks, cursor-paginated. |
| `getCollectionProfiles` | `[SimpleProfile]` | `getPaginatedCollectionProfiles` | Get profiles the user follows. |
| `getProfileCollection` | `ProfileCollection` | `getProfileCollection` | Get a compact snapshot of the user's collection for the profile screen. |
| `addItemsToCollection` | `Bool` | `AddItemsToCollection` | Add several items of mixed types to the collection in one request. |

### Podcasts

| Swift method | Returns | GraphQL operation | Description |
|---|---|---|---|
| `getPodcastEpisodes` | `[Episode]` | `getPodcastEpisodes` | Get every episode of the given podcasts. |
| `getPaginatedEpisodes` | `PaginatedResult<Episode>` | `getPaginatedEpisodes` | Get episodes of one podcast, cursor-paginated. |
| `getPodcastsByCategory` | `[Podcast]` | `getPodcastsByCategoryIds` | Get podcasts belonging to the given catalogue categories. |
| `getPodcastsRecommendations` | `[Podcast]` | `getPodcastsRecommendations` | Get recommended podcasts. |
| `getPodcastsShortInfo` | `[Podcast]` | `getCommonPodcasts` | Get podcast metadata without episode lists. |
| `getRelatedPodcasts` | `[Podcast]` | `getRelatedPodcasts` | Get podcasts similar to the given one. |

### Audiobooks

| Swift method | Returns | GraphQL operation | Description |
|---|---|---|---|
| `getAudioBooks` | `[SimpleBook]` | `getAudioBook` | Get full audiobook cards. |
| `getAudioBook` | `SimpleBook?` | — | Get a single audiobook by ID. |
| `getAudioBooksShortInfo` | `[SimpleBook]` | `getCommonAudioBook` | Get audiobook cards without the catalogue metadata (age limits, BISAC genres). |
| `getBookIdByChapter` | `String?` | `getAudioBookIdByChapter` | Resolve which book a chapter belongs to. |
| `getBookChapters` | `[Chapter]` | `getBookChapters` | Get the chapter list of audiobooks. |
| `getChapters` | `[Chapter]` | `getChaptersById` | Get chapters by ID. |
| `getChapter` | `Chapter?` | `getChapter` | Get a single chapter by ID. |
| `getBookAuthors` | `[BookAuthor]` | `getBookAuthors` | Get book authors by ID. |
| `getAuthorBooks` | `PaginatedResult<SimpleBook>` | `getCursorBooks` | Get an author's books, cursor-paginated. |
| `getBooksRecommendations` | `[SimpleBook]` | — | Get recommended audiobooks. |
| `getRelatedBooks` | `[SimpleBook]` | `getRelatedBooks` | Get books similar to the given one. |
| `getRelatedAuthors` | `[BookAuthor]` | `getRelatedAuthors` | Get authors similar to the given one. |

### Profiles, follows & account

| Swift method | Returns | GraphQL operation | Description |
|---|---|---|---|
| `getProfiles` | `[SimpleProfile]` | `getProfiles` | Get profiles by ID. |
| `getProfileImage` | `Image?` | `getProfileImage` | Get just a profile's avatar. |
| `getProfilePodcasts` | `PaginatedResult<Podcast>` | `getProfilePodcasts` | Get podcasts a profile has in its collection. |
| `getRelatedProfiles` | `[SimpleProfile]` | `getProfileRelated` | Get profiles with similar taste. |
| `getFollowers` | `PaginatedResult<SimpleProfile>` | `followers` | Get followers of a profile, artist or other followable entity. |
| `getFollowing` | `PaginatedResult<SimpleProfile>` | `following` | Get profiles that the given profiles follow. |
| `setProfileSettings` | `Bool` | `setProfileSettings` | Update the current user's public profile. |
| `getRecommendationProfile` | `AnyCodable` | `getRecommendationProfile` | Get the active recommendation campaign for this account. |
| `submitRecommenderOnboarding` | `Bool` | `RecommenderOnboardingRequest` | Submit the artists chosen during recommender onboarding. |
| `createMigration` | `AnyCodable` | `createMigration` | Start importing playlists from another streaming service. |
| `getMigrationStatus` | `AnyCodable` | `migrationStatus` | Check how far along a playlist import is. |


---

## Operation reference

Variables as declared by the web client. `—` means the operation takes none.

| Operation | Kind | Variables |
|---|---|---|
| `AddItemsToCollection` | mutation | `$items: [CollectionItemInput]!` |
| `RecommenderOnboardingRequest` | mutation | `$ids: [ID!]!` |
| `addItemToCollection` | mutation | `$id: ID, $type: CollectionItemType` |
| `addItems` | mutation | `$id: ID!, $items: [PlaylistItem!] = []` |
| `artist` | query | `$ids: [ID!]!, $withlikesCount: Boolean = false, $withRelatedArtists: Boolean = false, $withPopularTracks: Boolean = false, $withPopularReleases: Boolean = false` |
| `artistAlbumsWithProfile` | query | `$ids: [ID!]!, $limit: Int = 100, $cursor: String = null` |
| `artistCompilationsWithProfile` | query | `$ids: [ID!]!, $limit: Int = 100, $cursor: String = null` |
| `artistReleasesWithProfile` | query | `$ids: [ID!]!, $limit: Int = 100, $cursor: String = null` |
| `artistSinglesWithProfile` | query | `$ids: [ID!]!, $limit: Int = 100, $cursor: String = null` |
| `createMigration` | mutation | `$links: [String!]!` |
| `createPlaylist` | mutation | `$items: [PlaylistItem!] = [], $name: String!` |
| `followers` | query | `$id: ID!, $itemType: FollowItemType! = profile, $cursor: String, $followersLimit: Int = 100` |
| `following` | query | `$id: [ID!]!, $cursor: String, $followingLimit: Int = 30` |
| `getArtistCursorPopularTracks` | query | `$ids: [ID!]!, $limit: Int!, $cursor: String, $withPreview: Boolean = false` |
| `getArtistPopularTracks` | query | `$ids: [ID!]!, $limit: Int!, $offset: Int!` |
| `getArtistReleases` | query | `$ids: [ID!]!, $limit: Int = 12, $includeTypes: [String!] = null, $excludeTypes: [String!] = null, $cursor: String = null` |
| `getArtistsShortInfo` | query | `$ids: [ID!]!, $withlikesCount: Boolean = false` |
| `getArtistsShortInfoWithImages` | query | `$ids: [ID!]!, $limitTracksImages: Int = 2` |
| `getAudioBook` | query | `$ids: [ID!]!, $withChapters: Boolean = false` |
| `getAudioBookIdByChapter` | query | `$id: ID!` |
| `getBlendedSearch` | query | `$limit: Int = 100, $query: String!` |
| `getBookAuthors` | query | `$ids: [ID!]!, $withLikesCount: Boolean = false` |
| `getBookChapters` | query | `$ids: [ID!]!` |
| `getBooksRecommendations` | query | `$first: Int!, $recType: RecBookTypeEnum!, $skip: Int! = 0, $withAuthors: Boolean = false` |
| `getChapter` | query | `$id: ID!` |
| `getChaptersById` | query | `$ids: [ID!]!` |
| `getClusterWaveContentShortInfo` | query | `$clusterId: NonNegativeInt!, $first: PositiveInt! = 1, $contentInput: PersonalWaveContentInput` |
| `getCollectionCount` | query | `—` |
| `getCollectionIds` | query | `—` |
| `getCommonAudioBook` | query | `$ids: [ID!]!, $withChapters: Boolean = false` |
| `getCommonPodcasts` | query | `$ids: [ID!]!` |
| `getCursorBooks` | query | `$ids: [ID!]!, $cursor: String = null, $limit: Int = 100` |
| `getDynamicBlockPagesCount` | query | `—` |
| `getEpisodes` | query | `$ids: [ID!]!` |
| `getFullTrack` | query | `$id: ID!, $withReleases: Boolean = false, $withArtists: Boolean = false, $withLikesCount: Boolean = false` |
| `getLikesCount` | query | `$ids: [ID!]!` |
| `getListeningRecent` | query | `$limit: Int = 30, $offset: Int = 0, $itemType: [RecentItemType!], $isKidContent: Boolean` |
| `getMostListenedTrack` | query | `$ids: [ID!]!` |
| `getMusicRecommendations` | query | `$contentType: DynamicBlockContentType!, $itemType: [DynamicBlockItemType!], $pages: [Int!]!` |
| `getNotFoundPageTrackInfo` | query | `$ids: [ID!]!` |
| `getNotificationsCount` | query | `$availableTypes: [NotificationTypes!]` |
| `getPaginatedCollection` | query | `$limit: Int = 30, $after: String = null` |
| `getPaginatedCollectionAll` | query | `$limit: Int = 30, $limitTracksOnPlaylist: Int = 3, $after: String = null, $withPlaylists: Boolean = false, $withReleases: Boolean = false, $withArtists: Boolean = false, $withPodcasts: Boolean = false, $withBooks: Boolean = false, $withEpisodes: Boolean = false` |
| `getPaginatedCollectionProfiles` | query | `$limit: Int = 1000` |
| `getPaginatedEpisodes` | query | `$ids: ID!, $limit: Int, $cursor: String, $order: OrderType!` |
| `getPersonalWave` | query | `$contentInput: PersonalWaveContentInput, $first: PositiveInt! = 2, $options: PersonalWaveOptions, $waveInput: WaveInput, $waveSrc: MagicSource` |
| `getPlaylistIds` | query | `—` |
| `getPlaylistInfo` | query | `$ids: [ID!]!, $first: Int = 3, $uniqueReleases: Boolean = true` |
| `getPlaylistTracks` | query | `$id: ID!, $limit: Int = 30, $offset: Int = 0` |
| `getPlaylistsProfile` | query | `$ids: [ID!]!, $limit: Int = 1, $limitTracks: Int = 3, $uniqueReleases: Boolean = true, $after: String = null` |
| `getPlaylistsShortInfo` | query | `$ids: [ID!]!, $withTracks: Boolean = false` |
| `getPodcastEpisodes` | query | `$ids: [ID!]!` |
| `getPodcasts` | query | `$ids: [ID!]!, $withEpisodes: Boolean = false, $withLikesCount: Boolean = false` |
| `getPodcastsByCategoryIds` | query | `$endCursor: String, $first: Int, $ids: [ID!]!, $last: Int, $sortBy: SortByEnum, $startCursor: String` |
| `getPodcastsRecommendations` | query | `$first: Int!, $recType: RecPodcastTypeEnum!, $skip: Int! = 0` |
| `getPopularSearches` | query | `$cursor: PageCursor = null, $explicit: Boolean, $limit: PositiveInt` |
| `getProfileCollection` | query | `$limit: PositiveInt = 10, $relatedArtistsLimit: Int = 10, $limitTracks: Int = 4, $uniqueReleases: Boolean = false` |
| `getProfileFirstPlaylistTracks` | query | `$ids: [ID!]!, $playlistTracksLimit: Int = 10, $playlistTracksOffset: Int = 0` |
| `getProfileImage` | query | `$id: ID!` |
| `getProfilePodcasts` | query | `$ids: [ID!]!, $cursor: String, $limit: Int, $withTotal: Boolean = false` |
| `getProfileRelated` | query | `$ids: [ID!]!, $limit: Int = 12` |
| `getProfiles` | query | `$ids: [ID!]!, $withPlaylists: Boolean = false, $countPlaylists: Int = 0, $playlistTracksLimit: Int = 10, $playlistTracksOffset: Int = 0` |
| `getProfilesShortPlaylistsInfo` | query | `$limit: Int = 6, $offset: String = null` |
| `getRadioStation` | query | `$ids: [ID!]!` |
| `getRadioStationsList` | query | `$limit: Int!, $offset: Int!` |
| `getRecommendationProfile` | query | `—` |
| `getRelatedArtists` | query | `$id: ID!, $limitArtists: PositiveInt!, $withPopularTrackArtist: Boolean! = true, $limitPopularTracks: Int!` |
| `getRelatedArtistsSimple` | query | `$id: ID!, $limitArtists: PositiveInt!` |
| `getRelatedAuthors` | query | `$id: ID!, $limitAuthors: Int` |
| `getRelatedBooks` | query | `$id: ID!, $limitBooks: Int` |
| `getRelatedPlaylists` | query | `$id: ID!, $limit: Int = 30` |
| `getRelatedPodcasts` | query | `$id: ID!, $limitPodcasts: Int` |
| `getRelatedReleases` | query | `$ids: [ID!]!, $limit: Int! = 100` |
| `getReleases` | query | `$ids: [ID!]!, $withTracks: Boolean! = false, $withRelated: Boolean! = false, $withArtists: Boolean! = false, $withPopularTrackArtist: Boolean! = false, $withReleasesArtist: Boolean! = false, $relatedLimit: Int! = 12, $popularTrackLimit: Int! = 3, $withLikesCount: Boolean = false, $withArtistsLikesCount: Boolean = false` |
| `getReleasesTracks` | query | `$ids: [ID!]!` |
| `getSearchAutocomplete` | query | `$query: String!, $limit: Int = 5` |
| `getShortsReleasesInfo` | query | `$ids: [ID!]!, $withArtists: Boolean! = false` |
| `getShortsTracksInfo` | query | `$ids: [ID!]!` |
| `getStream` | query | `$ids: [ID!]!, $quality: String, $encodeType: String, $includeFlacDrm: Boolean!, $useHLSv2: Boolean!` |
| `getSubscriptions` | query | `$status: [ActualUserSubscriptionStatus!]` |
| `getTrackStreamPreview` | query | `$ids: [ID!]!, $quality: String, $encodeType: String` |
| `getUnreadNotificationsCount` | query | `$availableTypes: [NotificationTypes!]` |
| `getUserPlaylist` | query | `$limit: Int = 6, $offset: String = null` |
| `getWavesShortInfo` | query | `$ids: [ID!]!` |
| `kidsWaveContent` | query | `$contentInput: KidsWaveContentInput, $waveSrc: WaveSource` |
| `migrationStatus` | query | `$migrationIds: [Int!]!` |
| `profileFollowersCount` | query | `$ids: [ID!]!, $withFollowing: Boolean = false, $withFollowers: Boolean = false` |
| `readAllNotifications` | mutation | `—` |
| `removeItemFromCollection` | mutation | `$id: ID, $type: CollectionItemType` |
| `removePlaylist` | mutation | `$id: ID!` |
| `setProfileSettings` | mutation | `$name: String, $description: String` |
| `updatePlaylist` | mutation | `$id: ID!, $isPublic: Boolean!, $items: [PlaylistItem!] = [], $name: String!` |
| `waveContent` | query | `$contentInput: WaveContentInput!` |

---

## Enum values recovered from the server

The schema hides introspection, so these were established by sending a
deliberately invalid value and reading the rejection, then confirming the
suggestion with a real request.

| GraphQL enum | Values | Notes |
|---|---|---|
| `RecommenderRadioEntityType` | `ARTIST`, `TRACK`, `RELEASE`, `PLAYLIST` | `RELEASE` and `PLAYLIST` confirmed by live request |
| `RecentItemType` | `Artist`, `Release`, `Playlist`, `Podcast`, `Book`, `RadioStation`, `PersonalWave`, `EditorialWave`, `FavoriteTracks` | PascalCase — mirrors the union's type names, not the usual SCREAMING_CASE |
| `OrderType` | `newest`, `oldest` | Lower-case. The web client keeps `"DESC"`/`"ASC"` internally and translates before querying |
| `RecBookTypeEnum` | `BOOK` (others unknown) | Only value the web client sends |
| `RecPodcastTypeEnum` | `PODCAST` (others unknown) | Only value the web client sends |

Swift wrappers: `RadioEntityType`, `RecentItemType`, `EpisodeOrder`. The two
recommendation types stay `String` parameters with a working default, because
their full value sets could not be enumerated.

---

## Notes on specific operations

### `listeningRecentV1` is not a track history

The union it returns (`UnionRecentMediaContent`) has eleven members — `Artist`,
`Release`, `Playlist`, `Podcast`, `Book`, `RadioStation`, `PersonalWave`,
`EditorialWave`, `FavoriteTracks`, `RadioArtist`, `RadioTrack` — and `Track` is
**not** among them. It answers "what did the user open recently", not "what did
they listen to". For tracks use `getListeningHistory(limit:)`, which is backed
by the separate `listeningHistory` query and still works.

### Waves need a local timestamp

`WaveContentInput` requires both `waveId` and `localtime: DateTime!`. The
server uses the timestamp when picking content, so morning and evening
listeners get different streams. `getWaveContent(waveId:localtime:)` fills it
in from `Date()` by default.

Wave IDs are small and stable: `1` is "МегаХит". Discover more through
`getRecentlyPlayed` entries of type `editorialWave`.

### Radio: one query, four names

The web client ships `getRadioByTrack`, `getRadioByArtistTracks`,
`getRadioByRelease` and `getRadioByPlaylist` as four separate documents that
differ only in the `RecommenderRadioEntityType` they pass. This package keeps
the single `getRadioByEntity` query and exposes four wrappers, so those four
documents are intentionally absent from `Resources/Queries`.

**Playlist radio returns nothing.** `PLAYLIST` is accepted by the schema but
every playlist tried — editorial and user-made, authorized and anonymous —
comes back with an empty track list and `cursor: 0`. `getRadioByPlaylist(_:)`
is provided because the API exposes it; an empty result is expected, not a bug.

### Per-section search was already implemented

`getSearchTracks`, `getSearchArtists`, `getSearchReleaseas` (sic),
`getSearchPlaylists`, `getSearchPodcasts`, `getSearchEpisodes`,
`getSearchProfiles`, `getSearchBooks`, `getSearchBookAuthors` and
`getSearchAll` duplicate the `search`-based methods this package already had
(`searchTracks(_:limit:cursor:)` and friends). They are deliberately not
bundled a second time. The ID-only variants — `getSearchArtistIds`,
`getSearchPodcastIds`, `getSearchBookIds`, `getSearchAuthorIds` — *are*
included, because fetching one field instead of a full entity is a meaningful
saving.

Note that `search` requires authorization: with an anonymous token it returns
`data.search: null` and **no error**, which is easy to mistake for a breakage.

### Playlist mutations come in two generations

The older `create`/`addItems`/`update` mutations return scalars; the web client
now calls `createV1`/`addItemsV1`/`updateV1`, which return `{ id }`. Both are
available — `createPlaylist(_:trackIds:)` uses the old one (stored as
`createPlaylistLegacy.graphql`), `createPlaylistV1(name:trackIds:)` the new one.
Prefer the `V1` variants when you need the resulting ID.

### Raw payloads

Four operations return shapes that vary too much to model usefully, so they
come back as `AnyCodable`: `getBlendedSearch`, `getRecommendationProfile`,
`createMigration` and `migrationStatus`. `getProfileListeningStatistics`
likewise returns `[String: AnyCodable]` because `statistics.data` changes shape
per period.
