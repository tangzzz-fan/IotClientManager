//
//  ConnectionFactory.swift
//  ConnectivityLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

/// 连接工厂协议
public protocol ConnectionFactoryProtocol {
    /// 工厂标识符
    var factoryId: String { get }
    
    /// 工厂名称
    var factoryName: String { get }
    
    /// 支持的连接类型
    var supportedConnectionTypes: Set<String> { get }
    
    /// 创建通信服务
    /// - Parameters:
    ///   - type: 连接类型
    ///   - configuration: 连接配置
    /// - Returns: 通信服务实例
    func createCommunicationService(
        type: String,
        configuration: Any?
    ) throws -> any CommunicationService
    
    /// 创建设备发现服务
    /// - Parameters:
    ///   - type: 发现类型
    ///   - configuration: 发现配置
    /// - Returns: 设备发现服务实例
    func createDeviceDiscoveryService(
        type: String,
        configuration: Any?
    ) throws -> any DeviceDiscovery
    
    /// 创建连接策略
    /// - Parameters:
    ///   - type: 策略类型
    ///   - configuration: 策略配置
    /// - Returns: 连接策略实例
    func createConnectionStrategy(
        type: String,
        configuration: ConnectionStrategyConfiguration?
    ) throws -> any ConnectionStrategy
    
    /// 验证连接类型是否支持
    /// - Parameter type: 连接类型
    /// - Returns: 是否支持
    func supportsConnectionType(_ type: String) -> Bool
    
    /// 获取连接类型的默认配置
    /// - Parameter type: 连接类型
    /// - Returns: 默认配置
    func getDefaultConfiguration(for type: String) -> Any?
    
    /// 获取工厂统计信息
    /// - Returns: 工厂统计信息
    func getFactoryStatistics() -> ConnectionFactoryStatistics
    
    /// 重置工厂统计信息
    func resetFactoryStatistics()
}

/// 连接工厂错误
public enum ConnectionFactoryError: Error, LocalizedError {
    case unsupportedConnectionType(String)
    case invalidConfiguration(String)
    case creationFailed(String)
    case factoryNotInitialized(String)
    case resourceUnavailable(String)
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedConnectionType(let type):
            return "不支持的连接类型: \(type)"
        case .invalidConfiguration(let message):
            return "无效配置: \(message)"
        case .creationFailed(let message):
            return "创建失败: \(message)"
        case .factoryNotInitialized(let message):
            return "工厂未初始化: \(message)"
        case .resourceUnavailable(let message):
            return "资源不可用: \(message)"
        case .unknown(let error):
            return "未知错误: \(error.localizedDescription)"
        }
    }
}

/// 连接工厂统计信息
public struct ConnectionFactoryStatistics {
    /// 创建的服务总数
    public let totalServicesCreated: Int
    
    /// 按类型分组的服务创建数量
    public let servicesByType: [String: Int]
    
    /// 创建失败次数
    public let creationFailures: Int
    
    /// 工厂启动时间
    public let factoryStartTime: Date
    
    /// 最后创建时间
    public let lastCreationTime: Date?
    
    /// 平均创建时间
    public let averageCreationTime: TimeInterval
    
    /// 活跃服务数量
    public let activeServices: Int
    
    /// 最后更新时间
    public let lastUpdated: Date
    
    public init(
        totalServicesCreated: Int = 0,
        servicesByType: [String: Int] = [:],
        creationFailures: Int = 0,
        factoryStartTime: Date = Date(),
        lastCreationTime: Date? = nil,
        averageCreationTime: TimeInterval = 0,
        activeServices: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.totalServicesCreated = totalServicesCreated
        self.servicesByType = servicesByType
        self.creationFailures = creationFailures
        self.factoryStartTime = factoryStartTime
        self.lastCreationTime = lastCreationTime
        self.averageCreationTime = averageCreationTime
        self.activeServices = activeServices
        self.lastUpdated = lastUpdated
    }
}

/// 连接工厂实现
public final class ConnectionFactory: ConnectionFactoryProtocol {
    
    // MARK: - Properties
    
    public let factoryId: String
    public let factoryName: String = "IOT连接工厂"
    
    public let supportedConnectionTypes: Set<String> = [
        "MQTT", "BLE", "Zigbee", "Matter", "HTTP", "WebSocket", "CoAP", "LoRaWAN"
    ]
    
    // MARK: - Private Properties
    
