import Foundation
import MQTTClient

struct MQTTConnectionState {
    let host: String
    let port: UInt32
    let subscribedTopics: [String: NSNumber]
    let lastConnectedTime: Date
}

protocol MQTTConnectionMemento {
    func saveState(_ state: MQTTConnectionState)
    func restoreState() -> MQTTConnectionState?
}

class MQTTConnectionCaretaker: MQTTConnectionMemento {
    private let userDefaults = UserDefaults.standard
    private let stateKey = "mqtt.connection.state"

    func saveState(_ state: MQTTConnectionState) {
        let data: [String: Any] = [
            "host": state.host,
            "port": state.port,
            "subscribedTopics": state.subscribedTopics,
            "lastConnectedTime": state.lastConnectedTime,
        ]
        userDefaults.set(data, forKey: stateKey)
    }

    func restoreState() -> MQTTConnectionState? {
        guard let data = userDefaults.dictionary(forKey: stateKey),
            let host = data["host"] as? String,
            let port = data["port"] as? UInt32,
            let topics = data["subscribedTopics"] as? [String: NSNumber],
            let lastConnectedTime = data["lastConnectedTime"] as? Date
        else {
            return nil
        }

        return MQTTConnectionState(
            host: host,
            port: port,
            subscribedTopics: topics,
            lastConnectedTime: lastConnectedTime
        )
    }
}
