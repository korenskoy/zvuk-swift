import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Constants for API endpoints and defaults.
enum APIConstants {
    static let apiURL = "https://zvuk.com/api/v1/graphql"
    static let tinyAPIURL = "https://zvuk.com/api/tiny"
    static let defaultUserAgent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36"
    static let defaultTimeout: TimeInterval = 10.0
    static let defaultHeaders: [String: String] = [
        "Accept": "application/json, text/plain, */*",
        "Accept-Language": "ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7",
        "Referer": "https://zvuk.com/",
        "Origin": "https://zvuk.com",
        "Content-Type": "application/json",
    ]
}

/// A log entry from a network request.
public struct NetworkLogEntry: Sendable {
    public let timestamp: Date
    public let method: String
    public let url: String
    public let statusCode: Int?
    public let duration: TimeInterval
    public let error: String?
    public let bytesSent: Int
    public let bytesReceived: Int
    public let requestBody: String?
    public let responseBody: String?
}

/// HTTP request handler for the Zvuk API.
final class Request: @unchecked Sendable {
    private let session: URLSession
    private var headers: [String: String]
    private var userAgent: String
    private let throttler: Throttler?
    private let timeout: TimeInterval
    private let lock = NSLock()
    var onLog: (@Sendable (NetworkLogEntry) -> Void)?

    init(
        token: String? = nil,
        timeout: TimeInterval = APIConstants.defaultTimeout,
        proxyURL: String? = nil,
        userAgent: String? = nil,
        throttler: Throttler? = nil
    ) {
        self.timeout = timeout
        self.userAgent = userAgent ?? APIConstants.defaultUserAgent
        self.throttler = throttler

        var headers = APIConstants.defaultHeaders
        if let token, !token.isEmpty {
            headers["X-Auth-Token"] = token
        }
        self.headers = headers

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        if let proxyURL, let url = URL(string: proxyURL) {
            let host = url.host ?? ""
            let port = url.port ?? 0
            config.connectionProxyDictionary = [
                kCFNetworkProxiesHTTPEnable: true,
                kCFNetworkProxiesHTTPProxy: host,
                kCFNetworkProxiesHTTPPort: port,
                kCFNetworkProxiesHTTPSEnable: true,
                kCFNetworkProxiesHTTPSProxy: host,
                kCFNetworkProxiesHTTPSPort: port,
            ]
        }
        self.session = URLSession(configuration: config)
    }

    func setAuthorization(_ token: String) {
        lock.lock()
        headers["X-Auth-Token"] = token
        lock.unlock()
    }

    private func currentHeaders() -> [String: String] {
        lock.lock()
        defer { lock.unlock() }
        return headers
    }

    // MARK: - GraphQL

    /// Execute a GraphQL query.
    func graphql(
        query: String,
        operationName: String? = nil,
        variables: [String: Any]? = nil
    ) async throws -> [String: Any] {
        if let throttler {
            await throttler.acquire()
        }

        var payload: [String: Any] = ["query": query]
        if let operationName { payload["operationName"] = operationName }
        if let variables { payload["variables"] = variables }

        let data = try JSONSerialization.data(withJSONObject: payload)
        var request = URLRequest(url: URL(string: APIConstants.apiURL)!)
        request.httpMethod = "POST"
        request.httpBody = data
        applyHeaders(to: &request)

        let responseData = try await performRequest(request)
        let parsed = try parseResponse(responseData)

        // Check for GraphQL errors
        if let errors = parsed["errors"] as? [[String: Any]], !errors.isEmpty {
            let details = errors.map { GraphQLErrorDetail(from: $0) }
            throw ZvukError.graphQL(message: "GraphQL request failed", errors: details)
        }

        return (parsed["data"] as? [String: Any]) ?? [:]
    }

    // MARK: - REST

