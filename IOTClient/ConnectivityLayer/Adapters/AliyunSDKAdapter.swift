//
//  AliyunSDKAdapter.swift
//  ConnectivityLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

// MARK: - Aliyun SDK Message Types

/// 阿里云SDK消息结构
public struct AliyunMessage: Codable, Hashable {
    /// 消息ID
    public let messageId: String
    
    /// 设备ID
    public let deviceId: String
    
    /// 产品Key
    public let productKey: String
    
    /// 消息类型
    public let messageType: AliyunMessageType
    
    /// 消息内容
    public let payload: Data
    
    /// 服务质量等级
    public let qos: AliyunQoS
    
    /// 时间戳
    public let timestamp: Date
    
    /// 消息属性
    public let properties: [String: String]
    
    /// 消息方向
    public let direction: AliyunMessageDirection
    
    public init(
        messageId: String = UUID().uuidString,
        deviceId: String,
        productKey: String,
        messageType: AliyunMessageType,
        payload: Data,
        qos: AliyunQoS = .atLeastOnce,
        timestamp: Date = Date(),
        properties: [String: String] = [:],
        direction: AliyunMessageDirection = .upstream
    ) {
        self.messageId = messageId
        self.deviceId = deviceId
        self.productKey = productKey
        self.messageType = messageType
        self.payload = payload
        self.qos = qos
        self.timestamp = timestamp
        self.properties = properties
        self.direction = direction
    }
}

/// 阿里云消息类型
public enum AliyunMessageType: String, CaseIterable, Codable {
    case property = "thing.event.property.post"
    case event = "thing.event.custom.post"
    case service = "thing.service.custom"
    case propertySet = "thing.service.property.set"
    case propertyGet = "thing.service.property.get"
    case deviceInfo = "thing.deviceinfo.update"
    case config = "thing.config.push"
    case ota = "ota.device.upgrade"
    case shadow = "thing.shadow.update"
    case topo = "thing.topo.add"
    case subDevice = "thing.sub.register"
    case gateway = "thing.gateway.found"
    case diagnostic = "thing.diagnostic.post"
    case log = "thing.log.post"
    case file = "thing.file.upload"
    case model = "thing.model.down"
    case ntp = "thing.ntp.response"
    case reset = "thing.reset"
    case disable = "thing.disable"
    case enable = "thing.enable"
    case delete = "thing.delete"
}

/// 阿里云消息方向
public enum AliyunMessageDirection: String, CaseIterable, Codable {
    case upstream = "up"     // 设备上报
    case downstream = "down" // 云端下发
}

/// 阿里云QoS等级
public enum AliyunQoS: Int, CaseIterable, Codable {
    case atMostOnce = 0     // 最多一次
    case atLeastOnce = 1    // 至少一次
    case exactlyOnce = 2    // 恰好一次
}

// MARK: - Aliyun SDK Configuration

/// 阿里云SDK配置
public struct AliyunConfiguration: Codable {
    /// 产品Key
    public let productKey: String
    
    /// 产品Secret
    public let productSecret: String
    
    /// 设备名称
    public let deviceName: String
    
    /// 设备Secret
    public let deviceSecret: String
    
    /// 区域ID
    public let regionId: String
    
    /// 实例ID（企业版）
    public let instanceId: String?
    
    /// 连接域名
    public let endpoint: String?
    
    /// 连接端口
    public let port: Int
    
    /// 是否使用SSL
    public let useSSL: Bool
    
    /// 连接超时时间
    public let connectionTimeout: TimeInterval
    
    /// 心跳间隔
    public let keepAliveInterval: TimeInterval
    
    /// 自动重连
    public let autoReconnect: Bool
    
    /// 重连间隔
    public let reconnectInterval: TimeInterval
    
    /// 最大重连次数
    public let maxReconnectAttempts: Int
    
    /// 消息缓存大小
    public let messageBufferSize: Int
    
    /// 是否启用设备影子
    public let enableDeviceShadow: Bool
    
    /// 是否启用物模型
    public let enableThingModel: Bool
    
    /// 是否启用OTA
    public let enableOTA: Bool
    
    /// 是否启用子设备管理
    public let enableSubDevice: Bool
    
    /// 日志级别
    public let logLevel: AliyunLogLevel
    
    /// 自定义属性
    public let customProperties: [String: String]
    
