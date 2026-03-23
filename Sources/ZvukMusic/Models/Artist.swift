import Foundation

/// Brief artist information.
public struct SimpleArtist: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let image: Image?

    public init(id: String = "", title: String = "", image: Image? = nil) {
        self.id = id
        self.title = title
        self.image = image
    }
}

/// Full artist information.
public struct Artist: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let image: Image?
    public let secondImage: Image?
    public let searchTitle: String?
    public let description: String?
    public let hasPage: Bool?
    public let animation: Animation?
    public let collectionItemData: CollectionItem?
    public let releases: [SimpleRelease]
    public let popularTracks: [SimpleTrack]
    public let relatedArtists: [SimpleArtist]

    public init(
        id: String = "",
        title: String = "",
        image: Image? = nil,
        secondImage: Image? = nil,
        searchTitle: String? = nil,
        description: String? = nil,
        hasPage: Bool? = nil,
        animation: Animation? = nil,
        collectionItemData: CollectionItem? = nil,
        releases: [SimpleRelease] = [],
        popularTracks: [SimpleTrack] = [],
        relatedArtists: [SimpleArtist] = []
    ) {
        self.id = id
        self.title = title
        self.image = image
        self.secondImage = secondImage
        self.searchTitle = searchTitle
        self.description = description
        self.hasPage = hasPage
        self.animation = animation
        self.collectionItemData = collectionItemData
        self.releases = releases
        self.popularTracks = popularTracks
        self.relatedArtists = relatedArtists
    }

    /// Whether the artist is liked.
    public var isLiked: Bool {
        collectionItemData?.isLiked ?? false
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        image = try? c.decodeIfPresent(Image.self, forKey: .image)
        secondImage = try? c.decodeIfPresent(Image.self, forKey: .secondImage)
        searchTitle = try? c.decodeIfPresent(String.self, forKey: .searchTitle)
        description = try? c.decodeIfPresent(String.self, forKey: .description)
        hasPage = try? c.decodeIfPresent(Bool.self, forKey: .hasPage)
        animation = try? c.decodeIfPresent(Animation.self, forKey: .animation)
        collectionItemData = try? c.decodeIfPresent(CollectionItem.self, forKey: .collectionItemData)
        releases = try c.decodeArray([SimpleRelease].self, forKey: .releases)
        popularTracks = try c.decodeArray([SimpleTrack].self, forKey: .popularTracks)
        relatedArtists = try c.decodeArray([SimpleArtist].self, forKey: .relatedArtists)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, image, secondImage, searchTitle, description, hasPage
        case animation, collectionItemData, releases, popularTracks, relatedArtists
    }
}
