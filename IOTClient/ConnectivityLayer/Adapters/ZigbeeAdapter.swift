//
//  ZigbeeAdapter.swift
//  ConnectivityLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

/// Zigbee消息结构
public struct ZigbeeMessage: Codable {
    /// 源地址
    public let sourceAddress: String
    
    /// 目标地址
    public let destinationAddress: String
    
    /// 集群ID
    public let clusterId: UInt16
    
    /// 端点ID
    public let endpointId: UInt8
    
    /// 消息数据
    public let data: Data
    
    /// 消息类型
    public let messageType: ZigbeeMessageType
    
    /// 序列号
    public let sequenceNumber: UInt8
    
    /// 时间戳
    public let timestamp: Date
    
    /// 链路质量指示器
    public let lqi: UInt8?
    
    /// 接收信号强度指示器
    public let rssi: Int8?
    
    public init(
        sourceAddress: String,
        destinationAddress: String,
        clusterId: UInt16,
        endpointId: UInt8,
        data: Data,
        messageType: ZigbeeMessageType,
        sequenceNumber: UInt8,
        timestamp: Date = Date(),
        lqi: UInt8? = nil,
        rssi: Int8? = nil
    ) {
        self.sourceAddress = sourceAddress
        self.destinationAddress = destinationAddress
        self.clusterId = clusterId
        self.endpointId = endpointId
        self.data = data
        self.messageType = messageType
        self.sequenceNumber = sequenceNumber
        self.timestamp = timestamp
        self.lqi = lqi
        self.rssi = rssi
    }
    
    /// 从字符串创建消息
    public init(
        sourceAddress: String,
        destinationAddress: String,
        clusterId: UInt16,
        endpointId: UInt8,
        message: String,
        messageType: ZigbeeMessageType,
        sequenceNumber: UInt8
    ) {
        self.init(
            sourceAddress: sourceAddress,
            destinationAddress: destinationAddress,
            clusterId: clusterId,
            endpointId: endpointId,
            data: message.data(using: .utf8) ?? Data(),
            messageType: messageType,
            sequenceNumber: sequenceNumber
        )
    }
    
    /// 获取消息内容字符串
    public var messageString: String? {
        return String(data: data, encoding: .utf8)
    }
    
    /// 消息大小（字节）
    public var size: Int {
        return data.count
    }
    
    /// 是否为广播消息
    public var isBroadcast: Bool {
        return destinationAddress == "FFFF" || destinationAddress == "FFFC" || destinationAddress == "FFFD"
    }
}

/// Zigbee消息类型
public enum ZigbeeMessageType: String, CaseIterable, Codable {
    case command = "command"
    case response = "response"
    case report = "report"
    case notification = "notification"
    case broadcast = "broadcast"
    
    public var displayName: String {
        switch self {
        case .command:
            return "命令"
        case .response:
            return "响应"
        case .report:
            return "报告"
        case .notification:
            return "通知"
        case .broadcast:
            return "广播"
        }
    }
}

/// Zigbee连接配置
public struct ZigbeeConfiguration {
    /// 网络PAN ID
    public let panId: UInt16
    
    /// 网络扩展PAN ID
    public let extendedPanId: UInt64
    
    /// 网络密钥
    public let networkKey: Data?
    
    /// 信道
    public let channel: UInt8
    
    /// 网络地址
    public let networkAddress: UInt16
    
    /// IEEE地址
    public let ieeeAddress: UInt64
    
    /// 设备类型
    public let deviceType: ZigbeeDeviceType
    
    /// 电源类型
    public let powerSource: ZigbeePowerSource
    
    /// 安全级别
    public let securityLevel: ZigbeeSecurityLevel
    
    /// 连接超时时间（秒）
    public let connectionTimeout: TimeInterval
    
    /// 重传次数
    public let retryCount: Int
    
    /// 重传间隔（毫秒）
    public let retryInterval: TimeInterval
    
    /// 心跳间隔（秒）
    public let heartbeatInterval: TimeInterval
    
    /// 支持的集群列表
    public let supportedClusters: [UInt16]
    
