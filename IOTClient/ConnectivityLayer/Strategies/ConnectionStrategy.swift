//
//  ConnectionStrategy.swift
//  ConnectivityLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

/// 连接策略协议
public protocol ConnectionStrategy {
    /// 策略标识符
    var strategyId: String { get }
    
    /// 策略名称
    var strategyName: String { get }
    
    /// 策略描述
    var strategyDescription: String { get }
    
    /// 支持的协议类型
    var supportedProtocols: Set<String> { get }
    
    /// 策略优先级（数值越小优先级越高）
    var priority: Int { get }
    
    /// 是否启用
    var isEnabled: Bool { get set }
    
    /// 连接参数
    associatedtype ConnectionParameters
    
    /// 连接结果
    associatedtype ConnectionResult
    
    /// 执行连接策略
    /// - Parameters:
    ///   - parameters: 连接参数
    ///   - context: 连接上下文
    /// - Returns: 连接结果的发布者
    func executeConnection(
        with parameters: ConnectionParameters,
        context: ConnectionContext
    ) -> AnyPublisher<ConnectionResult, ConnectionStrategyError>
    
    /// 验证连接参数
    /// - Parameter parameters: 连接参数
    /// - Returns: 验证结果
    func validateParameters(_ parameters: ConnectionParameters) -> ConnectionValidationResult
    
    /// 估算连接时间
    /// - Parameters:
    ///   - parameters: 连接参数
    ///   - context: 连接上下文
    /// - Returns: 估算的连接时间（秒）
    func estimateConnectionTime(
        with parameters: ConnectionParameters,
        context: ConnectionContext
    ) -> TimeInterval
    
    /// 获取策略配置
    /// - Returns: 策略配置
    func getConfiguration() -> ConnectionStrategyConfiguration
    
    /// 更新策略配置
    /// - Parameter configuration: 新的策略配置
    func updateConfiguration(_ configuration: ConnectionStrategyConfiguration)
    
    /// 重置策略状态
    func reset()
}

/// 连接策略错误
public enum ConnectionStrategyError: Error, LocalizedError {
    case invalidParameters(String)
    case connectionFailed(String)
    case timeout(String)
    case unsupportedProtocol(String)
    case strategyDisabled(String)
    case configurationError(String)
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidParameters(let message):
            return "无效参数: \(message)"
        case .connectionFailed(let message):
            return "连接失败: \(message)"
        case .timeout(let message):
            return "连接超时: \(message)"
        case .unsupportedProtocol(let message):
            return "不支持的协议: \(message)"
        case .strategyDisabled(let message):
            return "策略已禁用: \(message)"
        case .configurationError(let message):
            return "配置错误: \(message)"
        case .unknown(let error):
            return "未知错误: \(error.localizedDescription)"
        }
    }
}

/// 连接上下文
public struct ConnectionContext {
    /// 设备标识符
    public let deviceId: String
    
    /// 设备类型
    public let deviceType: String
    
    /// 连接历史
    public let connectionHistory: [ConnectionAttempt]
    
    /// 网络环境信息
    public let networkEnvironment: NetworkEnvironment
    
    /// 用户偏好
    public let userPreferences: UserConnectionPreferences
    
    /// 系统状态
    public let systemState: SystemConnectionState
    
    /// 额外上下文信息
    public let additionalInfo: [String: Any]
    
    public init(
        deviceId: String,
        deviceType: String,
        connectionHistory: [ConnectionAttempt] = [],
        networkEnvironment: NetworkEnvironment = NetworkEnvironment(),
        userPreferences: UserConnectionPreferences = UserConnectionPreferences(),
        systemState: SystemConnectionState = SystemConnectionState(),
        additionalInfo: [String: Any] = [:]
    ) {
        self.deviceId = deviceId
        self.deviceType = deviceType
        self.connectionHistory = connectionHistory
        self.networkEnvironment = networkEnvironment
        self.userPreferences = userPreferences
        self.systemState = systemState
        self.additionalInfo = additionalInfo
    }
}

/// 连接尝试记录
public struct ConnectionAttempt {
    /// 尝试时间
    public let attemptTime: Date
    
    /// 使用的策略
    public let strategyId: String
    
