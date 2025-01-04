import Foundation

struct Configuration {
    static let mqttHosts = [
        "development": "mqtt-dev.example.com",
        "staging": "mqtt-staging.example.com",
        "production": "mqtt.example.com"
    ]
    
    static let mqttPorts = [
        "development": UInt32(8883),
        "staging": UInt32(8883),
        "production": UInt32(8883)
    ]
}

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

    var mqttHost: String {
        return Configuration.mqttHosts[String(describing: self)] ?? "mqtt-dev.example.com"
    }

    var mqttPort: UInt32 {
        return Configuration.mqttPorts[String(describing: self)] ?? 8883
    }
}