    public init(
        panId: UInt16,
        extendedPanId: UInt64,
        networkKey: Data? = nil,
        channel: UInt8 = 11,
        networkAddress: UInt16 = 0x0000,
        ieeeAddress: UInt64,
        deviceType: ZigbeeDeviceType = .endDevice,
        powerSource: ZigbeePowerSource = .battery,
        securityLevel: ZigbeeSecurityLevel = .standard,
        connectionTimeout: TimeInterval = 30,
        retryCount: Int = 3,
        retryInterval: TimeInterval = 1.0,
        heartbeatInterval: TimeInterval = 60,
        supportedClusters: [UInt16] = []
    ) {
        self.panId = panId
        self.extendedPanId = extendedPanId
        self.networkKey = networkKey
        self.channel = channel
        self.networkAddress = networkAddress
        self.ieeeAddress = ieeeAddress
        self.deviceType = deviceType
        self.powerSource = powerSource
        self.securityLevel = securityLevel
        self.connectionTimeout = connectionTimeout
        self.retryCount = retryCount
        self.retryInterval = retryInterval
        self.heartbeatInterval = heartbeatInterval
        self.supportedClusters = supportedClusters
    }
    
    /// 创建默认配置
    public static func `default`(ieeeAddress: UInt64) -> ZigbeeConfiguration {
        return ZigbeeConfiguration(
            panId: 0x1234,
            extendedPanId: 0x1234567890ABCDEF,
            ieeeAddress: ieeeAddress
        )
    }
}

/// Zigbee设备类型
public enum ZigbeeDeviceType: String, CaseIterable, Codable {
    case coordinator = "coordinator"
    case router = "router"
    case endDevice = "endDevice"
    
    public var displayName: String {
        switch self {
        case .coordinator:
            return "协调器"
        case .router:
            return "路由器"
        case .endDevice:
            return "终端设备"
        }
    }
}

/// Zigbee电源类型
public enum ZigbeePowerSource: String, CaseIterable, Codable {
    case mains = "mains"
    case battery = "battery"
    case unknown = "unknown"
    
    public var displayName: String {
        switch self {
        case .mains:
            return "市电"
        case .battery:
            return "电池"
        case .unknown:
            return "未知"
        }
    }
}

/// Zigbee安全级别
public enum ZigbeeSecurityLevel: String, CaseIterable, Codable {
    case none = "none"
    case standard = "standard"
    case high = "high"
    
    public var displayName: String {
        switch self {
        case .none:
            return "无安全"
        case .standard:
            return "标准安全"
        case .high:
            return "高级安全"
        }
    }
}

/// Zigbee发现的设备信息
public struct ZigbeeDiscoveredDevice {
    /// 网络地址
    public let networkAddress: UInt16
    
    /// IEEE地址
    public let ieeeAddress: UInt64
    
    /// 设备类型
    public let deviceType: ZigbeeDeviceType
    
    /// 电源类型
    public let powerSource: ZigbeePowerSource
    
    /// 制造商ID
    public let manufacturerId: UInt16?
    
    /// 产品ID
    public let productId: UInt16?
    
    /// 设备版本
    public let deviceVersion: UInt8?
    
    /// 支持的集群列表
    public let supportedClusters: [UInt16]
    
    /// 链路质量指示器
    public let lqi: UInt8?
    
    /// 接收信号强度指示器
    public let rssi: Int8?
    
    /// 发现时间
    public let discoveredAt: Date
    
    /// 最后活跃时间
    public let lastActiveAt: Date
    
    /// 设备标识符
    public var identifier: String {
        return String(format: "%04X", networkAddress)
    }
    
    /// IEEE地址字符串
    public var ieeeAddressString: String {
        return String(format: "%016llX", ieeeAddress)
    }
    
    /// 设备名称
    public var name: String {
        return "Zigbee设备 \(identifier)"
    }
    
