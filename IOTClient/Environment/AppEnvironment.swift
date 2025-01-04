import Foundation

enum AppEnvironment {
    case development
    case staging
    case production

    static var current: AppEnvironment {
        // 这里需要根据你的项目配置来返回当前环境
        #if DEBUG
            return .development
        #else
            return .production
        #endif
    }

    var prefix: String {
        switch self {
        case .development:
            return "dev"
        case .staging:
            return "uat"
        case .production:
            return ""
        }
    }
}
