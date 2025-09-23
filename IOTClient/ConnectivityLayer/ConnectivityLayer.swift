//
//  ConnectivityLayer.swift
//  ConnectivityLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

// MARK: - Public Exports

// Protocols
public typealias CommunicationService = ConnectivityLayer.CommunicationService
public typealias DeviceDiscovery = ConnectivityLayer.DeviceDiscovery
public typealias ConnectionStrategy = ConnectivityLayer.ConnectionStrategy

// Adapters
public typealias MQTTAdapter = ConnectivityLayer.MQTTAdapter
public typealias BLEAdapter = ConnectivityLayer.BLEAdapter
public typealias ZigbeeAdapter = ConnectivityLayer.ZigbeeAdapter
public typealias MatterAdapter = ConnectivityLayer.MatterAdapter

// Strategies
public typealias ReconnectionStrategy = ConnectivityLayer.ReconnectionStrategy

// Factories
public typealias ConnectionFactory = ConnectivityLayer.ConnectionFactory
public typealias ConnectionFactoryProtocol = ConnectivityLayer.ConnectionFactoryProtocol

// Models
public typealias ConnectionInfo = ConnectivityLayer.ConnectionInfo
public typealias ConnectionParameters = ConnectivityLayer.ConnectionParameters
public typealias ConnectionQuality = ConnectivityLayer.ConnectionQuality
public typealias ConnectionStatistics = ConnectivityLayer.ConnectionStatistics
public typealias ConnectionEvent = ConnectivityLayer.ConnectionEvent
public typealias ConnectionError = ConnectivityLayer.ConnectionError
public typealias DisconnectionReason = ConnectivityLayer.DisconnectionReason

// Enums
public typealias ConnectionState = ConnectivityLayer.ConnectionState
public typealias ConnectionPriority = ConnectivityLayer.ConnectionPriority
public typealias QualityOfService = ConnectivityLayer.QualityOfService
public typealias QualityLevel = ConnectivityLayer.QualityLevel

// MARK: - ConnectivityLayer Module

/// ConnectivityLayer 模块信息
public struct ConnectivityLayerInfo {
    /// 模块名称
    public static let name = "ConnectivityLayer"
    
    /// 模块版本
    public static let version = "1.0.0"
    
    /// 模块描述
    public static let description = "IOT设备连接层 - 提供统一的设备通信和发现接口"
    
    /// 支持的协议
    public static let supportedProtocols = ["MQTT", "BLE", "Zigbee", "Matter", "HTTP", "WebSocket", "CoAP"]
    
    /// 模块特性
    public static let features = [
        "统一通信接口",
        "多协议支持",
        "设备自动发现",
        "连接策略管理",
        "连接质量监控",
        "自动重连机制",
        "连接池管理",
        "性能统计分析"
    ]
    
    /// 依赖模块
    public static let dependencies = ["Foundation", "Combine"]
}

