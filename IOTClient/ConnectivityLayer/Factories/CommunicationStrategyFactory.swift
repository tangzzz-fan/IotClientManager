//
//  CommunicationStrategyFactory.swift
//  ConnectivityLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation

// MARK: - Communication Strategy Factory Protocol

/// 通信策略工厂协议
public protocol CommunicationStrategyFactoryProtocol {
    /// 创建指定名称的策略
    func createStrategy(name: String) -> (any CommunicationStrategy)?
    
    /// 获取所有可用策略
    func getAllStrategies() -> [any CommunicationStrategy]
    
    /// 获取适用于特定上下文的策略
    func getAvailableStrategies(for context: CommunicationContext) -> [StrategyInfo]
    
    /// 注册新策略
    func registerStrategy(_ strategy: any CommunicationStrategy)
    
    /// 注销策略
    func unregisterStrategy(name: String)
}

// MARK: - Communication Strategy Factory

/// 通信策略工厂
public final class CommunicationStrategyFactory: CommunicationStrategyFactoryProtocol {
    
    // MARK: - Properties
    
    /// 注册的策略创建器
    private var strategyCreators: [String: () -> any CommunicationStrategy] = [:]
    
    /// 策略缓存
    private var strategyCache: [String: any CommunicationStrategy] = [:]
    
    /// 工厂统计信息
    private var statistics: StrategyFactoryStatistics
    
    // MARK: - Initialization
    
    public init() {
        self.statistics = StrategyFactoryStatistics()
        registerDefaultStrategies()
    }
    
    // MARK: - Public Methods
    
    public func createStrategy(name: String) -> (any CommunicationStrategy)? {
        statistics.recordStrategyRequest(name: name)
        
        // 先检查缓存
        if let cachedStrategy = strategyCache[name] {
            statistics.recordCacheHit()
            return cachedStrategy
        }
        
        // 使用创建器创建新实例
        guard let creator = strategyCreators[name] else {
            statistics.recordStrategyNotFound(name: name)
            return nil
        }
        
        let strategy = creator()
        strategyCache[name] = strategy
        statistics.recordStrategyCreated(name: name)
        
        return strategy
    }
    
    public func getAllStrategies() -> [any CommunicationStrategy] {
        return strategyCreators.keys.compactMap { createStrategy(name: $0) }
    }
    
    public func getAvailableStrategies(for context: CommunicationContext) -> [StrategyInfo] {
        let allStrategies = getAllStrategies()
        
        return allStrategies.compactMap { strategy in
            let evaluation = strategy.evaluate(context: context)
            
            guard evaluation.isApplicable else { return nil }
            
            return StrategyInfo(
                name: strategy.strategyName,
                description: strategy.strategyDescription,
                supportedProtocols: strategy.supportedProtocols,
                priority: strategy.priority,
                suitabilityScore: evaluation.suitabilityScore
            )
        }.sorted { $0.suitabilityScore > $1.suitabilityScore }
    }
    
    public func registerStrategy(_ strategy: any CommunicationStrategy) {
        let name = strategy.strategyName
        
        strategyCreators[name] = {
            // 这里应该返回策略的新实例，但由于协议限制，我们返回同一个实例
            // 在实际实现中，应该有一个工厂方法来创建新实例
            return strategy
        }
        
        statistics.recordStrategyRegistered(name: name)
    }
    
    public func unregisterStrategy(name: String) {
        strategyCreators.removeValue(forKey: name)
        strategyCache.removeValue(forKey: name)
        statistics.recordStrategyUnregistered(name: name)
    }
    
    /// 获取工厂统计信息
    public func getStatistics() -> StrategyFactoryStatistics {
        return statistics
    }
    
    /// 清理缓存
    public func clearCache() {
        strategyCache.removeAll()
        statistics.recordCacheCleared()
    }
    
    /// 获取策略使用统计
    public func getStrategyUsageStatistics() -> [String: Int] {
        return statistics.strategyRequestCounts
    }
}

