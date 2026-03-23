import Foundation

/// Base error type for the ZvukMusic library.
public enum ZvukError: Error, LocalizedError, Sendable {
    /// Network/HTTP error.
    case network(message: String, underlying: (any Error)? = nil)
    /// Request timed out.
    case timedOut
    /// Bad request (HTTP 400).
    case badRequest(message: String)
    /// Authorization error (HTTP 401/403 or invalid token).
    case unauthorized(message: String)
    /// Resource not found (HTTP 404).
    case notFound(message: String)
    /// Rate limit exceeded (HTTP 429).
    case rateLimited(message: String, retryAfter: Int?)
    /// GraphQL query error.
    case graphQL(message: String, errors: [GraphQLErrorDetail])
    /// Subscription required for content access.
    case subscriptionRequired(message: String)
    /// Requested audio quality is not available.
    case qualityNotAvailable(message: String)
    /// API detected bot activity and blocked the request.
    case botDetected(message: String)

    public var errorDescription: String? {
        switch self {
        case .network(let message, _):
            return message
        case .timedOut:
            return "Request timed out"
        case .badRequest(let message):
            return message
        case .unauthorized(let message):
            return message
        case .notFound(let message):
            return message
        case .rateLimited(let message, let retryAfter):
            if let retryAfter {
                return "\(message) (retry after \(retryAfter)s)"
            }
            return message
        case .graphQL(let message, let errors):
            if !errors.isEmpty {
                let messages = errors.map(\.message)
                return "\(message): \(messages.joined(separator: "; "))"
            }
            return message
        case .subscriptionRequired(let message):
            return message
        case .qualityNotAvailable(let message):
            return message
        case .botDetected(let message):
            return message
        }
    }
}

/// Detail of a GraphQL error.
public struct GraphQLErrorDetail: @unchecked Sendable {
    public let message: String
    public let extensions: [String: Any]?

    public init(message: String, extensions: [String: Any]? = nil) {
        self.message = message
        self.extensions = extensions
    }

    init(from dictionary: [String: Any]) {
        self.message = dictionary["message"] as? String ?? "Unknown GraphQL error"
        self.extensions = dictionary["extensions"] as? [String: Any]
    }
}
