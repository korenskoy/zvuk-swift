import Foundation
import Testing

@testable import ZvukMusic

// Проверка работоспособности: радио, волны, подсказки поиска, дискография,
// подкасты, аудиокниги, профили и авторизованное чтение коллекции.
//
// Каждый метод вызывается один раз на реальных данных — это не разбор
// граничных случаев, а ответ на вопрос «запрос и модель вообще сходятся?».
// Схема Zvuk закрыта для интроспекции, так что проверить это иначе нельзя:
// важно, что ответ разобрался в модель, а не просто вернулся со статусом 200.
//
// Запускать строго последовательно (`swift test --no-parallel`): параллельные
// запросы к Zvuk недопустимы.

@Suite("Integration / Radio Stations", .serialized)
struct RadioStationTests {
    let client: ZvukClient

    init() async throws {
        client = try await SharedClient.shared.get()
    }

    @Test("Radio stations list decodes")
    func radioStations() async throws {
        let stations = try await client.getRadioStations(limit: 5)
        #expect(!stations.isEmpty, "Каталог радиостанций не должен быть пустым")
        #expect(stations.allSatisfy { !$0.id.isEmpty && !$0.name.isEmpty })
    }

    /// `source` — массив, а не строка: пока он был объявлен `String?`,
    /// `try?` глотал несоответствие типов и станция приходила без потока.
    /// Поэтому проверяется значение, а не факт разбора.
    @Test("Radio stations carry a playable stream")
    func radioStationsHaveStreams() async throws {
        let stations = try await client.getRadioStations(limit: 30)
        let withStream = stations.filter { $0.streamURL != nil }
        #expect(withStream.count == stations.count,
                "Поток должен быть у каждой станции, а он есть у \(withStream.count) из \(stations.count)")
        // Форматы разные: HLS-плейлисты у большинства, прямые Icecast-потоки
        // (.mp3, .aacp, без расширения) у меньшинства. Общее — рабочая http(s)-ссылка.
        #expect(stations.allSatisfy { $0.streamURL?.scheme?.hasPrefix("http") ?? false })
    }

    @Test("Radio station by ID decodes")
    func radioStationById() async throws {
        let station = try await client.getRadioStation("1")
        #expect(station?.id == "1")
        #expect(station?.name.isEmpty == false)
    }
}

@Suite("Integration / Waves", .serialized)
struct WaveTests {
    let client: ZvukClient

    init() async throws {
        client = try await SharedClient.shared.get()
    }

    @Test("Editorial wave info decodes")
    func waveInfo() async throws {
        let wave = try await client.getWave("1")
        #expect(wave?.id == "1")
        #expect(wave?.title.isEmpty == false)
    }
}

@Suite("Integration / Search Suggestions", .serialized)
struct SearchSuggestionTests {
    let client: ZvukClient

    init() async throws {
        client = try await SharedClient.shared.get()
    }

    @Test("Autocomplete returns suggestions")
    func autocomplete() async throws {
        let suggestions = try await client.getSearchAutocomplete("нирв", limit: 5)
        #expect(!suggestions.isEmpty)
    }

    @Test("Popular searches decode")
    func popularSearches() async throws {
        let popular = try await client.getPopularSearches(limit: 5)
        #expect(!popular.queries.isEmpty)
    }

    @Test("Artist ID search resolves a name")
    func artistIds() async throws {
        let ids = try await client.searchArtistIDs("Radiohead", limit: 1)
        #expect(!ids.isEmpty)
    }
}

@Suite("Integration / Artist Discography", .serialized)
struct ArtistDiscographyTests {
    let client: ZvukClient

    init() async throws {
        client = try await SharedClient.shared.get()
    }

    /// Radiohead — стабильный публичный артист.
    private let artistId = "433980"

    @Test("Short artist info decodes")
    func shortInfo() async throws {
        let artists = try await client.getArtistsShortInfo([artistId])
        #expect(artists.first?.title.isEmpty == false)
    }

    @Test("Popular tracks decode")
    func popularTracks() async throws {
        let tracks = try await client.getArtistPopularTracks(artistId, limit: 5)
        #expect(!tracks.isEmpty)
    }