    /// 连接结果
    public let result: ConnectionAttemptResult
    
    /// 连接持续时间
    public let duration: TimeInterval
    
    /// 错误信息（如果失败）
    public let error: Error?
    
    /// 额外信息
    public let metadata: [String: Any]
    
    public init(
        attemptTime: Date = Date(),
        strategyId: String,
        result: ConnectionAttemptResult,
        duration: TimeInterval,
        error: Error? = nil,
        metadata: [String: Any] = [:]
    ) {
        self.attemptTime = attemptTime
        self.strategyId = strategyId
        self.result = result
        self.duration = duration
        self.error = error
        self.metadata = metadata
    }
}

/// 连接尝试结果
public enum ConnectionAttemptResult: String, CaseIterable, Codable {
    case success = "success"
    case failed = "failed"
    case timeout = "timeout"
    case cancelled = "cancelled"
    
    public var displayName: String {
        switch self {
        case .success:
            return "成功"
        case .failed:
            return "失败"
        case .timeout:
            return "超时"
        case .cancelled:
            return "取消"
        }
    }
}

/// 网络环境信息
public struct NetworkEnvironment {
    /// WiFi信息
    public let wifiInfo: WiFiInfo?
    
    /// 蜂窝网络信息
    public let cellularInfo: CellularInfo?
    
    /// 网络质量
    public let networkQuality: NetworkQuality
    
    /// 带宽信息
    public let bandwidth: BandwidthInfo?
    
    /// 延迟信息
    public let latency: LatencyInfo?
    
    public init(
        wifiInfo: WiFiInfo? = nil,
        cellularInfo: CellularInfo? = nil,
        networkQuality: NetworkQuality = .unknown,
        bandwidth: BandwidthInfo? = nil,
        latency: LatencyInfo? = nil
    ) {
        self.wifiInfo = wifiInfo
        self.cellularInfo = cellularInfo
        self.networkQuality = networkQuality
        self.bandwidth = bandwidth
        self.latency = latency
    }
}

/// WiFi信息
public struct WiFiInfo {
    public let ssid: String
    public let bssid: String?
    public let signalStrength: Int // dBm
    public let frequency: Double // GHz
    public let securityType: String
    
    public init(
        ssid: String,
        bssid: String? = nil,
        signalStrength: Int,
        frequency: Double,
        securityType: String
    ) {
        self.ssid = ssid
        self.bssid = bssid
        self.signalStrength = signalStrength
        self.frequency = frequency
        self.securityType = securityType
    }
}

/// 蜂窝网络信息
public struct CellularInfo {
    public let carrierName: String?
    public let networkType: String // 4G, 5G, etc.
    public let signalStrength: Int
    public let isRoaming: Bool
    
    public init(
        carrierName: String? = nil,
        networkType: String,
        signalStrength: Int,
        isRoaming: Bool = false
    ) {
        self.carrierName = carrierName
        self.networkType = networkType
        self.signalStrength = signalStrength
        self.isRoaming = isRoaming
    }
}

/// 网络质量
public enum NetworkQuality: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case unknown = "unknown"
    
    public var displayName: String {
        switch self {
        case .excellent:
            return "优秀"
        case .good:
            return "良好"
        case .fair:
            return "一般"
        case .poor:
            return "较差"
        case .unknown:
            return "未知"
        }
    }
}

/// 带宽信息
public struct BandwidthInfo {
    public let downloadSpeed: Double // Mbps
    public let uploadSpeed: Double // Mbps
    public let measuredAt: Date
    
    public init(downloadSpeed: Double, uploadSpeed: Double, measuredAt: Date = Date()) {
        self.downloadSpeed = downloadSpeed
        self.uploadSpeed = uploadSpeed
        self.measuredAt = measuredAt
    }
}

/// 延迟信息
public struct LatencyInfo {
    public let averageLatency: TimeInterval // ms
    public let minLatency: TimeInterval // ms
    public let maxLatency: TimeInterval // ms
    public let jitter: TimeInterval // ms
    public let measuredAt: Date
    