    public init(
        networkAddress: UInt16,
        ieeeAddress: UInt64,
        deviceType: ZigbeeDeviceType,
        powerSource: ZigbeePowerSource,
        manufacturerId: UInt16? = nil,
        productId: UInt16? = nil,
        deviceVersion: UInt8? = nil,
        supportedClusters: [UInt16] = [],
        lqi: UInt8? = nil,
        rssi: Int8? = nil,
        discoveredAt: Date = Date(),
        lastActiveAt: Date = Date()
    ) {
        self.networkAddress = networkAddress
        self.ieeeAddress = ieeeAddress
        self.deviceType = deviceType
        self.powerSource = powerSource
        self.manufacturerId = manufacturerId
        self.productId = productId
        self.deviceVersion = deviceVersion
        self.supportedClusters = supportedClusters
        self.lqi = lqi
        self.rssi = rssi
        self.discoveredAt = discoveredAt
        self.lastActiveAt = lastActiveAt
    }
}

/// Zigbee扫描配置
public struct ZigbeeScanConfiguration {
    /// 扫描信道列表
    public let channels: [UInt8]
    
    /// 扫描持续时间（秒）
    public let duration: TimeInterval?
    
    /// 扫描类型
    public let scanType: ZigbeeScanType
    
    /// 信号强度阈值
    public let rssiThreshold: Int8?
    
    /// 链路质量阈值
    public let lqiThreshold: UInt8?
    
    /// 设备类型过滤
    public let deviceTypeFilter: [ZigbeeDeviceType]?
    
    public init(
        channels: [UInt8] = [11, 15, 20, 25],
        duration: TimeInterval? = nil,
        scanType: ZigbeeScanType = .active,
        rssiThreshold: Int8? = nil,
        lqiThreshold: UInt8? = nil,
        deviceTypeFilter: [ZigbeeDeviceType]? = nil
    ) {
        self.channels = channels
        self.duration = duration
        self.scanType = scanType
        self.rssiThreshold = rssiThreshold
        self.lqiThreshold = lqiThreshold
        self.deviceTypeFilter = deviceTypeFilter
    }
    
    /// 创建默认扫描配置
    public static var `default`: ZigbeeScanConfiguration {
        return ZigbeeScanConfiguration()
    }
}

/// Zigbee扫描类型
public enum ZigbeeScanType: String, CaseIterable, Codable {
    case active = "active"
    case passive = "passive"
    case orphan = "orphan"
    
    public var displayName: String {
        switch self {
        case .active:
            return "主动扫描"
        case .passive:
            return "被动扫描"
        case .orphan:
            return "孤儿扫描"
        }
    }
}

/// Zigbee适配器实现
public final class ZigbeeAdapter: CommunicationService, DeviceDiscovery {
    
    // MARK: - Type Aliases
    
    public typealias Configuration = ZigbeeConfiguration
    public typealias Message = ZigbeeMessage
    public typealias DiscoveredDevice = ZigbeeDiscoveredDevice
    public typealias ScanConfiguration = ZigbeeScanConfiguration
    
    // MARK: - CommunicationService Properties
    
    public let serviceId: String
    public let serviceName: String = "Zigbee服务"
    
    @Published private var _connectionState: ConnectionState = .disconnected
    public var connectionState: ConnectionState {
        return _connectionState
    }
    
    public var connectionStatePublisher: AnyPublisher<ConnectionState, Never> {
        return $_connectionState.eraseToAnyPublisher()
    }
    
    private let _messageSubject = PassthroughSubject<ZigbeeMessage, Never>()
    public var messagePublisher: AnyPublisher<ZigbeeMessage, Never> {
        return _messageSubject.eraseToAnyPublisher()
    }
    
    private let _errorSubject = PassthroughSubject<CommunicationError, Never>()
    public var errorPublisher: AnyPublisher<CommunicationError, Never> {
        return _errorSubject.eraseToAnyPublisher()
    }
    
    public let supportsAutoReconnect: Bool = true
    public var maxReconnectAttempts: Int = 5
    public var reconnectInterval: TimeInterval = 10.0
    
    // MARK: - DeviceDiscovery Properties
    
    public let discoveryId: String
    public let discoveryName: String = "Zigbee设备发现"
    
    @Published private var _scanState: ScanState = .idle
    public var scanState: ScanState {
        return _scanState
    }
    
