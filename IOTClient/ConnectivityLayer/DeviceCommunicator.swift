//
//  DeviceCommunicator.swift
//  ConnectivityLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

// MARK: - Communication Context

/// 通信上下文信息
public struct CommunicationContext {
    /// 设备ID
    public let deviceId: String
    
    /// 设备类型
    public let deviceType: String
    
    /// 设备型号
    public let deviceModel: String?
    
    /// 优先协议
    public let preferredProtocols: [String]
    
    /// 网络环境
    public let networkEnvironment: NetworkEnvironment
    
    /// 用户偏好
    public let userPreferences: CommunicationPreferences
    
    /// 历史连接信息
    public let connectionHistory: [ConnectionHistoryEntry]
    
    /// 设备能力
    public let deviceCapabilities: DeviceCapabilities
    
    /// 当前时间
    public let timestamp: Date
    
    public init(
        deviceId: String,
        deviceType: String,
        deviceModel: String? = nil,
        preferredProtocols: [String] = [],
        networkEnvironment: NetworkEnvironment = NetworkEnvironment(),
        userPreferences: CommunicationPreferences = CommunicationPreferences(),
        connectionHistory: [ConnectionHistoryEntry] = [],
        deviceCapabilities: DeviceCapabilities = DeviceCapabilities(),
        timestamp: Date = Date()
    ) {
        self.deviceId = deviceId
        self.deviceType = deviceType
        self.deviceModel = deviceModel
        self.preferredProtocols = preferredProtocols
        self.networkEnvironment = networkEnvironment
        self.userPreferences = userPreferences
        self.connectionHistory = connectionHistory
        self.deviceCapabilities = deviceCapabilities
        self.timestamp = timestamp
    }
}

/// 通信偏好设置
public struct CommunicationPreferences {
    /// 优先考虑的因素
    public let priorityFactor: PriorityFactor
    
    /// 是否允许自动切换协议
    public let allowProtocolSwitching: Bool
    
    /// 最大连接超时时间
    public let maxConnectionTimeout: TimeInterval
    
    /// 是否启用省电模式
    public let powerSavingMode: Bool
    
    /// 数据使用偏好
    public let dataUsagePreference: DataUsagePreference
    
    /// 安全级别要求
    public let securityLevel: SecurityLevel
    
    public init(
        priorityFactor: PriorityFactor = .balanced,
        allowProtocolSwitching: Bool = true,
        maxConnectionTimeout: TimeInterval = 30,
        powerSavingMode: Bool = false,
        dataUsagePreference: DataUsagePreference = .balanced,
        securityLevel: SecurityLevel = .standard
    ) {
        self.priorityFactor = priorityFactor
        self.allowProtocolSwitching = allowProtocolSwitching
        self.maxConnectionTimeout = maxConnectionTimeout
        self.powerSavingMode = powerSavingMode
        self.dataUsagePreference = dataUsagePreference
        self.securityLevel = securityLevel
    }
}

/// 优先考虑因素
public enum PriorityFactor: String, CaseIterable {
    case speed = "speed"           // 优先速度
    case reliability = "reliability" // 优先可靠性
    case powerSaving = "power"     // 优先省电
    case security = "security"     // 优先安全
    case balanced = "balanced"     // 平衡
}

/// 数据使用偏好
public enum DataUsagePreference: String, CaseIterable {
    case minimal = "minimal"       // 最小化数据使用
    case balanced = "balanced"     // 平衡
    case unlimited = "unlimited"   // 不限制
}

/// 安全级别
public enum SecurityLevel: String, CaseIterable {
    case basic = "basic"           // 基础安全
    case standard = "standard"     // 标准安全
    case high = "high"             // 高安全
    case enterprise = "enterprise" // 企业级安全
}

/// 连接历史记录
public struct ConnectionHistoryEntry {
    /// 协议类型
    public let protocolType: String
    
    /// 连接时间
    public let connectionTime: Date
    
    /// 连接持续时间
    public let duration: TimeInterval
    
    /// 连接质量
    public let quality: ConnectionQuality
    
    /// 是否成功
    public let wasSuccessful: Bool
    
    /// 断开原因
    public let disconnectionReason: DisconnectionReason?
    
    public init(
        protocolType: String,
        connectionTime: Date,
        duration: TimeInterval,
        quality: ConnectionQuality,
        wasSuccessful: Bool,
        disconnectionReason: DisconnectionReason? = nil
    ) {
        self.protocolType = protocolType
        self.connectionTime = connectionTime
        self.duration = duration
        self.quality = quality
        self.wasSuccessful = wasSuccessful
        self.disconnectionReason = disconnectionReason
    }
}