    public init(
        averageLatency: TimeInterval,
        minLatency: TimeInterval,
        maxLatency: TimeInterval,
        jitter: TimeInterval,
        measuredAt: Date = Date()
    ) {
        self.averageLatency = averageLatency
        self.minLatency = minLatency
        self.maxLatency = maxLatency
        self.jitter = jitter
        self.measuredAt = measuredAt
    }
}

/// 用户连接偏好
public struct UserConnectionPreferences {
    /// 偏好的连接类型
    public let preferredConnectionTypes: [String]
    
    /// 连接超时偏好
    public let connectionTimeout: TimeInterval
    
    /// 是否允许自动重连
    public let allowAutoReconnect: Bool
    
    /// 是否优先考虑速度
    public let prioritizeSpeed: Bool
    
    /// 是否优先考虑稳定性
    public let prioritizeStability: Bool
    
    /// 是否允许后台连接
    public let allowBackgroundConnection: Bool
    
    public init(
        preferredConnectionTypes: [String] = [],
        connectionTimeout: TimeInterval = 30.0,
        allowAutoReconnect: Bool = true,
        prioritizeSpeed: Bool = false,
        prioritizeStability: Bool = true,
        allowBackgroundConnection: Bool = true
    ) {
        self.preferredConnectionTypes = preferredConnectionTypes
        self.connectionTimeout = connectionTimeout
        self.allowAutoReconnect = allowAutoReconnect
        self.prioritizeSpeed = prioritizeSpeed
        self.prioritizeStability = prioritizeStability
        self.allowBackgroundConnection = allowBackgroundConnection
    }
}

/// 系统连接状态
public struct SystemConnectionState {
    /// 系统负载
    public let systemLoad: Double // 0.0 - 1.0
    
    /// 可用内存
    public let availableMemory: Int64 // bytes
    
    /// 电池电量
    public let batteryLevel: Double? // 0.0 - 1.0
    
    /// 是否处于低电量模式
    public let isLowPowerModeEnabled: Bool
    
    /// 活跃连接数
    public let activeConnectionCount: Int
    
    /// 系统时间
    public let systemTime: Date
    
    public init(
        systemLoad: Double = 0.0,
        availableMemory: Int64 = 0,
        batteryLevel: Double? = nil,
        isLowPowerModeEnabled: Bool = false,
        activeConnectionCount: Int = 0,
        systemTime: Date = Date()
    ) {
        self.systemLoad = systemLoad
        self.availableMemory = availableMemory
        self.batteryLevel = batteryLevel
        self.isLowPowerModeEnabled = isLowPowerModeEnabled
        self.activeConnectionCount = activeConnectionCount
        self.systemTime = systemTime
    }
}

/// 连接验证结果
public struct ConnectionValidationResult {
    /// 是否有效
    public let isValid: Bool
    
    /// 验证消息
    public let messages: [ValidationMessage]
    
    /// 建议的修复方案
    public let suggestions: [String]
    
    public init(isValid: Bool, messages: [ValidationMessage] = [], suggestions: [String] = []) {
        self.isValid = isValid
        self.messages = messages
        self.suggestions = suggestions
    }
    
    /// 创建成功的验证结果
    public static func success() -> ConnectionValidationResult {
        return ConnectionValidationResult(isValid: true)
    }
    
    /// 创建失败的验证结果
    public static func failure(messages: [ValidationMessage], suggestions: [String] = []) -> ConnectionValidationResult {
        return ConnectionValidationResult(isValid: false, messages: messages, suggestions: suggestions)
    }
}

/// 验证消息
public struct ValidationMessage {
    /// 消息级别
    public let level: ValidationLevel
    
    /// 消息内容
    public let message: String
    
    /// 相关字段
    public let field: String?
    
    public init(level: ValidationLevel, message: String, field: String? = nil) {
        self.level = level
        self.message = message
        self.field = field
    }
}

/// 验证级别
public enum ValidationLevel: String, CaseIterable, Codable {
    case error = "error"
    case warning = "warning"
    case info = "info"
    
    public var displayName: String {
        switch self {
        case .error:
            return "错误"
        case .warning:
            return "警告"
        case .info:
            return "信息"
        }
    }
}

/// 连接策略配置
public struct ConnectionStrategyConfiguration {
    /// 超时设置
    public let timeoutSettings: TimeoutSettings
    
