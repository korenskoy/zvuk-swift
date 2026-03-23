import Foundation

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
