import Foundation

protocol MQTTConfigurable {
    var host: String { get }
    var port: UInt32 { get }
    var clientId: String { get }
    var username: String { get }
    var password: String { get }
    var willTopic: String { get }
    var willMessage: Data { get }
}

struct MQTTConfiguration: MQTTConfigurable {
    let host: String
    let port: UInt32
    let clientId: String
    let username: String
    let password: String
    let willTopic: String = "/app/will/"
    let willMessage: Data

    static func createDefault(environment: AppEnvironment, region: String, userId: String)
        -> MQTTConfiguration
    {
        let host = Self.buildHost(environment: environment, region: region)
        let port: UInt32 = environment == .production ? 19973 : 18883
        let clientId = "p_\(userId)_\(region.lowercased())_ios_platform"

        let willMessage = try? JSONSerialization.data(
            withJSONObject: ["subject": "connect"],
            options: .prettyPrinted
        )

        return MQTTConfiguration(
            host: host,
            port: port,
            clientId: clientId,
            username: userId,
            password: UserManager.shared.accessToken,
            willMessage: willMessage ?? Data()
        )
    }

    private static func buildHost(environment: AppEnvironment, region: String) -> String {
        let prefix = environment.prefix
        return "\(prefix)app.mt.\(region).iot.test"
    }
}
