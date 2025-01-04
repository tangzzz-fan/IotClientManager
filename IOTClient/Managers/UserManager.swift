import Foundation

final class UserManager {
    static let shared = UserManager()

    private init() {}

    var currentUserId: String {
        return UserDefaults.standard.string(forKey: "currentUserId") ?? ""
    }

    var accessToken: String {
        return UserDefaults.standard.string(forKey: "accessToken") ?? ""
    }
}
