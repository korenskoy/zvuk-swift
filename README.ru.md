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
    .package(url: "https://github.com/korenskoy/zvuk-swift.git", from: "0.2.0"),
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

// Полнотекстовый поиск
let search = try await client.search("Metallica", limit: 10)
print("Найдено треков: \(search.tracks?.page?.total ?? 0)")
print("Найдено артистов: \(search.artists?.page?.total ?? 0)")
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
| `search(_:limit:...)` | Полнотекстовый поиск с фильтрами |

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

## Ссылки

Библиотека спроектирована на основе анализа веб-приложения [Zvuk.com](https://zvuk.com) и следующих open-source проектов:

- [zvuk-music](https://github.com/trudenboy/zvuk-music) — Python-библиотека для API Zvuk (оригинал)
- [gozvuk](https://github.com/oklookat/gozvuk) — Неофициальный Go-клиент для API Zvuk.com
- [sberzvuk-api](https://github.com/Aiving/sberzvuk-api) — JavaScript/TypeScript-библиотека для API Zvuk

## Лицензия

MIT License