    /// Курсор проверяется отдельно: `Request` переводит ключи ответа в
    /// camelCase, и сопоставление с `page_info` молча давало пустую страницу —
    /// ошибка, которую проверка одних лишь items не ловит.
    @Test("Cursor-paginated popular tracks carry a usable cursor")
    func popularTracksPage() async throws {
        let page = try await client.getArtistPopularTracksPage(artistId, limit: 5)
        #expect(!page.items.isEmpty)
        #expect(page.page.hasNextPage, "У Radiohead больше пяти популярных треков")
        #expect(page.page.endCursor?.isEmpty == false)

        let next = try await client.getArtistPopularTracksPage(
            artistId, limit: 5, cursor: page.page.endCursor)
        #expect(!next.items.isEmpty)
        #expect(next.items.first?.id != page.items.first?.id, "Вторая страница должна отличаться")
    }

    @Test("Releases page decodes")
    func releasesPage() async throws {
        let page = try await client.getArtistReleasesPage(artistId, limit: 5)
        #expect(!page.items.isEmpty)
    }

    @Test("Related artists decode")
    func relatedArtists() async throws {
        let artists = try await client.getRelatedArtistsSimple(artistId, limit: 5)
        #expect(!artists.isEmpty)
    }
}

@Suite("Integration / Release Details", .serialized)
struct ReleaseDetailTests {
    let client: ZvukClient

    init() async throws {
        client = try await SharedClient.shared.get()
    }

    /// "The Bends" — стабильный публичный релиз.
    private let releaseId = "14607201"

    @Test("Related releases decode")
    func relatedReleases() async throws {
        let releases = try await client.getRelatedReleases([releaseId], limit: 5)
        #expect(!releases.isEmpty)
    }

    @Test("Release tracks decode")
    func releaseTracks() async throws {
        let tracks = try await client.getReleasesTracks([releaseId])
        #expect(!tracks.isEmpty)
    }

    @Test("Short release info decodes")
    func shortInfo() async throws {
        let releases = try await client.getReleasesShortInfo([releaseId])
        #expect(releases.first?.title.isEmpty == false)
    }
}

@Suite("Integration / Podcasts", .serialized)
struct PodcastTests {
    let client: ZvukClient

    init() async throws {
        client = try await SharedClient.shared.get()
    }

    private let podcastId = "49509660"

    @Test("Podcast short info decodes")
    func shortInfo() async throws {
        let podcasts = try await client.getPodcastsShortInfo([podcastId])
        #expect(podcasts.first?.title.isEmpty == false)
    }

    @Test("Podcast episodes decode")
    func episodes() async throws {
        let episodes = try await client.getPodcastEpisodes([podcastId])
        #expect(!episodes.isEmpty)
    }

    @Test("Paginated episodes decode")
    func paginatedEpisodes() async throws {
        let page = try await client.getPaginatedEpisodes(podcastId, limit: 5)
        #expect(!page.items.isEmpty)
    }

    @Test("Related podcasts decode")
    func related() async throws {
        let podcasts = try await client.getRelatedPodcasts(podcastId, limit: 5)
        #expect(!podcasts.isEmpty)
    }

    @Test("Podcast recommendations decode")
    func recommendations() async throws {
        let podcasts = try await client.getPodcastsRecommendations(first: 3)
        #expect(!podcasts.isEmpty)
    }
}

@Suite("Integration / Audiobooks", .serialized)
struct AudiobookTests {
    let client: ZvukClient

    init() async throws {
        client = try await SharedClient.shared.get()
    }

    private let bookId = "35036265"
    private let authorId = "3298"

    @Test("Audiobook decodes")
    func book() async throws {
        let book = try await client.getAudioBook(bookId)
        #expect(book?.title.isEmpty == false)
    }

    @Test("Short audiobook info decodes")
    func shortInfo() async throws {
        let books = try await client.getAudioBooksShortInfo([bookId])
        #expect(books.first?.title.isEmpty == false)
    }

    @Test("Chapters decode and resolve back to their book")
    func chapters() async throws {
        let chapters = try await client.getBookChapters([bookId])
        #expect(!chapters.isEmpty)
        guard let first = chapters.first else { return }

        let byId = try await client.getChapters([first.id])
        #expect(byId.first?.id == first.id)

        let single = try await client.getChapter(first.id)
        #expect(single?.id == first.id)

        let resolved = try await client.getBookIdByChapter(first.id)
        #expect(resolved == bookId)
    }