/// 设备能力
public struct DeviceCapabilities {
    /// 支持的协议
    public let supportedProtocols: [String]
    
    /// 是否支持BLE
    public let supportsBLE: Bool
    
    /// 是否支持WiFi
    public let supportsWiFi: Bool
    
    /// 是否支持Zigbee
    public let supportsZigbee: Bool
    
    /// 是否支持Matter
    public let supportsMatter: Bool
    
    /// 电池供电
    public let isBatteryPowered: Bool
    
    /// 移动设备
    public let isMobile: Bool
    
    /// 最大传输速率
    public let maxTransferRate: Double?
    
    /// 支持的加密方式
    public let supportedEncryption: [String]
    
    public init(
        supportedProtocols: [String] = [],
        supportsBLE: Bool = false,
        supportsWiFi: Bool = false,
        supportsZigbee: Bool = false,
        supportsMatter: Bool = false,
        isBatteryPowered: Bool = false,
        isMobile: Bool = false,
        maxTransferRate: Double? = nil,
        supportedEncryption: [String] = []
    ) {
        self.supportedProtocols = supportedProtocols
        self.supportsBLE = supportsBLE
        self.supportsWiFi = supportsWiFi
        self.supportsZigbee = supportsZigbee
        self.supportsMatter = supportsMatter
        self.isBatteryPowered = isBatteryPowered
        self.isMobile = isMobile
        self.maxTransferRate = maxTransferRate
        self.supportedEncryption = supportedEncryption
    }
}

// MARK: - Communication Strategy Protocol

/// 通信策略协议
public protocol CommunicationStrategy {
    /// 策略名称
    var strategyName: String { get }
    
    /// 策略描述
    var strategyDescription: String { get }
    
    /// 支持的协议类型
    var supportedProtocols: [String] { get }
    
    /// 策略优先级
    var priority: Int { get }
    
    /// 评估策略适用性
    func evaluate(context: CommunicationContext) -> StrategyEvaluation
    
    /// 选择最佳协议
    func selectProtocol(context: CommunicationContext) -> ProtocolSelection
    
    /// 创建通信服务
    func createCommunicationService(
        protocol: String,
        context: CommunicationContext,
        factory: ConnectionFactory
    ) throws -> any CommunicationService
}

/// 策略评估结果
public struct StrategyEvaluation {
    /// 适用性评分（0-100）
    public let suitabilityScore: Int
    
    /// 是否适用
    public let isApplicable: Bool
    
    /// 评估原因
    public let reasons: [String]
    
    /// 预期性能
    public let expectedPerformance: PerformanceMetrics
    
    /// 风险评估
    public let risks: [String]
    
    public init(
        suitabilityScore: Int,
        isApplicable: Bool,
        reasons: [String] = [],
        expectedPerformance: PerformanceMetrics = PerformanceMetrics(),
        risks: [String] = []
    ) {
        self.suitabilityScore = suitabilityScore
        self.isApplicable = isApplicable
        self.reasons = reasons
        self.expectedPerformance = expectedPerformance
        self.risks = risks
    }
}

/// 协议选择结果
public struct ProtocolSelection {
    /// 选择的协议
    public let selectedProtocol: String
    
    /// 备选协议
    public let alternativeProtocols: [String]
    
    /// 选择原因
    public let selectionReason: String
    
    /// 配置参数
    public let configuration: [String: Any]
    
    /// 预期连接时间
    public let expectedConnectionTime: TimeInterval
    
    public init(
        selectedProtocol: String,
        alternativeProtocols: [String] = [],
        selectionReason: String,
        configuration: [String: Any] = [:],
        expectedConnectionTime: TimeInterval = 10.0
    ) {
        self.selectedProtocol = selectedProtocol
        self.alternativeProtocols = alternativeProtocols
        self.selectionReason = selectionReason
        self.configuration = configuration
        self.expectedConnectionTime = expectedConnectionTime
    }
}

/// 性能指标
public struct PerformanceMetrics {
    /// 预期延迟（毫秒）
    public let expectedLatency: Double
    
    /// 预期吞吐量（KB/s）
    public let expectedThroughput: Double
    
    /// 预期可靠性（0-1）
    public let expectedReliability: Double
    
    /// 预期功耗（相对值）
    public let expectedPowerConsumption: Double
    
