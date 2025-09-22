import Foundation

struct Configuration {
    static let mqttHosts = [
        "development": "mqtt-dev.example.com",
        "staging": "mqtt-staging.example.com",
        "production": "mqtt.example.com",
        "test": "broker.hivemq.com" // 公共MQTT Broker用于测试
    ]
    
    static let mqttPorts = [
        "development": UInt32(8883),
        "staging": UInt32(8883),
        "production": UInt32(8883),
        "test": UInt32(1883) // HiveMQ公共Broker端口
    ]
}

enum AppEnvironment {
    case development
    case staging
    case production
    case test // 用于测试的公共MQTT Broker

    static var current: AppEnvironment {
        // 这里需要根据你的项目配置来返回当前环境
        #if DEBUG
            return .test // 在调试模式下使用公共测试Broker
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
        case .test:
            return "test"
        }
    }

    var mqttHost: String {
        return "broker.hivemq.com"
    }

    var mqttPort: UInt32 {
        return 1883
    }
}
