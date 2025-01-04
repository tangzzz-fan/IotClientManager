import Foundation

final class RegionManager {
    static let shared = RegionManager()

    private init() {}

    var currentRegion: String {
        // 从你的配置系统获取当前区域
        return UserDefaults.standard.string(forKey: "currentRegion") ?? "cn"
    }
}
