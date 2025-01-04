import Foundation
import MQTTClient

class MQTTConfigurationBuilder {
    private var host: String = ""
    private var port: UInt32 = 8883
    private var clientId: String = ""
    private var username: String = ""
    private var password: String = ""
    private var willTopic: String = ""
    private var willMessage: Data = Data()

    func setHost(_ host: String) -> MQTTConfigurationBuilder {
        self.host = host
        return self
    }

    func setPort(_ port: UInt32) -> MQTTConfigurationBuilder {
        self.port = port
        return self
    }

    func setClientId(_ clientId: String) -> MQTTConfigurationBuilder {
        self.clientId = clientId
        return self
    }

    func setCredentials(username: String, password: String) -> MQTTConfigurationBuilder {
        self.username = username
        self.password = password
        return self
    }

    func setWill(topic: String, message: Data) -> MQTTConfigurationBuilder {
        self.willTopic = topic
        self.willMessage = message
        return self
    }

    func build() -> MQTTConfiguration {
        return MQTTConfiguration(
            host: host,
            port: port,
            clientId: clientId,
            username: username,
            password: password,
            willMessage: willMessage
        )
    }

    static func defaultConfiguration() -> MQTTConfigurationBuilder {
        return MQTTConfigurationBuilder()
            .setHost(AppEnvironment.current.mqttHost)
            .setPort(AppEnvironment.current.mqttPort)
            .setClientId(UUID().uuidString)
            .setCredentials(
                username: UserManager.shared.currentUserId,
                password: UserManager.shared.accessToken
            )
            .setWill(
                topic: "client/\(UserManager.shared.currentUserId)/status",
                message: "offline".data(using: .utf8)!
            )
    }
}
