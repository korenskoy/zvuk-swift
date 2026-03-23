import Foundation

/// Rate limiter for API calls using token bucket algorithm.
public actor Throttler {
    private let rateLimit: Int
    private let period: TimeInterval
    private var tokens: Double
    private var lastRefill: ContinuousClock.Instant

    /// - Parameters:
    ///   - rateLimit: Maximum requests per period.
    ///   - period: Time period in seconds (default 1.0).
    public init(rateLimit: Int = 5, period: TimeInterval = 1.0) {
        precondition(rateLimit > 0, "rateLimit must be positive")
        precondition(period > 0, "period must be positive")
        self.rateLimit = rateLimit
        self.period = period
        self.tokens = Double(rateLimit)
        self.lastRefill = .now
    }

    /// Wait until a request slot is available.
    public func acquire() async {
        while true {
            let now = ContinuousClock.now
            let elapsed = Double((now - lastRefill).components.seconds)
                + Double((now - lastRefill).components.attoseconds) / 1e18
            tokens = min(Double(rateLimit), tokens + elapsed * (Double(rateLimit) / period))
            lastRefill = now

            if tokens >= 1.0 {
                tokens -= 1.0
                return
            }
            let sleepDuration = period / Double(rateLimit)
            try? await Task.sleep(for: .seconds(sleepDuration))
        }
    }
}
