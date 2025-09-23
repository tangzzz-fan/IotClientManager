//
//  MatterAdapter.swift
//  ConnectivityLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

/// Matter消息结构
public struct MatterMessage: Codable {
    /// 节点ID
    public let nodeId: UInt64
    
    /// 端点ID
    public let endpointId: UInt16
    
    /// 集群ID
    public let clusterId: UInt32
    
    /// 命令ID
    public let commandId: UInt32
    
    /// 消息数据
    public let data: Data
    
    /// 消息类型
    public let messageType: MatterMessageType
    
    /// 交互模型
    public let interactionModel: MatterInteractionModel
    
    /// 时间戳
    public let timestamp: Date
    
    /// 消息ID
    public let messageId: UInt32
    
    /// 交换ID
    public let exchangeId: UInt16
    
    public init(
        nodeId: UInt64,
        endpointId: UInt16,
        clusterId: UInt32,
        commandId: UInt32,
        data: Data,
        messageType: MatterMessageType,
        interactionModel: MatterInteractionModel,
        timestamp: Date = Date(),
        messageId: UInt32,
        exchangeId: UInt16
    ) {
        self.nodeId = nodeId
        self.endpointId = endpointId
        self.clusterId = clusterId
        self.commandId = commandId
        self.data = data
        self.messageType = messageType
        self.interactionModel = interactionModel
        self.timestamp = timestamp
        self.messageId = messageId
        self.exchangeId = exchangeId
    }
    
