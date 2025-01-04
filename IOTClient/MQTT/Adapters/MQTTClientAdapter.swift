import MQTTClient

protocol MQTTClientAdapter {
    func connect(completion: @escaping (Result<Void, Error>) -> Void)
    func disconnect()
    func publish(message: Data, topic: String, qos: Int, retained: Bool)
    func subscribe(to topics: [String])
    func unsubscribe(from topics: [String])
    func checkConnection(completion: @escaping (Bool) -> Void)
}

class MQTTClientCocoaAdapter: MQTTClientAdapter {
    private let client: MQTTSessionManager

    init(client: MQTTSessionManager) {
        self.client = client
    }

    func connect(completion: @escaping (Result<Void, Error>) -> Void) {
        // 实现具体的连接逻辑
        client.connect { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func disconnect() {
        client.disconnect { error in
            print("error: \(String(describing: error?.localizedDescription))")
        }
    }

    func publish(message: Data, topic: String, qos: Int, retained: Bool) {
        _ = client.send(message, topic: topic, qos: MQTTQosLevel(rawValue: UInt8(qos))!, retain: retained)
    }

    func subscribe(to topics: [String]) {
        let qosLevel = MQTTQosLevel.atLeastOnce.rawValue
        let subscriptions = topics.reduce(into: [String: NSNumber]()) { result, topic in
            result[topic] = NSNumber(value: qosLevel)
        }
        client.subscriptions = subscriptions
    }

    func unsubscribe(from topics: [String]) {
        var currentSubscriptions = client.subscriptions ?? [:]
        topics.forEach { currentSubscriptions.removeValue(forKey: $0) }
        client.subscriptions = currentSubscriptions
    }

    func checkConnection(completion: @escaping (Bool) -> Void) {
        completion(client.state == .connected)
    }
}
