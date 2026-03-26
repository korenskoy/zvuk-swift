import Foundation

// MARK: - Grid Names

/// Known grid names for ``ZvukClient/getGrid(name:)``.
///
/// Each grid returns a ``GridPage`` describing a full page layout.
/// Sections contain typed item IDs that can be fetched via corresponding API methods.
///
/// ```swift
/// let grid = try await client.getGrid(name: GridName.popularMusic)
/// for section in grid.sections {
///     let playlists = try await client.getPlaylists(section.playlistIds)
/// }
/// ```
public enum GridName {
    /// Popular / Music page layout.
    ///
    /// Sections include:
    /// - "Похожие на..." — 1 random artist from top-100 (type: `artist`) → use with `getRelatedArtists`
    /// - "Новинки недели" — 1 playlist (type: `playlist`, view: `only-tracks`)
    /// - "Новые релизы" — ~117 releases (type: `release`) → use with `getReleases`
    /// - "Новое в жанрах" — ~36 playlists (type: `playlist`)
    /// - "Топ 100" — 1 playlist (type: `playlist`, view: `only-tracks`)
    /// - "Актуальные хиты" — ~10 playlists (type: `playlist`)
    /// - "Новые лица" / ГРОМЧЕ — ~7 playlists (type: `playlist`)
    /// - "Главное за месяц" — 1 playlist (type: `playlist`, view: `only-tracks`)
    /// - "Новое от редакции" — ~24 playlists (type: `playlist`)
    public static let popularMusic = "popular_music_web"

    /// Popular / Books page layout.
    ///
    /// Sections contain book IDs (type: `book`) → use with `getBooks`.
    public static let popularBooks = "popular_book_web"

    /// Popular / Radio page layout.
    ///
    /// Sections contain radio station group IDs.
    public static let popularRadio = "web-public-main-radio"

    /// Ad configuration grid.
    public static let adsConfig = "web-ads-config"
}

/// Known grid content names for ``ZvukClient/getGridContent(name:)``.
///
/// Each returns a ``GridContentPage`` with a flat list of typed item IDs.
///
/// ```swift
/// let top = try await client.getGridContent(name: GridContentName.top100Artists)
/// let artists = try await client.getArtists(top.ids)
/// ```
public enum GridContentName {
    /// Top 100 artists. Returns ~100 items with `type: "artist"`.
    ///
    /// Use returned IDs with `getArtists(_:)` or `getRelatedArtists(id:)`.
    public static let top100Artists = "top_100_artists_new_web"

    /// Top 100 podcasts. Returns ~100 items with `type: "podcast"`.
    ///
    /// Use returned IDs with `getPodcasts(_:)`.
    public static let top100Podcasts = "top_100_podcasts_new_web"

    /// Editorial playlists. Returns items with `type: "playlist"`.
    ///
    /// Use returned IDs with `getPlaylists(_:)`.
    public static let editorialPlaylists = "editorial_playlist"
}

// MARK: - Grid Content Item

/// Grid content item from the Tiny API.
public struct GridContentItem: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let type: String

    public init(id: String = "", type: String = "") {
        self.id = id
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let str = try? c.decode(String.self, forKey: .id) {
            id = str
        } else if let num = try? c.decode(Int.self, forKey: .id) {
            id = String(num)
        } else {
            id = ""
        }
        type = (try? c.decode(String.self, forKey: .type)) ?? ""
    }

    private enum CodingKeys: String, CodingKey {
        case id, type
    }
}

// MARK: - Grid Page

/// Full grid page from `api/tiny/grid?name=...`.
public struct GridPage: Codable, Hashable, Sendable {
    public let version: String
    public let sections: [GridSection]

    public init(version: String = "", sections: [GridSection] = []) {
        self.version = version
        self.sections = sections
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = (try? c.decode(String.self, forKey: .version)) ?? ""
        sections = (try? c.decode([GridSection].self, forKey: .sections)) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case version, sections
    }

    /// Filter sections by type.
    public func sections(ofType type: String) -> [GridSection] {
        sections.filter { $0.type == type }
    }

    /// All item IDs of a given type across all sections.
    public func itemIds(ofType type: String) -> [String] {
        sections.flatMap { $0.items(ofType: type) }.map(\.id)
    }
}

/// A section within a grid page.
public struct GridSection: Codable, Hashable, Sendable {
    public let uuid: String
    public let type: String
    public let view: String
    public let enabled: Bool
    public let header: GridSectionHeader?
    public let content: GridSectionContent?
    public let data: [GridContentItem]

    public init(
        uuid: String = "",
        type: String = "",
        view: String = "",
        enabled: Bool = true,
        header: GridSectionHeader? = nil,
        content: GridSectionContent? = nil,
        data: [GridContentItem] = []
    ) {
        self.uuid = uuid
        self.type = type
        self.view = view
        self.enabled = enabled
        self.header = header
        self.content = content
        self.data = data
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        uuid = (try? c.decode(String.self, forKey: .uuid)) ?? ""
        type = (try? c.decode(String.self, forKey: .type)) ?? ""
        view = (try? c.decode(String.self, forKey: .view)) ?? ""
        enabled = (try? c.decode(Bool.self, forKey: .enabled)) ?? true
        header = try? c.decode(GridSectionHeader.self, forKey: .header)
        content = try? c.decode(GridSectionContent.self, forKey: .content)
        data = (try? c.decode([GridContentItem].self, forKey: .data)) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case uuid = "UUID"
        case type, view, enabled, header, content, data
    }

    /// Filter data items by type (e.g. "playlist", "release", "artist").
    public func items(ofType type: String) -> [GridContentItem] {
        data.filter { $0.type == type }
    }

    /// All playlist IDs in this section.
    public var playlistIds: [String] { items(ofType: "playlist").map(\.id) }

    /// All release IDs in this section.
    public var releaseIds: [String] { items(ofType: "release").map(\.id) }

    /// All artist IDs in this section.
    public var artistIds: [String] { items(ofType: "artist").map(\.id) }
}

/// Header of a grid section.
public struct GridSectionHeader: Codable, Hashable, Sendable {
    public let title: String
    public let icon: String

    public init(title: String = "", icon: String = "") {
        self.title = title
        self.icon = icon
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title = (try? c.decode(String.self, forKey: .title)) ?? ""
        icon = (try? c.decode(String.self, forKey: .icon)) ?? ""
    }

    private enum CodingKeys: String, CodingKey {
        case title, icon
    }
}

/// Content metadata of a grid section (for listing type).
public struct GridSectionContent: Codable, Hashable, Sendable {
    public let list: String
    public let count: Int
    public let random: Bool?

    public init(list: String = "", count: Int = 0, random: Bool? = nil) {
        self.list = list
        self.count = count
        self.random = random
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        list = (try? c.decode(String.self, forKey: .list)) ?? ""
        count = (try? c.decode(Int.self, forKey: .count)) ?? 0
        random = try? c.decode(Bool.self, forKey: .random)
    }

    private enum CodingKeys: String, CodingKey {
        case list, count, random
    }
}

// MARK: - Grid Content Page

/// Result from `api/tiny/grid/content?name=...`.
public struct GridContentPage: Codable, Hashable, Sendable {
    public let type: String
    public let data: [GridContentItem]

    public init(type: String = "", data: [GridContentItem] = []) {
        self.type = type
        self.data = data
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = (try? c.decode(String.self, forKey: .type)) ?? ""
        data = (try? c.decode([GridContentItem].self, forKey: .data)) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case type, data
    }

    /// All IDs in this content page.
    public var ids: [String] { data.map(\.id) }
}
