import Foundation

/// Loads GraphQL query/mutation files from the bundle resources.
enum GraphQLLoader {
    /// Cache for loaded queries.
    nonisolated(unsafe) private static var cache: [String: String] = [:]
    private static let lock = NSLock()

    /// Load a GraphQL query by name.
    /// - Parameter name: Query name (without .graphql extension).
    /// - Returns: GraphQL query string.
    /// - Throws: If the file is not found.
    static func loadQuery(_ name: String) throws -> String {
        lock.lock()
        if let cached = cache[name] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        // Search in Queries, then Mutations
        let subdirs = ["Queries", "Mutations"]
        for subdir in subdirs {
            if let url = Bundle.module.url(
                forResource: name,
                withExtension: "graphql",
                subdirectory: subdir
            ) {
                let content = try String(contentsOf: url, encoding: .utf8)
                lock.lock()
                cache[name] = content
                lock.unlock()
                return content
            }
        }

        throw ZvukError.notFound(message: "GraphQL file not found: \(name).graphql")
    }
}
