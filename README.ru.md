# ZvukMusic

Неофициальная Swift-библиотека для работы с API музыкального сервиса [Zvuk.com](https://zvuk.com).

**Основана на [zvuk-music](https://github.com/trudenboy/zvuk-music) — Python-библиотеке.**

> **Дисклеймер:** Библиотека не связана с Zvuk.com и не является официальной. Она создана на основе анализа веб-приложения Zvuk.com и существующих open-source проектов (см. [Ссылки](#ссылки)).

> [!IMPORTANT]
> Для использования библиотеки необходим аккаунт и оплаченная подписка на zvuk.com.

## Требования

- macOS 15+
- Swift 6.0+

## Установка

### Swift Package Manager

Добавьте в `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/korenskoy/zvuk-swift.git", from: "0.3.0"),
]
```

Или в Xcode: **File → Add Package Dependencies** и вставьте URL репозитория.

## Быстрый старт

### Анонимный доступ

```swift
import ZvukMusic

// Получение анонимного токена (ограниченный функционал)
let token = try await ZvukClient.getAnonymousToken()
let client = ZvukClient(token: token)

// Поиск
let results = try await client.quickSearch("Metallica")
for track in results.tracks {
    print("\(track.title) - \(track.artistsString)")
}
```

### Авторизованный доступ

Для полного функционала (high quality, лайки, плейлисты) необходим токен авторизованного пользователя:

1. Войдите на [zvuk.com](https://zvuk.com) в браузере
2. Откройте https://zvuk.com/api/tiny/profile
3. Скопируйте значение поля `token`

```swift
import ZvukMusic

let client = ZvukClient(token: "ваш_токен")

// Получение информации об артисте
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

## Примеры использования

### Поиск

```swift
// Быстрый поиск (для автокомплита)
let quick = try await client.quickSearch("Nothing Else Matters", limit: 5)

// Полнотекстовый поиск по всем разделам
let search = try await client.search("Metallica", limit: 10)
print("Найдено треков: \(search.tracks?.page?.total ?? 0)")
print("Найдено артистов: \(search.artists?.page?.total ?? 0)")

// Поиск по одному разделу с курсорной пагинацией
var cursor: String? = nil
repeat {
    let page = try await client.searchTracks("Metallica", limit: 20, cursor: cursor)
    for track in page.items {
        print("\(track.title) — \(track.artistsString)")
    }
    cursor = page.page?.cursor
} while cursor != nil

// Остальные помощники устроены так же:
_ = try await client.searchArtists("Metallica")
_ = try await client.searchReleases("Metallica")
_ = try await client.searchPlaylists("Metallica")
_ = try await client.searchPodcasts("Serial")
_ = try await client.searchEpisodes("Serial")
_ = try await client.searchProfiles("dj")
_ = try await client.searchBooks("Dune") // раздел books без курсора
```

### Треки

```swift
// Получение трека
if let track = try await client.getTrack("5896627") {
    print("\(track.title) (\(track.durationString))")
}

// Получение URL для стриминга
let url = try await client.getStreamURL("5896627", quality: .high)
print("Stream URL: \(url)")

// Скачивание трека
try await client.download(url: url, to: "track.mp3")
```

### Плейлисты

```swift
// Создание плейлиста
let playlistId = try await client.createPlaylist("Мой плейлист", trackIds: ["5896627", "5896628"])

// Добавление треков
_ = try await client.addTracksToPlaylist(playlistId, trackIds: ["5896629"])

// Получение плейлиста
if let playlist = try await client.getPlaylist(playlistId) {
    for track in playlist.tracks {
        print("  - \(track.title)")
    }
}

// Удаление плейлиста
_ = try await client.deletePlaylist(playlistId)
```

### Коллекция (лайки)

```swift
// Лайкнуть трек
_ = try await client.likeTrack("5896627")

// Получить лайкнутые треки
let liked = try await client.getLikedTracks(orderBy: .dateAdded, direction: .desc)
for track in liked {
    print("\(track.title) - \(track.artistsString)")
}

// Убрать лайк
_ = try await client.unlikeTrack("5896627")
```

### Артисты и релизы

```swift
// Информация об артисте
if let artist = try await client.getArtist(
    "754367",
    withReleases: true,
    withPopularTracks: true,
    withRelatedArtists: true
) {
    print("Артист: \(artist.title)")
    print("Релизов: \(artist.releases.count)")
    print("Популярные треки: \(artist.popularTracks.count)")
}

// Получение релиза
if let release = try await client.getRelease("12345") {
    print("Альбом: \(release.title) (\(release.year ?? 0))")
    for track in release.tracks {
        print("  \(track.title)")
    }
}
```

## Качество аудио

| Качество | Битрейт | Требует подписку |
|----------|---------|------------------|
| `.mid` | 128kbps MP3 | Нет |
| `.high` | 320kbps MP3 | Да |
| `.flac` | FLAC | Да |

```swift
do {
    let url = try await client.getStreamURL("5896627", quality: .high)
} catch let error as ZvukError {
    switch error {
    case .subscriptionRequired:
        // Fallback на mid качество
        let url = try await client.getStreamURL("5896627", quality: .mid)
    default:
        throw error
    }
}
```

## Прямой стриминг (без DRM)

```swift
if let stream = try await client.getDirectStreamURL("5896627", quality: .high) {
    print("Direct URL: \(stream.stream)")
}
```

## Тексты песен

```swift
if let lyrics = try await client.getLyrics("5896627") {
    print(lyrics.lyrics)
    print("Синхронизированный: \(lyrics.isSynced)")
}
```

## Уведомления

```swift
// Получить ленту уведомлений
let feed = try await client.getNotifications(limit: 15)

for notification in feed.notifications {
    print("[\(notification.createdAt)]")
    switch notification.body {
    case .newRelease(let author, let release):
        print("Новый релиз: \(release.title) от \(author.title)")
    case .newPodcastEpisode(let episode):
        print("Новый эпизод: \(episode.title)")
    case .newBook(let author, let book):
        print("Новая книга: \(book.title) от \(author.rname)")
    case .newProfilePlaylist(let author, let playlist):
        print("Новый плейлист: \(playlist.title) от \(author.name)")
    case .playlistTracksAdded(let author, let playlist, let count):
        print("\(author.name) добавил \(count) треков в \(playlist.title)")
    case .playlistLiked(let author, let playlist):
        print("\(author.name) лайкнул \(playlist.title)")
    case .unknown(let typename):
        print("Неизвестное уведомление: \(typename)")
    }
}

// Пагинация
if feed.pageInfo.hasNextPage, let cursor = feed.pageInfo.cursor {
    let nextPage = try await client.getNotifications(cursor: cursor, limit: 15)
}

// Фильтрация по типу
let releasesOnly = try await client.getNotifications(types: [.newRelease])

// Проверка непрочитанных
let hasUnread = try await client.hasUnreadNotifications()
```

## Рекомендации

```swift
// Получить персональные рекомендации
let recommendations = try await client.getMusicRecommendations()

for page in recommendations.pages {
    for item in page.items {
        switch item {
        case .artist(let artist):
            print("Артист: \(artist.title)")
        case .release(let release):
            print("Релиз: \(release.title)")
        case .playlist(let playlist):
            print("Плейлист: \(playlist.title) (\(playlist.trackCount) треков)")
            for track in playlist.tracks {
                print("  - \(track.title) — \(track.artistsString)")
            }
        case .unknown:
            break
        }
    }
}

// Запросить конкретные страницы
let page2 = try await client.getMusicRecommendations(pages: [2])

// Фильтрация по типу элементов
let artistsOnly = try await client.getMusicRecommendations(
    itemTypes: [.artist]
)
```

## Волна и Радио

```swift
// Персональная волна с настройками
let tracks = try await client.getPersonalWave(
    count: 10,
    energy: 0.8,       // 0.0 (спокойное) ... 1.0 (энергичное)
    fun: 0.5,          // 0.0 (грустное) ... 1.0 (весёлое)
    genres: [.electronic, .rock],
    language: .russian,
    popularity: .popular
)
for track in tracks {
    print("\(track.title) — \(track.artistsString)")
}

// Только инструментальная музыка (без вокала)
let instrumental = try await client.getPersonalWave(
    energy: 0.3,
    fun: 0.7,
    instrumental: true
)

// Радио по артисту (похожие треки)
let radio = try await client.getRadioByArtist("754367")
print("Треков: \(radio.tracks.count), курсор: \(radio.cursor)")

// Пагинация
let nextPage = try await client.getRadioByArtist("754367", cursor: radio.cursor)

// Радио по треку
let trackRadio = try await client.getRadioByTrack("5896627")

// Радио по релизу или плейлисту
let releaseRadio = try await client.getRadioByRelease("14607201")
let playlistRadio = try await client.getRadioByPlaylist("123456")
```

### Интернет-радиостанции

Радиостанции — отдельный тип контента: не список треков, а непрерывный поток.

```swift
let stations = try await client.getRadioStations(limit: 20)
for station in stations {
    print(station.name)                  // «Европа Плюс - Россия»
    print(station.source ?? "")          // ссылка на поток
    print(station.metaDataUrl ?? "")     // метаданные эфира
    print(station.logoColored?.svg ?? "")
}

let single = try await client.getRadioStation("1")
```

### Редакционные волны

Волна — поток, который набирает сервер. `localtime` обязателен: утром и
вечером подбор разный.

```swift
let wave = try await client.getWave("1")        // «МегаХит»
print(wave?.description ?? "")                  // «Топ российских чартов»

let items = try await client.getWaveContent(waveId: "1")
for item in items {
    print(item.track?.title ?? item.itemId, "можно пропустить:", item.skippable)
}
```

## Недавнее

`getRecentlyPlayed` возвращает *сущности, которые пользователь открывал* —
альбомы, плейлисты, артистов, волны, радиостанции, — а не отдельные треки.
Историю треков даёт `getListeningHistory(limit:)`.

```swift
let recent = try await client.getRecentlyPlayed(limit: 10)
for item in recent {
    print(item.type ?? .release, item.title ?? item.id, item.lastListeningDttm ?? "")
}

// Только альбомы и плейлисты
let filtered = try await client.getRecentlyPlayed(
    limit: 20,
    itemTypes: [.release, .playlist]
)
```

## Подсказки поиска

```swift
// Автодополнение недопечатанного запроса
let suggestions = try await client.getSearchAutocomplete("нирв")
// ["нирвана", "нирвана лучшее", "нирван", "нирванна"]

// Что ищут остальные
let popular = try await client.getPopularSearches(limit: 10)
print(popular.queries)

// Получить id по названию, не выкачивая сущность целиком
let ids = try await client.searchArtistIDs("Radiohead", limit: 1)
```

## Дешёвые счётчики

Проверить, что лежит в коллекции, не выкачивая её:

```swift
let trackCount = try await client.getCollectionTracksCount()
let ids = try await client.getCollectionIDs()
print(ids.tracks.count, ids.releases.count, ids.artists.count)

let followers = try await client.getArtistLikesCount(["433980"])
```

## Гриды (разметка страниц)

```swift
// Получить разметку страницы «Популярное / Музыка»
let grid = try await client.getGrid(name: GridName.popularMusic)

for section in grid.sections where section.enabled {
    print("\(section.header?.title ?? "—") (\(section.data.count) элементов)")

    // Загрузить плейлисты секции
    if !section.playlistIds.isEmpty {
        let playlists = try await client.getPlaylists(section.playlistIds)
    }

    // Загрузить релизы
    if !section.releaseIds.isEmpty {
        let releases = try await client.getReleases(section.releaseIds)
    }
}

// Получить ID артистов из Топ-100
let top = try await client.getGridContent(name: GridContentName.top100Artists)
let artists = try await client.getArtists(top.ids)

```

## Подписка

```swift
let sub = try await client.getSubscription()
if let subscription = sub.subscription {
    print("Статус: \(subscription.status)")
    print("План: \(subscription.title)")
    print("Цена: \(subscription.planPrice)")
    print("Истекает: \(subscription.expirationDate)")
    print("Премиум: \(subscription.hasPremium)")
}
```

## Feature Flags

```swift
let info = try await client.getFeaturedInfo()

// Проверка конкретного флага
if info.hasFeature("hls2_enable_web") {
    print("HLS v2 включён")
}

// Страна пользователя
print("Страна: \(info.country ?? "неизвестно")")

// Все feature-флаги
for feature in info.features {
    print("  - \(feature)")
}
```

## Обработка ошибок

```swift
do {
    let track = try await client.getTrack("123456789")
} catch let error as ZvukError {
    switch error {
    case .notFound:
        print("Трек не найден")
    case .unauthorized:
        print("Невалидный токен")
    case .botDetected:
        print("API заблокировал запрос (бот-защита)")
    case .rateLimited(_, let retryAfter):
        print("Превышен лимит запросов, повтор через \(retryAfter ?? 0)с")
    case .subscriptionRequired:
        print("Требуется подписка")
    default:
        print("Ошибка: \(error.localizedDescription)")
    }
}
```

## Конфигурация

```swift
let client = ZvukClient(
    token: "ваш_токен",
    timeout: 15.0,                          // Таймаут запросов (по умолчанию 10с)
    proxyURL: "http://proxy:8080",           // Прокси-сервер (опционально)
    userAgent: "MyApp/1.0",                  // User-Agent (опционально)
    rateLimit: 5                             // Макс. запросов/секунду
)
```

## Справочник API

Ниже — наиболее востребованные методы. Полный каталог (каждый метод, стоящая
за ним GraphQL-операция и её переменные) — в **[API.md](API.md)**.

### ZvukClient

Все методы — `async throws`.

**Авторизация и профиль:**

| Метод | Описание |
|-------|----------|
| `getAnonymousToken()` | Получить анонимный токен (статический) |
| `getProfile()` | Профиль пользователя |
| `isAuthorized()` | Проверка авторизации |

**Поиск:**

| Метод | Описание |
|-------|----------|
| `quickSearch(_:limit:)` | Быстрый поиск (автокомплит) |
| `search(_:limit:...)` | Полнотекстовый поиск, фильтры и курсоры по разделам |
| `searchTracks(_:limit:cursor:)` | Постраничный поиск только треков |
| `searchArtists(_:limit:cursor:)` | Постраничный поиск только артистов |
| `searchReleases(_:limit:cursor:)` | Постраничный поиск только релизов |
| `searchPlaylists(_:limit:cursor:)` | Постраничный поиск только плейлистов |
| `searchPodcasts(_:limit:cursor:)` | Постраничный поиск только подкастов |
| `searchEpisodes(_:limit:cursor:)` | Постраничный поиск только эпизодов подкастов |
| `searchProfiles(_:limit:cursor:)` | Постраничный поиск только профилей |
| `searchBooks(_:limit:)` | Поиск только аудиокниг (без курсора) |

**Треки и стриминг:**

| Метод | Описание |
|-------|----------|
| `getTrack(_:)` | Получить трек |
| `getTracks(_:)` | Получить несколько треков |
| `getFullTrack(_:withArtists:withReleases:)` | Трек с полной информацией |
| `getStreamURL(_:quality:)` | URL для стриминга |
| `getStreamURLs(_:)` | Несколько URL стримов |
| `getDirectStreamURL(_:quality:)` | Прямой URL (без DRM) |
| `getLyrics(_:)` | Текст песни |

**Артисты и релизы:**

| Метод | Описание |
|-------|----------|
| `getArtist(_:...)` | Артист (с релизами, треками, связанными) |
| `getArtists(_:...)` | Несколько артистов |
| `getRelease(_:)` | Релиз (альбом/сингл) |
| `getReleases(_:relatedLimit:)` | Несколько релизов |

**Плейлисты:**

| Метод | Описание |
|-------|----------|
| `getPlaylist(_:)` | Получить плейлист |
| `getPlaylists(_:)` | Несколько плейлистов |
| `getShortPlaylist(_:)` | Краткая информация о плейлисте |
| `getPlaylistTracks(_:limit:offset:)` | Треки плейлиста |
| `createPlaylist(_:trackIds:)` | Создать плейлист |
| `renamePlaylist(_:newName:)` | Переименовать |
| `addTracksToPlaylist(_:trackIds:)` | Добавить треки |
| `updatePlaylist(_:trackIds:name:isPublic:)` | Обновить плейлист |
| `setPlaylistPublic(_:isPublic:)` | Изменить видимость |
| `deletePlaylist(_:)` | Удалить плейлист |

**Подкасты:**

| Метод | Описание |
|-------|----------|
| `getPodcast(_:)` | Получить подкаст |
| `getPodcasts(_:)` | Несколько подкастов |
| `getEpisode(_:)` | Получить эпизод |
| `getEpisodes(_:)` | Несколько эпизодов |

**Коллекция (лайки):**

| Метод | Описание |
|-------|----------|
| `getCollection()` | Коллекция пользователя |
| `getLikedTracks(orderBy:direction:)` | Лайкнутые треки |
| `getUserPlaylists()` | Плейлисты пользователя |
| `getPaginatedCollection(...)` | Пагинированная коллекция (все типы) |
| `likeTrack(_:)` / `unlikeTrack(_:)` | Лайк / анлайк трека |
| `likeRelease(_:)` / `unlikeRelease(_:)` | Лайк / анлайк релиза |
| `likeArtist(_:)` / `unlikeArtist(_:)` | Лайк / анлайк артиста |
| `likePlaylist(_:)` / `unlikePlaylist(_:)` | Лайк / анлайк плейлиста |
| `likePodcast(_:)` / `unlikePodcast(_:)` | Лайк / анлайк подкаста |

**Скрытая коллекция:**

| Метод | Описание |
|-------|----------|
| `getHiddenCollection()` | Скрытые элементы |
| `getHiddenTracks()` | Скрытые треки |
| `hideTrack(_:)` / `unhideTrack(_:)` | Скрыть / показать трек |

**Профили и социальные функции:**

| Метод | Описание |
|-------|----------|
| `getProfileFollowersCount(_:)` | Количество подписчиков |
| `getFollowingCount(_:)` | Количество подписок |
| `hasUnreadNotifications()` | Непрочитанные уведомления |
| `getNotifications(types:cursor:limit:)` | Лента уведомлений с пагинацией |
| `readAllNotifications()` | Отметить все уведомления прочитанными |

**История:**

| Метод | Описание |
|-------|----------|
| `getListeningHistory(limit:)` | История прослушиваний |
| `getListenedEpisodes()` | Прослушанные эпизоды |

**Рекомендации:**

| Метод | Описание |
|-------|----------|
| `getMusicRecommendations(contentType:itemTypes:pages:)` | Персональные рекомендации |

**Волна и Радио:**

| Метод | Описание |
|-------|----------|
| `getPersonalWave(count:energy:fun:genres:language:instrumental:popularity:)` | Персональная волна |
| `getRadioByArtist(_:limit:cursor:)` | Радио по артисту |
| `getRadioByTrack(_:limit:cursor:)` | Радио по треку |

**Подписка и конфигурация:**

| Метод | Описание |
|-------|----------|
| `getSubscription()` | Информация о подписке |
| `getFeaturedInfo()` | Feature flags и таргетинг |

**Гриды (разметка страниц):**

| Метод | Описание |
|-------|----------|
| `getGrid(name:)` | Разметка страницы с секциями и ID элементов |
| `getGridContent(name:)` | Плоский список ID (топ-100, редакционные) |
| `getEditorialPlaylistIds()` | ID редакционных плейлистов |

Доступные константы `GridName` для `getGrid(name:)`:

| Константа | Описание |
|-----------|----------|
| `GridName.popularMusic` | Популярное/Музыка — плейлисты, релизы, артисты, жанровые чарты |
| `GridName.popularBooks` | Популярное/Книги — разделы аудиокниг |
| `GridName.popularRadio` | Популярное/Радио — группы радиостанций |
| `GridName.adsConfig` | Конфигурация рекламы |

Доступные константы `GridContentName` для `getGridContent(name:)`:

| Константа | Описание |
|-----------|----------|
| `GridContentName.top100Artists` | Топ-100 артистов → используйте с `getArtists(_:)` |
| `GridContentName.top100Podcasts` | Топ-100 подкастов → используйте с `getPodcasts(_:)` |
| `GridContentName.editorialPlaylists` | Редакционные плейлисты → используйте с `getPlaylists(_:)` |

**Синтез:**

| Метод | Описание |
|-------|----------|
| `synthesisPlaylistBuild(firstAuthorId:secondAuthorId:)` | AI-плейлист |
| `getSynthesisPlaylists(_:)` | Синтез-плейлисты |

**Интернет-радио:**

| Метод | Описание |
|-------|----------|
| `getRadioStations(limit:offset:)` | Каталог станций |
| `getRadioStations(ids:)` / `getRadioStation(_:)` | Станции по id |
| `getRadioByRelease(_:limit:cursor:)` | Радио по релизу |
| `getRadioByPlaylist(_:limit:cursor:)` | Радио по плейлисту |

**Волны:**

| Метод | Описание |
|-------|----------|
| `getWaves(_:)` / `getWave(_:)` | Название, описание, обложка волны |
| `getWaveContent(waveId:localtime:)` | Следующая порция контента волны |
| `getKidsWaveContent(waveId:localtime:waveSource:)` | Детская волна |
| `getClusterWaveContent(clusterId:first:localtime:)` | Превью кластера персональной волны |

**Недавнее и счётчики:**

| Метод | Описание |
|-------|----------|
| `getRecentlyPlayed(limit:offset:itemTypes:isKidContent:)` | Недавно открытые сущности (не треки) |
| `getCollectionTracksCount()` | Сколько треков в коллекции |
| `getCollectionIDs()` | Все id коллекции по типам |
| `getOwnPlaylistIDs()` | id собственных плейлистов |
| `getArtistLikesCount(_:)` | Число подписчиков артистов |
| `getSubscriptions(statuses:)` | Активные подписки |
| `getUnreadNotificationsCount(types:)` | Непрочитанные уведомления |

**Подсказки поиска:**

| Метод | Описание |
|-------|----------|
| `getSearchAutocomplete(_:limit:)` | Автодополнение запроса |
| `getPopularSearches(limit:cursor:explicit:)` | Популярные запросы |
| `getBlendedSearch(_:limit:)` | Смешанная выдача по релевантности (сырая) |
| `searchArtistIDs(_:limit:)` и аналоги | Поиск только id: артисты, подкасты, книги, авторы |

**Артисты (дополнительно):**

| Метод | Описание |
|-------|----------|
| `getArtistsShortInfo(_:withLikesCount:)` | Только имя и обложка |
| `getArtistPopularTracks(_:limit:offset:)` | Популярные треки, offset-пагинация |
| `getArtistPopularTracksPage(_:limit:cursor:withPreview:)` | Популярные треки, курсорная пагинация |
| `getArtistReleasesPage(_:limit:includeTypes:excludeTypes:cursor:)` | Релизы с фильтром по типу |
| `getArtistAlbums(_:)` / `getArtistSingles(_:)` / `getArtistCompilations(_:)` | Разделы дискографии |
| `getRelatedArtists(_:limit:popularTracksLimit:withPopularTracks:)` | Похожие артисты |
| `getArtistPage(_:...)` | Всё, что показывает веб-страница артиста |

**Релизы и треки (дополнительно):**

| Метод | Описание |
|-------|----------|
| `getRelatedReleases(_:limit:)` | Похожие релизы |
| `getReleasesTracks(_:)` | Только треклисты |
| `getReleasesShortInfo(_:withArtists:)` | Название, тип, обложка |
| `getTracksShortInfo(_:)` / `getTracksMinimalInfo(_:)` | Облегчённые данные о треках |
| `getTrackStreamPreviews(_:quality:encodeType:)` | Превью-ссылки (подписка не нужна) |

**Аудиокниги:**

| Метод | Описание |
|-------|----------|
| `getAudioBooks(_:withChapters:)` | Карточки книг |
| `getBookChapters(_:)` / `getChapters(_:)` / `getChapter(_:)` | Главы |
| `getBookAuthors(_:withLikesCount:)` / `getAuthorBooks(_:limit:cursor:)` | Авторы и их книги |
| `getRelatedBooks(_:limit:)` / `getRelatedAuthors(_:limit:)` | Похожие книги и авторы |
| `getBooksRecommendations(recType:first:skip:withAuthors:)` | Рекомендованные книги |

**Профили и подписки на людей:**

| Метод | Описание |
|-------|----------|
| `getProfiles(_:withPlaylists:...)` | Профили по id |
| `getProfilePlaylists(_:...)` / `getProfileFirstPlaylistTracks(_:limit:offset:)` | Плейлисты профиля |
| `getFollowers(_:itemType:limit:cursor:)` / `getFollowing(_:limit:cursor:)` | Граф подписок |
| `getRelatedProfiles(_:limit:)` | Профили с похожим вкусом |
| `setProfileSettings(name:description:)` | Изменить свой профиль |
| `createMigration(links:)` / `getMigrationStatus(_:)` | Импорт плейлистов из другого сервиса |

## Ссылки

Библиотека спроектирована на основе анализа веб-приложения [Zvuk.com](https://zvuk.com) и следующих open-source проектов:

- [zvuk-music](https://github.com/trudenboy/zvuk-music) — Python-библиотека для API Zvuk (оригинал)
- [gozvuk](https://github.com/oklookat/gozvuk) — Неофициальный Go-клиент для API Zvuk.com
- [sberzvuk-api](https://github.com/Aiving/sberzvuk-api) — JavaScript/TypeScript-библиотека для API Zvuk

## Лицензия

MIT License