    public init(
        expectedLatency: Double = 100.0,
        expectedThroughput: Double = 100.0,
        expectedReliability: Double = 0.95,
        expectedPowerConsumption: Double = 1.0
    ) {
        self.expectedLatency = expectedLatency
        self.expectedThroughput = expectedThroughput
        self.expectedReliability = expectedReliability
        self.expectedPowerConsumption = expectedPowerConsumption
    }
}

// MARK: - Device Communicator

/// 设备通信器 - 通信策略的上下文类
public final class DeviceCommunicator: ObservableObject {
    
    // MARK: - Properties
    
    /// 当前通信策略
    @Published public private(set) var currentStrategy: (any CommunicationStrategy)?
    
    /// 当前通信服务
    @Published public private(set) var currentService: (any CommunicationService)?
    
    /// 通信上下文
    @Published public private(set) var context: CommunicationContext
    
    /// 连接状态
    @Published public private(set) var connectionState: ConnectionState = .disconnected
    
    /// 通信统计
    @Published public private(set) var statistics: CommunicationStatistics
    
    // MARK: - Publishers
    
    /// 消息发布者
    public let messagePublisher = PassthroughSubject<Any, Never>()
    
    /// 连接事件发布者
    public let connectionEventPublisher = PassthroughSubject<ConnectionEvent, Never>()
    
    /// 策略变更发布者
    public let strategyChangePublisher = PassthroughSubject<StrategyChangeEvent, Never>()
    
    // MARK: - Private Properties
    
    private let connectionFactory: ConnectionFactory
    private let strategyFactory: CommunicationStrategyFactory
    private var cancellables = Set<AnyCancellable>()
    
    private let communicationQueue = DispatchQueue(label: "device-communicator", qos: .userInitiated)
    private var connectionMonitorTimer: Timer?
    private var strategyEvaluationTimer: Timer?
    
    // MARK: - Initialization
    
    public init(
        context: CommunicationContext,
        connectionFactory: ConnectionFactory = ConnectionFactory(),
        strategyFactory: CommunicationStrategyFactory = CommunicationStrategyFactory()
    ) {
        self.context = context
        self.connectionFactory = connectionFactory
        self.strategyFactory = strategyFactory
        self.statistics = CommunicationStatistics(deviceId: context.deviceId)
        
        setupMonitoring()
    }
    
    deinit {
        disconnect()
        stopMonitoring()
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    
    /// 连接设备
    public func connect() async throws {
        guard connectionState != .connected && connectionState != .connecting else {
            return
        }
        
        connectionState = .connecting
        
        do {
            // 选择最佳策略
            let strategy = try selectBestStrategy()
            currentStrategy = strategy
            
            // 选择协议并创建服务
            let protocolSelection = strategy.selectProtocol(context: context)
            let service = try strategy.createCommunicationService(
                protocol: protocolSelection.selectedProtocol,
                context: context,
                factory: connectionFactory
            )
            
            currentService = service
            
            // 设置服务监听
            setupServiceMonitoring(service)
            
            // 执行连接
            try await service.connect()
            
            connectionState = .connected
            statistics.recordConnection(successful: true)
            
            // 发布连接事件
            let connectionInfo = ConnectionInfo(
                deviceId: context.deviceId,
                connectionType: protocolSelection.selectedProtocol,
                state: .connected
            )
            connectionEventPublisher.send(.connected(connectionInfo: connectionInfo))
            
        } catch {
            connectionState = .error
            statistics.recordConnection(successful: false)
            
            connectionEventPublisher.send(.connectionFailed(
                deviceId: context.deviceId,
                error: error
            ))
            
            throw error
        }
    }
    
    /// 断开连接
    public func disconnect() {
        guard connectionState != .disconnected else { return }
        
        connectionState = .disconnecting
        
        currentService?.disconnect()
        currentService = nil
        
        connectionState = .disconnected
        statistics.recordDisconnection()
        
        connectionEventPublisher.send(.disconnected(
            connectionId: context.deviceId,
            reason: .userRequested
        ))
    }
    
    /// 发送消息
    public func sendMessage(_ message: Any) async throws {
        guard let service = currentService else {
            throw CommunicationError.notConnected
        }
        
        try await service.sendMessage(message)
        statistics.recordMessageSent()
    }
    
    /// 订阅主题
    public func subscribe(to topic: String) async throws {
        guard let service = currentService else {
            throw CommunicationError.notConnected
        }
        
        try await service.subscribe(to: topic)
    }
    
    /// 取消订阅
    public func unsubscribe(from topic: String) async throws {
        guard let service = currentService else {
            throw CommunicationError.notConnected
        }
        
        try await service.unsubscribe(from: topic)
    }
    
    /// 更新通信上下文
    public func updateContext(_ newContext: CommunicationContext) {
        let oldContext = context
        context = newContext
        
        // 如果设备类型或能力发生变化，重新评估策略
        if oldContext.deviceType != newContext.deviceType ||
           oldContext.deviceCapabilities.supportedProtocols != newContext.deviceCapabilities.supportedProtocols {
            Task {
                await reevaluateStrategy()
            }
        }
    }
    
    /// 强制切换策略
    public func switchStrategy(to strategyName: String) async throws {
        guard let newStrategy = strategyFactory.createStrategy(name: strategyName) else {
            throw CommunicationError.strategyNotFound
        }
        
        let wasConnected = connectionState == .connected
        
        if wasConnected {
            disconnect()
        }
        
        currentStrategy = newStrategy
        
        strategyChangePublisher.send(StrategyChangeEvent(
            oldStrategy: currentStrategy?.strategyName,
            newStrategy: newStrategy.strategyName,
            reason: "用户手动切换"
        ))
        
        if wasConnected {
            try await connect()
        }
    }
    
    /// 获取可用策略
    public func getAvailableStrategies() -> [StrategyInfo] {
        return strategyFactory.getAvailableStrategies(for: context)
    }
    
    /// 获取连接信息
    public func getConnectionInfo() -> [String: Any] {
        var info: [String: Any] = [
            "deviceId": context.deviceId,
            "deviceType": context.deviceType,
            "connectionState": connectionState.rawValue,
            "statistics": statistics.toDictionary()
        ]
        
        if let strategy = currentStrategy {
            info["currentStrategy"] = strategy.strategyName
        }
        
        if let service = currentService {
            info["currentService"] = service.serviceName
            info["serviceInfo"] = service.getConnectionInfo()
        }
        
        return info
    }
}

// MARK: - Private Implementation

private extension DeviceCommunicator {
    