    public init(
        productKey: String,
        productSecret: String,
        deviceName: String,
        deviceSecret: String,
        regionId: String = "cn-shanghai",
        instanceId: String? = nil,
        endpoint: String? = nil,
        port: Int = 443,
        useSSL: Bool = true,
        connectionTimeout: TimeInterval = 30,
        keepAliveInterval: TimeInterval = 60,
        autoReconnect: Bool = true,
        reconnectInterval: TimeInterval = 5,
        maxReconnectAttempts: Int = 10,
        messageBufferSize: Int = 1000,
        enableDeviceShadow: Bool = false,
        enableThingModel: Bool = true,
        enableOTA: Bool = false,
        enableSubDevice: Bool = false,
        logLevel: AliyunLogLevel = .info,
        customProperties: [String: String] = [:]
    ) {
        self.productKey = productKey
        self.productSecret = productSecret
        self.deviceName = deviceName
        self.deviceSecret = deviceSecret
        self.regionId = regionId
        self.instanceId = instanceId
        self.endpoint = endpoint
        self.port = port
        self.useSSL = useSSL
        self.connectionTimeout = connectionTimeout
        self.keepAliveInterval = keepAliveInterval
        self.autoReconnect = autoReconnect
        self.reconnectInterval = reconnectInterval
        self.maxReconnectAttempts = maxReconnectAttempts
        self.messageBufferSize = messageBufferSize
        self.enableDeviceShadow = enableDeviceShadow
        self.enableThingModel = enableThingModel
        self.enableOTA = enableOTA
        self.enableSubDevice = enableSubDevice
        self.logLevel = logLevel
        self.customProperties = customProperties
    }
}

/// 阿里云日志级别
public enum AliyunLogLevel: String, CaseIterable, Codable {
    case verbose = "verbose"
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    case none = "none"
}

// MARK: - Aliyun SDK Adapter

/// 阿里云SDK适配器
public final class AliyunSDKAdapter: CommunicationService {
    
    // MARK: - CommunicationService Properties
    
    public let serviceId: String = "aliyun-sdk"
    public let serviceName: String = "阿里云IoT SDK"
    public let serviceDescription: String = "阿里云物联网平台SDK通信服务"
    public let supportedMessageTypes: [String] = AliyunMessageType.allCases.map { $0.rawValue }
    
    @Published public private(set) var connectionState: ConnectionState = .disconnected
    @Published public private(set) var lastError: Error?
    @Published public private(set) var diagnostics: ConnectionDiagnostics = ConnectionDiagnostics()
    
    public var connectionStatePublisher: AnyPublisher<ConnectionState, Never> {
        $connectionState.eraseToAnyPublisher()
    }
    
    public var messagePublisher: AnyPublisher<Any, Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    public var errorPublisher: AnyPublisher<Error, Never> {
        $lastError.compactMap { $0 }.eraseToAnyPublisher()
    }
    
