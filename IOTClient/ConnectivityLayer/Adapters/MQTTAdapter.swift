//
//  MQTTAdapter.swift
//  ConnectivityLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine
import Network

/// MQTT消息结构
public struct MQTTMessage: Codable {
    /// 主题
    public let topic: String
    
    /// 消息内容
    public let payload: Data
    
    /// 服务质量等级
    public let qos: MQTTQoS
    
    /// 保留消息标志
    public let retain: Bool
    
    /// 消息ID（QoS > 0时使用）
    public let messageId: UInt16?
    
    /// 时间戳
    public let timestamp: Date
    
    public init(
        topic: String,
        payload: Data,
        qos: MQTTQoS = .atMostOnce,
        retain: Bool = false,
        messageId: UInt16? = nil,
        timestamp: Date = Date()
    ) {
        self.topic = topic
        self.payload = payload
        self.qos = qos
        self.retain = retain
        self.messageId = messageId
        self.timestamp = timestamp
    }
    
    /// 从字符串创建消息
    public init(
        topic: String,
        message: String,
        qos: MQTTQoS = .atMostOnce,
        retain: Bool = false
    ) {
        self.init(
            topic: topic,
            payload: message.data(using: .utf8) ?? Data(),
            qos: qos,
            retain: retain
        )
    }
    
    /// 获取消息内容字符串
    public var messageString: String? {
        return String(data: payload, encoding: .utf8)
    }
    
    /// 消息大小（字节）
    public var size: Int {
        return payload.count
    }
}

/// MQTT服务质量等级
public enum MQTTQoS: Int, CaseIterable, Codable {
    case atMostOnce = 0     // 最多一次
    case atLeastOnce = 1    // 至少一次
    case exactlyOnce = 2    // 恰好一次
    
    public var displayName: String {
        switch self {
        case .atMostOnce:
            return "最多一次 (QoS 0)"
        case .atLeastOnce:
            return "至少一次 (QoS 1)"
        case .exactlyOnce:
            return "恰好一次 (QoS 2)"
        }
    }
}

/// MQTT连接配置
public struct MQTTConfiguration {
    /// 服务器地址
    public let host: String
    
    /// 服务器端口
    public let port: Int
    
    /// 客户端ID
    public let clientId: String
    
    /// 用户名
    public let username: String?
    
    /// 密码
    public let password: String?
    
    /// 使用SSL/TLS
    public let useSSL: Bool
    
    /// 保持连接间隔（秒）
    public let keepAliveInterval: TimeInterval
    
    /// 连接超时（秒）
    public let connectionTimeout: TimeInterval
    
    /// 自动重连
    public let autoReconnect: Bool
    
    /// 清除会话
    public let cleanSession: Bool
    
    /// 遗嘱消息
    public let willMessage: MQTTWillMessage?
    
    /// SSL配置
    public let sslConfiguration: MQTTSSLConfiguration?
    
    public init(
        host: String,
        port: Int = 1883,
        clientId: String = UUID().uuidString,
        username: String? = nil,
        password: String? = nil,
        useSSL: Bool = false,
        keepAliveInterval: TimeInterval = 60,
        connectionTimeout: TimeInterval = 30,
        autoReconnect: Bool = true,
        cleanSession: Bool = true,
        willMessage: MQTTWillMessage? = nil,
        sslConfiguration: MQTTSSLConfiguration? = nil
    ) {
        self.host = host
        self.port = port
        self.clientId = clientId
        self.username = username
        self.password = password
        self.useSSL = useSSL
        self.keepAliveInterval = keepAliveInterval
        self.connectionTimeout = connectionTimeout
        self.autoReconnect = autoReconnect
        self.cleanSession = cleanSession
        self.willMessage = willMessage
        self.sslConfiguration = sslConfiguration
    }
    
    /// 创建默认配置
    public static func `default`(host: String, port: Int = 1883) -> MQTTConfiguration {
        return MQTTConfiguration(host: host, port: port)
    }
    
    /// 创建SSL配置
    public static func ssl(host: String, port: Int = 8883) -> MQTTConfiguration {
        return MQTTConfiguration(host: host, port: port, useSSL: true)
    }
}