    @Test("Book authors decode")
    func authors() async throws {
        let authors = try await client.getBookAuthors([authorId])
        #expect(authors.first?.rname.isEmpty == false)
    }

    @Test("Author books decode")
    func authorBooks() async throws {
        let page = try await client.getAuthorBooks([authorId], limit: 5)
        #expect(!page.items.isEmpty)
    }

    @Test("Related books decode")
    func relatedBooks() async throws {
        let books = try await client.getRelatedBooks(bookId, limit: 5)
        #expect(!books.isEmpty)
    }

    @Test("Related authors decode")
    func relatedAuthors() async throws {
        let authors = try await client.getRelatedAuthors(authorId, limit: 5)
        #expect(!authors.isEmpty)
    }

    @Test("Book recommendations decode")
    func recommendations() async throws {
        let books = try await client.getBooksRecommendations(first: 3)
        #expect(!books.isEmpty)
    }
}

@Suite("Integration / Seeds & Previews", .serialized)
struct SeedAndPreviewTests {
    let client: ZvukClient

    init() async throws {
        client = try await SharedClient.shared.get()
    }

    @Test("Radio by release decodes")
    func radioByRelease() async throws {
        let radio = try await client.getRadioByRelease("14607201", limit: 5)
        #expect(!radio.tracks.isEmpty)
    }

    /// Сервер принимает тип `PLAYLIST`, но неизменно отвечает пустым списком —
    /// проверено на редакционных и пользовательских плейлистах, под
    /// авторизацией тоже. Поэтому проверяем только то, что запрос проходит и
    /// разбирается, а не наличие треков.
    @Test("Radio by playlist responds without error")
    func radioByPlaylist() async throws {
        let radio = try await client.getRadioByPlaylist("5641825", limit: 5)
        #expect(radio.cursor >= 0)
    }

    @Test("Wave content decodes")
    func waveContent() async throws {
        let items = try await client.getWaveContent(waveId: "1")
        #expect(!items.isEmpty)
        #expect(items.first?.track != nil)
    }

    @Test("Stream previews decode")
    func previews() async throws {
        let previews = try await client.getTrackStreamPreviews(["85248905"])
        #expect(previews["85248905"] != nil)
    }

    @Test("Playlist info decodes")
    func playlistInfo() async throws {
        let playlists = try await client.getPlaylistInfo(["5641825"])
        #expect(playlists.first?.title.isEmpty == false)
    }

    @Test("Related playlists decode")
    func relatedPlaylists() async throws {
        let playlists = try await client.getRelatedPlaylists("5641825", limit: 5)
        #expect(!playlists.isEmpty)
    }
}

/// Методы, которым нужен токен реального аккаунта. С анонимным токеном они
/// возвращают пустоту без ошибки, поэтому осмысленны только при заполненном
/// `ZVUK_TOKEN` в `.env`.
///
/// Мутации сюда намеренно не включены: они меняют состояние аккаунта.
@Suite("Integration / Authorized Reads", .serialized)
struct AuthorizedReadTests {
    let client: ZvukClient

    init() async throws {
        client = try await SharedClient.shared.get()
    }

    @Test("Recently played decodes")
    func recentlyPlayed() async throws {
        let recent = try await client.getRecentlyPlayed(limit: 10)
        #expect(!recent.isEmpty, "У активного аккаунта должно быть недавнее")
        #expect(recent.allSatisfy { !$0.id.isEmpty })
        #expect(recent.allSatisfy { !$0.typename.isEmpty })
    }

    @Test("Recently played respects the type filter")
    func recentlyPlayedFiltered() async throws {
        let recent = try await client.getRecentlyPlayed(limit: 10, itemTypes: [.release, .playlist])
        #expect(recent.allSatisfy { $0.type == .release || $0.type == .playlist })
    }

    @Test("Collection counters agree with collection IDs")
    func collectionCounters() async throws {
        let count = try await client.getCollectionTracksCount()
        #expect(count > 0)

        let ids = try await client.getCollectionIDs()
        #expect(ids.tracks.count == count, "Счётчик треков и список id должны сходиться")
    }

