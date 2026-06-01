import Foundation

/// The authenticated user, as returned in the `user` field of login responses
/// and by `GET /auth/me`.
struct UserAccount: Codable, Hashable {
    let id: Int
    let email: String
    let name: String?
    let emailVerified: Bool

    enum CodingKeys: String, CodingKey {
        case id, email, name
        case emailVerified = "email_verified"
    }

    var displayName: String {
        if let name, !name.isEmpty { return name }
        return email.split(separator: "@").first.map(String.init) ?? email
    }
}

/// `POST /auth/login` and `POST /auth/apple` response.
struct AuthResponse: Codable {
    let token: String
    let user: UserAccount
}

/// `GET /api/pro-status`. No Stripe calls — local DB only.
struct ProStatus: Codable {
    let isPro: Bool
    let isTrial: Bool
    let trialDaysLeft: Int
    let subscriptionInterval: String?   // "month" | "year" | "family" | nil
    let isFounder: Bool
    let familyRole: String?             // "owner" | "member" | nil
    let familyOwnerName: String?
    let memberSince: String?            // e.g. "May 2026"

    enum CodingKeys: String, CodingKey {
        case isPro = "is_pro"
        case isTrial = "is_trial"
        case trialDaysLeft = "trial_days_left"
        case subscriptionInterval = "subscription_interval"
        case isFounder = "is_founder"
        case familyRole = "family_role"
        case familyOwnerName = "family_owner_name"
        case memberSince = "member_since"
    }

    /// A short status label for the Settings screen.
    var label: String {
        if isTrial { return "Trial · \(trialDaysLeft)d left" }
        if isPro {
            switch subscriptionInterval {
            case "year":   return "Pro · Annual"
            case "family": return "Pro · Family"
            case "month":  return "Pro · Monthly"
            default:       return familyRole == "member" ? "Pro · Family seat" : "Pro"
            }
        }
        return "Free"
    }
}