// MARK: - Private Implementation

private extension CommunicationStrategyFactory {
    
    func registerDefaultStrategies() {
        // 注册默认策略
        registerStrategy(AutomaticStrategy())
        registerStrategy(ReliabilityFirstStrategy())
        registerStrategy(SpeedFirstStrategy())
        registerStrategy(PowerSavingStrategy())
        registerStrategy(SecurityFirstStrategy())
        registerStrategy(BLEOnlyStrategy())
        registerStrategy(WiFiOnlyStrategy())
        registerStrategy(HybridStrategy())
    }
}

// MARK: - Strategy Factory Statistics

/// 策略工厂统计信息
public struct StrategyFactoryStatistics {
    /// 策略请求次数
    public private(set) var totalRequests: Int = 0
    
    /// 缓存命中次数
    public private(set) var cacheHits: Int = 0
    
    /// 策略创建次数
    public private(set) var strategiesCreated: Int = 0
    
    /// 策略未找到次数
    public private(set) var strategiesNotFound: Int = 0
    
    /// 各策略请求次数
    public private(set) var strategyRequestCounts: [String: Int] = [:]
    
    /// 注册的策略数量
    public private(set) var registeredStrategiesCount: Int = 0
    
    /// 最后更新时间
    public private(set) var lastUpdated: Date = Date()
    
    /// 缓存命中率
    public var cacheHitRate: Double {
        return totalRequests > 0 ? Double(cacheHits) / Double(totalRequests) : 0
    }
    
    /// 策略创建成功率
    public var strategyCreationSuccessRate: Double {
        return totalRequests > 0 ? Double(strategiesCreated) / Double(totalRequests) : 0
    }
    
    public mutating func recordStrategyRequest(name: String) {
        totalRequests += 1
        strategyRequestCounts[name, default: 0] += 1
        lastUpdated = Date()
    }
    
    public mutating func recordCacheHit() {
        cacheHits += 1
        lastUpdated = Date()
    }
    
    public mutating func recordStrategyCreated(name: String) {
        strategiesCreated += 1
        lastUpdated = Date()
    }
    
    public mutating func recordStrategyNotFound(name: String) {
        strategiesNotFound += 1
        lastUpdated = Date()
    }
    
    public mutating func recordStrategyRegistered(name: String) {
        registeredStrategiesCount += 1
        lastUpdated = Date()
    }
    
    public mutating func recordStrategyUnregistered(name: String) {
        registeredStrategiesCount = max(0, registeredStrategiesCount - 1)
        strategyRequestCounts.removeValue(forKey: name)
        lastUpdated = Date()
    }
    
    public mutating func recordCacheCleared() {
        lastUpdated = Date()
    }
}

// MARK: - Concrete Communication Strategies

/// 自动策略 - 根据上下文自动选择最佳协议
public struct AutomaticStrategy: CommunicationStrategy {
    public let strategyName = "Automatic"
    public let strategyDescription = "根据设备类型、网络环境和用户偏好自动选择最佳通信协议"
    public let supportedProtocols = ["MQTT", "BLE", "Zigbee", "Matter", "HTTP", "WebSocket"]
    public let priority = 100
    
    public func evaluate(context: CommunicationContext) -> StrategyEvaluation {
        var score = 80
        var reasons: [String] = []
        
        // 根据设备类型调整评分
        switch context.deviceType.lowercased() {
        case "sensor", "switch", "light":
            score += 10
            reasons.append("适合智能家居设备")
        case "robot", "camera":
            score += 5
            reasons.append("适合高带宽设备")
        default:
            break
        }
        
        // 根据网络环境调整评分
        if context.networkEnvironment.wifiInfo?.isConnected == true {
            score += 10
            reasons.append("WiFi网络可用")
        }
        
        // 根据用户偏好调整评分
        if context.userPreferences.priorityFactor == .balanced {
            score += 5
            reasons.append("平衡模式适合自动选择")
        }
        
        return StrategyEvaluation(
            suitabilityScore: min(100, score),
            isApplicable: true,
            reasons: reasons,
            expectedPerformance: PerformanceMetrics(
                expectedLatency: 100,
                expectedThroughput: 500,
                expectedReliability: 0.9,
                expectedPowerConsumption: 1.0
            )
        )
    }
    