/// ConnectivityLayer 管理器
public final class ConnectivityLayerManager: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = ConnectivityLayerManager()
    
    // MARK: - Properties
    
    /// 连接工厂
    public let connectionFactory: ConnectionFactory
    
    /// 活跃连接
    @Published public private(set) var activeConnections: [String: ConnectionInfo] = [:]
    
    /// 连接事件发布者
    public let connectionEventPublisher = PassthroughSubject<ConnectionEvent, Never>()
    
    /// 配置
    @Published public var configuration: ConnectivityLayerConfiguration
    
    /// 状态
    @Published public private(set) var status: ConnectivityLayerStatus
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let connectionQueue = DispatchQueue(label: "connectivity-layer", qos: .userInitiated)
    private var connectionServices: [String: any CommunicationService] = [:]
    private var discoveryServices: [String: any DeviceDiscovery] = [:]
    private var connectionStrategies: [String: any ConnectionStrategy] = [:]
    
    // MARK: - Initialization
    
    private init() {
        self.connectionFactory = ConnectionFactory()
        self.configuration = ConnectivityLayerConfiguration()
        self.status = ConnectivityLayerStatus()
        
        setupEventHandling()
    }
    
    // MARK: - Public Methods
    
    /// 初始化连接层
    public func initialize(with config: ConnectivityLayerConfiguration? = nil) {
        print("[ConnectivityLayerManager] 初始化连接层管理器")
        if let config = config {
            self.configuration = config
        }
        
        status.isInitialized = true
        status.lastUpdated = Date()
        
        // 预创建常用服务
        if configuration.preloadServices {
            preloadServices()
        }
    }
    
    /// 关闭连接层
    public func shutdown() {
        print("[ConnectivityLayerManager] 关闭连接层管理器")
        
        // 清理所有活动连接
        for (_, connectionInfo) in activeConnections {
            // 这里可以添加具体的连接关闭逻辑
        }
        activeConnections.removeAll()
        
        // 清理服务
        connectionServices.removeAll()
        discoveryServices.removeAll()
        connectionStrategies.removeAll()
        
        // 取消所有订阅
        cancellables.removeAll()
        
        // 更新状态
        status = ConnectivityLayerStatus(isInitialized: false, activeConnectionCount: 0)
    }
    
    /// 获取连接层状态
    public func getStatus() -> ConnectivityLayerStatus {
        return status
    }
    
    /// 创建通信服务
    public func createCommunicationService(
        type: String,
        deviceId: String,
        configuration: Any? = nil
    ) throws -> any CommunicationService {
        
        let service = try connectionFactory.createCommunicationService(
            type: type,
            configuration: configuration
        )
        
        let serviceKey = "\(type)-\(deviceId)"
        connectionServices[serviceKey] = service
        
        // 监听服务事件
        setupServiceEventHandling(service: service, deviceId: deviceId)
        
        return service
    }
    
    /// 创建设备发现服务
    public func createDeviceDiscoveryService(
        type: String,
        configuration: Any? = nil
    ) throws -> any DeviceDiscovery {
        
        let service = try connectionFactory.createDeviceDiscoveryService(
            type: type,
            configuration: configuration
        )
        
        discoveryServices[type] = service
        
        return service
    }
    
    /// 创建连接策略
    public func createConnectionStrategy(
        type: String,
        configuration: ConnectionStrategyConfiguration? = nil
    ) throws -> any ConnectionStrategy {
        
        let strategy = try connectionFactory.createConnectionStrategy(
            type: type,
            configuration: configuration
        )
        
        connectionStrategies[type] = strategy
        
        return strategy
    }
    
    /// 获取连接信息
    public func getConnectionInfo(for connectionId: String) -> ConnectionInfo? {
        return activeConnections[connectionId]
    }
    
    /// 获取所有连接信息
    public func getAllConnections() -> [ConnectionInfo] {
        return Array(activeConnections.values)
    }
    
    /// 获取按类型分组的连接
    public func getConnectionsByType() -> [String: [ConnectionInfo]] {
        return Dictionary(grouping: activeConnections.values) { $0.connectionType }
    }
    
    /// 获取连接统计信息
    public func getConnectionStatistics() -> ConnectivityLayerStatistics {
        let connections = Array(activeConnections.values)
        
        return ConnectivityLayerStatistics(
            totalConnections: connections.count,
            activeConnections: connections.filter { $0.isConnected }.count,
            connectionsByType: Dictionary(grouping: connections) { $0.connectionType }
                .mapValues { $0.count },
            averageQualityScore: connections.isEmpty ? 0 : 
                connections.map { $0.quality.qualityScore }.reduce(0, +) / connections.count,
            totalDataTransferred: connections.map { $0.statistics.bytesSent + $0.statistics.bytesReceived }.reduce(0, +),
            factoryStatistics: connectionFactory.getFactoryStatistics(),
            lastUpdated: Date()
        )
    }
    
    /// 清理非活跃连接
    public func cleanupInactiveConnections() {
        let now = Date()
        let inactiveThreshold = configuration.inactiveConnectionTimeout
        
        activeConnections = activeConnections.filter { _, connection in
            guard let lastActive = connection.lastActiveAt else {
                return now.timeIntervalSince(connection.createdAt) < inactiveThreshold
            }
            return now.timeIntervalSince(lastActive) < inactiveThreshold
        }
        
        connectionFactory.cleanupDeadReferences()
    }
    
    /// 重置统计信息
    public func resetStatistics() {
        connectionFactory.resetFactoryStatistics()
        
        for connection in activeConnections.values {
            var mutableConnection = connection
            mutableConnection.statistics.reset()
            activeConnections[connection.connectionId] = mutableConnection
        }
    }
    
    /// 获取健康状态
    public func getHealthStatus() -> ConnectivityLayerHealth {
        let connections = Array(activeConnections.values)
        let totalConnections = connections.count
        
        guard totalConnections > 0 else {
            return ConnectivityLayerHealth(
                overallStatus: .healthy,
                connectionHealth: [:],
                issues: [],
                recommendations: [],
                lastChecked: Date()
            )
        }
        
        let healthyConnections = connections.filter { $0.statistics.healthStatus == .healthy }.count
        let warningConnections = connections.filter { $0.statistics.healthStatus == .warning }.count
        let criticalConnections = connections.filter { $0.statistics.healthStatus == .critical }.count
        
        let overallStatus: HealthStatus
        if criticalConnections > totalConnections / 4 {
            overallStatus = .critical
        } else if warningConnections > totalConnections / 2 {
            overallStatus = .warning
        } else {
            overallStatus = .healthy
        }
        
        let connectionHealth = Dictionary(uniqueKeysWithValues: 
            connections.map { ($0.connectionId, $0.statistics.healthStatus) }
        )
        
        var issues: [String] = []
        var recommendations: [String] = []
        
        if criticalConnections > 0 {
            issues.append("\(criticalConnections)个连接处于严重状态")
            recommendations.append("检查严重状态的连接并进行修复")
        }
        
        if warningConnections > 0 {
            issues.append("\(warningConnections)个连接处于警告状态")
            recommendations.append("监控警告状态的连接")
        }
        
        return ConnectivityLayerHealth(
            overallStatus: overallStatus,
            connectionHealth: connectionHealth,
            issues: issues,
            recommendations: recommendations,
            lastChecked: Date()
        )
    }
}

