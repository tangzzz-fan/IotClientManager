import Foundation
import MQTTClient

protocol MQTTClientManaging: AnyObject {
    func connect(completion: @escaping (Result<Void, Error>) -> Void)
    func disconnect()
    func subscribe(to topics: [String])
    func unsubscribe(from topics: [String])
}

final class MQTTClientManager: NSObject, MQTTClientManaging {
    static let shared = MQTTClientManager()

    private let sessionManager: MQTTSessionManager
    private let configuration: MQTTConfigurable
    private let securityPolicyFactory: MQTTSecurityPolicyCreating
    private var subscribedTopics: [String: NSNumber] = [:]
    private var keepAliveTimer: Timer?

    private override init() {
        self.sessionManager = MQTTSessionManager()
        self.securityPolicyFactory = MQTTSecurityPolicyFactory()
        self.configuration = MQTTConfiguration.createDefault(
            environment: AppEnvironment.current,
            region: RegionManager.shared.currentRegion,
            userId: UserManager.shared.currentUserId
        )
        super.init()
        self.sessionManager.delegate = self
        setupLogging()
        setupReconnection()
    }

    private func setupLogging() {
        MQTTLog.setLogLevel(.info)
    }

    func connect(completion: @escaping (Result<Void, Error>) -> Void) {
        let transport = setupTransport()

        sessionManager.connect(
            to: configuration.host,
            port: Int(configuration.port),
            tls: true,
            keepalive: 60,
            clean: true,
            auth: true,
            user: configuration.username,
            pass: configuration.password,
            will: true,
            willTopic: configuration.willTopic,
            willMsg: configuration.willMessage,
            willQos: .atMostOnce,
            willRetainFlag: true,
            withClientId: configuration.clientId,
            securityPolicy: securityPolicyFactory.createSecurityPolicy(),
            certificates: transport.certificates,
            protocolLevel: MQTTProtocolVersion.version0
        ) {[weak self] error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
                self?.startKeepAliveTimer()
            }
        }
    }

    func disconnect() {
        sessionManager.disconnect { [weak self] error in
            if error == nil {
                self?.subscribedTopics.removeAll()
            }
        }
        sessionManager.delegate = nil
        keepAliveTimer?.invalidate()
        keepAliveTimer = nil
    }

    private func setupTransport() -> MQTTSSLSecurityPolicyTransport {
        let transport = MQTTSSLSecurityPolicyTransport()
        transport.host = configuration.host
        transport.port = configuration.port
        transport.tls = true
        transport.securityPolicy = securityPolicyFactory.createSecurityPolicy()
        return transport
    }

    func subscribe(to topics: [String]) {
        topics.forEach { topic in
            subscribedTopics[topic] = NSNumber(value: MQTTClient.MQTTQosLevel.atLeastOnce.rawValue)
        }
        sessionManager.subscriptions = subscribedTopics
    }

    func unsubscribe(from topics: [String]) {
        topics.forEach { topic in
            subscribedTopics.removeValue(forKey: topic)
        }
        sessionManager.subscriptions = subscribedTopics

        if subscribedTopics.isEmpty {
            disconnect()
        }
    }

    func publish(
        message: Data,
        to topic: String,
        qos: MQTTClient.MQTTQosLevel = .atLeastOnce,
        retained: Bool = false,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        let msgId = sessionManager.send(message, topic: topic, qos: qos, retain: retained)
        if msgId == 0 {
            completion?(.failure(MQTTError.publishFailed))
            return
        }
        completion?(.success(()))
    }
}

// MARK: - MQTTSessionManagerDelegate
extension MQTTClientManager: MQTTSessionManagerDelegate {
    func sessionManager(
        _ sessionManager: MQTTSessionManager, didChange newState: MQTTSessionManagerState
    ) {
        switch newState {
        case .starting:
            print("Starting connection")
        case .connecting:
            print("Connecting")
        case .connected:
            print("Connected")
        case .closing:
            print("Closing connection")
        case .error:
            print("Connection error")
        default:
            break
        }
    }

    func handleMessage(_ data: Data, onTopic topic: String, retained: Bool) {
        let messageHandler = MQTTMessageHandler()
        messageHandler.handle(data: data, topic: topic, retained: retained)
    }
}

// MARK: - Private Helper Methods
extension MQTTClientManager {
    private func setupReconnection() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNetworkChange(_:)),
            name: .connectivityStatusChanged,
            object: nil
        )
    }

    @objc private func handleNetworkChange(_ notification: Notification) {
        guard let isConnected = notification.object as? Bool else { return }
        if isConnected && sessionManager.state != .connected {
            connect { _ in }
        }
    }

    private func startKeepAliveTimer() {
        keepAliveTimer?.invalidate()
        keepAliveTimer = Timer.scheduledTimer(
            withTimeInterval: 30,
            repeats: true
        ) { [weak self] _ in
            self?.checkConnection()
        }
    }

    private func checkConnection() {
        if sessionManager.state != .connected {
            connect { _ in }
        }
    }
}

// MARK: - Error Handling
enum MQTTError: LocalizedError {
    case connectionFailed
    case publishFailed
    case subscriptionFailed
    case disconnectionFailed
    case invalidConfiguration

    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Failed to connect to MQTT broker"
        case .publishFailed:
            return "Failed to publish message"
        case .subscriptionFailed:
            return "Failed to subscribe to topic"
        case .disconnectionFailed:
            return "Failed to disconnect from broker"
        case .invalidConfiguration:
            return "Invalid MQTT configuration"
        }
    }
}
