import Foundation
import Testing

@testable import ZvukMusic

@Suite("Models")
struct ModelsTests {

    // MARK: - Image

    @Test func imageGetURL() {
        let image = Image(src: "/static/cover.jpg")
        let url = image.getURL(width: 200, height: 200)
        #expect(url.contains("https://zvuk.com/static/cover.jpg"))
        #expect(url.contains("size=200x200"))
    }

    @Test func imageGetURLWithExistingParams() {
        let image = Image(src: "https://cdn.zvuk.com/img.jpg?foo=bar")
        let url = image.getURL(width: 300, height: 300)
        #expect(url.contains("size=300x300"))
        #expect(url.contains("foo=bar"))
    }

    // MARK: - Track

    @Test func simpleTrackDuration() {
        let track = SimpleTrack(id: "1", title: "Test", duration: 185)
        #expect(track.durationString == "3:05")
    }

    @Test func simpleTrackArtistsString() {
        let track = SimpleTrack(
            id: "1", title: "Test",
            artists: [
                SimpleArtist(id: "a1", title: "Artist 1"),
                SimpleArtist(id: "a2", title: "Artist 2"),
            ]
        )
        #expect(track.artistsString == "Artist 1, Artist 2")
    }

    @Test func trackIsLiked() {
        let liked = Track(
            id: "1", title: "T",
            collectionItemData: CollectionItem(itemStatus: .liked)
        )
        #expect(liked.isLiked == true)

        let notLiked = Track(id: "2", title: "T")
        #expect(notLiked.isLiked == false)
    }

    // MARK: - Release

    @Test func releaseYear() {
        let release = SimpleRelease(id: "1", title: "Album", date: "2023-05-15")
        #expect(release.year == 2023)

        let noDate = SimpleRelease(id: "2", title: "X")
        #expect(noDate.year == nil)
    }

    // MARK: - Stream

    @Test func streamUrlsGetURL() throws {
        let urls = StreamUrls(mid: "http://mid", high: "http://high", flacdrm: "http://flac")
        #expect(try urls.getURL(quality: .mid) == "http://mid")
        #expect(try urls.getURL(quality: .high) == "http://high")
        #expect(try urls.getURL(quality: .flac) == "http://flac")
    }

