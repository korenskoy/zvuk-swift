import Foundation

extension KeyedDecodingContainer {
    /// Decode an array, defaulting to empty if key is missing or null.
    /// Filters out null elements inside the array.
    func decodeArray<T: Decodable>(_ type: [T].Type, forKey key: Key) throws -> [T] {
        if let array = try? decodeIfPresent([T?].self, forKey: key) {
            return array.compactMap { $0 }
        }
        return []
    }

    /// Decode a value with a default if key is missing or null.
    func decodeDefault<T: Decodable>(_ type: T.Type, forKey key: Key, default defaultValue: T) throws -> T {
        (try? decodeIfPresent(T.self, forKey: key)) ?? defaultValue
    }
}
