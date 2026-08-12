import Foundation
import Synchronization

/// Loads GraphQL query/mutation files from the bundle resources.
enum GraphQLLoader {
    /// Cache for loaded queries.
    private static let cache = Mutex<[String: String]>([:])

    /// Load a GraphQL query by name.
    /// - Parameter name: Query name (without .graphql extension).
    /// - Returns: GraphQL query string.
    /// - Throws: If the file is not found.
    static func loadQuery(_ name: String) throws -> String {
        if let cached = cache.withLock({ $0[name] }) {
            return cached
        }

        // Search in Queries, then Mutations
        let subdirs = ["Queries", "Mutations"]
        for subdir in subdirs {
            if let url = Bundle.module.url(
                forResource: name,
                withExtension: "graphql",
                subdirectory: subdir
            ) {
                let content = try String(contentsOf: url, encoding: .utf8)
                cache.withLock { $0[name] = content }
                return content
            }
        }

        throw ZvukError.notFound(message: "GraphQL file not found: \(name).graphql")
    }
}
