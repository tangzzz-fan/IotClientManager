import Foundation
import MQTTClient

protocol MQTTClientManaging: AnyObject {
    func connect(completion: @escaping (Result<Void, Error>) -> Void)
    func disconnect()
    func subscribe(to topics: [String])
    func unsubscribe(from topics: [String])
    func publish(
        message: Data,
        to topic: String,
        qos: MQTTQosLevel,
        retained: Bool,
        completion: ((Result<Void, Error>) -> Void)?
    )
}

final class MQTTClientManager: NSObject, MQTTClientManaging {
    static let shared = MQTTClientManager()

    private let clientAdapter: MQTTClientAdapter
    private let connectionMemento: MQTTConnectionMemento
    private let messageHandlerChain: MessageHandler
    private var configuration: MQTTConfigurable
    private var keepAliveTimer: Timer?
    private var subscribedTopics: [String: NSNumber] = [:]

    init(
        configuration: MQTTConfigurable = MQTTConfigurationBuilder()
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
            .build(),
        clientAdapter: MQTTClientAdapter? = nil,
        connectionMemento: MQTTConnectionMemento = MQTTConnectionCaretaker()
    ) {
        self.configuration = configuration

        // 初始化消息处理链
        let willHandler = WillMessageHandler()
        let statusHandler = StatusMessageHandler()
        let notificationHandler = NotificationMessageHandler()
        willHandler.next = statusHandler
        statusHandler.next = notificationHandler
        self.messageHandlerChain = willHandler

        // 初始化适配器
        if let adapter = clientAdapter {
            self.clientAdapter = adapter
        } else {
            let sessionManager = MQTTSessionManager()
            self.clientAdapter = MQTTClientCocoaAdapter(client: sessionManager, configuration: configuration)
        }

        self.connectionMemento = connectionMemento

        super.init()

        setupReconnection()
        restoreConnectionState()
    }

    var isConnected: Bool {
        return clientAdapter.isConnected
    }
    
    /// 初始化MQTT客户端管理器
    func initialize() {
        print("[MQTTClientManager] 初始化MQTT客户端管理器")
        // 恢复连接状态
        restoreConnectionState()
        // 设置网络监听
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNetworkChange(_:)),
            name: .networkStatusChanged,
            object: nil
        )
    }
    
    /// 关闭MQTT客户端管理器
    func shutdown() {
        print("[MQTTClientManager] 关闭MQTT客户端管理器")
        disconnect()
        keepAliveTimer?.invalidate()
        keepAliveTimer = nil
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    func connect(completion: @escaping (Result<Void, Error>) -> Void) {
        print("Attempting to connect to MQTT broker at \(configuration.host):\(configuration.port)")
        clientAdapter.connect { [weak self] result in
            switch result {
            case .success:
                print("Successfully connected to MQTT broker")
                self?.startKeepAliveTimer()
                self?.saveConnectionState()
                completion(.success(()))
            case .failure(let error):
                print("Failed to connect to MQTT broker: \(error)")
                completion(.failure(error))
            }
        }
    }

    func disconnect() {
        print("Disconnecting from MQTT broker")
        keepAliveTimer?.invalidate()
        keepAliveTimer = nil
        clientAdapter.disconnect()
        subscribedTopics.removeAll()
        saveConnectionState()
    }

    func subscribe(to topics: [String]) {
        print("Subscribing to topics: \(topics)")
        topics.forEach { topic in
            subscribedTopics[topic] = NSNumber(value: MQTTQosLevel.atLeastOnce.rawValue)
        }
        clientAdapter.subscribe(to: topics)
        saveConnectionState()
    }

    func unsubscribe(from topics: [String]) {
        print("Unsubscribing from topics: \(topics)")
        topics.forEach { topic in
            subscribedTopics.removeValue(forKey: topic)
        }
        clientAdapter.unsubscribe(from: topics)

        if subscribedTopics.isEmpty {
            disconnect()
        }
        saveConnectionState()
    }

    func publish(
        message: Data,
        to topic: String,
        qos: MQTTQosLevel = .atLeastOnce,
        retained: Bool = false,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        print("Publishing message to topic: \(topic)")
        clientAdapter.publish(
            message: message,
            topic: topic,
            qos: Int(qos.rawValue),
            retained: retained
        )
        completion?(.success(()))
    }

    // MARK: - Private Methods

    private func setupReconnection() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNetworkChange(_:)),
            name: .connectivityStatusChanged,
            object: nil
        )
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
        clientAdapter.checkConnection { [weak self] isConnected in
            if !isConnected {
                print("Connection lost, attempting to reconnect...")
                self?.connect { _ in }
            }
        }
    }

    private func saveConnectionState() {
        let state = MQTTConnectionState(
            host: configuration.host,
            port: configuration.port,
            subscribedTopics: subscribedTopics,
            lastConnectedTime: Date()
        )
        connectionMemento.saveState(state)
    }

    private func restoreConnectionState() {
        guard let savedState = connectionMemento.restoreState() else { return }
        print("Restoring connection state with topics: \(Array(savedState.subscribedTopics.keys))")
        subscribe(to: Array(savedState.subscribedTopics.keys))
    }

    @objc private func handleNetworkChange(_ notification: Notification) {
        guard let isConnected = notification.object as? Bool else { return }
        print("Network status changed: isConnected = \(isConnected)")
        if isConnected {
            connect { _ in }
        }
    }

    // MARK: - Message Handling

    func handleMessage(_ data: Data, onTopic topic: String, retained: Bool) {
        print("Handling message on topic: \(topic)")
        _ = messageHandlerChain.handle(data: data, topic: topic, retained: retained)
    }
}

// MARK: - MQTTSessionManagerDelegate
extension MQTTClientManager: MQTTSessionManagerDelegate {
    func sessionManager(
        _ sessionManager: MQTTSessionManager, didChange newState: MQTTSessionManagerState
    ) {
        switch newState {
        case .starting:
            print("MQTT connection state: Starting connection")
        case .connecting:
            print("MQTT connection state: Connecting to broker")
        case .connected:
            print("MQTT connection state: Successfully connected to broker")
        case .closing:
            print("MQTT connection state: Closing connection")
        case .error:
            print("MQTT connection state: Connection error occurred")
        case .closed:
            print("MQTT connection state: Connection closed")
        default:
            print("MQTT connection state: Unknown state \(newState)")
        }
    }
    
    func sessionManager(_ sessionManager: MQTTSessionManager, didReceive message: Data, onTopic topic: String, qos: MQTTQosLevel, retained: Bool, mid: UInt32) {
        print("Received MQTT message on topic: \(topic)")
        handleMessage(message, onTopic: topic, retained: retained)
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