    private var statistics: ConnectionFactoryStatistics
    private var createdServices = [String: WeakServiceReference]()
    private var serviceCreators = [String: ServiceCreator]()
    private var discoveryCreators = [String: DiscoveryCreator]()
    private var strategyCreators = [String: StrategyCreator]()
    private let creationQueue = DispatchQueue(label: "connection-factory", qos: .userInitiated)
    private var creationTimes: [TimeInterval] = []
    private let maxCreationTimeHistory = 100
    
    // MARK: - Initialization
    
    public init(factoryId: String = "default-connection-factory") {
        self.factoryId = factoryId
        self.statistics = ConnectionFactoryStatistics()
        
        setupDefaultCreators()
    }
    
    // MARK: - ConnectionFactoryProtocol Implementation
    
    public func createCommunicationService(
        type: String,
        configuration: Any?
    ) throws -> any CommunicationService {
        
        let startTime = Date()
        
        guard supportsConnectionType(type) else {
            updateStatistics(creationFailure: true)
            throw ConnectionFactoryError.unsupportedConnectionType(type)
        }
        
        guard let creator = serviceCreators[type] else {
            updateStatistics(creationFailure: true)
            throw ConnectionFactoryError.creationFailed("未找到\(type)类型的服务创建器")
        }
        
        do {
            let service = try creator.create(configuration: configuration)
            let serviceId = UUID().uuidString
            
            // 存储弱引用
            createdServices[serviceId] = WeakServiceReference(service: service)
            
            // 更新统计信息
            let creationTime = Date().timeIntervalSince(startTime)
            updateStatistics(serviceType: type, creationTime: creationTime)
            
            return service
        } catch {
            updateStatistics(creationFailure: true)
            throw ConnectionFactoryError.creationFailed("创建\(type)服务失败: \(error.localizedDescription)")
        }
    }
    
    public func createDeviceDiscoveryService(
        type: String,
        configuration: Any?
    ) throws -> any DeviceDiscovery {
        
        let startTime = Date()
        
        guard supportsConnectionType(type) else {
            updateStatistics(creationFailure: true)
            throw ConnectionFactoryError.unsupportedConnectionType(type)
        }
        
        guard let creator = discoveryCreators[type] else {
            updateStatistics(creationFailure: true)
            throw ConnectionFactoryError.creationFailed("未找到\(type)类型的发现服务创建器")
        }
        
        do {
            let service = try creator.create(configuration: configuration)
            let serviceId = UUID().uuidString
            
            // 存储弱引用
            createdServices[serviceId] = WeakServiceReference(service: service)
            
            // 更新统计信息
            let creationTime = Date().timeIntervalSince(startTime)
            updateStatistics(serviceType: "\(type)Discovery", creationTime: creationTime)
            
            return service
        } catch {
            updateStatistics(creationFailure: true)
            throw ConnectionFactoryError.creationFailed("创建\(type)发现服务失败: \(error.localizedDescription)")
        }
    }
    
    public func createConnectionStrategy(
        type: String,
        configuration: ConnectionStrategyConfiguration?
    ) throws -> any ConnectionStrategy {
        
        let startTime = Date()
        
        guard let creator = strategyCreators[type] else {
            updateStatistics(creationFailure: true)
            throw ConnectionFactoryError.creationFailed("未找到\(type)类型的策略创建器")
        }
        
        do {
            let strategy = try creator.create(configuration: configuration)
            
            // 更新统计信息
            let creationTime = Date().timeIntervalSince(startTime)
            updateStatistics(serviceType: "\(type)Strategy", creationTime: creationTime)
            
            return strategy
        } catch {
            updateStatistics(creationFailure: true)
            throw ConnectionFactoryError.creationFailed("创建\(type)策略失败: \(error.localizedDescription)")
        }
    }
    
    public func supportsConnectionType(_ type: String) -> Bool {
        return supportedConnectionTypes.contains(type)
    }
    