    public var scanStatePublisher: AnyPublisher<ScanState, Never> {
        return $_scanState.eraseToAnyPublisher()
    }
    
    private let _discoveredDeviceSubject = PassthroughSubject<ZigbeeDiscoveredDevice, Never>()
    public var discoveredDevicePublisher: AnyPublisher<ZigbeeDiscoveredDevice, Never> {
        return _discoveredDeviceSubject.eraseToAnyPublisher()
    }
    
    private let _deviceLostSubject = PassthroughSubject<String, Never>()
    public var deviceLostPublisher: AnyPublisher<String, Never> {
        return _deviceLostSubject.eraseToAnyPublisher()
    }
    
    private let _scanErrorSubject = PassthroughSubject<DiscoveryError, Never>()
    public var scanErrorPublisher: AnyPublisher<DiscoveryError, Never> {
        return _scanErrorSubject.eraseToAnyPublisher()
    }
    
    public let supportedDeviceTypes: Set<String> = ["Zigbee", "ZigBee 3.0"]
    public let supportsBackgroundScanning: Bool = true
    public let scanRange: Double? = 100.0 // 约100米
    
    // MARK: - Private Properties
    
    private var currentConfiguration: ZigbeeConfiguration?
    private var currentScanConfiguration: ZigbeeScanConfiguration?
    private var discoveredDevices = [String: ZigbeeDiscoveredDevice]()
    private var deviceFilter: DeviceFilter?
    private var scanTimer: Timer?
    private var heartbeatTimer: Timer?
    private var reconnectAttempts = 0
    private var sequenceNumber: UInt8 = 0
    private var statistics = ServiceStatistics()
    private var scanStatistics = ScanStatistics()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(serviceId: String = "zigbee-adapter") {
        self.serviceId = serviceId
        self.discoveryId = serviceId
        
        setupStateMonitoring()
    }
    
    // MARK: - CommunicationService Implementation
    