/// MQTT遗嘱消息
public struct MQTTWillMessage {
    /// 遗嘱主题
    public let topic: String
    
    /// 遗嘱消息
    public let message: String
    
    /// 服务质量等级
    public let qos: MQTTQoS
    
    /// 保留标志
    public let retain: Bool
    
    public init(
        topic: String,
        message: String,
        qos: MQTTQoS = .atMostOnce,
        retain: Bool = false
    ) {
        self.topic = topic
        self.message = message
        self.qos = qos
        self.retain = retain
    }
}

/// MQTT SSL配置
public struct MQTTSSLConfiguration {
    /// 证书验证模式
    public let certificateVerification: CertificateVerification
    
    /// 客户端证书路径
    public let clientCertificatePath: String?
    
    /// 客户端私钥路径
    public let clientPrivateKeyPath: String?
    
    /// CA证书路径
    public let caCertificatePath: String?
    
    /// 允许的协议版本
    public let allowedProtocols: Set<String>
    
    public init(
        certificateVerification: CertificateVerification = .required,
        clientCertificatePath: String? = nil,
        clientPrivateKeyPath: String? = nil,
        caCertificatePath: String? = nil,
        allowedProtocols: Set<String> = ["TLSv1.2", "TLSv1.3"]
    ) {
        self.certificateVerification = certificateVerification
        self.clientCertificatePath = clientCertificatePath
        self.clientPrivateKeyPath = clientPrivateKeyPath
        self.caCertificatePath = caCertificatePath
        self.allowedProtocols = allowedProtocols
    }
    
    public enum CertificateVerification {
        case none
        case optional
        case required
    }
}

/// MQTT适配器实现
public final class MQTTAdapter: CommunicationService {
    
    // MARK: - Type Aliases
    
    public typealias Configuration = MQTTConfiguration
    public typealias Message = MQTTMessage
    
    // MARK: - Properties
    
    public let serviceId: String
    public let serviceName: String = "MQTT服务"
    
    @Published private var _connectionState: ConnectionState = .disconnected
    public var connectionState: ConnectionState {
        return _connectionState
    }
    
    public var connectionStatePublisher: AnyPublisher<ConnectionState, Never> {
        return $_connectionState.eraseToAnyPublisher()
    }
    
    private let _messageSubject = PassthroughSubject<MQTTMessage, Never>()
    public var messagePublisher: AnyPublisher<MQTTMessage, Never> {
        return _messageSubject.eraseToAnyPublisher()
    }
    
    private let _errorSubject = PassthroughSubject<CommunicationError, Never>()
    public var errorPublisher: AnyPublisher<CommunicationError, Never> {
        return _errorSubject.eraseToAnyPublisher()
    }
    
    public let supportsAutoReconnect: Bool = true
    public var maxReconnectAttempts: Int = 3
    public var reconnectInterval: TimeInterval = 5.0
    
    // MARK: - Private Properties
    
    private var currentConfiguration: MQTTConfiguration?
    private var connection: NWConnection?
    private var connectionQueue: DispatchQueue
    private var cancellables = Set<AnyCancellable>()
    private var subscriptions = Set<String>()
    private var pendingMessages = [UInt16: MQTTMessage]()
    private var messageIdCounter: UInt16 = 1
    private var reconnectAttempts = 0
    private var reconnectTimer: Timer?
    private var keepAliveTimer: Timer?
    private var statistics = ServiceStatistics()
    
    // MARK: - Initialization
    
    public init(serviceId: String = "mqtt-adapter") {
        self.serviceId = serviceId
        self.connectionQueue = DispatchQueue(label: "mqtt.connection.\(serviceId)", qos: .userInitiated)
        
        setupConnectionStateMonitoring()
    }
    