    /// 从字符串创建消息
    public init(
        nodeId: UInt64,
        endpointId: UInt16,
        clusterId: UInt32,
        commandId: UInt32,
        message: String,
        messageType: MatterMessageType,
        interactionModel: MatterInteractionModel,
        messageId: UInt32,
        exchangeId: UInt16
    ) {
        self.init(
            nodeId: nodeId,
            endpointId: endpointId,
            clusterId: clusterId,
            commandId: commandId,
            data: message.data(using: .utf8) ?? Data(),
            messageType: messageType,
            interactionModel: interactionModel,
            messageId: messageId,
            exchangeId: exchangeId
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
    
    /// 节点ID字符串
    public var nodeIdString: String {
        return String(format: "%016llX", nodeId)
    }
}

/// Matter消息类型
public enum MatterMessageType: String, CaseIterable, Codable {
    case invoke = "invoke"
    case read = "read"
    case write = "write"
    case subscribe = "subscribe"
    case report = "report"
    case response = "response"
    
    public var displayName: String {
        switch self {
        case .invoke:
            return "调用"
        case .read:
            return "读取"
        case .write:
            return "写入"
        case .subscribe:
            return "订阅"
        case .report:
            return "报告"
        case .response:
            return "响应"
        }
    }
}

/// Matter交互模型
public enum MatterInteractionModel: String, CaseIterable, Codable {
    case invoke = "invoke"
    case read = "read"
    case write = "write"
    case subscribe = "subscribe"
    case timedRequest = "timedRequest"
    
    public var displayName: String {
        switch self {
        case .invoke:
            return "调用命令"
        case .read:
            return "读取属性"
        case .write:
            return "写入属性"
        case .subscribe:
            return "订阅属性"
        case .timedRequest:
            return "定时请求"
        }
    }
}

/// Matter连接配置
public struct MatterConfiguration {
    /// 网络凭据
    public let networkCredentials: MatterNetworkCredentials
    
    /// 设备认证信息
    public let deviceAttestation: MatterDeviceAttestation?
    
    /// 操作凭据
    public let operationalCredentials: MatterOperationalCredentials?
    
    /// 连接超时时间（秒）
    public let connectionTimeout: TimeInterval
    
    /// 会话超时时间（秒）
    public let sessionTimeout: TimeInterval
    
    /// 重传配置
    public let retransmissionConfig: MatterRetransmissionConfig
    
    /// 安全配置
    public let securityConfig: MatterSecurityConfig
    
    /// 支持的设备类型
    public let supportedDeviceTypes: [UInt32]
    
    /// 供应商ID
    public let vendorId: UInt16
    
    /// 产品ID
    public let productId: UInt16
    
    public init(
        networkCredentials: MatterNetworkCredentials,
        deviceAttestation: MatterDeviceAttestation? = nil,
        operationalCredentials: MatterOperationalCredentials? = nil,
        connectionTimeout: TimeInterval = 30,
        sessionTimeout: TimeInterval = 3600,
        retransmissionConfig: MatterRetransmissionConfig = MatterRetransmissionConfig(),
        securityConfig: MatterSecurityConfig = MatterSecurityConfig(),
        supportedDeviceTypes: [UInt32] = [],
        vendorId: UInt16,
        productId: UInt16
    ) {
        self.networkCredentials = networkCredentials
        self.deviceAttestation = deviceAttestation
        self.operationalCredentials = operationalCredentials
        self.connectionTimeout = connectionTimeout
        self.sessionTimeout = sessionTimeout
        self.retransmissionConfig = retransmissionConfig
        self.securityConfig = securityConfig
        self.supportedDeviceTypes = supportedDeviceTypes
        self.vendorId = vendorId
        self.productId = productId
    }
    
    /// 创建默认配置
    public static func `default`(vendorId: UInt16, productId: UInt16) -> MatterConfiguration {
        return MatterConfiguration(
            networkCredentials: MatterNetworkCredentials.default,
            vendorId: vendorId,
            productId: productId
        )
    }
}

/// Matter网络凭据
public struct MatterNetworkCredentials {
    /// 网络类型
    public let networkType: MatterNetworkType
    
    /// WiFi凭据
    public let wifiCredentials: MatterWiFiCredentials?
    
    /// Thread凭据
    public let threadCredentials: MatterThreadCredentials?
    
    /// 以太网配置
    public let ethernetConfig: MatterEthernetConfig?
    
    public init(
        networkType: MatterNetworkType,
        wifiCredentials: MatterWiFiCredentials? = nil,
        threadCredentials: MatterThreadCredentials? = nil,
        ethernetConfig: MatterEthernetConfig? = nil
    ) {
        self.networkType = networkType
        self.wifiCredentials = wifiCredentials
        self.threadCredentials = threadCredentials
        self.ethernetConfig = ethernetConfig
    }
    
    public static var `default`: MatterNetworkCredentials {
        return MatterNetworkCredentials(networkType: .wifi)
    }
}

/// Matter网络类型
public enum MatterNetworkType: String, CaseIterable, Codable {
    case wifi = "wifi"
    case thread = "thread"
    case ethernet = "ethernet"
    
    public var displayName: String {
        switch self {
        case .wifi:
            return "WiFi"
        case .thread:
            return "Thread"
        case .ethernet:
            return "以太网"
        }
    }
}

/// Matter WiFi凭据
public struct MatterWiFiCredentials {
    public let ssid: String
    public let password: String
    public let securityType: MatterWiFiSecurityType
    
    public init(ssid: String, password: String, securityType: MatterWiFiSecurityType = .wpa2) {
        self.ssid = ssid
        self.password = password
        self.securityType = securityType
    }
}

/// Matter WiFi安全类型
public enum MatterWiFiSecurityType: String, CaseIterable, Codable {
    case none = "none"
    case wep = "wep"
    case wpa = "wpa"
    case wpa2 = "wpa2"
    case wpa3 = "wpa3"
}

/// Matter Thread凭据
public struct MatterThreadCredentials {
    public let operationalDataset: Data
    public let networkName: String
    public let extendedPanId: Data
    public let networkKey: Data
    
    public init(operationalDataset: Data, networkName: String, extendedPanId: Data, networkKey: Data) {
        self.operationalDataset = operationalDataset
        self.networkName = networkName
        self.extendedPanId = extendedPanId
        self.networkKey = networkKey
    }
}

/// Matter以太网配置
public struct MatterEthernetConfig {
    public let dhcpEnabled: Bool
    public let staticIpConfig: MatterStaticIPConfig?
    
    public init(dhcpEnabled: Bool = true, staticIpConfig: MatterStaticIPConfig? = nil) {
        self.dhcpEnabled = dhcpEnabled
        self.staticIpConfig = staticIpConfig
    }
}

/// Matter静态IP配置
public struct MatterStaticIPConfig {
    public let ipAddress: String
    public let subnetMask: String
    public let gateway: String
    public let dnsServers: [String]
    
    public init(ipAddress: String, subnetMask: String, gateway: String, dnsServers: [String] = []) {
        self.ipAddress = ipAddress
        self.subnetMask = subnetMask
        self.gateway = gateway
        self.dnsServers = dnsServers
    }
}

/// Matter设备认证
public struct MatterDeviceAttestation {
    public let certificateDeclaration: Data
    public let deviceAttestationCertificate: Data
    public let productAttestationIntermediateCertificate: Data
    
    public init(
        certificateDeclaration: Data,
        deviceAttestationCertificate: Data,
        productAttestationIntermediateCertificate: Data
    ) {
        self.certificateDeclaration = certificateDeclaration
        self.deviceAttestationCertificate = deviceAttestationCertificate
        self.productAttestationIntermediateCertificate = productAttestationIntermediateCertificate
    }
}

/// Matter操作凭据
public struct MatterOperationalCredentials {
    public let rootCertificate: Data
    public let intermediateCertificate: Data?
    public let operationalCertificate: Data
    public let privateKey: Data
    
    public init(
        rootCertificate: Data,
        intermediateCertificate: Data? = nil,
        operationalCertificate: Data,
        privateKey: Data
    ) {
        self.rootCertificate = rootCertificate
        self.intermediateCertificate = intermediateCertificate
        self.operationalCertificate = operationalCertificate
        self.privateKey = privateKey
    }
}

/// Matter重传配置
public struct MatterRetransmissionConfig {
    public let maxRetries: Int
    public let initialRetryInterval: TimeInterval
    public let maxRetryInterval: TimeInterval
    public let backoffMultiplier: Double
    
    public init(
        maxRetries: Int = 3,
        initialRetryInterval: TimeInterval = 1.0,
        maxRetryInterval: TimeInterval = 30.0,
        backoffMultiplier: Double = 2.0
    ) {
        self.maxRetries = maxRetries
        self.initialRetryInterval = initialRetryInterval
        self.maxRetryInterval = maxRetryInterval
        self.backoffMultiplier = backoffMultiplier
    }
}

/// Matter安全配置
public struct MatterSecurityConfig {
    public let enableCASE: Bool
    public let enablePASE: Bool
    public let sessionIdleTimeout: TimeInterval
    public let sessionActiveTimeout: TimeInterval
    
    public init(
        enableCASE: Bool = true,
        enablePASE: Bool = true,
        sessionIdleTimeout: TimeInterval = 300,
        sessionActiveTimeout: TimeInterval = 3600
    ) {
        self.enableCASE = enableCASE
        self.enablePASE = enablePASE
        self.sessionIdleTimeout = sessionIdleTimeout
        self.sessionActiveTimeout = sessionActiveTimeout
    }
}

/// Matter发现的设备信息
public struct MatterDiscoveredDevice {
    /// 节点ID
    public let nodeId: UInt64
    
    /// 设备名称
    public let deviceName: String?
    
    /// 设备类型
    public let deviceType: UInt32
    
    /// 供应商ID
    public let vendorId: UInt16
    
    /// 产品ID
    public let productId: UInt16
    
    /// 网络类型
    public let networkType: MatterNetworkType
    
    /// IP地址
    public let ipAddress: String?
    
    /// 端口
    public let port: UInt16?
    
    /// 支持的集群列表
    public let supportedClusters: [UInt32]
    
    /// 设备状态
    public let deviceState: MatterDeviceState
    
    /// 发现时间
    public let discoveredAt: Date
    
    /// 最后活跃时间
    public let lastActiveAt: Date
    
    /// 设备标识符
    public var identifier: String {
        return String(format: "%016llX", nodeId)
    }
    
    /// 显示名称
    public var displayName: String {
        return deviceName ?? "Matter设备 \(identifier)"
    }
    
    public init(
        nodeId: UInt64,
        deviceName: String? = nil,
        deviceType: UInt32,
        vendorId: UInt16,
        productId: UInt16,
        networkType: MatterNetworkType,
        ipAddress: String? = nil,
        port: UInt16? = nil,
        supportedClusters: [UInt32] = [],
        deviceState: MatterDeviceState = .unknown,
        discoveredAt: Date = Date(),
        lastActiveAt: Date = Date()
    ) {
        self.nodeId = nodeId
        self.deviceName = deviceName
        self.deviceType = deviceType
        self.vendorId = vendorId
        self.productId = productId
        self.networkType = networkType
        self.ipAddress = ipAddress
        self.port = port
        self.supportedClusters = supportedClusters
        self.deviceState = deviceState
        self.discoveredAt = discoveredAt
        self.lastActiveAt = lastActiveAt
    }
}

/// Matter设备状态
public enum MatterDeviceState: String, CaseIterable, Codable {
    case unknown = "unknown"
    case commissioned = "commissioned"
    case operational = "operational"
    case offline = "offline"
    case error = "error"
    
    public var displayName: String {
        switch self {
        case .unknown:
            return "未知"
        case .commissioned:
            return "已配网"
        case .operational:
            return "运行中"
        case .offline:
            return "离线"
        case .error:
            return "错误"
        }
    }
}

/// Matter扫描配置
public struct MatterScanConfiguration {
    /// 扫描类型
    public let scanType: MatterScanType
    
    /// 扫描持续时间（秒）
    public let duration: TimeInterval?
    
    /// 设备类型过滤
    public let deviceTypeFilter: [UInt32]?
    
    /// 供应商ID过滤
    public let vendorIdFilter: [UInt16]?
    
    /// 网络类型过滤
    public let networkTypeFilter: [MatterNetworkType]?
    
    public init(
        scanType: MatterScanType = .all,
        duration: TimeInterval? = nil,
        deviceTypeFilter: [UInt32]? = nil,
        vendorIdFilter: [UInt16]? = nil,
        networkTypeFilter: [MatterNetworkType]? = nil
    ) {
        self.scanType = scanType
        self.duration = duration
        self.deviceTypeFilter = deviceTypeFilter
        self.vendorIdFilter = vendorIdFilter
        self.networkTypeFilter = networkTypeFilter
    }
    
    /// 创建默认扫描配置
    public static var `default`: MatterScanConfiguration {
        return MatterScanConfiguration()
    }
}

/// Matter扫描类型
public enum MatterScanType: String, CaseIterable, Codable {
    case all = "all"
    case commissioned = "commissioned"
    case uncommissioned = "uncommissioned"
    
    public var displayName: String {
        switch self {
        case .all:
            return "全部设备"
        case .commissioned:
            return "已配网设备"
        case .uncommissioned:
            return "未配网设备"
        }
    }
}

/// Matter适配器实现
public final class MatterAdapter: CommunicationService, DeviceDiscovery {
    
    // MARK: - Type Aliases
    
    public typealias Configuration = MatterConfiguration
    public typealias Message = MatterMessage
    public typealias DiscoveredDevice = MatterDiscoveredDevice
    public typealias ScanConfiguration = MatterScanConfiguration
    
    // MARK: - CommunicationService Properties
    
    public let serviceId: String
    public let serviceName: String = "Matter服务"
    
    @Published private var _connectionState: ConnectionState = .disconnected
    public var connectionState: ConnectionState {
        return _connectionState
    }
    
    public var connectionStatePublisher: AnyPublisher<ConnectionState, Never> {
        return $_connectionState.eraseToAnyPublisher()
    }
    
    private let _messageSubject = PassthroughSubject<MatterMessage, Never>()
    public var messagePublisher: AnyPublisher<MatterMessage, Never> {
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
    public let discoveryName: String = "Matter设备发现"
    
    @Published private var _scanState: ScanState = .idle
    public var scanState: ScanState {
        return _scanState
    }
    
    public var scanStatePublisher: AnyPublisher<ScanState, Never> {
        return $_scanState.eraseToAnyPublisher()
    }
    
    private let _discoveredDeviceSubject = PassthroughSubject<MatterDiscoveredDevice, Never>()
    public var discoveredDevicePublisher: AnyPublisher<MatterDiscoveredDevice, Never> {
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
    
    public let supportedDeviceTypes: Set<String> = ["Matter", "Thread", "Matter over WiFi", "Matter over Thread"]
    public let supportsBackgroundScanning: Bool = true
    public let scanRange: Double? = nil // 无限制范围
    
    // MARK: - Private Properties
    
    private var currentConfiguration: MatterConfiguration?
    private var currentScanConfiguration: MatterScanConfiguration?
    private var discoveredDevices = [String: MatterDiscoveredDevice]()
    private var deviceFilter: DeviceFilter?
    private var scanTimer: Timer?
    private var sessionTimer: Timer?
    private var reconnectAttempts = 0
    private var messageIdCounter: UInt32 = 0
    private var exchangeIdCounter: UInt16 = 0
    private var statistics = ServiceStatistics()
    private var scanStatistics = ScanStatistics()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(serviceId: String = "matter-adapter") {
        self.serviceId = serviceId
        self.discoveryId = serviceId
        
        setupStateMonitoring()
    }
    
    // MARK: - CommunicationService Implementation
    
    public func connect(with configuration: MatterConfiguration) -> AnyPublisher<Void, CommunicationError> {
        return Future<Void, CommunicationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.connectionFailed("适配器已释放")))
                return
            }
            
            self.currentConfiguration = configuration
            self._connectionState = .connecting
            
            // 模拟Matter设备配网和连接过程
            self.performMatterConnection(configuration: configuration, promise: promise)
        }
        .eraseToAnyPublisher()
    }
    