    @Test func streamUrlsSubscriptionRequired() {
        let urls = StreamUrls(mid: "http://mid")
        #expect(throws: ZvukError.self) {
            try urls.getURL(quality: .high)
        }
    }

    @Test func streamUrlsBestAvailable() {
        let full = StreamUrls(mid: "http://mid", high: "http://high", flacdrm: "http://flac")
        #expect(full.bestAvailable.quality == .flac)

        let midOnly = StreamUrls(mid: "http://mid")
        #expect(midOnly.bestAvailable.quality == .mid)
    }

    // MARK: - CollectionItem

    @Test func collectionItemIsLiked() {
        let liked = CollectionItem(itemStatus: .liked)
        #expect(liked.isLiked == true)

        let notLiked = CollectionItem()
        #expect(notLiked.isLiked == false)
    }

    // MARK: - Profile

    @Test func profileAuthorized() {
        let anon = Profile(result: ProfileResult(isAnonymous: true, token: "t"))
        #expect(anon.isAuthorized == false)

        let auth = Profile(result: ProfileResult(isAnonymous: false, token: "t"))
        #expect(auth.isAuthorized == true)
    }

    // MARK: - Page

    @Test func pageNavigation() {
        let page = Page(total: 100, next: 20)
        #expect(page.hasNext == true)
        #expect(page.hasPrev == false)

        let cursorPage = Page(cursor: "abc")
        #expect(cursorPage.hasNext == true)
    }

    // MARK: - Lyrics

    @Test func lyricsType() {
        let synced = Lyrics(lyrics: "[00:01]Hello", type: "subtitle")
        #expect(synced.isSynced == true)
        #expect(synced.lyricsType == .subtitle)

        let plain = Lyrics(lyrics: "Hello world", type: "lyrics")
        #expect(plain.isSynced == false)
    }

    // MARK: - Book

    @Test func bookAuthorsString() {
        let book = SimpleBook(
            id: "1", title: "Book",
            authorNames: ["Author A"],
            bookAuthors: [BookAuthor(id: "a1", rname: "Doe John")]
        )
        #expect(book.authorsString == "Doe John")

        let bookNoAuthors = SimpleBook(id: "2", title: "Book", authorNames: ["Author B"])
        #expect(bookNoAuthors.authorsString == "Author B")
    }

    // MARK: - Recommendation

    @Test func recommendationItemArtist() throws {
        let json = """
            {"__typename": "Artist", "id": "123", "title": "Test Artist", "image": {"src": "/img.jpg"}, "mark": null}
            """.data(using: .utf8)!

        let item = try JSONDecoder().decode(RecommendationItem.self, from: json)
        guard case .artist(let artist) = item else {
            Issue.record("Expected .artist")
            return
        }
        #expect(artist.id == "123")
        #expect(artist.title == "Test Artist")
        #expect(artist.image?.src == "/img.jpg")
        #expect(artist.mark == nil)
    }

    @Test func recommendationItemRelease() throws {
        let json = """
            {"__typename": "Release", "id": "456", "title": "Test Album", "artists": [{"id": "1", "title": "A"}], "image": null, "mark": "new"}
            """.data(using: .utf8)!

        let item = try JSONDecoder().decode(RecommendationItem.self, from: json)
        guard case .release(let release) = item else {
            Issue.record("Expected .release")
            return
        }
        #expect(release.id == "456")
        #expect(release.title == "Test Album")
        #expect(release.artists.count == 1)
        #expect(release.mark == "new")
    }

    @Test func recommendationItemPlaylist() throws {
        let json = """
            {"__typename": "Playlist", "id": "6", "title": "My Playlist", "duration": 14891, "trackCount": 60, "tracks": []}
            """.data(using: .utf8)!

        let item = try JSONDecoder().decode(RecommendationItem.self, from: json)
        guard case .playlist(let playlist) = item else {
            Issue.record("Expected .playlist")
            return
        }
        #expect(playlist.id == "6")
        #expect(playlist.title == "My Playlist")
        #expect(playlist.duration == 14891)
        #expect(playlist.trackCount == 60)
    }

    @Test func recommendationItemUnknown() throws {
        let json = """
            {"__typename": "SomeFutureType", "id": "1"}
            """.data(using: .utf8)!

        let item = try JSONDecoder().decode(RecommendationItem.self, from: json)
        guard case .unknown = item else {
            Issue.record("Expected .unknown")
            return
        }
    }

    @Test func dynamicBlockDecode() throws {
        let json = """
            {
                "totalPages": 2,
                "pages": [{
                    "page": 1,
                    "items": [
                        {"__typename": "Artist", "id": "1", "title": "Artist 1", "image": null, "mark": null},
                        {"__typename": "Playlist", "id": "6", "title": "Playlist 1", "duration": 100, "trackCount": 10, "tracks": []}
                    ]
                }]
            }
            """.data(using: .utf8)!

        let block = try JSONDecoder().decode(DynamicBlock.self, from: json)
        #expect(block.totalPages == 2)
        #expect(block.pages.count == 1)
        #expect(block.pages[0].page == 1)
        #expect(block.pages[0].items.count == 2)

        guard case .artist(let artist) = block.pages[0].items[0] else {
            Issue.record("Expected .artist")
            return
        }
        #expect(artist.title == "Artist 1")

        guard case .playlist(let playlist) = block.pages[0].items[1] else {
            Issue.record("Expected .playlist")
            return
        }
        #expect(playlist.title == "Playlist 1")
        #expect(playlist.trackCount == 10)
    }

    @Test func recommendationPlaylistWithTracks() throws {
        let json = """
            {
                "__typename": "Playlist",
                "id": "6",
                "title": "Test Playlist",
                "duration": 500,
                "trackCount": 2,
                "tracks": [
                    {
                        "id": "100",
                        "title": "Track 1",
                        "duration": 180,
                        "explicit": false,
                        "hasFlac": true,
                        "availability": 2,
                        "artists": [{"id": "1", "title": "Artist 1"}],
                        "release": {"id": "10", "title": "Release 1", "image": {"src": "/cover.jpg"}}
                    }
                ]
            }
            """.data(using: .utf8)!

        let item = try JSONDecoder().decode(RecommendationItem.self, from: json)
        guard case .playlist(let playlist) = item else {
            Issue.record("Expected .playlist")
            return
        }
        #expect(playlist.tracks.count == 1)
        #expect(playlist.tracks[0].title == "Track 1")
        #expect(playlist.tracks[0].hasFlac == true)
        #expect(playlist.tracks[0].artists[0].title == "Artist 1")
    }

    @Test func dynamicBlockEnums() {
        #expect(DynamicBlockContentType.music.rawValue == "Music")
        #expect(DynamicBlockItemType.artist.rawValue == "Artist")
        #expect(DynamicBlockItemType.release.rawValue == "Release")
        #expect(DynamicBlockItemType.playlist.rawValue == "Playlist")
    }

    // MARK: - PaginatedCollection

    @Test func cursorPageDecode() throws {
        let json = """
            {"endCursor": "abc123", "hasNextPage": true}
            """.data(using: .utf8)!
        let page = try JSONDecoder().decode(CursorPage.self, from: json)
        #expect(page.endCursor == "abc123")
        #expect(page.hasNextPage == true)
    }

    @Test func paginatedCollectionReleasesDecode() throws {
        let json = """
            {
                "releases": {
                    "items": [
                        {
                            "id": "24612588",
                            "title": "The Best Of",
                            "type": "album",
                            "mark": null,
                            "image": {"src": "/cover.jpg"},
                            "artists": [{"id": "1", "title": "Artist"}],
                            "explicit": true
                        }
                    ],
                    "page": {
                        "endCursor": "eyJ0ZXN0IjoxfQ==",
                        "hasNextPage": false
                    }
                }
            }
            """.data(using: .utf8)!

        let collection = try JSONDecoder().decode(PaginatedCollection.self, from: json)
        #expect(collection.playlists == nil)
        #expect(collection.artists == nil)

        let releases = try #require(collection.releases)
        #expect(releases.items.count == 1)
        #expect(releases.items[0].id == "24612588")
        #expect(releases.items[0].title == "The Best Of")
        #expect(releases.items[0].type == .album)
        #expect(releases.items[0].explicit == true)
        #expect(releases.items[0].artists[0].title == "Artist")
        #expect(releases.page.hasNextPage == false)
        #expect(releases.page.endCursor == "eyJ0ZXN0IjoxfQ==")
    }

    @Test func paginatedCollectionArtistsDecode() throws {
        let json = """
            {
                "artists": {
                    "items": [
                        {"id": "1", "title": "Artist 1", "image": {"src": "/a.jpg", "palette": "#000"}, "mark": "new"}
                    ],
                    "page": {"endCursor": null, "hasNextPage": false}
                }
            }
            """.data(using: .utf8)!

        let collection = try JSONDecoder().decode(PaginatedCollection.self, from: json)
        let artists = try #require(collection.artists)
        #expect(artists.items[0].mark == "new")
        #expect(artists.items[0].image?.palette == "#000")
    }

    @Test func collectionBookDecode() throws {
        let json = """
            {"id": "1", "title": "Book", "bookAuthors": [{"id": "a1", "rname": "Doe John"}], "image": null, "mark": null, "explicit": false}
            """.data(using: .utf8)!

        let book = try JSONDecoder().decode(CollectionBook.self, from: json)
        #expect(book.id == "1")
        #expect(book.authorsString == "Doe John")
        #expect(book.explicit == false)
    }

    // MARK: - Codable roundtrip

    @Test func simpleTrackCodable() throws {
        let json = """
            {
                "id": "123",
                "title": "Nothing Else Matters",
                "duration": 388,
                "explicit": false,
                "artists": [{"id": "1", "title": "Metallica"}],
                "release": null
            }
            """.data(using: .utf8)!

        let track = try JSONDecoder().decode(SimpleTrack.self, from: json)
        #expect(track.id == "123")
        #expect(track.title == "Nothing Else Matters")
        #expect(track.duration == 388)
        #expect(track.artists.count == 1)
        #expect(track.artists[0].title == "Metallica")
    }

    // MARK: - RadioResult

    @Test func radioResultDecode() throws {
        let json = """
            {
                "cursor": 25,
                "tracks": [
                    {"id": "100", "title": "Track 1", "duration": 200, "explicit": false, "hasFlac": true, "availability": 2, "artists": [], "release": null},
                    {"id": "101", "title": "Track 2", "duration": 180, "explicit": true, "hasFlac": false, "availability": 2, "artists": [], "release": null}
                ]
            }
            """.data(using: .utf8)!

        let result = try JSONDecoder().decode(RadioResult.self, from: json)
        #expect(result.cursor == 25)
        #expect(result.tracks.count == 2)
        #expect(result.tracks[0].title == "Track 1")
        #expect(result.tracks[1].explicit == true)
    }

    @Test func radioResultDefaultValues() throws {
        let json = "{}".data(using: .utf8)!
        let result = try JSONDecoder().decode(RadioResult.self, from: json)
        #expect(result.cursor == 0)
        #expect(result.tracks.isEmpty)
    }

    @Test func radioResultNullTracks() throws {
        let json = """
            {"cursor": 5, "tracks": [null, {"id": "1", "title": "T", "duration": 100, "explicit": false, "hasFlac": false, "availability": 2, "artists": [], "release": null}, null]}
            """.data(using: .utf8)!

        let result = try JSONDecoder().decode(RadioResult.self, from: json)
        #expect(result.tracks.count == 1)
        #expect(result.tracks[0].id == "1")
    }

    // MARK: - Subscription

    @Test func subscriptionDecode() throws {
        let json = """
            {
                "id": 123,
                "status": "confirmed",
                "name": "Test_Plan",
                "price": 1.0,
                "partner": "sberprime",
                "duration": 60,
                "title": "СберПрайм",
                "is_trial": false,
                "is_recurrent": true,
                "start": 1774092114000,
                "expiration": 1779310799000,
                "payment_details": {
                    "price_type": "evaluate",
                    "external_subscription_id": "uuid-123",
                    "is_owner": true
                },
                "plan_id": 128529456,
                "plan_price": 299.0,
                "services_available": ["premium"]
            }
            """.data(using: .utf8)!

        let sub = try JSONDecoder().decode(Subscription.self, from: json)
        #expect(sub.id == 123)
        #expect(sub.status == "confirmed")
        #expect(sub.partner == "sberprime")
        #expect(sub.title == "СберПрайм")
        #expect(sub.isTrial == false)
        #expect(sub.isRecurrent == true)
        #expect(sub.planPrice == 299.0)
        #expect(sub.hasPremium == true)
        #expect(sub.paymentDetails?.priceType == "evaluate")
        #expect(sub.paymentDetails?.isOwner == true)
        #expect(sub.startDate.timeIntervalSince1970 > 0)
        #expect(sub.expirationDate > sub.startDate)
    }

    @Test func subscriptionResultDecode() throws {
        let json = """
            {
                "subscription": {"id": 1, "status": "confirmed", "name": "P", "price": 0, "partner": "", "duration": 30, "title": "T", "is_trial": true, "is_recurrent": false, "start": 0, "expiration": 0, "plan_id": 1, "plan_price": 0, "services_available": []},
                "is_suspended": false
            }
            """.data(using: .utf8)!

        let result = try JSONDecoder().decode(SubscriptionResult.self, from: json)
        #expect(result.subscription?.isTrial == true)
        #expect(result.isSuspended == false)
    }

    @Test func subscriptionResultNoSubscription() throws {
        let json = """
            {"is_suspended": false}
            """.data(using: .utf8)!

        let result = try JSONDecoder().decode(SubscriptionResult.self, from: json)
        #expect(result.subscription == nil)
        #expect(result.isSuspended == false)
    }

    // MARK: - FeaturedInfo

    @Test func featuredInfoDecode() throws {
        let json = """
            {
                "closed_banners": ["banner1"],
                "targets": ["feature:hls2_enable_web", "feature:wave_v2", "country:SE", "device:web", "device:all"]
            }
            """.data(using: .utf8)!

        let info = try JSONDecoder().decode(FeaturedInfo.self, from: json)
        #expect(info.closedBanners == ["banner1"])
        #expect(info.targets.count == 5)
    }

    @Test func featuredInfoFeatures() {
        let info = FeaturedInfo(targets: ["feature:hls2_enable_web", "feature:wave_v2", "country:SE", "device:web"])
        #expect(info.features == ["hls2_enable_web", "wave_v2"])
        #expect(info.hasFeature("hls2_enable_web") == true)
        #expect(info.hasFeature("nonexistent") == false)
    }

    @Test func featuredInfoCountryAndDevices() {
        let info = FeaturedInfo(targets: ["country:RU", "device:web", "device:all"])
        #expect(info.country == "RU")
        #expect(info.devices == ["web", "all"])
    }

    @Test func featuredInfoEmpty() throws {
        let json = "{}".data(using: .utf8)!
        let info = try JSONDecoder().decode(FeaturedInfo.self, from: json)
        #expect(info.closedBanners.isEmpty)
        #expect(info.targets.isEmpty)
        #expect(info.country == nil)
        #expect(info.features.isEmpty)
    }

    // MARK: - Wave & Radio Enums

    @Test func waveGenreRawValues() {
        #expect(WaveGenre.ambient.rawValue == "easy_listening_ambient")
        #expect(WaveGenre.hipHop.rawValue == "hip_hop")
        #expect(WaveGenre.folk.rawValue == "folk_world_country")
        #expect(WaveGenre.instrumental.rawValue == "instrumental_acoustic")
    }

    @Test func waveLanguageRawValues() {
        #expect(WaveLanguage.foreign.rawValue == "foreign")
        #expect(WaveLanguage.russian.rawValue == "russian")
    }

    @Test func wavePopularityRawValues() {
        #expect(WavePopularity.rare.rawValue == 0)
        #expect(WavePopularity.popular.rawValue == 1)
    }

    @Test func radioEntityTypeRawValues() {
        #expect(RadioEntityType.artist.rawValue == "ARTIST")
        #expect(RadioEntityType.track.rawValue == "TRACK")
    }

    // MARK: - Grid

    @Test func gridPageDecode() throws {
        let json = """
            {
                "version": "1.0",
                "sections": [
                    {
                        "UUID": "abc-123",
                        "type": "listing",
                        "view": "",
                        "enabled": true,
                        "header": {"title": "Новые релизы", "icon": "master_folder"},
                        "content": {"list": "New releases", "count": 10, "random": false},
                        "data": [
                            {"type": "release", "id": 123},
                            {"type": "release", "id": 456}
                        ]
                    },
                    {
                        "UUID": "def-456",
                        "type": "content",
                        "view": "only-tracks",
                        "enabled": true,
                        "data": [{"type": "playlist", "id": 1124972}]
                    }
                ]
            }
            """.data(using: .utf8)!

        let page = try JSONDecoder().decode(GridPage.self, from: json)
        #expect(page.version == "1.0")
        #expect(page.sections.count == 2)

        let listing = page.sections[0]
        #expect(listing.uuid == "abc-123")
        #expect(listing.type == "listing")
        #expect(listing.header?.title == "Новые релизы")
        #expect(listing.header?.icon == "master_folder")
        #expect(listing.content?.list == "New releases")
        #expect(listing.content?.count == 10)
        #expect(listing.content?.random == false)
        #expect(listing.releaseIds == ["123", "456"])
        #expect(listing.artistIds.isEmpty)

        let content = page.sections[1]
        #expect(content.type == "content")
        #expect(content.view == "only-tracks")
        #expect(content.playlistIds == ["1124972"])
    }

    @Test func gridPageHelpers() {
        let section1 = GridSection(type: "listing", data: [
            GridContentItem(id: "1", type: "artist"),
            GridContentItem(id: "2", type: "release"),
        ])
        let section2 = GridSection(type: "content", data: [
            GridContentItem(id: "3", type: "playlist"),
        ])
        let page = GridPage(sections: [section1, section2])

        #expect(page.sections(ofType: "listing").count == 1)
        #expect(page.sections(ofType: "content").count == 1)
        #expect(page.itemIds(ofType: "artist") == ["1"])
        #expect(page.itemIds(ofType: "release") == ["2"])
        #expect(page.itemIds(ofType: "playlist") == ["3"])
    }

    @Test func gridPageEmpty() throws {
        let json = "{}".data(using: .utf8)!
        let page = try JSONDecoder().decode(GridPage.self, from: json)
        #expect(page.version == "")
        #expect(page.sections.isEmpty)
    }

    @Test func gridContentPageDecode() throws {
        let json = """
            {
                "type": "content",
                "data": [
                    {"type": "artist", "id": 124994},
                    {"type": "artist", "id": 486859}
                ]
            }
            """.data(using: .utf8)!

        let page = try JSONDecoder().decode(GridContentPage.self, from: json)
        #expect(page.type == "content")
        #expect(page.ids == ["124994", "486859"])
        #expect(page.data[0].type == "artist")
    }

    @Test func gridSectionItemFilters() {
        let section = GridSection(data: [
            GridContentItem(id: "1", type: "playlist"),
            GridContentItem(id: "2", type: "release"),
            GridContentItem(id: "3", type: "playlist"),
            GridContentItem(id: "4", type: "artist"),
        ])
        #expect(section.playlistIds == ["1", "3"])
        #expect(section.releaseIds == ["2"])
        #expect(section.artistIds == ["4"])
        #expect(section.items(ofType: "podcast").isEmpty)
    }

    // MARK: - Codable roundtrip

    @Test func enumsCodable() throws {
        let json = "\"high\"".data(using: .utf8)!
        let quality = try JSONDecoder().decode(Quality.self, from: json)
        #expect(quality == .high)

        let releaseJson = "\"album\"".data(using: .utf8)!
        let releaseType = try JSONDecoder().decode(ReleaseType.self, from: releaseJson)
        #expect(releaseType == .album)
    }
}
