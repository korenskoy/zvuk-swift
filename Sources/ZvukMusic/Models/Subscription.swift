import Foundation

/// Payment details for a subscription.
public struct PaymentDetails: Codable, Hashable, Sendable {
    public let priceType: String
    public let externalSubscriptionId: String
    public let isOwner: Bool

    public init(
        priceType: String = "",
        externalSubscriptionId: String = "",
        isOwner: Bool = false
    ) {
        self.priceType = priceType
        self.externalSubscriptionId = externalSubscriptionId
        self.isOwner = isOwner
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        priceType = try c.decodeDefault(String.self, forKey: .priceType, default: "")
        externalSubscriptionId = try c.decodeDefault(String.self, forKey: .externalSubscriptionId, default: "")
        isOwner = try c.decodeDefault(Bool.self, forKey: .isOwner, default: false)
    }

    private enum CodingKeys: String, CodingKey {
        case priceType = "price_type"
        case externalSubscriptionId = "external_subscription_id"
        case isOwner = "is_owner"
    }
}

/// Subscription information.
public struct Subscription: Codable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let status: String
    public let name: String
    public let price: Double
    public let partner: String
    public let duration: Int
    public let title: String
    public let isTrial: Bool
    public let isRecurrent: Bool
    public let start: Int64
    public let expiration: Int64
    public let paymentDetails: PaymentDetails?
    public let planId: Int
    public let planPrice: Double
    public let servicesAvailable: [String]

    public init(
        id: Int = 0,
        status: String = "",
        name: String = "",
        price: Double = 0,
        partner: String = "",
        duration: Int = 0,
        title: String = "",
        isTrial: Bool = false,
        isRecurrent: Bool = false,
        start: Int64 = 0,
        expiration: Int64 = 0,
        paymentDetails: PaymentDetails? = nil,
        planId: Int = 0,
        planPrice: Double = 0,
        servicesAvailable: [String] = []
    ) {
        self.id = id
        self.status = status
        self.name = name
        self.price = price
        self.partner = partner
        self.duration = duration
        self.title = title
        self.isTrial = isTrial
        self.isRecurrent = isRecurrent
        self.start = start
        self.expiration = expiration
        self.paymentDetails = paymentDetails
        self.planId = planId
        self.planPrice = planPrice
        self.servicesAvailable = servicesAvailable
    }

    /// Subscription start date.
    public var startDate: Date {
        Date(timeIntervalSince1970: Double(start) / 1000)
    }

    /// Subscription expiration date.
    public var expirationDate: Date {
        Date(timeIntervalSince1970: Double(expiration) / 1000)
    }

    /// Whether the subscription includes premium access.
    public var hasPremium: Bool {
        servicesAvailable.contains("premium")
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(Int.self, forKey: .id, default: 0)
        status = try c.decodeDefault(String.self, forKey: .status, default: "")
        name = try c.decodeDefault(String.self, forKey: .name, default: "")
        price = try c.decodeDefault(Double.self, forKey: .price, default: 0)
        partner = try c.decodeDefault(String.self, forKey: .partner, default: "")
        duration = try c.decodeDefault(Int.self, forKey: .duration, default: 0)
        title = try c.decodeDefault(String.self, forKey: .title, default: "")
        isTrial = try c.decodeDefault(Bool.self, forKey: .isTrial, default: false)
        isRecurrent = try c.decodeDefault(Bool.self, forKey: .isRecurrent, default: false)
        start = try c.decodeDefault(Int64.self, forKey: .start, default: 0)
        expiration = try c.decodeDefault(Int64.self, forKey: .expiration, default: 0)
        paymentDetails = try? c.decodeIfPresent(PaymentDetails.self, forKey: .paymentDetails)
        planId = try c.decodeDefault(Int.self, forKey: .planId, default: 0)
        planPrice = try c.decodeDefault(Double.self, forKey: .planPrice, default: 0)
        servicesAvailable = try c.decodeArray([String].self, forKey: .servicesAvailable)
    }

    private enum CodingKeys: String, CodingKey {
        case id, status, name, price, partner, duration, title, start, expiration
        case isTrial = "is_trial"
        case isRecurrent = "is_recurrent"
        case paymentDetails = "payment_details"
        case planId = "plan_id"
        case planPrice = "plan_price"
        case servicesAvailable = "services_available"
    }
}

/// Top-level subscription response.
public struct SubscriptionResult: Codable, Hashable, Sendable {
    public let subscription: Subscription?
    public let isSuspended: Bool

    public init(subscription: Subscription? = nil, isSuspended: Bool = false) {
        self.subscription = subscription
        self.isSuspended = isSuspended
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        subscription = try? c.decodeIfPresent(Subscription.self, forKey: .subscription)
        isSuspended = try c.decodeDefault(Bool.self, forKey: .isSuspended, default: false)
    }

    private enum CodingKeys: String, CodingKey {
        case subscription
        case isSuspended = "is_suspended"
    }
}