    public func disconnect() -> AnyPublisher<Void, CommunicationError> {
        return Future<Void, CommunicationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.connectionFailed("适配器已释放")))
                return
            }
            
            self.performMatterDisconnection(promise: promise)
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
    
    public func sendMessageWithResponse(_ message: MatterMessage, timeout: TimeInterval) -> AnyPublisher<MatterMessage, CommunicationError> {
        return Future<MatterMessage, CommunicationError> { [weak self] promise in
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
        .catch { error -> AnyPublisher<MatterMessage, CommunicationError> in
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
        // Matter中的"订阅"指订阅属性变化
        return Future<Void, CommunicationError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.subscriptionFailed("适配器已释放")))
                return
            }
            
            // 解析topic为节点ID、端点ID和集群ID
            let components = topic.components(separatedBy: "/")
            guard components.count >= 3,
                  let nodeId = UInt64(components[0], radix: 16),
                  let endpointId = UInt16(components[1]),
                  let clusterId = UInt32(components[2], radix: 16) else {
                promise(.failure(.subscriptionFailed("无效的主题格式")))
                return
            }
            
            self.performSubscription(nodeId: nodeId, endpointId: endpointId, clusterId: clusterId, promise: promise)
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
            guard components.count >= 3,
                  let nodeId = UInt64(components[0], radix: 16),
                  let endpointId = UInt16(components[1]),
                  let clusterId = UInt32(components[2], radix: 16) else {
                promise(.failure(.subscriptionFailed("无效的主题格式")))
                return
            }
            
            self.performUnsubscription(nodeId: nodeId, endpointId: endpointId, clusterId: clusterId, promise: promise)
        }
        .eraseToAnyPublisher()
    }
    
    public func updateConfiguration(_ configuration: MatterConfiguration) -> AnyPublisher<Void, CommunicationError> {
        currentConfiguration = configuration
        return Just(())
            .setFailureType(to: CommunicationError.self)
            .eraseToAnyPublisher()
    }
    
    public func getCurrentConfiguration() -> MatterConfiguration? {
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
                "vendorId": currentConfiguration?.vendorId ?? 0,
                "productId": currentConfiguration?.productId ?? 0,
                "networkType": currentConfiguration?.networkCredentials.networkType.rawValue ?? "unknown"
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
    
    public func startScanning(with configuration: MatterScanConfiguration?) -> AnyPublisher<Void, DiscoveryError> {
        return Future<Void, DiscoveryError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.scanStartFailed("适配器已释放")))
                return
            }
            
            guard self._scanState.canStartScanning else {
                promise(.failure(.scanStartFailed("当前状态不允许开始扫描")))
                return
            }
            
            self.currentScanConfiguration = configuration ?? MatterScanConfiguration.default
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
    
    public func getDiscoveredDevices() -> [MatterDiscoveredDevice] {
        return Array(discoveredDevices.values)
    }
    
    public func getDevice(by deviceId: String) -> MatterDiscoveredDevice? {
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
    
    public func updateScanConfiguration(_ configuration: MatterScanConfiguration) -> AnyPublisher<Void, DiscoveryError> {
        currentScanConfiguration = configuration
        return Just(())
            .setFailureType(to: DiscoveryError.self)
            .eraseToAnyPublisher()
    }
    
    public func getCurrentScanConfiguration() -> MatterScanConfiguration? {
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

private extension MatterAdapter {
    
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
            startSessionTimer()
        case .disconnected, .failed:
            stopSessionTimer()
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
    
    func startSessionTimer() {
        guard let timeout = currentConfiguration?.sessionTimeout else { return }
        
        sessionTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            self?._connectionState = .disconnected
            self?._errorSubject.send(.sessionExpired)
        }
    }
    
    func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }
    
    func performMatterConnection(configuration: MatterConfiguration, promise: @escaping (Result<Void, CommunicationError>) -> Void) {
        // 模拟Matter设备配网过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
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
    
    func performMatterDisconnection(promise: @escaping (Result<Void, CommunicationError>) -> Void) {
        stopSessionTimer()
        _connectionState = .disconnected
        promise(.success(()))
    }
    
    func performSendMessage(_ message: MatterMessage, promise: @escaping (Result<MatterMessage, CommunicationError>) -> Void) {
        // 模拟Matter消息发送
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else {
                promise(.failure(.messageSendFailed("适配器已释放")))
                return
            }
            
            // 模拟发送成功并返回响应
            let responseMessage = MatterMessage(
                nodeId: message.nodeId,
                endpointId: message.endpointId,
                clusterId: message.clusterId,
                commandId: message.commandId,
                data: Data([0x00]), // 响应数据
                messageType: .response,
                interactionModel: message.interactionModel,
                messageId: self.getNextMessageId(),
                exchangeId: message.exchangeId
            )
            
            self.updateStatistics(messagesSent: 1, bytesSent: Int64(message.data.count))
            promise(.success(responseMessage))
        }
    }
    
    func performSubscription(nodeId: UInt64, endpointId: UInt16, clusterId: UInt32, promise: @escaping (Result<Void, CommunicationError>) -> Void) {
        // 模拟Matter属性订阅
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            promise(.success(()))
        }
    }
    
    func performUnsubscription(nodeId: UInt64, endpointId: UInt16, clusterId: UInt32, promise: @escaping (Result<Void, CommunicationError>) -> Void) {
        // 模拟Matter属性取消订阅
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            promise(.success(()))
        }
    }
    
    func performStartScanning(promise: @escaping (Result<Void, DiscoveryError>) -> Void) {
        _scanState = .starting
        
        // 模拟扫描开始
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
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
        // 模拟发现Matter设备
        let mockDevices = [
            MatterDiscoveredDevice(
                nodeId: 0x1234567890ABCDEF,
                deviceName: "智能灯泡",
                deviceType: 0x0100, // 灯泡设备类型
                vendorId: 0x1234,
                productId: 0x5678,
                networkType: .wifi,
                ipAddress: "192.168.1.100",
                port: 5540,
                supportedClusters: [0x0006, 0x0008, 0x0300],
                deviceState: .operational
            ),
            MatterDiscoveredDevice(
                nodeId: 0xFEDCBA0987654321,
                deviceName: "智能开关",
                deviceType: 0x0103, // 开关设备类型
                vendorId: 0x5678,
                productId: 0x1234,
                networkType: .thread,
                supportedClusters: [0x0006],
                deviceState: .operational
            )
        ]
        
        for (index, device) in mockDevices.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index + 1) * 3.0) { [weak self] in
                guard let self = self, self._scanState == .scanning else { return }
                
                if self.shouldIncludeDevice(device) {
                    self.discoveredDevices[device.identifier] = device
                    self._discoveredDeviceSubject.send(device)
                    self.updateScanStatistics(devicesDiscovered: 1)
                }
            }
        }
    }
    
    func shouldIncludeDevice(_ device: MatterDiscoveredDevice) -> Bool {
        guard let filter = deviceFilter else { return true }
        
        // 设备类型过滤
        if let deviceTypes = filter.deviceTypes {
            let supportedTypes = Set(["Matter", "Thread", "Matter over WiFi", "Matter over Thread"])
            if deviceTypes.isDisjoint(with: supportedTypes) {
                return false
            }
        }
        
        // 名称模式过滤
        if let namePattern = filter.namePattern {
            if !device.displayName.localizedCaseInsensitiveContains(namePattern) {
                return false
            }
        }
        
        // 扫描配置过滤
        if let scanConfig = currentScanConfiguration {
            // 设备类型过滤
            if let deviceTypeFilter = scanConfig.deviceTypeFilter {
                if !deviceTypeFilter.contains(device.deviceType) {
                    return false
                }
            }
            
            // 供应商ID过滤
            if let vendorIdFilter = scanConfig.vendorIdFilter {
                if !vendorIdFilter.contains(device.vendorId) {
                    return false
                }
            }
            
            // 网络类型过滤
            if let networkTypeFilter = scanConfig.networkTypeFilter {
                if !networkTypeFilter.contains(device.networkType) {
                    return false
                }
            }
        }
        
        return true
    }
    
    func getNextMessageId() -> UInt32 {
        messageIdCounter += 1
        return messageIdCounter
    }
    
    func getNextExchangeId() -> UInt16 {
        exchangeIdCounter += 1
        return exchangeIdCounter
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