    /// 重试设置
    public let retrySettings: RetrySettings
    
    /// 性能设置
    public let performanceSettings: PerformanceSettings
    
    /// 安全设置
    public let securitySettings: SecuritySettings
    
    /// 自定义参数
    public let customParameters: [String: Any]
    
    public init(
        timeoutSettings: TimeoutSettings = TimeoutSettings(),
        retrySettings: RetrySettings = RetrySettings(),
        performanceSettings: PerformanceSettings = PerformanceSettings(),
        securitySettings: SecuritySettings = SecuritySettings(),
        customParameters: [String: Any] = [:]
    ) {
        self.timeoutSettings = timeoutSettings
        self.retrySettings = retrySettings
        self.performanceSettings = performanceSettings
        self.securitySettings = securitySettings
        self.customParameters = customParameters
    }
}

/// 超时设置
public struct TimeoutSettings {
    public let connectionTimeout: TimeInterval
    public let readTimeout: TimeInterval
    public let writeTimeout: TimeInterval
    public let keepAliveTimeout: TimeInterval
    
    public init(
        connectionTimeout: TimeInterval = 30.0,
        readTimeout: TimeInterval = 10.0,
        writeTimeout: TimeInterval = 10.0,
        keepAliveTimeout: TimeInterval = 60.0
    ) {
        self.connectionTimeout = connectionTimeout
        self.readTimeout = readTimeout
        self.writeTimeout = writeTimeout
        self.keepAliveTimeout = keepAliveTimeout
    }
}

/// 重试设置
public struct RetrySettings {
    public let maxRetries: Int
    public let initialDelay: TimeInterval
    public let maxDelay: TimeInterval
    public let backoffMultiplier: Double
    public let jitterEnabled: Bool
    
    public init(
        maxRetries: Int = 3,
        initialDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        backoffMultiplier: Double = 2.0,
        jitterEnabled: Bool = true
    ) {
        self.maxRetries = maxRetries
        self.initialDelay = initialDelay
        self.maxDelay = maxDelay
        self.backoffMultiplier = backoffMultiplier
        self.jitterEnabled = jitterEnabled
    }
}

/// 性能设置
public struct PerformanceSettings {
    public let bufferSize: Int
    public let concurrentConnections: Int
    public let compressionEnabled: Bool
    public let keepAliveEnabled: Bool
    
    public init(
        bufferSize: Int = 8192,
        concurrentConnections: Int = 10,
        compressionEnabled: Bool = false,
        keepAliveEnabled: Bool = true
    ) {
        self.bufferSize = bufferSize
        self.concurrentConnections = concurrentConnections
        self.compressionEnabled = compressionEnabled
        self.keepAliveEnabled = keepAliveEnabled
    }
}

/// 安全设置
public struct SecuritySettings {
    public let tlsEnabled: Bool
    public let certificateValidationEnabled: Bool
    public let allowSelfSignedCertificates: Bool
    public let minimumTLSVersion: String
    
    public init(
        tlsEnabled: Bool = true,
        certificateValidationEnabled: Bool = true,
        allowSelfSignedCertificates: Bool = false,
        minimumTLSVersion: String = "1.2"
    ) {
        self.tlsEnabled = tlsEnabled
        self.certificateValidationEnabled = certificateValidationEnabled
        self.allowSelfSignedCertificates = allowSelfSignedCertificates
        self.minimumTLSVersion = minimumTLSVersion
    }
}

// MARK: - Default Implementations

public extension ConnectionStrategy {
    
    func estimateConnectionTime(with parameters: ConnectionParameters, context: ConnectionContext) -> TimeInterval {
        // 基于历史连接数据估算
        let recentAttempts = context.connectionHistory.prefix(5)
        let successfulAttempts = recentAttempts.filter { $0.result == .success }
        
        if !successfulAttempts.isEmpty {
            let averageDuration = successfulAttempts.reduce(0) { $0 + $1.duration } / Double(successfulAttempts.count)
            return averageDuration
        }
        
        // 默认估算时间
        return 10.0
    }
    
    func reset() {
        // 默认实现：无操作
    }
}