    public func connect(with configuration: ZigbeeConfiguration) -> AnyPublisher<Void, CommunicationError> {
        return Future<Void, CommunicationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.connectionFailed("适配器已释放")))
                return
            }
            
            self.currentConfiguration = configuration
            self._connectionState = .connecting
            
            // 模拟Zigbee网络连接过程
            self.performZigbeeConnection(configuration: configuration, promise: promise)
        }
        .eraseToAnyPublisher()
    }
    
    public func disconnect() -> AnyPublisher<Void, CommunicationError> {
        return Future<Void, CommunicationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.connectionFailed("适配器已释放")))
                return
            }
            
            self.performZigbeeDisconnection(promise: promise)
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
    
    public func sendMessageWithResponse(_ message: ZigbeeMessage, timeout: TimeInterval) -> AnyPublisher<ZigbeeMessage, CommunicationError> {
        return Future<ZigbeeMessage, CommunicationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.messageSendFailed("适配器已释放")))
                return
            }
            
            guard self._connectionState == .connected else {
                promise(.failure(.messageSendFailed("设备未连接")))
                return
            }
            
            self.performSendMessage(message, promise: promise)
        }
        .timeout(.seconds(timeout), scheduler: DispatchQueue.main)
        .catch { error -> AnyPublisher<ZigbeeMessage, CommunicationError> in
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
        // Zigbee中的"订阅"通常指绑定到特定集群
        return Future<Void, CommunicationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.subscriptionFailed("适配器已释放")))
                return
            }
            
            // 解析topic为设备地址和集群ID
            let components = topic.components(separatedBy: "/")
            guard components.count >= 2,
                  let clusterId = UInt16(components[1], radix: 16) else {
                promise(.failure(.subscriptionFailed("无效的主题格式")))
                return
            }
            
            let deviceAddress = components[0]
            self.performSubscription(deviceAddress: deviceAddress, clusterId: clusterId, promise: promise)
        }
        .eraseToAnyPublisher()
    }
    
    public func unsubscribe(from topic: String) -> AnyPublisher<Void, CommunicationError> {
        return Future<Void, CommunicationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.subscriptionFailed("适配器已释放")))
                return
            }
            
            let components = topic.components(separatedBy: "/")
            guard components.count >= 2,
                  let clusterId = UInt16(components[1], radix: 16) else {
                promise(.failure(.subscriptionFailed("无效的主题格式")))
                return
            }
            
            let deviceAddress = components[0]
            self.performUnsubscription(deviceAddress: deviceAddress, clusterId: clusterId, promise: promise)
        }
        .eraseToAnyPublisher()
    }
    
    public func updateConfiguration(_ configuration: ZigbeeConfiguration) -> AnyPublisher<Void, CommunicationError> {
        currentConfiguration = configuration
        return Just(())
            .setFailureType(to: CommunicationError.self)
            .eraseToAnyPublisher()
    }
    
    public func getCurrentConfiguration() -> ZigbeeConfiguration? {
        return currentConfiguration
    }
    
    public func getDiagnostics() -> ConnectionDiagnostics {
        return ConnectionDiagnostics(
            connectionState: connectionState,
            connectionDuration: nil,
            lastConnectedAt: nil,
            lastDisconnectedAt: nil,
            reconnectCount: reconnectAttempts,
            lastError: nil,
            latency: nil,
            signalStrength: nil,
            additionalInfo: [
                "discoveredDevices": discoveredDevices.count,
                "panId": currentConfiguration?.panId ?? 0,
                "channel": currentConfiguration?.channel ?? 0,
                "deviceType": currentConfiguration?.deviceType.rawValue ?? "unknown"
            ]
        )
    }
    
    public func getStatistics() -> ServiceStatistics {
        return statistics
    }
    
    public func resetStatistics() {
        statistics = ServiceStatistics()
    }
    
    // MARK: - DeviceDiscovery Implementation
    
    public func startScanning(with configuration: ZigbeeScanConfiguration?) -> AnyPublisher<Void, DiscoveryError> {
        return Future<Void, DiscoveryError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.scanStartFailed("适配器已释放")))
                return
            }
            
            guard self._connectionState == .connected else {
                promise(.failure(.scanStartFailed("Zigbee网络未连接")))
                return
            }
            
            guard self._scanState.canStartScanning else {
                promise(.failure(.scanStartFailed("当前状态不允许开始扫描")))
                return
            }
            
            self.currentScanConfiguration = configuration ?? ZigbeeScanConfiguration.default
            self.performStartScanning(promise: promise)
        }
        .eraseToAnyPublisher()
    }
    
    public func stopScanning() -> AnyPublisher<Void, DiscoveryError> {
        return Future<Void, DiscoveryError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.scanStopFailed("适配器已释放")))
                return
            }
            
            self.performStopScanning(promise: promise)
        }
        .eraseToAnyPublisher()
    }
    
    public func getDiscoveredDevices() -> [ZigbeeDiscoveredDevice] {
        return Array(discoveredDevices.values)
    }
    
    public func getDevice(by deviceId: String) -> ZigbeeDiscoveredDevice? {
        return discoveredDevices[deviceId]
    }
    
    public func clearDiscoveredDevices() {
        discoveredDevices.removeAll()
    }
    
    public func removeDevice(deviceId: String) -> Bool {
        return discoveredDevices.removeValue(forKey: deviceId) != nil
    }
    
    public func setDeviceFilter(_ filter: DeviceFilter?) {
        deviceFilter = filter
    }
    
    public func getCurrentFilter() -> DeviceFilter? {
        return deviceFilter
    }
    
    public func updateScanConfiguration(_ configuration: ZigbeeScanConfiguration) -> AnyPublisher<Void, DiscoveryError> {
        currentScanConfiguration = configuration
        return Just(())
            .setFailureType(to: DiscoveryError.self)
            .eraseToAnyPublisher()
    }
    
    public func getCurrentScanConfiguration() -> ZigbeeScanConfiguration? {
        return currentScanConfiguration
    }
    
    public func getScanStatistics() -> ScanStatistics {
        return scanStatistics
    }
    
    public func resetScanStatistics() {
        scanStatistics = ScanStatistics()
    }
}