    deinit {
        disconnect()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Connection Management
    
    public func connect(with configuration: MQTTConfiguration) -> AnyPublisher<Void, CommunicationError> {
        return Future<Void, CommunicationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.connectionFailed("适配器已释放")))
                return
            }
            
            self.currentConfiguration = configuration
            self._connectionState = .connecting
            
            self.connectionQueue.async {
                self.performConnection(configuration: configuration, promise: promise)
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func disconnect() -> AnyPublisher<Void, CommunicationError> {
        return Future<Void, CommunicationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.connectionFailed("适配器已释放")))
                return
            }
            
            self.connectionQueue.async {
                self.performDisconnection(promise: promise)
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func reconnect() -> AnyPublisher<Void, CommunicationError> {
        guard let configuration = currentConfiguration else {
            return Fail(error: CommunicationError.invalidConfiguration("无连接配置"))
                .eraseToAnyPublisher()
        }
        
        return disconnect()
            .flatMap { _ in
                return self.connect(with: configuration)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Message Handling
    
    public func sendMessageWithResponse(_ message: MQTTMessage, timeout: TimeInterval) -> AnyPublisher<MQTTMessage, CommunicationError> {
        guard connectionState.canSendMessage else {
            return Fail(error: CommunicationError.connectionLost)
                .eraseToAnyPublisher()
        }
        
        return Future<MQTTMessage, CommunicationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.messageSendFailed("适配器已释放")))
                return
            }
            
            self.connectionQueue.async {
                self.performSendMessage(message, promise: promise)
            }
        }
        .timeout(.seconds(timeout), scheduler: connectionQueue)
        .catch { error -> AnyPublisher<MQTTMessage, CommunicationError> in
            if error is TimeoutError {
                return Fail(error: CommunicationError.timeout("发送消息超时"))
                    .eraseToAnyPublisher()
            } else {
                return Fail(error: error as? CommunicationError ?? CommunicationError.unknown(error))
                    .eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func subscribe(to topic: String) -> AnyPublisher<Void, CommunicationError> {
        guard connectionState.canSendMessage else {
            return Fail(error: CommunicationError.connectionLost)
                .eraseToAnyPublisher()
        }
        
        return Future<Void, CommunicationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.subscriptionFailed("适配器已释放")))
                return
            }
            
            self.connectionQueue.async {
                self.performSubscribe(topic: topic, promise: promise)
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func unsubscribe(from topic: String) -> AnyPublisher<Void, CommunicationError> {
        guard connectionState.canSendMessage else {
            return Fail(error: CommunicationError.connectionLost)
                .eraseToAnyPublisher()
        }
        
        return Future<Void, CommunicationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.subscriptionFailed("适配器已释放")))
                return
            }
            
            self.connectionQueue.async {
                self.performUnsubscribe(topic: topic, promise: promise)
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Configuration
    
    public func updateConfiguration(_ configuration: MQTTConfiguration) -> AnyPublisher<Void, CommunicationError> {
        return disconnect()
            .flatMap { _ in
                return self.connect(with: configuration)
            }
            .eraseToAnyPublisher()
    }
    
    public func getCurrentConfiguration() -> MQTTConfiguration? {
        return currentConfiguration
    }
    
    // MARK: - Diagnostics
    
    public func getDiagnostics() -> ConnectionDiagnostics {
        return ConnectionDiagnostics(
            connectionState: connectionState,
            connectionDuration: getConnectionDuration(),
            lastConnectedAt: getLastConnectedTime(),
            lastDisconnectedAt: getLastDisconnectedTime(),
            reconnectCount: reconnectAttempts,
            lastError: getLastError(),
            latency: getLatency(),
            signalStrength: nil,
            additionalInfo: [
                "subscriptions": subscriptions.count,
                "pendingMessages": pendingMessages.count,
                "messageIdCounter": messageIdCounter
            ]
        )
    }
    
    public func getStatistics() -> ServiceStatistics {
        return statistics
    }
    
    public func resetStatistics() {
        statistics = ServiceStatistics()
    }
}

// MARK: - Private Implementation

private extension MQTTAdapter {
    