    /// GET request returning parsed JSON.
    func get(url: String, params: [String: String]? = nil) async throws -> [String: Any]? {
        if let throttler {
            await throttler.acquire()
        }

        guard var components = URLComponents(string: url) else {
            throw ZvukError.network(message: "Invalid URL: \(url)")
        }
        if let params {
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let requestURL = components.url else {
            throw ZvukError.network(message: "Invalid URL: \(url)")
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        applyHeaders(to: &request)

        let responseData = try await performRequest(request)
        let parsed = try parseResponse(responseData)

        // Tiny API: {"result": {...}} — unwrap
        if let result = parsed["result"] as? [String: Any] {
            return result
        }
        return parsed
    }

    /// POST request returning parsed JSON.
    func post(url: String, body: [String: Any]? = nil) async throws -> [String: Any]? {
        if let throttler {
            await throttler.acquire()
        }

        guard let requestURL = URL(string: url) else {
            throw ZvukError.network(message: "Invalid URL: \(url)")
        }
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        applyHeaders(to: &request)

        let responseData = try await performRequest(request)
        let parsed = try parseResponse(responseData)
        return parsed
    }

    /// Download a file to disk.
    func download(url: String, to filePath: String) async throws {
        if let throttler {
            await throttler.acquire()
        }

        guard let requestURL = URL(string: url) else {
            throw ZvukError.network(message: "Invalid URL: \(url)")
        }
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        applyHeaders(to: &request)

        let data = try await performRequest(request)
        try data.write(to: URL(fileURLWithPath: filePath))
    }

    // MARK: - Private

    private func applyHeaders(to request: inout URLRequest) {
        let hdrs = currentHeaders()
        for (key, value) in hdrs {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
    }

    private func performRequest(_ request: URLRequest) async throws -> Data {
        let start = CFAbsoluteTimeGetCurrent()
        let method = request.httpMethod ?? "GET"
        let urlString = request.url?.absoluteString ?? "?"
        let sentBytes = request.httpBody?.count ?? 0
        let reqBody = request.httpBody

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            emitLog(method: method, url: urlString, statusCode: nil, start: start, sent: sentBytes, received: 0, error: "Timeout", requestData: reqBody)
            throw ZvukError.timedOut
        } catch {
            emitLog(method: method, url: urlString, statusCode: nil, start: start, sent: sentBytes, received: 0, error: error.localizedDescription, requestData: reqBody)
            throw ZvukError.network(message: error.localizedDescription, underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            emitLog(method: method, url: urlString, statusCode: nil, start: start, sent: sentBytes, received: data.count, error: "Invalid response", requestData: reqBody, responseData: data)
            throw ZvukError.network(message: "Invalid response")
        }

        let statusCode = httpResponse.statusCode

        guard (200...299).contains(statusCode) else {
            let message = parseErrorMessage(from: data) ?? "Unknown error"
            emitLog(method: method, url: urlString, statusCode: statusCode, start: start, sent: sentBytes, received: data.count, error: message, requestData: reqBody, responseData: data)
            switch statusCode {
            case 400:
                throw ZvukError.badRequest(message: message)
            case 401, 403:
                throw ZvukError.unauthorized(message: message)
            case 404:
                throw ZvukError.notFound(message: message)
            case 429:
                let retryAfter = (httpResponse.value(forHTTPHeaderField: "Retry-After"))
                    .flatMap(Int.init)
                throw ZvukError.rateLimited(message: message, retryAfter: retryAfter)
            default:
                throw ZvukError.network(message: "\(message) (\(statusCode))")
            }
        }

        emitLog(method: method, url: urlString, statusCode: statusCode, start: start, sent: sentBytes, received: data.count, error: nil, requestData: reqBody, responseData: data)
        return data
    }

    private func emitLog(method: String, url: String, statusCode: Int?, start: CFAbsoluteTime, sent: Int, received: Int, error: String?, requestData: Data? = nil, responseData: Data? = nil) {
        guard let onLog else { return }
        let reqBody = requestData.flatMap { String(data: $0, encoding: .utf8) }
        let resBody = responseData.flatMap { String(data: $0, encoding: .utf8) }
        let entry = NetworkLogEntry(
            timestamp: Date(),
            method: method,
            url: url,
            statusCode: statusCode,
            duration: CFAbsoluteTimeGetCurrent() - start,
            error: error,
            bytesSent: sent,
            bytesReceived: received,
            requestBody: reqBody,
            responseBody: resBody
        )
        onLog(entry)
    }

    private func parseResponse(_ data: Data) throws -> [String: Any] {
        // Check for bot protection
        if let text = String(data: data, encoding: .utf8) {
            let lower = text.lowercased()
            if lower.contains("bot activity") || lower.prefix(100).contains("<html") {
                throw ZvukError.botDetected(
                    message: "API detected bot activity. Try using a different User-Agent.")
            }
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ZvukError.network(message: "Invalid server response (not JSON)")
        }

        return convertKeysToCamelCase(json)
    }

    private func parseErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        if let errors = json["errors"] as? [[String: Any]],
            let first = errors.first,
            let message = first["message"] as? String
        {
            return message
        }
        if let message = json["message"] as? String {
            return message
        }
        return nil
    }

    /// Recursively convert snake_case JSON keys to camelCase.
    private func convertKeysToCamelCase(_ dict: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in dict {
            let camelKey = snakeToCamelCase(key)
            result[camelKey] = convertValue(value)
        }
        return result
    }

    private func convertValue(_ value: Any) -> Any {
        if let dict = value as? [String: Any] {
            return convertKeysToCamelCase(dict)
        }
        if let array = value as? [Any] {
            return array.map { convertValue($0) }
        }
        return value
    }

    /// Convert snake_case to camelCase.
    private func snakeToCamelCase(_ text: String) -> String {
        // Preserve GraphQL meta fields like __typename
        guard !text.hasPrefix("__") else { return text }
        let parts = text.split(separator: "_", omittingEmptySubsequences: false)
        guard parts.count > 1 else { return text }
        let first = String(parts[0])
        let rest = parts.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }
        return first + rest.joined()
    }
}