    public func selectProtocol(context: CommunicationContext) -> ProtocolSelection {
        // 智能协议选择逻辑
        let deviceCapabilities = context.deviceCapabilities
        let networkEnv = context.networkEnvironment
        let preferences = context.userPreferences
        
        var protocolScores: [String: Int] = [:]
        
        // 评估各协议适用性
        if deviceCapabilities.supportsWiFi && networkEnv.wifiInfo?.isConnected == true {
            protocolScores["MQTT"] = 90
            protocolScores["HTTP"] = 80
            protocolScores["WebSocket"] = 85
        }
        
        if deviceCapabilities.supportsBLE {
            let bleScore = preferences.powerSavingMode ? 95 : 70
            protocolScores["BLE"] = bleScore
        }
        
        if deviceCapabilities.supportsZigbee {
            protocolScores["Zigbee"] = 85
        }
        
        if deviceCapabilities.supportsMatter {
            protocolScores["Matter"] = 88
        }
        
        // 根据用户偏好调整评分
        switch preferences.priorityFactor {
        case .speed:
            protocolScores["HTTP"] = (protocolScores["HTTP"] ?? 0) + 10
            protocolScores["WebSocket"] = (protocolScores["WebSocket"] ?? 0) + 10
        case .reliability:
            protocolScores["MQTT"] = (protocolScores["MQTT"] ?? 0) + 10
            protocolScores["Matter"] = (protocolScores["Matter"] ?? 0) + 10
        case .powerSaving:
            protocolScores["BLE"] = (protocolScores["BLE"] ?? 0) + 15
            protocolScores["Zigbee"] = (protocolScores["Zigbee"] ?? 0) + 10
        case .security:
            protocolScores["Matter"] = (protocolScores["Matter"] ?? 0) + 15
            protocolScores["MQTT"] = (protocolScores["MQTT"] ?? 0) + 10
        case .balanced:
            // 保持默认评分
            break
        }
        
        // 选择评分最高的协议
        let bestProtocol = protocolScores.max { $0.value < $1.value }
        let selectedProtocol = bestProtocol?.key ?? "MQTT"
        
        let alternatives = protocolScores.keys
            .filter { $0 != selectedProtocol }
            .sorted { protocolScores[$0] ?? 0 > protocolScores[$1] ?? 0 }
        
        return ProtocolSelection(
            selectedProtocol: selectedProtocol,
            alternativeProtocols: Array(alternatives.prefix(3)),
            selectionReason: "基于设备能力、网络环境和用户偏好的智能选择",
            expectedConnectionTime: 5.0
        )
    }
    
    public func createCommunicationService(
        protocol: String,
        context: CommunicationContext,
        factory: ConnectionFactory
    ) throws -> any CommunicationService {
        return try factory.createCommunicationService(type: protocol, configuration: nil)
    }
}

/// 可靠性优先策略
public struct ReliabilityFirstStrategy: CommunicationStrategy {
    public let strategyName = "ReliabilityFirst"
    public let strategyDescription = "优先选择最可靠的通信协议，确保连接稳定性"
    public let supportedProtocols = ["MQTT", "Matter", "HTTP"]
    public let priority = 80
    