// MARK: - Private Implementation

private extension ZigbeeAdapter {
    
    func setupStateMonitoring() {
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
            startHeartbeat()
        case .disconnected, .failed:
            stopHeartbeat()
            if currentConfiguration != nil && reconnectAttempts < maxReconnectAttempts {
                scheduleReconnect()
            }
        default:
            break
        }
    }
    
    func scheduleReconnect() {
        reconnectAttempts += 1
        _connectionState = .reconnecting
        
        DispatchQueue.main.asyncAfter(deadline: .now() + reconnectInterval) { [weak self] in
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
    
    func startHeartbeat() {
        guard let interval = currentConfiguration?.heartbeatInterval else { return }
        
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }
    
    func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    func sendHeartbeat() {
        guard let config = currentConfiguration else { return }
        
        let heartbeatMessage = ZigbeeMessage(
            sourceAddress: String(format: "%04X", config.networkAddress),
            destinationAddress: "0000", // 协调器地址
            clusterId: 0x0000, // 基本集群
            endpointId: 0x01,
            data: Data([0x00]), // 心跳数据
            messageType: .command,
            sequenceNumber: getNextSequenceNumber()
        )
        
        performSendMessage(heartbeatMessage) { result in
            // 心跳结果处理
        }
    }
    
    func performZigbeeConnection(configuration: ZigbeeConfiguration, promise: @escaping (Result<Void, CommunicationError>) -> Void) {
        // 模拟Zigbee网络连接过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else {
                promise(.failure(.connectionFailed("适配器已释放")))
                return
            }
            
            // 模拟连接成功
            self._connectionState = .connected
            self.updateStatistics(successfulConnections: 1)
            promise(.success(()))
        }
    }
    
    func performZigbeeDisconnection(promise: @escaping (Result<Void, CommunicationError>) -> Void) {
        stopHeartbeat()
        _connectionState = .disconnected
        promise(.success(()))
    }
    
    func performSendMessage(_ message: ZigbeeMessage, promise: @escaping (Result<ZigbeeMessage, CommunicationError>) -> Void) {
        // 模拟消息发送
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else {
                promise(.failure(.messageSendFailed("适配器已释放")))
                return
            }
            
            // 模拟发送成功并返回响应
            let responseMessage = ZigbeeMessage(
                sourceAddress: message.destinationAddress,
                destinationAddress: message.sourceAddress,
                clusterId: message.clusterId,
                endpointId: message.endpointId,
                data: Data([0x00]), // 响应数据
                messageType: .response,
                sequenceNumber: message.sequenceNumber
            )
            
            self.updateStatistics(messagesSent: 1, bytesSent: Int64(message.data.count))
            promise(.success(responseMessage))
        }
    }
    
    func performSubscription(deviceAddress: String, clusterId: UInt16, promise: @escaping (Result<Void, CommunicationError>) -> Void) {
        // 模拟绑定操作
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            promise(.success(()))
        }
    }
    
    func performUnsubscription(deviceAddress: String, clusterId: UInt16, promise: @escaping (Result<Void, CommunicationError>) -> Void) {
        // 模拟解绑操作
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            promise(.success(()))
        }
    }
    
    func performStartScanning(promise: @escaping (Result<Void, DiscoveryError>) -> Void) {
        _scanState = .starting
        
        // 模拟扫描开始
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else {
                promise(.failure(.scanStartFailed("适配器已释放")))
                return
            }
            
            self._scanState = .scanning
            self.startMockDeviceDiscovery()
            
            // 设置扫描超时
            if let duration = self.currentScanConfiguration?.duration {
                self.scanTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                    self?.stopScanning()
                        .sink(
                            receiveCompletion: { _ in },
                            receiveValue: { _ in }
                        )
                        .store(in: &self?.cancellables ?? Set<AnyCancellable>())
                }
            }
            
            self.updateScanStatistics(scanCount: 1)
            promise(.success(()))
        }
    }
    
    func performStopScanning(promise: @escaping (Result<Void, DiscoveryError>) -> Void) {
        _scanState = .stopping
        
        scanTimer?.invalidate()
        scanTimer = nil
        
        _scanState = .idle
        promise(.success(()))
    }
    
    func startMockDeviceDiscovery() {
        // 模拟发现设备
        let mockDevices = [
            ZigbeeDiscoveredDevice(
                networkAddress: 0x1234,
                ieeeAddress: 0x123456789ABCDEF0,
                deviceType: .endDevice,
                powerSource: .battery,
                manufacturerId: 0x1234,
                supportedClusters: [0x0006, 0x0008],
                lqi: 200,
                rssi: -45
            ),
            ZigbeeDiscoveredDevice(
                networkAddress: 0x5678,
                ieeeAddress: 0x56789ABCDEF01234,
                deviceType: .router,
                powerSource: .mains,
                manufacturerId: 0x5678,
                supportedClusters: [0x0006, 0x0300],
                lqi: 180,
                rssi: -50
            )
        ]
        
        for (index, device) in mockDevices.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index + 1) * 2.0) { [weak self] in
                guard let self = self, self._scanState == .scanning else { return }
                
                if self.shouldIncludeDevice(device) {
                    self.discoveredDevices[device.identifier] = device
                    self._discoveredDeviceSubject.send(device)
                    self.updateScanStatistics(devicesDiscovered: 1)
                }
            }
        }
    }
    
    func shouldIncludeDevice(_ device: ZigbeeDiscoveredDevice) -> Bool {
        guard let filter = deviceFilter else { return true }
        
        // 信号强度过滤
        if let minRSSI = filter.minRSSI, let deviceRSSI = device.rssi {
            if Int(deviceRSSI) < minRSSI {
                return false
            }
        }
        
        // 设备类型过滤
        if let deviceTypes = filter.deviceTypes {
            if !deviceTypes.contains("Zigbee") && !deviceTypes.contains("ZigBee 3.0") {
                return false
            }
        }
        
        // 名称模式过滤
        if let namePattern = filter.namePattern {
            if !device.name.localizedCaseInsensitiveContains(namePattern) {
                return false
            }
        }
        
        return true
    }
    
    func getNextSequenceNumber() -> UInt8 {
        sequenceNumber = (sequenceNumber + 1) % 256
        return sequenceNumber
    }
    
    func updateStatistics(messagesSent: Int = 0, messagesReceived: Int = 0, bytesSent: Int64 = 0, bytesReceived: Int64 = 0, successfulConnections: Int = 0, failedConnections: Int = 0) {
        statistics = ServiceStatistics(
            messagesSent: statistics.messagesSent + messagesSent,
            messagesReceived: statistics.messagesReceived + messagesReceived,
            bytesSent: statistics.bytesSent + bytesSent,
            bytesReceived: statistics.bytesReceived + bytesReceived,
            connectionAttempts: statistics.connectionAttempts + successfulConnections + failedConnections,
            successfulConnections: statistics.successfulConnections + successfulConnections,
            failedConnections: statistics.failedConnections + failedConnections,
            averageLatency: statistics.averageLatency,
            statisticsStartTime: statistics.statisticsStartTime,
            lastUpdated: Date()
        )
    }
    
    func updateScanStatistics(scanCount: Int = 0, devicesDiscovered: Int = 0) {
        scanStatistics = ScanStatistics(
            scanStartTime: scanStatistics.scanStartTime,
            totalScanDuration: scanStatistics.totalScanDuration,
            scanCount: scanStatistics.scanCount + scanCount,
            devicesDiscovered: scanStatistics.devicesDiscovered + devicesDiscovered,
            activeDevices: discoveredDevices.count,
            devicesLost: scanStatistics.devicesLost,
            averageDiscoveryTime: scanStatistics.averageDiscoveryTime,
            strongestRSSI: scanStatistics.strongestRSSI,
            weakestRSSI: scanStatistics.weakestRSSI,
            averageRSSI: scanStatistics.averageRSSI,
            deviceTypeStats: scanStatistics.deviceTypeStats,
            errorCount: scanStatistics.errorCount,
            lastUpdated: Date()
        )
    }
}

private struct TimeoutError: Error {}