import Foundation

// GraphQL answers arrive as untyped dictionaries and almost every field of
// interest sits one or two objects deep — `{ wave: { waveContent: [...] } }`.
// These helpers keep that digging to one expression per call site.
extension Dictionary where Key == String, Value == Any {
    /// Walk a chain of nested object keys, e.g. `result.object("wave")`.
    /// A missing or mistyped step yields an empty dictionary rather than `nil`,
    /// which is what the decoders want anyway.
    func object(_ keys: String...) -> [String: Any] {
        walk(keys[...])
    }

    /// Value at the end of a chain of nested object keys, e.g.
    /// `result.value("wave", "waveContent")`.
    func value(_ keys: String...) -> Any? {
        guard let last = keys.last else { return nil }
        return walk(keys.dropLast())[last]
    }

    /// Whether a mutation reported success.
    ///
    /// Some mutations answer with a plain `Bool`, others with a payload object
    /// (`{ id }`) and a few with `null` on failure — so anything present and
    /// non-null counts as success.
    func succeeded(_ keys: String...) -> Bool {
        guard let last = keys.last, let result = walk(keys.dropLast())[last] else { return false }
        if let flag = result as? Bool { return flag }
        return !(result is NSNull)
    }

    private func walk(_ keys: ArraySlice<String>) -> [String: Any] {
        keys.reduce(self) { $0[$1] as? [String: Any] ?? [:] }
    }
}

extension ZvukClient {
    /// Build a ``PaginatedResult`` from a `{ <pageInfoKey>: { endCursor, hasNextPage }, <itemsKey>: [...] }`
    /// payload.
    ///
    /// Documents alias the schema's snake_case `page_info` to `pageInfo`, so
    /// the response key is always camelCase. Only two shapes reach here:
    /// `pageInfo` (the default) and `page`.
    func paginated<Item: Codable & Hashable & Sendable>(
        _ type: Item.Type,
        from container: [String: Any],
        itemsKey: String,
        pageInfoKey: String = "pageInfo"
    ) throws -> PaginatedResult<Item> {
        PaginatedResult(
            items: try decodeList(Item.self, from: container[itemsKey]),
            page: CursorPage(
                endCursor: container.value(pageInfoKey, "endCursor") as? String,
                hasNextPage: container.value(pageInfoKey, "hasNextPage") as? Bool ?? false
            )
        )
    }

    /// Encode track IDs as the `PlaylistItem` inputs every playlist mutation expects.
    static func playlistItems(_ trackIds: [String]) -> [[String: String]] {
        trackIds.map { ["type": "track", "item_id": $0] }
    }
}

extension ZvukClient {
    /// Load a bundled operation and run it.
    ///
    /// Every file in `Resources/` is named after the GraphQL operation it
    /// contains, so one string serves as both the file name and the
    /// `operationName`. The two pre-existing calls where they genuinely differ
    /// keep the explicit `request.graphql` form.
    func perform(_ operation: String, _ variables: [String: Any] = [:]) async throws -> [String: Any] {
        let gql = try GraphQLLoader.loadQuery(operation)
        return try await request.graphql(query: gql, operationName: operation, variables: variables)
    }
}
