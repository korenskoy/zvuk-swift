import Foundation

/// Price of a subscription plan.
public struct SubscriptionTypePrice: Codable, Hashable, Sendable {
    public let price: Double?

    public init(price: Double? = nil) {
        self.price = price
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        price = try? c.decodeIfPresent(Double.self, forKey: .price)
    }

    private enum CodingKeys: String, CodingKey {
        case price
    }
}

/// An active subscription as returned by the `subscriptions` query.
///
/// This is the model behind ``ZvukClient/getSubscriptions(statuses:)``. It is
/// distinct from ``Subscription``, which comes from the older
/// ``ZvukClient/getSubscription()`` endpoint and carries payment details
/// instead of plan metadata.
public struct UserSubscription: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    /// Internal plan name, e.g. `SberPrajm_na_24_mes_v_Ritejle`.
    public let name: String
    /// Whether the plan is part of SberPrime.
    public let isPrime: Bool
    /// Plan status, e.g. `confirmed`.
    public let status: String
    /// Start date, ISO-8601.
    public let startDate: String?
    /// Expiration date, ISO-8601.
    public let expirationDate: String?
    /// Whether this is a trial period.
    public let isTrial: Bool
    public let category: String?
    /// Where the subscription was bought, e.g. `sberprime`.
    public let platform: String?
    /// Plan options, shape varies by plan.
    public let options: AnyCodable?
    /// Price charged for this subscription.
    public let price: Double?
    /// Nested plan price.
    public let subscriptionType: SubscriptionTypePrice?
    public let ageCategory: String?
    /// Whether the subscription renews automatically.
    public let hasRecurrent: Bool

    public init(
        id: String = "",
        name: String = "",
        isPrime: Bool = false,
        status: String = "",
        startDate: String? = nil,
        expirationDate: String? = nil,
        isTrial: Bool = false,
        category: String? = nil,
        platform: String? = nil,
        options: AnyCodable? = nil,
        price: Double? = nil,
        subscriptionType: SubscriptionTypePrice? = nil,
        ageCategory: String? = nil,
        hasRecurrent: Bool = false
    ) {
        self.id = id
        self.name = name
        self.isPrime = isPrime
        self.status = status
        self.startDate = startDate
        self.expirationDate = expirationDate
        self.isTrial = isTrial
        self.category = category
        self.platform = platform
        self.options = options
        self.price = price
        self.subscriptionType = subscriptionType
        self.ageCategory = ageCategory
        self.hasRecurrent = hasRecurrent
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeDefault(String.self, forKey: .id, default: "")
        name = try c.decodeDefault(String.self, forKey: .name, default: "")
        isPrime = try c.decodeDefault(Bool.self, forKey: .isPrime, default: false)
        status = try c.decodeDefault(String.self, forKey: .status, default: "")
        startDate = try? c.decodeIfPresent(String.self, forKey: .startDate)
        expirationDate = try? c.decodeIfPresent(String.self, forKey: .expirationDate)
        isTrial = try c.decodeDefault(Bool.self, forKey: .isTrial, default: false)
        category = try? c.decodeIfPresent(String.self, forKey: .category)
        platform = try? c.decodeIfPresent(String.self, forKey: .platform)
        options = try? c.decodeIfPresent(AnyCodable.self, forKey: .options)
        price = try? c.decodeIfPresent(Double.self, forKey: .price)
        subscriptionType = try? c.decodeIfPresent(SubscriptionTypePrice.self, forKey: .subscriptionType)
        ageCategory = try? c.decodeIfPresent(String.self, forKey: .ageCategory)
        hasRecurrent = try c.decodeDefault(Bool.self, forKey: .hasRecurrent, default: false)
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, isPrime, status, startDate, expirationDate, isTrial
        case category, platform, options, price, subscriptionType, ageCategory, hasRecurrent
    }
}

/// Main plus secondary subscriptions of the current user.
public struct UserSubscriptions: Codable, Hashable, Sendable {
    /// The plan currently granting access, `nil` for free accounts.
    public let main: UserSubscription?
    /// Additional plans, e.g. promo packages.
    public let secondary: [UserSubscription]

    public init(main: UserSubscription? = nil, secondary: [UserSubscription] = []) {
        self.main = main
        self.secondary = secondary
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        main = try? c.decodeIfPresent(UserSubscription.self, forKey: .main)
        secondary = try c.decodeArray([UserSubscription].self, forKey: .secondary)
    }

    private enum CodingKeys: String, CodingKey {
        case main = "mainSubscription"
        case secondary = "secondarySubscriptions"
    }
}
