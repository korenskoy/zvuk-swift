import Foundation

/// Brief profile information.
public struct SimpleProfile: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
    public let image: Image?

    public init(id: String = "", name: String = "", description: String? = nil, image: Image? = nil)
    {
        self.id = id
        self.name = name
        self.description = description
        self.image = image
    }
}

/// External profile information.
public struct ExternalProfile: Codable, Hashable, Sendable {
    public let birthday: Int?
    public let email: String?
    public let externalId: String?
    public let firstName: String?
    public let lastName: String?
    public let middleName: String?
    public let gender: String?
    public let phone: String?
    public let type: String?

    public init(
        birthday: Int? = nil,
        email: String? = nil,
        externalId: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        middleName: String? = nil,
        gender: String? = nil,
        phone: String? = nil,
        type: String? = nil
    ) {
        self.birthday = birthday
        self.email = email
        self.externalId = externalId
        self.firstName = firstName
        self.lastName = lastName
        self.middleName = middleName
        self.gender = gender
        self.phone = phone
        self.type = type
    }
}

/// Full profile data from API.
public struct ProfileResult: Codable, Hashable, Sendable {
    public let isAnonymous: Bool?
    public let allowExplicit: Bool?
    public let birthday: Int?
    public let created: Int?
    public let email: String?
    public let externalProfile: ExternalProfile?
    public let gender: String?
    public let id: Int?
    public let image: Image?
    public let isActive: Bool?
    public let isAgreement: Bool?
    public let isEditor: Bool?
    public let isRegistered: Bool?
    public let name: String?
    public let phone: String?
    public let registered: Int?
    public let token: String
    public let username: String?

    public init(
        isAnonymous: Bool? = nil,
        allowExplicit: Bool? = nil,
        birthday: Int? = nil,
        created: Int? = nil,
        email: String? = nil,
        externalProfile: ExternalProfile? = nil,
        gender: String? = nil,
        id: Int? = nil,
        image: Image? = nil,
        isActive: Bool? = nil,
        isAgreement: Bool? = nil,
        isEditor: Bool? = nil,
        isRegistered: Bool? = nil,
        name: String? = nil,
        phone: String? = nil,
        registered: Int? = nil,
        token: String = "",
        username: String? = nil
    ) {
        self.isAnonymous = isAnonymous
        self.allowExplicit = allowExplicit
        self.birthday = birthday
        self.created = created
        self.email = email
        self.externalProfile = externalProfile
        self.gender = gender
        self.id = id
        self.image = image
        self.isActive = isActive
        self.isAgreement = isAgreement
        self.isEditor = isEditor
        self.isRegistered = isRegistered
        self.name = name
        self.phone = phone
        self.registered = registered
        self.token = token
        self.username = username
    }

    /// Whether the user is authorized (not anonymous).
    public var isAuthorized: Bool {
        !(isAnonymous ?? true)
    }
}

/// User profile wrapper.
public struct Profile: Codable, Hashable, Sendable {
    public let result: ProfileResult?

    public init(result: ProfileResult? = nil) {
        self.result = result
    }

    /// Whether the user is authorized.
    public var isAuthorized: Bool {
        result?.isAuthorized ?? false
    }

    /// Authorization token.
    public var token: String {
        result?.token ?? ""
    }
}