    func selectBestStrategy() throws -> any CommunicationStrategy {
        let availableStrategies = strategyFactory.getAllStrategies()
        
        guard !availableStrategies.isEmpty else {
            throw CommunicationError.noStrategyAvailable
        }
        
        // 评估所有策略
        let evaluations = availableStrategies.compactMap { strategy -> (any CommunicationStrategy, StrategyEvaluation)? in
            let evaluation = strategy.evaluate(context: context)
            return evaluation.isApplicable ? (strategy, evaluation) : nil
        }
        
        guard !evaluations.isEmpty else {
            throw CommunicationError.noSuitableStrategy
        }
        
        // 选择评分最高的策略
        let bestStrategy = evaluations.max { $0.1.suitabilityScore < $1.1.suitabilityScore }
        
        return bestStrategy!.0
    }
    
    func setupServiceMonitoring(_ service: any CommunicationService) {
        // 监听连接状态变化
        service.connectionStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.connectionState = state
            }
            .store(in: &cancellables)
        
        // 监听消息
        service.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.statistics.recordMessageReceived()
                self?.messagePublisher.send(message)
            }
            .store(in: &cancellables)
        
        // 监听错误
        service.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.statistics.recordError()
                self?.handleServiceError(error)
            }
            .store(in: &cancellables)
    }
    
    func setupMonitoring() {
        // 连接质量监控
        connectionMonitorTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.monitorConnectionQuality()
        }
        
        // 策略重新评估
        strategyEvaluationTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            Task {
                await self?.reevaluateStrategy()
            }
        }
    }
    
    func stopMonitoring() {
        connectionMonitorTimer?.invalidate()
        connectionMonitorTimer = nil
        
        strategyEvaluationTimer?.invalidate()
        strategyEvaluationTimer = nil
    }
    
    func monitorConnectionQuality() {
        guard let service = currentService else { return }
        
        // 获取诊断信息
        service.diagnosticsPublisher
            .first()
            .sink { [weak self] diagnostics in
                self?.statistics.updateQuality(from: diagnostics)
            }
            .store(in: &cancellables)
    }
    
    func reevaluateStrategy() async {
        guard let currentStrategy = currentStrategy else { return }
        
        // 重新评估当前策略
        let currentEvaluation = currentStrategy.evaluate(context: context)
        
        // 如果当前策略评分过低，尝试切换
        if currentEvaluation.suitabilityScore < 60 {
            do {
                let newStrategy = try selectBestStrategy()
                if newStrategy.strategyName != currentStrategy.strategyName {
                    try await switchStrategy(to: newStrategy.strategyName)
                }
            } catch {
                print("策略重新评估失败: \(error)")
            }
        }
    }
    
    func handleServiceError(_ error: Error) {
        // 根据错误类型决定是否需要切换策略
        if case CommunicationError.connectionLost = error {
            Task {
                await reevaluateStrategy()
            }
        }
    }
}