    public func evaluate(context: CommunicationContext) -> StrategyEvaluation {
        var score = 70
        var reasons: [String] = []
        
        if context.userPreferences.priorityFactor == .reliability {
            score += 20
            reasons.append("用户偏好可靠性")
        }
        
        if context.connectionHistory.contains(where: { $0.wasSuccessful && $0.quality.qualityLevel == .excellent }) {
            score += 10
            reasons.append("历史连接质量良好")
        }
        
        return StrategyEvaluation(
            suitabilityScore: score,
            isApplicable: true,
            reasons: reasons,
            expectedPerformance: PerformanceMetrics(
                expectedLatency: 150,
                expectedThroughput: 300,
                expectedReliability: 0.98,
                expectedPowerConsumption: 1.2
            )
        )
    }
    
    public func selectProtocol(context: CommunicationContext) -> ProtocolSelection {
        let capabilities = context.deviceCapabilities
        
        if capabilities.supportsMatter {
            return ProtocolSelection(
                selectedProtocol: "Matter",
                alternativeProtocols: ["MQTT", "HTTP"],
                selectionReason: "Matter协议提供最高的可靠性和互操作性"
            )
        } else if capabilities.supportsWiFi {
            return ProtocolSelection(
                selectedProtocol: "MQTT",
                alternativeProtocols: ["HTTP"],
                selectionReason: "MQTT协议在WiFi环境下提供良好的可靠性"
            )
        } else {
            return ProtocolSelection(
                selectedProtocol: "HTTP",
                alternativeProtocols: [],
                selectionReason: "HTTP协议作为备选方案"
            )
        }
    }
    
    public func createCommunicationService(
        protocol: String,
        context: CommunicationContext,
        factory: ConnectionFactory
    ) throws -> any CommunicationService {
        // 为可靠性优化配置
        var config: Any?
        
        switch protocol {
        case "MQTT":
            config = MQTTConfiguration(
                brokerHost: "localhost",
                brokerPort: 1883,
                clientId: "reliable-\(context.deviceId)",
                qos: .exactlyOnce,
                cleanSession: false,
                keepAlive: 30
            )
        default:
            break
        }
        
        return try factory.createCommunicationService(type: protocol, configuration: config)
    }
}

/// 速度优先策略
public struct SpeedFirstStrategy: CommunicationStrategy {
    public let strategyName = "SpeedFirst"
    public let strategyDescription = "优先选择最快的通信协议，最小化延迟"
    public let supportedProtocols = ["WebSocket", "HTTP", "MQTT"]
    public let priority = 75
    
    public func evaluate(context: CommunicationContext) -> StrategyEvaluation {
        var score = 60
        
        if context.userPreferences.priorityFactor == .speed {
            score += 25
        }
        
        if context.networkEnvironment.wifiInfo?.signalStrength ?? 0 > 0.8 {
            score += 15
        }
        
        return StrategyEvaluation(
            suitabilityScore: score,
            isApplicable: context.deviceCapabilities.supportsWiFi,
            reasons: ["优化连接速度和响应时间"],
            expectedPerformance: PerformanceMetrics(
                expectedLatency: 50,
                expectedThroughput: 1000,
                expectedReliability: 0.85,
                expectedPowerConsumption: 1.5
            )
        )
    }
    
    public func selectProtocol(context: CommunicationContext) -> ProtocolSelection {
        return ProtocolSelection(
            selectedProtocol: "WebSocket",
            alternativeProtocols: ["HTTP", "MQTT"],
            selectionReason: "WebSocket提供最低延迟的实时通信"
        )
    }
    
    public func createCommunicationService(
        protocol: String,
        context: CommunicationContext,
        factory: ConnectionFactory
    ) throws -> any CommunicationService {
        return try factory.createCommunicationService(type: protocol, configuration: nil)
    }
}

/// 省电策略
public struct PowerSavingStrategy: CommunicationStrategy {
    public let strategyName = "PowerSaving"
    public let strategyDescription = "优先选择低功耗通信协议，延长设备电池寿命"
    public let supportedProtocols = ["BLE", "Zigbee"]
    public let priority = 70
    