    public func getDefaultConfiguration(for type: String) -> Any? {
        switch type.lowercased() {
        case "mqtt":
            return MQTTConfiguration(
                brokerHost: "localhost",
                brokerPort: 1883,
                clientId: "iot-client-\(UUID().uuidString.prefix(8))",
                username: nil,
                password: nil,
                cleanSession: true,
                keepAlive: 60,
                qos: .atLeastOnce,
                willMessage: nil,
                sslConfiguration: nil
            )
            
        case "ble":
            return BLEConfiguration(
                scanTimeout: 30.0,
                connectionTimeout: 10.0,
                serviceUUIDs: [],
                allowDuplicates: false,
                scanMode: .balanced,
                characteristics: []
            )
            
        case "zigbee":
            return ZigbeeConfiguration(
                networkId: 0x1234,
                channel: 11,
                panId: 0x5678,
                extendedPanId: Data(repeating: 0, count: 8),
                networkKey: Data(repeating: 0, count: 16),
                securityLevel: .high,
                coordinatorAddress: 0x0000,
                deviceType: .endDevice,
                powerSource: .battery
            )
            
        case "matter":
            return MatterConfiguration.default(vendorId: 0x1234, productId: 0x5678)
            
        default:
            return nil
        }
    }
    
    public func getFactoryStatistics() -> ConnectionFactoryStatistics {
        cleanupDeadReferences()
        return statistics
    }
    
    public func resetFactoryStatistics() {
        statistics = ConnectionFactoryStatistics(factoryStartTime: statistics.factoryStartTime)
        creationTimes.removeAll()
    }
    
    // MARK: - Public Methods
    
    /// 注册自定义服务创建器
    public func registerServiceCreator(_ creator: ServiceCreator, for type: String) {
        serviceCreators[type] = creator
    }
    
    /// 注册自定义发现服务创建器
    public func registerDiscoveryCreator(_ creator: DiscoveryCreator, for type: String) {
        discoveryCreators[type] = creator
    }
    
    /// 注册自定义策略创建器
    public func registerStrategyCreator(_ creator: StrategyCreator, for type: String) {
        strategyCreators[type] = creator
    }
    
    /// 获取活跃服务列表
    public func getActiveServices() -> [String: Any] {
        cleanupDeadReferences()
        return createdServices.compactMapValues { $0.service }
    }
    
    /// 清理已释放的服务引用
    public func cleanupDeadReferences() {
        createdServices = createdServices.filter { $0.value.service != nil }
        
        // 更新活跃服务数量
        let activeCount = createdServices.count
        statistics = ConnectionFactoryStatistics(
            totalServicesCreated: statistics.totalServicesCreated,
            servicesByType: statistics.servicesByType,
            creationFailures: statistics.creationFailures,
            factoryStartTime: statistics.factoryStartTime,
            lastCreationTime: statistics.lastCreationTime,
            averageCreationTime: statistics.averageCreationTime,
            activeServices: activeCount,
            lastUpdated: Date()
        )
    }
}

// MARK: - Private Implementation

private extension ConnectionFactory {
    
    func setupDefaultCreators() {
        // 设置通信服务创建器
        serviceCreators["MQTT"] = MQTTServiceCreator()
        serviceCreators["BLE"] = BLEServiceCreator()
        serviceCreators["Zigbee"] = ZigbeeServiceCreator()
        serviceCreators["Matter"] = MatterServiceCreator()
        
        // 设置发现服务创建器
        discoveryCreators["BLE"] = BLEDiscoveryCreator()
        discoveryCreators["Zigbee"] = ZigbeeDiscoveryCreator()
        discoveryCreators["Matter"] = MatterDiscoveryCreator()
        
        // 设置策略创建器
        strategyCreators["reconnection"] = ReconnectionStrategyCreator()
        strategyCreators["loadBalancing"] = LoadBalancingStrategyCreator()
        strategyCreators["failover"] = FailoverStrategyCreator()
    }
    
    func updateStatistics(
        serviceType: String? = nil,
        creationTime: TimeInterval? = nil,
        creationFailure: Bool = false
    ) {
        
        var newServicesByType = statistics.servicesByType
        var newTotalCreated = statistics.totalServicesCreated
        var newFailures = statistics.creationFailures
        var newLastCreationTime = statistics.lastCreationTime
        var newAverageCreationTime = statistics.averageCreationTime
        
        if let serviceType = serviceType {
            newServicesByType[serviceType] = (newServicesByType[serviceType] ?? 0) + 1
            newTotalCreated += 1
            newLastCreationTime = Date()
        }
        
        if creationFailure {
            newFailures += 1
        }
        
        if let creationTime = creationTime {
            creationTimes.append(creationTime)
            if creationTimes.count > maxCreationTimeHistory {
                creationTimes.removeFirst()
            }
            newAverageCreationTime = creationTimes.reduce(0, +) / Double(creationTimes.count)
        }
        
        statistics = ConnectionFactoryStatistics(
            totalServicesCreated: newTotalCreated,
            servicesByType: newServicesByType,
            creationFailures: newFailures,
            factoryStartTime: statistics.factoryStartTime,
            lastCreationTime: newLastCreationTime,
            averageCreationTime: newAverageCreationTime,
            activeServices: statistics.activeServices,
            lastUpdated: Date()
        )
    }
}