    public var diagnosticsPublisher: AnyPublisher<ConnectionDiagnostics, Never> {
        $diagnostics.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    
    private let configuration: AliyunConfiguration
    private let messageSubject = PassthroughSubject<Any, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    // 模拟阿里云SDK客户端
    private var aliyunClient: AliyunSDKClient?
    private let connectionQueue = DispatchQueue(label: "aliyun-sdk-connection", qos: .userInitiated)
    private let messageQueue = DispatchQueue(label: "aliyun-sdk-message", qos: .default)
    
    // 连接管理
    private var isConnecting = false
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private var heartbeatTimer: Timer?
    
    // 消息管理
    private var messageBuffer: [AliyunMessage] = []
    private var subscriptions: Set<String> = []
    private var pendingMessages: [String: AliyunMessage] = [:]
    
    // 统计信息
    private var connectionStartTime: Date?
    private var lastMessageTime: Date?
    private var messagesSent = 0
    private var messagesReceived = 0
    private var bytesSent: Int64 = 0
    private var bytesReceived: Int64 = 0
    
    // MARK: - Initialization
    
    public init(configuration: AliyunConfiguration) {
        self.configuration = configuration
        setupDiagnostics()
    }
    
    deinit {
        disconnect()
        cancellables.removeAll()
    }
    
    // MARK: - CommunicationService Methods
    
    public func connect() async throws {
        guard connectionState != .connected && !isConnecting else {
            return
        }
        
        isConnecting = true
        connectionState = .connecting
        
        do {
            try await performConnection()
            connectionState = .connected
            connectionStartTime = Date()
            reconnectAttempts = 0
            
            startHeartbeat()
            
            if configuration.autoReconnect {
                setupReconnectionHandling()
            }
            
        } catch {
            connectionState = .disconnected
            lastError = error
            throw error
        } finally {
            isConnecting = false
        }
    }
    
    public func disconnect() {
        connectionState = .disconnecting
        
        stopHeartbeat()
        stopReconnectionTimer()
        
        aliyunClient?.disconnect()
        aliyunClient = nil
        
        connectionState = .disconnected
        connectionStartTime = nil
        
        clearMessageBuffer()
    }
    
    public func sendMessage(_ message: Any) async throws {
        guard connectionState == .connected else {
            throw CommunicationError.notConnected
        }
        
        guard let aliyunMessage = message as? AliyunMessage else {
            throw CommunicationError.invalidMessageFormat
        }
        
        try await sendAliyunMessage(aliyunMessage)
    }
    
    public func subscribe(to topic: String) async throws {
        guard connectionState == .connected else {
            throw CommunicationError.notConnected
        }
        
        try await performSubscription(topic: topic)
        subscriptions.insert(topic)
    }
    
    public func unsubscribe(from topic: String) async throws {
        guard connectionState == .connected else {
            throw CommunicationError.notConnected
        }
        
        try await performUnsubscription(topic: topic)
        subscriptions.remove(topic)
    }
    
    public func updateConfiguration(_ config: Any) throws {
        guard let aliyunConfig = config as? AliyunConfiguration else {
            throw CommunicationError.invalidConfiguration
        }
        
        // 如果连接中，需要重新连接以应用新配置
        if connectionState == .connected {
            disconnect()
            Task {
                try? await connect()
            }
        }
    }
    
    public func getConnectionInfo() -> [String: Any] {
        var info: [String: Any] = [
            "serviceId": serviceId,
            "serviceName": serviceName,
            "connectionState": connectionState.rawValue,
            "productKey": configuration.productKey,
            "deviceName": configuration.deviceName,
            "regionId": configuration.regionId,
            "useSSL": configuration.useSSL,
            "port": configuration.port,
            "subscriptions": Array(subscriptions),
            "messagesSent": messagesSent,
            "messagesReceived": messagesReceived,
            "bytesSent": bytesSent,
            "bytesReceived": bytesReceived,
            "reconnectAttempts": reconnectAttempts,
            "bufferSize": messageBuffer.count
        ]
        
        if let connectionStartTime = connectionStartTime {
            info["connectionDuration"] = Date().timeIntervalSince(connectionStartTime)
        }
        
        if let lastMessageTime = lastMessageTime {
            info["lastMessageTime"] = lastMessageTime
        }
        
        if let instanceId = configuration.instanceId {
            info["instanceId"] = instanceId
        }
        
        return info
    }
}

// MARK: - Private Implementation

private extension AliyunSDKAdapter {
    
    func performConnection() async throws {
        // 创建阿里云SDK客户端
        aliyunClient = AliyunSDKClient(configuration: configuration)
        
        // 设置消息接收回调
        aliyunClient?.onMessageReceived = { [weak self] message in
            self?.handleReceivedMessage(message)
        }
        
        // 设置连接状态回调
        aliyunClient?.onConnectionStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.handleConnectionStateChange(state)
            }
        }
        
        // 执行连接
        try await aliyunClient?.connect()
        