    public func evaluate(context: CommunicationContext) -> StrategyEvaluation {
        var score = 50
        
        if context.deviceCapabilities.isBatteryPowered {
            score += 30
        }
        
        if context.userPreferences.powerSavingMode {
            score += 20
        }
        
        return StrategyEvaluation(
            suitabilityScore: score,
            isApplicable: context.deviceCapabilities.supportsBLE || context.deviceCapabilities.supportsZigbee,
            reasons: ["优化电池使用，延长设备寿命"],
            expectedPerformance: PerformanceMetrics(
                expectedLatency: 200,
                expectedThroughput: 100,
                expectedReliability: 0.9,
                expectedPowerConsumption: 0.3
            )
        )
    }
    
    public func selectProtocol(context: CommunicationContext) -> ProtocolSelection {
        let capabilities = context.deviceCapabilities
        
        if capabilities.supportsBLE {
            return ProtocolSelection(
                selectedProtocol: "BLE",
                alternativeProtocols: capabilities.supportsZigbee ? ["Zigbee"] : [],
                selectionReason: "BLE提供最低的功耗"
            )
        } else if capabilities.supportsZigbee {
            return ProtocolSelection(
                selectedProtocol: "Zigbee",
                alternativeProtocols: [],
                selectionReason: "Zigbee提供良好的低功耗网络连接"
            )
        } else {
            throw CommunicationError.noSuitableProtocol
        }
    }
    
    public func createCommunicationService(
        protocol: String,
        context: CommunicationContext,
        factory: ConnectionFactory
    ) throws -> any CommunicationService {
        return try factory.createCommunicationService(type: protocol, configuration: nil)
    }
}

/// 安全优先策略
public struct SecurityFirstStrategy: CommunicationStrategy {
    public let strategyName = "SecurityFirst"
    public let strategyDescription = "优先选择最安全的通信协议，确保数据安全"
    public let supportedProtocols = ["Matter", "MQTT"]
    public let priority = 85
    
    public func evaluate(context: CommunicationContext) -> StrategyEvaluation {
        var score = 65
        
        if context.userPreferences.securityLevel == .high || context.userPreferences.securityLevel == .enterprise {
            score += 25
        }
        
        return StrategyEvaluation(
            suitabilityScore: score,
            isApplicable: true,
            reasons: ["提供最高级别的安全保护"],
            expectedPerformance: PerformanceMetrics(
                expectedLatency: 120,
                expectedThroughput: 400,
                expectedReliability: 0.95,
                expectedPowerConsumption: 1.1
            )
        )
    }
    
    public func selectProtocol(context: CommunicationContext) -> ProtocolSelection {
        if context.deviceCapabilities.supportsMatter {
            return ProtocolSelection(
                selectedProtocol: "Matter",
                alternativeProtocols: ["MQTT"],
                selectionReason: "Matter提供端到端加密和设备认证"
            )
        } else {
            return ProtocolSelection(
                selectedProtocol: "MQTT",
                alternativeProtocols: [],
                selectionReason: "MQTT支持TLS加密"
            )
        }
    }
    
    public func createCommunicationService(
        protocol: String,
        context: CommunicationContext,
        factory: ConnectionFactory
    ) throws -> any CommunicationService {
        return try factory.createCommunicationService(type: protocol, configuration: nil)
    }
}

/// BLE专用策略
public struct BLEOnlyStrategy: CommunicationStrategy {
    public let strategyName = "BLEOnly"
    public let strategyDescription = "仅使用蓝牙低功耗通信"
    public let supportedProtocols = ["BLE"]
    public let priority = 60
    
    public func evaluate(context: CommunicationContext) -> StrategyEvaluation {
        let score = context.deviceCapabilities.supportsBLE ? 90 : 0
        
        return StrategyEvaluation(
            suitabilityScore: score,
            isApplicable: context.deviceCapabilities.supportsBLE,
            reasons: context.deviceCapabilities.supportsBLE ? ["设备支持BLE"] : ["设备不支持BLE"]
        )
    }
    