// MARK: - Private Implementation

private extension ConnectivityLayerManager {
    
    func setupEventHandling() {
        // 监听连接事件
        connectionEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleConnectionEvent(event)
            }
            .store(in: &cancellables)
        
        // 定期清理非活跃连接
        Timer.publish(every: configuration.cleanupInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.cleanupInactiveConnections()
            }
            .store(in: &cancellables)
    }
    
    func setupServiceEventHandling(service: any CommunicationService, deviceId: String) {
        // 监听连接状态变化
        service.connectionStatePublisher
            .sink { [weak self] state in
                self?.handleConnectionStateChange(deviceId: deviceId, state: state)
            }
            .store(in: &cancellables)
        
        // 监听诊断信息
        service.diagnosticsPublisher
            .sink { [weak self] diagnostics in
                self?.handleDiagnosticsUpdate(deviceId: deviceId, diagnostics: diagnostics)
            }
            .store(in: &cancellables)
    }
    
    func handleConnectionEvent(_ event: ConnectionEvent) {
        switch event {
        case .connected(let connectionInfo):
            activeConnections[connectionInfo.connectionId] = connectionInfo
            status.activeConnectionCount = activeConnections.count
            
        case .disconnected(let connectionId, _):
            activeConnections.removeValue(forKey: connectionId)
            status.activeConnectionCount = activeConnections.count
            
        case .qualityChanged(let connectionId, let quality):
            if var connection = activeConnections[connectionId] {
                connection.updateQuality(quality)
                activeConnections[connectionId] = connection
            }
            
        case .statisticsUpdated(let connectionId, let statistics):
            if var connection = activeConnections[connectionId] {
                connection.statistics = statistics
                connection.lastUpdated = Date()
                activeConnections[connectionId] = connection
            }
            
        default:
            break
        }
        
        status.lastUpdated = Date()
    }
    
    func handleConnectionStateChange(deviceId: String, state: ConnectionState) {
        // 查找对应的连接信息并更新状态
        for (connectionId, var connection) in activeConnections {
            if connection.deviceId == deviceId {
                connection.updateState(state)
                activeConnections[connectionId] = connection
                
                let event: ConnectionEvent
                switch state {
                case .connected:
                    event = .connected(connectionInfo: connection)
                case .disconnected:
                    event = .disconnected(connectionId: connectionId, reason: .unknown)
                case .connecting:
                    event = .connecting(deviceId: deviceId, connectionType: connection.connectionType)
                default:
                    return
                }
                
                connectionEventPublisher.send(event)
                break
            }
        }
    }
    
    func handleDiagnosticsUpdate(deviceId: String, diagnostics: ConnectionDiagnostics) {
        // 根据诊断信息更新连接质量
        for (connectionId, var connection) in activeConnections {
            if connection.deviceId == deviceId {
                var quality = connection.quality
                quality.updateMetrics(
                    signalStrength: diagnostics.signalStrength,
                    latency: diagnostics.latency,
                    throughput: diagnostics.throughput
                )
                connection.updateQuality(quality)
                activeConnections[connectionId] = connection
                
                connectionEventPublisher.send(.qualityChanged(connectionId: connectionId, quality: quality))
                break
            }
        }
    }
    
    func preloadServices() {
        let commonTypes = ["MQTT", "BLE", "Zigbee", "Matter"]
        
        for type in commonTypes {
            do {
                _ = try connectionFactory.createCommunicationService(type: type, configuration: nil)
            } catch {
                print("预加载\(type)服务失败: \(error)")
            }
        }
    }
}