    func setupConnectionStateMonitoring() {
        // 监听连接状态变化
        connectionStatePublisher
            .sink { [weak self] state in
                self?.handleConnectionStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    func handleConnectionStateChange(_ state: ConnectionState) {
        switch state {
        case .connected:
            reconnectAttempts = 0
            startKeepAlive()
        case .disconnected, .failed:
            stopKeepAlive()
            if currentConfiguration?.autoReconnect == true && reconnectAttempts < maxReconnectAttempts {
                scheduleReconnect()
            }
        case .connecting, .reconnecting, .suspended:
            break
        }
    }
    
    func performConnection(configuration: MQTTConfiguration, promise: @escaping (Result<Void, CommunicationError>) -> Void) {
        // 创建网络连接
        let host = NWEndpoint.Host(configuration.host)
        let port = NWEndpoint.Port(integerLiteral: UInt16(configuration.port))
        let endpoint = NWEndpoint.hostPort(host: host, port: port)
        
        let parameters = NWParameters.tcp
        if configuration.useSSL {
            parameters.defaultProtocolStack.applicationProtocols.insert(NWProtocolTLS.Options(), at: 0)
        }
        
        connection = NWConnection(to: endpoint, using: parameters)
        
        connection?.stateUpdateHandler = { [weak self] state in
            self?.handleNWConnectionState(state, promise: promise)
        }
        
        connection?.start(queue: connectionQueue)
        
        // 设置连接超时
        DispatchQueue.main.asyncAfter(deadline: .now() + configuration.connectionTimeout) { [weak self] in
            if self?._connectionState == .connecting {
                self?._connectionState = .failed
                promise(.failure(.connectionTimeout))
            }
        }
    }
    
    func handleNWConnectionState(_ state: NWConnection.State, promise: @escaping (Result<Void, CommunicationError>) -> Void) {
        switch state {
        case .ready:
            _connectionState = .connected
            promise(.success(()))
        case .failed(let error):
            _connectionState = .failed
            promise(.failure(.connectionFailed(error.localizedDescription)))
        case .cancelled:
            _connectionState = .disconnected
        default:
            break
        }
    }
    
    func performDisconnection(promise: @escaping (Result<Void, CommunicationError>) -> Void) {
        connection?.cancel()
        connection = nil
        _connectionState = .disconnected
        stopKeepAlive()
        cancelReconnectTimer()
        promise(.success(()))
    }
    
    func performSendMessage(_ message: MQTTMessage, promise: @escaping (Result<MQTTMessage, CommunicationError>) -> Void) {
        guard let connection = connection else {
            promise(.failure(.connectionLost))
            return
        }
        
        // 构建MQTT消息包
        let messageData = buildMQTTPublishPacket(message)
        
        connection.send(content: messageData, completion: .contentProcessed { [weak self] error in
            if let error = error {
                promise(.failure(.messageSendFailed(error.localizedDescription)))
            } else {
                self?.updateStatistics(messagesSent: 1, bytesSent: Int64(messageData.count))
                promise(.success(message))
            }
        })
    }
    
    func performSubscribe(topic: String, promise: @escaping (Result<Void, CommunicationError>) -> Void) {
        guard let connection = connection else {
            promise(.failure(.connectionLost))
            return
        }
        
        // 构建MQTT订阅包
        let subscribeData = buildMQTTSubscribePacket(topic: topic)
        
        connection.send(content: subscribeData, completion: .contentProcessed { [weak self] error in
            if let error = error {
                promise(.failure(.subscriptionFailed(error.localizedDescription)))
            } else {
                self?.subscriptions.insert(topic)
                promise(.success(()))
            }
        })
    }
    
    func performUnsubscribe(topic: String, promise: @escaping (Result<Void, CommunicationError>) -> Void) {
        guard let connection = connection else {
            promise(.failure(.connectionLost))
            return
        }
        
        // 构建MQTT取消订阅包
        let unsubscribeData = buildMQTTUnsubscribePacket(topic: topic)
        
        connection.send(content: unsubscribeData, completion: .contentProcessed { [weak self] error in
            if let error = error {
                promise(.failure(.subscriptionFailed(error.localizedDescription)))
            } else {
                self?.subscriptions.remove(topic)
                promise(.success(()))
            }
        })
    }
    
    func startKeepAlive() {
        guard let configuration = currentConfiguration else { return }
        
        keepAliveTimer = Timer.scheduledTimer(withTimeInterval: configuration.keepAliveInterval, repeats: true) { [weak self] _ in
            self?.sendKeepAlive()
        }
    }
    
    func stopKeepAlive() {
        keepAliveTimer?.invalidate()
        keepAliveTimer = nil
    }
    
    func sendKeepAlive() {
        guard let connection = connection else { return }
        
        let pingData = buildMQTTPingPacket()
        connection.send(content: pingData, completion: .contentProcessed { _ in })
    }
    
    func scheduleReconnect() {
        reconnectAttempts += 1
        _connectionState = .reconnecting
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectInterval, repeats: false) { [weak self] _ in
            self?.performAutoReconnect()
        }
    }
    
    func performAutoReconnect() {
        guard let configuration = currentConfiguration else { return }
        
        reconnect()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        self?.scheduleReconnect()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    func cancelReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    // MARK: - MQTT Protocol Implementation
    
    func buildMQTTPublishPacket(_ message: MQTTMessage) -> Data {
        // 简化的MQTT PUBLISH包构建
        // 实际实现需要完整的MQTT协议支持
        var data = Data()
        
        // Fixed Header
        let messageType: UInt8 = 0x30 // PUBLISH
        data.append(messageType)
        
        // Variable Header + Payload
        let topicData = message.topic.data(using: .utf8) ?? Data()
        let topicLength = UInt16(topicData.count)
        data.append(contentsOf: topicLength.bigEndian.bytes)
        data.append(topicData)
        data.append(message.payload)
        
        // Remaining Length
        let remainingLength = data.count - 1
        data.insert(UInt8(remainingLength), at: 1)
        
        return data
    }
    
    func buildMQTTSubscribePacket(topic: String) -> Data {
        // 简化的MQTT SUBSCRIBE包构建
        var data = Data()
        
        let messageType: UInt8 = 0x82 // SUBSCRIBE
        data.append(messageType)
        
        let topicData = topic.data(using: .utf8) ?? Data()
        let topicLength = UInt16(topicData.count)
        data.append(contentsOf: topicLength.bigEndian.bytes)
        data.append(topicData)
        data.append(0x00) // QoS
        
        let remainingLength = data.count - 1
        data.insert(UInt8(remainingLength), at: 1)
        
        return data
    }
    
    func buildMQTTUnsubscribePacket(topic: String) -> Data {
        // 简化的MQTT UNSUBSCRIBE包构建
        var data = Data()
        
        let messageType: UInt8 = 0xA2 // UNSUBSCRIBE
        data.append(messageType)
        
        let topicData = topic.data(using: .utf8) ?? Data()
        let topicLength = UInt16(topicData.count)
        data.append(contentsOf: topicLength.bigEndian.bytes)
        data.append(topicData)
        
        let remainingLength = data.count - 1
        data.insert(UInt8(remainingLength), at: 1)
        
        return data
    }
    
    func buildMQTTPingPacket() -> Data {
        // MQTT PINGREQ包
        return Data([0xC0, 0x00])
    }
    
    // MARK: - Helper Methods
    
    func updateStatistics(messagesSent: Int = 0, messagesReceived: Int = 0, bytesSent: Int64 = 0, bytesReceived: Int64 = 0) {
        statistics = ServiceStatistics(
            messagesSent: statistics.messagesSent + messagesSent,
            messagesReceived: statistics.messagesReceived + messagesReceived,
            bytesSent: statistics.bytesSent + bytesSent,
            bytesReceived: statistics.bytesReceived + bytesReceived,
            connectionAttempts: statistics.connectionAttempts,
            successfulConnections: statistics.successfulConnections,
            failedConnections: statistics.failedConnections,
            averageLatency: statistics.averageLatency,
            statisticsStartTime: statistics.statisticsStartTime,
            lastUpdated: Date()
        )
    }
    
    func getConnectionDuration() -> TimeInterval? {
        // 实现连接时长计算
        return nil
    }
    
    func getLastConnectedTime() -> Date? {
        // 实现最后连接时间获取
        return nil
    }
    
    func getLastDisconnectedTime() -> Date? {
        // 实现最后断开时间获取
        return nil
    }
    
    func getLastError() -> CommunicationError? {
        // 实现最后错误获取
        return nil
    }
    
    func getLatency() -> Double? {
        // 实现延迟计算
        return nil
    }
}

// MARK: - Extensions

private extension UInt16 {
    var bytes: [UInt8] {
        return [UInt8(self >> 8), UInt8(self & 0xFF)]
    }
}

private struct TimeoutError: Error {}