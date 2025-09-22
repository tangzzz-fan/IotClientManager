import Foundation

final class UserManager {
    static let shared = UserManager()

    private init() {}

    var currentUserId: String {
        let userId = UserDefaults.standard.string(forKey: "currentUserId") ?? "testUser"
        // 为测试目的设置默认用户ID
        if userId.isEmpty {
            UserDefaults.standard.set("testUser", forKey: "currentUserId")
            return "testUser"
        }
        return userId
    }

    var accessToken: String {
        let token = UserDefaults.standard.string(forKey: "accessToken") ?? "testToken"
        // 为测试目的设置默认访问令牌
        if token.isEmpty {
            UserDefaults.standard.set("testToken", forKey: "accessToken")
            return "testToken"
        }
        return token
    }
}