// MARK: - Configuration

/// ConnectivityLayer 配置
public struct ConnectivityLayerConfiguration {
    /// 是否预加载服务
    public var preloadServices: Bool
    
    /// 非活跃连接超时时间（秒）
    public var inactiveConnectionTimeout: TimeInterval
    
    /// 清理间隔（秒）
    public var cleanupInterval: TimeInterval
    
    /// 最大连接数
    public var maxConnections: Int
    
    /// 是否启用统计信息
    public var enableStatistics: Bool
    
    /// 是否启用健康检查
    public var enableHealthCheck: Bool
    
    /// 日志级别
    public var logLevel: LogLevel
    
    public init(
        preloadServices: Bool = true,
        inactiveConnectionTimeout: TimeInterval = 300,
        cleanupInterval: TimeInterval = 60,
        maxConnections: Int = 100,
        enableStatistics: Bool = true,
        enableHealthCheck: Bool = true,
        logLevel: LogLevel = .info
    ) {
        self.preloadServices = preloadServices
        self.inactiveConnectionTimeout = inactiveConnectionTimeout
        self.cleanupInterval = cleanupInterval
        self.maxConnections = maxConnections
        self.enableStatistics = enableStatistics
        self.enableHealthCheck = enableHealthCheck
        self.logLevel = logLevel
    }
}

/// 日志级别
public enum LogLevel: String, CaseIterable {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    case none = "none"
}

// MARK: - Status

/// ConnectivityLayer 状态
public struct ConnectivityLayerStatus {
    /// 是否已初始化
    public var isInitialized: Bool
    
    /// 活跃连接数
    public var activeConnectionCount: Int
    
    /// 最后更新时间
    public var lastUpdated: Date
    