// MARK: - Service Creators

/// 服务创建器协议
public protocol ServiceCreator {
    func create(configuration: Any?) throws -> any CommunicationService
}

/// 发现服务创建器协议
public protocol DiscoveryCreator {
    func create(configuration: Any?) throws -> any DeviceDiscovery
}

/// 策略创建器协议
public protocol StrategyCreator {
    func create(configuration: ConnectionStrategyConfiguration?) throws -> any ConnectionStrategy
}

// MARK: - Concrete Creators

/// MQTT服务创建器
public struct MQTTServiceCreator: ServiceCreator {
    public func create(configuration: Any?) throws -> any CommunicationService {
        let config = configuration as? MQTTConfiguration ?? MQTTConfiguration(
            brokerHost: "localhost",
            brokerPort: 1883,
            clientId: "mqtt-client-\(UUID().uuidString.prefix(8))",
            username: nil,
            password: nil,
            cleanSession: true,
            keepAlive: 60,
            qos: .atLeastOnce,
            willMessage: nil,
            sslConfiguration: nil
        )
        return MQTTAdapter(serviceId: "mqtt-\(UUID().uuidString.prefix(8))")
    }
}

/// BLE服务创建器
public struct BLEServiceCreator: ServiceCreator {
    public func create(configuration: Any?) throws -> any CommunicationService {
        return BLEAdapter(serviceId: "ble-\(UUID().uuidString.prefix(8))")
    }
}

/// Zigbee服务创建器
public struct ZigbeeServiceCreator: ServiceCreator {
    public func create(configuration: Any?) throws -> any CommunicationService {
        return ZigbeeAdapter(serviceId: "zigbee-\(UUID().uuidString.prefix(8))")
    }
}

/// Matter服务创建器
public struct MatterServiceCreator: ServiceCreator {
    public func create(configuration: Any?) throws -> any CommunicationService {
        return MatterAdapter(serviceId: "matter-\(UUID().uuidString.prefix(8))")
    }
}

/// BLE发现服务创建器
public struct BLEDiscoveryCreator: DiscoveryCreator {
    public func create(configuration: Any?) throws -> any DeviceDiscovery {
        return BLEAdapter(serviceId: "ble-discovery-\(UUID().uuidString.prefix(8))")
    }
}

/// Zigbee发现服务创建器
public struct ZigbeeDiscoveryCreator: DiscoveryCreator {
    public func create(configuration: Any?) throws -> any DeviceDiscovery {
        return ZigbeeAdapter(serviceId: "zigbee-discovery-\(UUID().uuidString.prefix(8))")
    }
}

/// Matter发现服务创建器
public struct MatterDiscoveryCreator: DiscoveryCreator {
    public func create(configuration: Any?) throws -> any DeviceDiscovery {
        return MatterAdapter(serviceId: "matter-discovery-\(UUID().uuidString.prefix(8))")
    }
}

/// 重连策略创建器
public struct ReconnectionStrategyCreator: StrategyCreator {
    public func create(configuration: ConnectionStrategyConfiguration?) throws -> any ConnectionStrategy {
        return ReconnectionStrategy(configuration: configuration ?? ConnectionStrategyConfiguration())
    }
}

/// 负载均衡策略创建器（占位符）
public struct LoadBalancingStrategyCreator: StrategyCreator {
    public func create(configuration: ConnectionStrategyConfiguration?) throws -> any ConnectionStrategy {
        // 这里应该返回实际的负载均衡策略实现
        return ReconnectionStrategy(configuration: configuration ?? ConnectionStrategyConfiguration())
    }
}

/// 故障转移策略创建器（占位符）
public struct FailoverStrategyCreator: StrategyCreator {
    public func create(configuration: ConnectionStrategyConfiguration?) throws -> any ConnectionStrategy {
        // 这里应该返回实际的故障转移策略实现
        return ReconnectionStrategy(configuration: configuration ?? ConnectionStrategyConfiguration())
    }
}

// MARK: - Supporting Types

/// 弱引用包装器
private class WeakServiceReference {
    weak var service: AnyObject?
    
    init(service: AnyObject) {
        self.service = service
    }
}