        // 订阅默认主题
        try await subscribeToDefaultTopics()
    }
    
    func sendAliyunMessage(_ message: AliyunMessage) async throws {
        guard let client = aliyunClient else {
            throw CommunicationError.notConnected
        }
        
        // 构建阿里云消息格式
        let topic = buildTopicForMessage(message)
        let payload = try buildPayloadForMessage(message)
        
        // 发送消息
        try await client.publish(topic: topic, payload: payload, qos: message.qos.rawValue)
        
        // 更新统计信息
        messagesSent += 1
        bytesSent += Int64(payload.count)
        lastMessageTime = Date()
        
        // 缓存消息（用于重发）
        if message.qos != .atMostOnce {
            pendingMessages[message.messageId] = message
        }
    }
    
    func performSubscription(topic: String) async throws {
        guard let client = aliyunClient else {
            throw CommunicationError.notConnected
        }
        
        try await client.subscribe(topic: topic, qos: AliyunQoS.atLeastOnce.rawValue)
    }
    
    func performUnsubscription(topic: String) async throws {
        guard let client = aliyunClient else {
            throw CommunicationError.notConnected
        }
        
        try await client.unsubscribe(topic: topic)
    }
    
    func subscribeToDefaultTopics() async throws {
        let defaultTopics = [
            "/sys/\(configuration.productKey)/\(configuration.deviceName)/thing/service/+",
            "/sys/\(configuration.productKey)/\(configuration.deviceName)/thing/config/push",
            "/sys/\(configuration.productKey)/\(configuration.deviceName)/rrpc/request/+"
        ]
        
        for topic in defaultTopics {
            try await performSubscription(topic: topic)
        }
    }
    
    func handleReceivedMessage(_ message: AliyunSDKMessage) {
        messageQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 转换为内部消息格式
            let aliyunMessage = self.convertToAliyunMessage(message)
            
            // 更新统计信息
            self.messagesReceived += 1
            self.bytesReceived += Int64(message.payload.count)
            self.lastMessageTime = Date()
            
            // 发布消息
            DispatchQueue.main.async {
                self.messageSubject.send(aliyunMessage)
            }
        }
    }
    
    func handleConnectionStateChange(_ state: AliyunSDKConnectionState) {
        switch state {
        case .connected:
            connectionState = .connected
        case .disconnected:
            connectionState = .disconnected
            if configuration.autoReconnect && reconnectAttempts < configuration.maxReconnectAttempts {
                scheduleReconnection()
            }
        case .connecting:
            connectionState = .connecting
        case .error(let error):
            connectionState = .error
            lastError = error
        }
    }
    
    func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: configuration.keepAliveInterval, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }
    
    func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    func sendHeartbeat() {
        guard connectionState == .connected else { return }
        
        Task {
            do {
                let heartbeatMessage = AliyunMessage(
                    deviceId: configuration.deviceName,
                    productKey: configuration.productKey,
                    messageType: .deviceInfo,
                    payload: "heartbeat".data(using: .utf8) ?? Data(),
                    qos: .atMostOnce
                )
                
                try await sendAliyunMessage(heartbeatMessage)
            } catch {
                print("心跳发送失败: \(error)")
            }
        }
    }
    
    func setupReconnectionHandling() {
        // 监听网络状态变化等
    }
    
    func scheduleReconnection() {
        guard reconnectAttempts < configuration.maxReconnectAttempts else {
            return
        }
        
        reconnectAttempts += 1
        let delay = configuration.reconnectInterval * Double(reconnectAttempts)
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task {
                try? await self?.connect()
            }
        }
    }
    
    func stopReconnectionTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    func clearMessageBuffer() {
        messageBuffer.removeAll()
        pendingMessages.removeAll()
    }
    
    func setupDiagnostics() {
        // 定期更新诊断信息
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateDiagnostics()
        }
    }
    
    func updateDiagnostics() {
        var newDiagnostics = diagnostics
        
        // 更新连接质量指标
        newDiagnostics.signalStrength = calculateSignalStrength()
        newDiagnostics.latency = calculateLatency()
        newDiagnostics.throughput = calculateThroughput()
        newDiagnostics.packetLoss = calculatePacketLoss()
        newDiagnostics.errorRate = calculateErrorRate()
        newDiagnostics.lastUpdated = Date()
        
        diagnostics = newDiagnostics
    }
    
    func calculateSignalStrength() -> Double {
        // 基于连接状态和错误率计算信号强度
        switch connectionState {
        case .connected:
            return max(0.5, 1.0 - Double(reconnectAttempts) * 0.1)
        case .connecting:
            return 0.3
        default:
            return 0.0
        }
    }
    
    func calculateLatency() -> TimeInterval {
        // 模拟延迟计算
        return configuration.useSSL ? 0.05 : 0.03
    }
    
    func calculateThroughput() -> Double {
        // 基于最近的消息传输计算吞吐量
        guard let lastMessageTime = lastMessageTime else { return 0 }
        
        let timeSinceLastMessage = Date().timeIntervalSince(lastMessageTime)
        return timeSinceLastMessage < 10 ? 1000.0 : 100.0
    }
    
    func calculatePacketLoss() -> Double {
        // 基于重连次数估算丢包率
        return min(0.1, Double(reconnectAttempts) * 0.01)
    }
    
    func calculateErrorRate() -> Double {
        // 基于错误次数计算错误率
        let totalMessages = messagesSent + messagesReceived
        return totalMessages > 0 ? Double(reconnectAttempts) / Double(totalMessages) : 0
    }
    
    func buildTopicForMessage(_ message: AliyunMessage) -> String {
        switch message.messageType {
        case .property:
            return "/sys/\(message.productKey)/\(message.deviceId)/thing/event/property/post"
        case .event:
            return "/sys/\(message.productKey)/\(message.deviceId)/thing/event/custom/post"
        case .service:
            return "/sys/\(message.productKey)/\(message.deviceId)/thing/service/custom"
        default:
            return "/sys/\(message.productKey)/\(message.deviceId)/\(message.messageType.rawValue)"
        }
    }
    
    func buildPayloadForMessage(_ message: AliyunMessage) throws -> Data {
        let payload: [String: Any] = [
            "id": message.messageId,
            "version": "1.0",
            "params": try JSONSerialization.jsonObject(with: message.payload),
            "method": message.messageType.rawValue
        ]
        
        return try JSONSerialization.data(withJSONObject: payload)
    }
    
    func convertToAliyunMessage(_ sdkMessage: AliyunSDKMessage) -> AliyunMessage {
        return AliyunMessage(
            messageId: sdkMessage.messageId,
            deviceId: sdkMessage.deviceId,
            productKey: sdkMessage.productKey,
            messageType: AliyunMessageType(rawValue: sdkMessage.method) ?? .property,
            payload: sdkMessage.payload,
            qos: AliyunQoS(rawValue: sdkMessage.qos) ?? .atLeastOnce,
            timestamp: sdkMessage.timestamp,
            properties: sdkMessage.properties,
            direction: .downstream
        )
    }
}