    @Test("Own playlist IDs decode")
    func ownPlaylistIds() async throws {
        let ids = try await client.getOwnPlaylistIDs()
        #expect(ids.allSatisfy { !$0.isEmpty })
    }

    @Test("Own playlists decode")
    func ownPlaylists() async throws {
        let page = try await client.getOwnPlaylists(limit: 5)
        #expect(page.items.allSatisfy { !$0.id.isEmpty })
    }

    @Test("Subscriptions decode")
    func subscriptions() async throws {
        let subscriptions = try await client.getSubscriptions()
        #expect(subscriptions.main != nil, "У аккаунта должна быть активная подписка")
        #expect(subscriptions.main?.status.isEmpty == false)
    }

    /// Поля REST-подписки проверяются по значениям, а не по факту разбора:
    /// модели декодируются лениво, поэтому несовпадение ключей даёт дефолты,
    /// а не ошибку — так `plan_id`, `services_available` и `payment_details`
    /// молча приходили пустыми.
    @Test("REST subscription fields carry values, not defaults")
    func subscriptionFieldValues() async throws {
        let sub = try #require(
            try await client.getSubscription().subscription,
            "У аккаунта должна быть активная подписка")
        #expect(sub.planId != 0)
        #expect(sub.expiration != 0)
        #expect(!sub.servicesAvailable.isEmpty)
        #expect(sub.expirationDate > sub.startDate)
        // plan_price не проверяем: у партнёрских подписок он законно равен нулю.
    }

    @Test("Profile reports an authorized account")
    func profileIsAuthorized() async throws {
        let profile = try await client.getProfile()
        #expect(!profile.token.isEmpty)
        #expect(profile.isAuthorized, "Токен из .env принадлежит зарегистрированному аккаунту")
    }

    @Test("Paginated collection tracks decode")
    func paginatedCollectionTracks() async throws {
        let page = try await client.getPaginatedCollectionTracks(limit: 5)
        #expect(!page.items.isEmpty)
        #expect(page.items.allSatisfy { !$0.title.isEmpty })
    }

    @Test("Profile collection snapshot decodes")
    func profileCollection() async throws {
        let collection = try await client.getProfileCollection(limit: 5)
        #expect(!collection.artists.isEmpty || !collection.tracks.isEmpty)
    }

    @Test("Followed profiles decode")
    func collectionProfiles() async throws {
        let profiles = try await client.getCollectionProfiles(limit: 50)
        #expect(profiles.allSatisfy { !$0.id.isEmpty })
    }

    @Test("Notification counters decode")
    func notificationCounters() async throws {
        let unread = try await client.getUnreadNotificationsCount()
        #expect(unread >= 0)
    }

    @Test("Artist likes count decodes")
    func artistLikes() async throws {
        let counts = try await client.getArtistLikesCount(["433980"])
        #expect(counts.first ?? 0 > 0)
    }
}

@Suite("Integration / Profiles (public)", .serialized)
struct PublicProfileTests {
    let client: ZvukClient

    init() async throws {
        client = try await SharedClient.shared.get()
    }

    /// Публичный профиль с опубликованными плейлистами.
    private let profileId = "1142332542"

    @Test("Profile decodes")
    func profile() async throws {
        let profiles = try await client.getProfiles([profileId])
        #expect(profiles.first?.id == profileId)
    }

    @Test("Profile image decodes")
    func image() async throws {
        let image = try await client.getProfileImage(profileId)
        #expect(image != nil)
    }

    @Test("Profile playlists decode")
    func playlists() async throws {
        let page = try await client.getProfilePlaylists([profileId], limit: 3)
        #expect(!page.items.isEmpty)
    }

    @Test("First playlist tracks decode")
    func firstPlaylistTracks() async throws {
        let tracks = try await client.getProfileFirstPlaylistTracks([profileId], limit: 5)
        #expect(!tracks.isEmpty)
    }

    @Test("Followers decode")
    func followers() async throws {
        let page = try await client.getFollowers(profileId, limit: 5)
        #expect(page.items.allSatisfy { !$0.id.isEmpty })
    }

    @Test("Related profiles decode")
    func related() async throws {
        let profiles = try await client.getRelatedProfiles([profileId], limit: 5)
        #expect(profiles.allSatisfy { !$0.id.isEmpty })
    }
}
