import Foundation

/// Podcast author.
public struct PodcastAuthor: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let name: String

    public init(id: String = "", name: String = "") {
        self.id = id
        self.name = name
    }
}

/// Brief podcast information.
public struct SimplePodcast: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let explicit: Bool
    public let image: Image?
    public let authors: [PodcastAuthor]

    public init(
        id: String = "",
        title: String = "",
        explicit: Bool = false,
        image: Image? = nil,
        authors: [PodcastAuthor] = []
    ) {
        self.id = id
        self.title = title
        self.explicit = explicit
        self.image = image
        self.authors = authors
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        explicit = try c.decodeDefault(Bool.self, forKey: .explicit, default: false)
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
        authors = try c.decodeArray([PodcastAuthor].self, forKey: .authors)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, explicit, image, authors
    }
}

/// Full podcast information.
public struct Podcast: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let explicit: Bool
    public let description: String?
    public let updatedDate: String?
    public let availability: Int
    public let type: String?
    public let image: Image?
    public let authors: [PodcastAuthor]
    public let episodes: [AnyCodable]
    public let collectionItemData: CollectionItem?

    public init(
        id: String = "",
        title: String = "",
        explicit: Bool = false,
        description: String? = nil,
        updatedDate: String? = nil,
        availability: Int = 0,
        type: String? = nil,
        image: Image? = nil,
        authors: [PodcastAuthor] = [],
        episodes: [AnyCodable] = [],
        collectionItemData: CollectionItem? = nil
    ) {
        self.id = id
        self.title = title
        self.explicit = explicit
        self.description = description
        self.updatedDate = updatedDate
        self.availability = availability
        self.type = type
        self.image = image
        self.authors = authors
        self.episodes = episodes
        self.collectionItemData = collectionItemData
    }

    /// Whether the podcast is liked.
    public var isLiked: Bool {
        collectionItemData?.isLiked ?? false
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        explicit = try c.decodeDefault(Bool.self, forKey: .explicit, default: false)
        description = try? c.decodeIfPresent(String.self, forKey: .description)
        updatedDate = try? c.decodeIfPresent(String.self, forKey: .updatedDate)
        availability = try c.decodeDefault(Int.self, forKey: .availability, default: 0)
        type = try? c.decodeIfPresent(String.self, forKey: .type)
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
        authors = try c.decodeArray([PodcastAuthor].self, forKey: .authors)
        episodes = try c.decodeArray([AnyCodable].self, forKey: .episodes)
        collectionItemData = try? c.decodeIfPresent(CollectionItem.self, forKey: .collectionItemData)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, explicit, description, updatedDate, availability
        case type, image, authors, episodes, collectionItemData
    }
}

/// Brief episode information.
public struct SimpleEpisode: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let explicit: Bool
    public let duration: Int
    public let publicationDate: String?
    public let image: Image?

    public init(
        id: String = "",
        title: String = "",
        explicit: Bool = false,
        duration: Int = 0,
        publicationDate: String? = nil,
        image: Image? = nil
    ) {
        self.id = id
        self.title = title
        self.explicit = explicit
        self.duration = duration
        self.publicationDate = publicationDate
        self.image = image
    }

    /// Duration in MM:SS format.
    public var durationString: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Full episode information.
public struct Episode: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let explicit: Bool
    public let description: String?
    public let duration: Int
    public let availability: Int
    public let publicationDate: String?
    public let image: Image?
    public let podcast: SimplePodcast?
    public let collectionItemData: CollectionItem?

    public init(
        id: String = "",
        title: String = "",
        explicit: Bool = false,
        description: String? = nil,
        duration: Int = 0,
        availability: Int = 0,
        publicationDate: String? = nil,
        image: Image? = nil,
        podcast: SimplePodcast? = nil,
        collectionItemData: CollectionItem? = nil
    ) {
        self.id = id
        self.title = title
        self.explicit = explicit
        self.description = description
        self.duration = duration
        self.availability = availability
        self.publicationDate = publicationDate
        self.image = image
        self.podcast = podcast
        self.collectionItemData = collectionItemData
    }

    /// Duration in MM:SS format.
    public var durationString: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