// MARK: - Mock Aliyun SDK Client

/// 模拟阿里云SDK客户端（实际项目中应使用真实的阿里云SDK）
private class AliyunSDKClient {
    let configuration: AliyunConfiguration
    var onMessageReceived: ((AliyunSDKMessage) -> Void)?
    var onConnectionStateChanged: ((AliyunSDKConnectionState) -> Void)?
    
    private var isConnected = false
    
    init(configuration: AliyunConfiguration) {
        self.configuration = configuration
    }
    
    func connect() async throws {
        // 模拟连接过程
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
        isConnected = true
        onConnectionStateChanged?(.connected)
    }
    
    func disconnect() {
        isConnected = false
        onConnectionStateChanged?(.disconnected)
    }
    
    func publish(topic: String, payload: Data, qos: Int) async throws {
        guard isConnected else {
            throw CommunicationError.notConnected
        }
        
        // 模拟发布消息
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
    }
    
    func subscribe(topic: String, qos: Int) async throws {
        guard isConnected else {
            throw CommunicationError.notConnected
        }
        
        // 模拟订阅
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
    }
    
    func unsubscribe(topic: String) async throws {
        guard isConnected else {
            throw CommunicationError.notConnected
        }
        
        // 模拟取消订阅
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
    }
}

/// 阿里云SDK消息
private struct AliyunSDKMessage {
    let messageId: String
    let deviceId: String
    let productKey: String
    let method: String
    let payload: Data
    let qos: Int
    let timestamp: Date
    let properties: [String: String]
}

/// 阿里云SDK连接状态
private enum AliyunSDKConnectionState {
    case connected
    case disconnected
    case connecting
    case error(Error)
}

// MARK: - Aliyun Utilities

/// 阿里云工具类
public struct AliyunUtils {
    
    /// 创建设备认证信息
    public static func createDeviceAuth(
        productKey: String,
        deviceName: String,
        deviceSecret: String
    ) -> [String: String] {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let clientId = "\(deviceName)|securemode=3,signmethod=hmacsha1,timestamp=\(timestamp)|"
        
        // 简化的签名计算（实际应使用HMAC-SHA1）
        let signContent = "clientId\(clientId)deviceName\(deviceName)productKey\(productKey)timestamp\(timestamp)"
        let sign = signContent.sha256
        
        return [
            "productKey": productKey,
            "deviceName": deviceName,
            "clientId": clientId,
            "timestamp": timestamp,
            "sign": sign,
            "signmethod": "hmacsha1"
        ]
    }
    
    /// 解析设备影子消息
    public static func parseDeviceShadow(_ data: Data) throws -> [String: Any] {
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
    
    /// 构建物模型消息
    public static func buildThingModelMessage(
        method: String,
        params: [String: Any]
    ) throws -> Data {
        let message: [String: Any] = [
            "id": UUID().uuidString,
            "version": "1.0",
            "method": method,
            "params": params
        ]
        
        return try JSONSerialization.data(withJSONObject: message)
    }
}

// MARK: - String Extension

private extension String {
    var sha256: String {
        // 简化的SHA256实现（实际应使用CryptoKit）
        return "sha256_\(self.hashValue)"
    }
}