    public func selectProtocol(context: CommunicationContext) -> ProtocolSelection {
        return ProtocolSelection(
            selectedProtocol: "BLE",
            alternativeProtocols: [],
            selectionReason: "专用BLE通信策略"
        )
    }
    
    public func createCommunicationService(
        protocol: String,
        context: CommunicationContext,
        factory: ConnectionFactory
    ) throws -> any CommunicationService {
        return try factory.createCommunicationService(type: protocol, configuration: nil)
    }
}

/// WiFi专用策略
public struct WiFiOnlyStrategy: CommunicationStrategy {
    public let strategyName = "WiFiOnly"
    public let strategyDescription = "仅使用WiFi网络通信"
    public let supportedProtocols = ["MQTT", "HTTP", "WebSocket"]
    public let priority = 65
    
    public func evaluate(context: CommunicationContext) -> StrategyEvaluation {
        let hasWiFi = context.deviceCapabilities.supportsWiFi && context.networkEnvironment.wifiInfo?.isConnected == true
        let score = hasWiFi ? 85 : 0
        
        return StrategyEvaluation(
            suitabilityScore: score,
            isApplicable: hasWiFi,
            reasons: hasWiFi ? ["WiFi网络可用"] : ["WiFi网络不可用"]
        )
    }
    
    public func selectProtocol(context: CommunicationContext) -> ProtocolSelection {
        return ProtocolSelection(
            selectedProtocol: "MQTT",
            alternativeProtocols: ["HTTP", "WebSocket"],
            selectionReason: "WiFi环境下的优选协议"
        )
    }
    
    public func createCommunicationService(
        protocol: String,
        context: CommunicationContext,
        factory: ConnectionFactory
    ) throws -> any CommunicationService {
        return try factory.createCommunicationService(type: protocol, configuration: nil)
    }
}

/// 混合策略
public struct HybridStrategy: CommunicationStrategy {
    public let strategyName = "Hybrid"
    public let strategyDescription = "根据情况动态切换多种通信协议"
    public let supportedProtocols = ["MQTT", "BLE", "Zigbee", "Matter", "HTTP"]
    public let priority = 90
    
    public func evaluate(context: CommunicationContext) -> StrategyEvaluation {
        let supportedCount = context.deviceCapabilities.supportedProtocols.count
        let score = min(95, 60 + supportedCount * 5)
        
        return StrategyEvaluation(
            suitabilityScore: score,
            isApplicable: supportedCount > 1,
            reasons: ["设备支持多种协议，适合混合策略"]
        )
    }
    
    public func selectProtocol(context: CommunicationContext) -> ProtocolSelection {
        // 复杂的协议选择逻辑，考虑多种因素
        let capabilities = context.deviceCapabilities
        let networkEnv = context.networkEnvironment
        
        if networkEnv.wifiInfo?.isConnected == true && capabilities.supportsWiFi {
            return ProtocolSelection(
                selectedProtocol: "MQTT",
                alternativeProtocols: ["BLE", "Zigbee"],
                selectionReason: "WiFi可用时优选MQTT，保留其他协议作为备选"
            )
        } else if capabilities.supportsBLE {
            return ProtocolSelection(
                selectedProtocol: "BLE",
                alternativeProtocols: ["Zigbee"],
                selectionReason: "WiFi不可用时使用BLE"
            )
        } else {
            return ProtocolSelection(
                selectedProtocol: "Zigbee",
                alternativeProtocols: [],
                selectionReason: "使用Zigbee作为最后选择"
            )
        }
    }
    
    public func createCommunicationService(
        protocol: String,
        context: CommunicationContext,
        factory: ConnectionFactory
    ) throws -> any CommunicationService {
        return try factory.createCommunicationService(type: protocol, configuration: nil)
    }
}

// MARK: - Communication Errors Extension

extension CommunicationError {
    static let noSuitableProtocol = CommunicationError.custom("没有合适的通信协议")
}