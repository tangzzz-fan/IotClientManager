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
    private let configuration: MQTTConfigurable

    init(client: MQTTSessionManager, configuration: MQTTConfigurable) {
        self.client = client
        self.configuration = configuration
        setupSessionManager()
    }
    
    private func setupSessionManager() {
        // MQTTSessionManager的属性设置已移至connect方法中
        // 这里只需要设置代理
        print("MQTTClientCocoaAdapter: Configured for \(configuration.host):\(configuration.port)")
    }

    func connect(completion: @escaping (Result<Void, Error>) -> Void) {
        print("MQTTClientCocoaAdapter: Attempting to connect to \(configuration.host):\(configuration.port)")
        
        client.connect(
            to: configuration.host,
            port: Int(configuration.port),
            tls: false,
            keepalive: 60,
            clean: true,
            auth: !configuration.username.isEmpty,
            user: configuration.username.isEmpty ? nil : configuration.username,
            pass: configuration.password.isEmpty ? nil : configuration.password,
            will: !configuration.willTopic.isEmpty,
            willTopic: configuration.willTopic.isEmpty ? nil : configuration.willTopic,
            willMsg: configuration.willMessage,
            willQos: .atLeastOnce,
            willRetainFlag: false,
            withClientId: configuration.clientId,
            securityPolicy: nil,
            certificates: nil,
            protocolLevel: .version311
        ) { error in
            if let error = error {
                print("MQTTClientCocoaAdapter: Connection failed with error: \(error)")
                completion(.failure(error))
            } else {
                print("MQTTClientCocoaAdapter: Connection successful")
                completion(.success(()))
            }
        }
    }

    func disconnect() {
        print("MQTTClientCocoaAdapter: Disconnecting")
        client.disconnect { error in
            if let error = error {
                print("MQTTClientCocoaAdapter: Error during disconnect: \(error.localizedDescription)")
            } else {
                print("MQTTClientCocoaAdapter: Disconnected successfully")
            }
        }
    }

    func publish(message: Data, topic: String, qos: Int, retained: Bool) {
        print("MQTTClientCocoaAdapter: Publishing message to topic: \(topic)")
        let result = client.send(message, topic: topic, qos: MQTTQosLevel(rawValue: UInt8(qos))!, retain: retained)
        if result == 0 {
            print("MQTTClientCocoaAdapter: Message published successfully")
        } else {
            print("MQTTClientCocoaAdapter: Failed to publish message, error code: \(result)")
        }
    }

    func subscribe(to topics: [String]) {
        print("MQTTClientCocoaAdapter: Subscribing to topics: \(topics)")
        let qosLevel = MQTTQosLevel.atLeastOnce.rawValue
        let subscriptions = topics.reduce(into: [String: NSNumber]()) { result, topic in
            result[topic] = NSNumber(value: qosLevel)
        }
        client.subscriptions = subscriptions
        print("MQTTClientCocoaAdapter: Subscriptions updated")
    }

    func unsubscribe(from topics: [String]) {
        print("MQTTClientCocoaAdapter: Unsubscribing from topics: \(topics)")
        var currentSubscriptions = client.subscriptions ?? [:]
        topics.forEach { currentSubscriptions.removeValue(forKey: $0) }
        client.subscriptions = currentSubscriptions
        print("MQTTClientCocoaAdapter: Unsubscribed successfully")
    }

    func checkConnection(completion: @escaping (Bool) -> Void) {
        let isConnected = client.state == .connected
        print("MQTTClientCocoaAdapter: Connection check - isConnected: \(isConnected)")
        completion(isConnected)
    }
}