    public init(
        isInitialized: Bool = false,
        activeConnectionCount: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.isInitialized = isInitialized
        self.activeConnectionCount = activeConnectionCount
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Statistics

/// ConnectivityLayer 统计信息
public struct ConnectivityLayerStatistics {
    /// 总连接数
    public let totalConnections: Int
    
    /// 活跃连接数
    public let activeConnections: Int
    
    /// 按类型分组的连接数
    public let connectionsByType: [String: Int]
    
    /// 平均质量评分
    public let averageQualityScore: Int
    
    /// 总数据传输量
    public let totalDataTransferred: Int64
    
    /// 工厂统计信息
    public let factoryStatistics: ConnectionFactoryStatistics
    
    /// 最后更新时间
    public let lastUpdated: Date
}

// MARK: - Health

/// ConnectivityLayer 健康状态
public struct ConnectivityLayerHealth {
    /// 整体状态
    public let overallStatus: HealthStatus
    
    /// 各连接健康状态
    public let connectionHealth: [String: HealthStatus]
    
    /// 问题列表
    public let issues: [String]
    
    /// 建议列表
    public let recommendations: [String]
    
    /// 最后检查时间
    public let lastChecked: Date
}

// MARK: - Utilities

/// ConnectivityLayer 工具类
public struct ConnectivityLayerUtils {
    
    /// 创建默认MQTT配置
    public static func createDefaultMQTTConfiguration(
        brokerHost: String,
        brokerPort: Int = 1883,
        clientId: String? = nil
    ) -> MQTTConfiguration {
        return MQTTConfiguration(
            brokerHost: brokerHost,
            brokerPort: brokerPort,
            clientId: clientId ?? "iot-client-\(UUID().uuidString.prefix(8))",
            username: nil,
            password: nil,
            cleanSession: true,
            keepAlive: 60,
            qos: .atLeastOnce,
            willMessage: nil,
            sslConfiguration: nil
        )
    }
    
    /// 创建默认BLE配置
    public static func createDefaultBLEConfiguration(
        scanTimeout: TimeInterval = 30.0,
        serviceUUIDs: [String] = []
    ) -> BLEConfiguration {
        return BLEConfiguration(
            scanTimeout: scanTimeout,
            connectionTimeout: 10.0,
            serviceUUIDs: serviceUUIDs,
            allowDuplicates: false,
            scanMode: .balanced,
            characteristics: []
        )
    }
    
    /// 验证连接配置
    public static func validateConnectionConfiguration(
        type: String,
        configuration: Any?
    ) -> ValidationResult {
        // 实现配置验证逻辑
        return ValidationResult(isValid: true, issues: [])
    }
    
    /// 生成连接摘要
    public static func generateConnectionSummary(
        connections: [ConnectionInfo]
    ) -> String {
        let totalConnections = connections.count
        let connectedCount = connections.filter { $0.isConnected }.count
        let connectionTypes = Set(connections.map { $0.connectionType })
        
        return """
        连接摘要:
        - 总连接数: \(totalConnections)
        - 已连接数: \(connectedCount)
        - 连接类型: \(connectionTypes.joined(separator: ", "))
        - 生成时间: \(Date())
        """
    }
}

#if DEBUG
// MARK: - Debug Utilities

extension ConnectivityLayerManager {
    
    /// 创建测试连接
    public func createTestConnection(
        deviceId: String = "test-device",
        connectionType: String = "TEST"
    ) -> ConnectionInfo {
        let connection = ConnectionInfo(
            deviceId: deviceId,
            connectionType: connectionType,
            state: .connected,
            parameters: .reliable(),
            quality: .good()
        )
        
        activeConnections[connection.connectionId] = connection
        return connection
    }
    
    /// 模拟连接事件
    public func simulateConnectionEvent(_ event: ConnectionEvent) {
        connectionEventPublisher.send(event)
    }
    
    /// 获取调试信息
    public func getDebugInfo() -> [String: Any] {
        return [
            "activeConnections": activeConnections.count,
            "connectionServices": connectionServices.count,
            "discoveryServices": discoveryServices.count,
            "connectionStrategies": connectionStrategies.count,
            "configuration": configuration,
            "status": status
        ]
    }
}
#endif