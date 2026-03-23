import Foundation

/// Image model.
public struct Image: Codable, Hashable, Sendable {
    /// Image URL or /static/... path.
    public let src: String
    /// Height.
    public let h: Int?
    /// Width.
    public let w: Int?
    /// Primary palette color.
    public let palette: String?
    /// Secondary palette color.
    public let paletteBottom: String?

    public init(
        src: String = "",
        h: Int? = nil,
        w: Int? = nil,
        palette: String? = nil,
        paletteBottom: String? = nil
    ) {
        self.src = src
        self.h = h
        self.w = w
        self.palette = palette
        self.paletteBottom = paletteBottom
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        src = (try? c.decodeIfPresent(String.self, forKey: .src)) ?? ""
        h = try? c.decodeIfPresent(Int.self, forKey: .h)
        w = try? c.decodeIfPresent(Int.self, forKey: .w)
        palette = try? c.decodeIfPresent(String.self, forKey: .palette)
        paletteBottom = try? c.decodeIfPresent(String.self, forKey: .paletteBottom)
    }

    private enum CodingKeys: String, CodingKey {
        case src, h, w, palette, paletteBottom
    }

    /// Get image URL with the specified size.
    public func getURL(width: Int = 300, height: Int = 300) -> String {
        precondition(width > 0 && height > 0, "width and height must be positive")

        var urlString = src
        if urlString.hasPrefix("/") {
            urlString = "https://zvuk.com\(urlString)"
        }

        guard var components = URLComponents(string: urlString) else { return urlString }
        var queryItems = components.queryItems ?? []
        queryItems.removeAll { $0.name == "size" }
        queryItems.append(URLQueryItem(name: "size", value: "\(width)x\(height)"))
        components.queryItems = queryItems
        return components.string ?? urlString
    }
}

/// Label / major.
public struct Label: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String

    public init(id: String = "", title: String = "") {
        self.id = id
        self.title = title
    }
}

/// Genre.
public struct Genre: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let shortName: String?

    public init(id: String = "", name: String = "", shortName: String? = nil) {
        self.id = id
        self.name = name
        self.shortName = shortName
    }
}

/// Background.
public struct Background: Codable, Hashable, Sendable {
    public let type: BackgroundType?
    public let image: String?
    public let color: AnyCodable?
    public let gradient: AnyCodable?

    public init(
        type: BackgroundType? = nil,
        image: String? = nil,
        color: AnyCodable? = nil,
        gradient: AnyCodable? = nil
    ) {
        self.type = type
        self.image = image
        self.color = color
        self.gradient = gradient
    }
}

/// Artist animation.
public struct Animation: Codable, Hashable, Sendable {
    public let artistId: String
    public let effect: String?
    public let image: String?
    public let background: Background?

    public init(
        artistId: String = "",
        effect: String? = nil,
        image: String? = nil,
        background: Background? = nil
    ) {
        self.artistId = artistId
        self.effect = effect
        self.image = image
        self.background = background
    }
}

/// Type-erased Codable value for arbitrary JSON.
public struct AnyCodable: Codable, Hashable, @unchecked Sendable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map(\.value)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            self.value = dict.mapValues(\.value)
        } else {
            self.value = NSNull()
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool: try container.encode(bool)
        case let int as Int: try container.encode(int)
        case let double as Double: try container.encode(double)
        case let string as String: try container.encode(string)
        case is NSNull: try container.encodeNil()
        default: try container.encodeNil()
        }
    }

    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        String(describing: lhs.value) == String(describing: rhs.value)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(String(describing: value))
    }
}