// MARK: - Communication Statistics

/// 通信统计信息
public struct CommunicationStatistics {
    /// 设备ID
    public let deviceId: String
    
    /// 连接次数
    public private(set) var connectionAttempts: Int = 0
    
    /// 成功连接次数
    public private(set) var successfulConnections: Int = 0
    
    /// 发送消息数
    public private(set) var messagesSent: Int = 0
    
    /// 接收消息数
    public private(set) var messagesReceived: Int = 0
    
    /// 错误次数
    public private(set) var errorCount: Int = 0
    
    /// 总连接时间
    public private(set) var totalConnectionTime: TimeInterval = 0
    
    /// 平均连接质量
    public private(set) var averageQuality: Double = 0
    
    /// 最后更新时间
    public private(set) var lastUpdated: Date = Date()
    
    /// 连接成功率
    public var connectionSuccessRate: Double {
        return connectionAttempts > 0 ? Double(successfulConnections) / Double(connectionAttempts) : 0
    }
    
    public init(deviceId: String) {
        self.deviceId = deviceId
    }
    
    public mutating func recordConnection(successful: Bool) {
        connectionAttempts += 1
        if successful {
            successfulConnections += 1
        }
        lastUpdated = Date()
    }
    
    public mutating func recordDisconnection() {
        lastUpdated = Date()
    }
    
    public mutating func recordMessageSent() {
        messagesSent += 1
        lastUpdated = Date()
    }
    
    public mutating func recordMessageReceived() {
        messagesReceived += 1
        lastUpdated = Date()
    }
    
    public mutating func recordError() {
        errorCount += 1
        lastUpdated = Date()
    }
    
    public mutating func updateQuality(from diagnostics: ConnectionDiagnostics) {
        // 简化的质量计算
        let quality = (diagnostics.signalStrength + (1.0 - diagnostics.packetLoss)) / 2.0
        averageQuality = (averageQuality + quality) / 2.0
        lastUpdated = Date()
    }
    
    public func toDictionary() -> [String: Any] {
        return [
            "deviceId": deviceId,
            "connectionAttempts": connectionAttempts,
            "successfulConnections": successfulConnections,
            "connectionSuccessRate": connectionSuccessRate,
            "messagesSent": messagesSent,
            "messagesReceived": messagesReceived,
            "errorCount": errorCount,
            "totalConnectionTime": totalConnectionTime,
            "averageQuality": averageQuality,
            "lastUpdated": lastUpdated
        ]
    }
}

// MARK: - Strategy Change Event

/// 策略变更事件
public struct StrategyChangeEvent {
    /// 旧策略名称
    public let oldStrategy: String?
    
    /// 新策略名称
    public let newStrategy: String
    
    /// 变更原因
    public let reason: String
    
    /// 变更时间
    public let timestamp: Date
    
    public init(
        oldStrategy: String?,
        newStrategy: String,
        reason: String,
        timestamp: Date = Date()
    ) {
        self.oldStrategy = oldStrategy
        self.newStrategy = newStrategy
        self.reason = reason
        self.timestamp = timestamp
    }
}

// MARK: - Strategy Info

/// 策略信息
public struct StrategyInfo {
    /// 策略名称
    public let name: String
    
    /// 策略描述
    public let description: String
    
    /// 支持的协议
    public let supportedProtocols: [String]
    
    /// 优先级
    public let priority: Int
    
    /// 适用性评分
    public let suitabilityScore: Int
    
    /// 是否当前使用
    public let isCurrentlyUsed: Bool
    
    public init(
        name: String,
        description: String,
        supportedProtocols: [String],
        priority: Int,
        suitabilityScore: Int,
        isCurrentlyUsed: Bool = false
    ) {
        self.name = name
        self.description = description
        self.supportedProtocols = supportedProtocols
        self.priority = priority
        self.suitabilityScore = suitabilityScore
        self.isCurrentlyUsed = isCurrentlyUsed
    }
}

// MARK: - Communication Errors

extension CommunicationError {
    static let strategyNotFound = CommunicationError.custom("指定的策略未找到")
    static let noStrategyAvailable = CommunicationError.custom("没有可用的通信策略")
    static let noSuitableStrategy = CommunicationError.custom("没有适合的通信策略")
}