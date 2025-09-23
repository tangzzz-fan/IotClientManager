//
//  ConnectionModels.swift
//  ConnectivityLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

// MARK: - Connection Models

/// 连接信息
public struct ConnectionInfo: Codable, Hashable {
    /// 连接标识符
    public let connectionId: String
    
    /// 设备标识符
    public let deviceId: String
    
    /// 连接类型
    public let connectionType: String
    
    /// 连接状态
    public var state: ConnectionState
    
    /// 连接参数
    public var parameters: ConnectionParameters
    
    /// 连接质量
    public var quality: ConnectionQuality
    
    /// 连接统计信息
    public var statistics: ConnectionStatistics
    
    /// 创建时间
    public let createdAt: Date
    
    /// 最后更新时间
    public var lastUpdated: Date
    
    /// 最后活跃时间
    public var lastActiveAt: Date?
    
    /// 连接元数据
    public var metadata: [String: Any] {
        get { _metadata }
        set { _metadata = newValue }
    }
    
    private var _metadata: [String: Any] = [:]
    
    public init(
        connectionId: String = UUID().uuidString,
        deviceId: String,
        connectionType: String,
        state: ConnectionState = .disconnected,
        parameters: ConnectionParameters = ConnectionParameters(),
        quality: ConnectionQuality = ConnectionQuality(),
        statistics: ConnectionStatistics = ConnectionStatistics(),
        createdAt: Date = Date(),
        lastUpdated: Date = Date(),
        lastActiveAt: Date? = nil,
        metadata: [String: Any] = [:]
    ) {
        self.connectionId = connectionId
        self.deviceId = deviceId
        self.connectionType = connectionType
        self.state = state
        self.parameters = parameters
        self.quality = quality
        self.statistics = statistics
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
        self.lastActiveAt = lastActiveAt
        self._metadata = metadata
    }
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case connectionId, deviceId, connectionType, state
        case parameters, quality, statistics
        case createdAt, lastUpdated, lastActiveAt
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        connectionId = try container.decode(String.self, forKey: .connectionId)
        deviceId = try container.decode(String.self, forKey: .deviceId)
        connectionType = try container.decode(String.self, forKey: .connectionType)
        state = try container.decode(ConnectionState.self, forKey: .state)
        parameters = try container.decode(ConnectionParameters.self, forKey: .parameters)
        quality = try container.decode(ConnectionQuality.self, forKey: .quality)
        statistics = try container.decode(ConnectionStatistics.self, forKey: .statistics)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        lastActiveAt = try container.decodeIfPresent(Date.self, forKey: .lastActiveAt)
        _metadata = [:]
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(connectionId, forKey: .connectionId)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encode(connectionType, forKey: .connectionType)
        try container.encode(state, forKey: .state)
        try container.encode(parameters, forKey: .parameters)
        try container.encode(quality, forKey: .quality)
        try container.encode(statistics, forKey: .statistics)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        try container.encodeIfPresent(lastActiveAt, forKey: .lastActiveAt)
    }
}

/// 连接参数
public struct ConnectionParameters: Codable, Hashable {
    /// 连接超时时间（秒）
    public var connectionTimeout: TimeInterval
    
    /// 读取超时时间（秒）
    public var readTimeout: TimeInterval
    
    /// 写入超时时间（秒）
    public var writeTimeout: TimeInterval
    
    /// 心跳间隔（秒）
    public var heartbeatInterval: TimeInterval
    
    /// 重连间隔（秒）
    public var reconnectInterval: TimeInterval
    
    /// 最大重连次数
    public var maxReconnectAttempts: Int
    
    /// 是否启用自动重连
    public var autoReconnect: Bool
    
    /// 是否启用心跳
    public var enableHeartbeat: Bool
    
    /// 缓冲区大小
    public var bufferSize: Int
    
    /// 优先级
    public var priority: ConnectionPriority
    
    /// 服务质量
    public var qos: QualityOfService
    
    /// 自定义参数
    public var customParameters: [String: String]
    
    public init(
        connectionTimeout: TimeInterval = 30.0,
        readTimeout: TimeInterval = 10.0,
        writeTimeout: TimeInterval = 10.0,
        heartbeatInterval: TimeInterval = 60.0,
        reconnectInterval: TimeInterval = 5.0,
        maxReconnectAttempts: Int = 3,
        autoReconnect: Bool = true,
        enableHeartbeat: Bool = true,
        bufferSize: Int = 8192,
        priority: ConnectionPriority = .normal,
        qos: QualityOfService = .reliable,
        customParameters: [String: String] = [:]
    ) {
        self.connectionTimeout = connectionTimeout
        self.readTimeout = readTimeout
        self.writeTimeout = writeTimeout
        self.heartbeatInterval = heartbeatInterval
        self.reconnectInterval = reconnectInterval
        self.maxReconnectAttempts = maxReconnectAttempts
        self.autoReconnect = autoReconnect
        self.enableHeartbeat = enableHeartbeat
        self.bufferSize = bufferSize
        self.priority = priority
        self.qos = qos
        self.customParameters = customParameters
    }
}

/// 连接优先级
public enum ConnectionPriority: String, Codable, CaseIterable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case critical = "critical"
    
    public var numericValue: Int {
        switch self {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
}

/// 服务质量
public enum QualityOfService: String, Codable, CaseIterable {
    case bestEffort = "best_effort"
    case reliable = "reliable"
    case realTime = "real_time"
    case guaranteed = "guaranteed"
}

/// 连接质量
public struct ConnectionQuality: Codable, Hashable {
    /// 信号强度（dBm）
    public var signalStrength: Double?
    
    /// 连接稳定性（0-1）
    public var stability: Double
    
    /// 延迟（毫秒）
    public var latency: TimeInterval
    
    /// 吞吐量（字节/秒）
    public var throughput: Double
    
    /// 丢包率（0-1）
    public var packetLoss: Double
    
    /// 错误率（0-1）
    public var errorRate: Double
    
    /// 质量评分（0-100）
    public var qualityScore: Int {
        let stabilityScore = stability * 30
        let latencyScore = max(0, 30 - (latency / 10)) // 延迟越低分数越高
        let throughputScore = min(20, throughput / 1000) // 吞吐量分数
        let lossScore = max(0, 10 - (packetLoss * 100)) // 丢包率越低分数越高
        let errorScore = max(0, 10 - (errorRate * 100)) // 错误率越低分数越高
        
        return Int(stabilityScore + latencyScore + throughputScore + lossScore + errorScore)
    }
    
    /// 质量等级
    public var qualityLevel: QualityLevel {
        switch qualityScore {
        case 80...100: return .excellent
        case 60..<80: return .good
        case 40..<60: return .fair
        case 20..<40: return .poor
        default: return .bad
        }
    }
    
    public init(
        signalStrength: Double? = nil,
        stability: Double = 1.0,
        latency: TimeInterval = 0,
        throughput: Double = 0,
        packetLoss: Double = 0,
        errorRate: Double = 0
    ) {
        self.signalStrength = signalStrength
        self.stability = max(0, min(1, stability))
        self.latency = max(0, latency)
        self.throughput = max(0, throughput)
        self.packetLoss = max(0, min(1, packetLoss))
        self.errorRate = max(0, min(1, errorRate))
    }
}

/// 质量等级
public enum QualityLevel: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case bad = "bad"
    
    public var localizedDescription: String {
        switch self {
        case .excellent: return "优秀"
        case .good: return "良好"
        case .fair: return "一般"
        case .poor: return "较差"
        case .bad: return "很差"
        }
    }
}

/// 连接统计信息
public struct ConnectionStatistics: Codable, Hashable {
    /// 连接次数
    public var connectionCount: Int
    
    /// 成功连接次数
    public var successfulConnections: Int
    
    /// 失败连接次数
    public var failedConnections: Int
    
    /// 断开连接次数
    public var disconnectionCount: Int
    
    /// 重连次数
    public var reconnectionCount: Int
    
    /// 发送的消息数量
    public var messagesSent: Int
    
    /// 接收的消息数量
    public var messagesReceived: Int
    
    /// 发送的字节数
    public var bytesSent: Int64
    
    /// 接收的字节数
    public var bytesReceived: Int64
    
    /// 错误次数
    public var errorCount: Int
    
    /// 总连接时间（秒）
    public var totalConnectionTime: TimeInterval
    
    /// 平均连接时间（秒）
    public var averageConnectionTime: TimeInterval {
        guard successfulConnections > 0 else { return 0 }
        return totalConnectionTime / Double(successfulConnections)
    }
    
    /// 连接成功率
    public var connectionSuccessRate: Double {
        guard connectionCount > 0 else { return 0 }
        return Double(successfulConnections) / Double(connectionCount)
    }
    
    /// 消息成功率
    public var messageSuccessRate: Double {
        let totalMessages = messagesSent + messagesReceived
        guard totalMessages > 0 else { return 0 }
        return Double(totalMessages - errorCount) / Double(totalMessages)
    }
    
    /// 最后重置时间
    public var lastResetTime: Date
    
    public init(
        connectionCount: Int = 0,
        successfulConnections: Int = 0,
        failedConnections: Int = 0,
        disconnectionCount: Int = 0,
        reconnectionCount: Int = 0,
        messagesSent: Int = 0,
        messagesReceived: Int = 0,
        bytesSent: Int64 = 0,
        bytesReceived: Int64 = 0,
        errorCount: Int = 0,
        totalConnectionTime: TimeInterval = 0,
        lastResetTime: Date = Date()
    ) {
        self.connectionCount = connectionCount
        self.successfulConnections = successfulConnections
        self.failedConnections = failedConnections
        self.disconnectionCount = disconnectionCount
        self.reconnectionCount = reconnectionCount
        self.messagesSent = messagesSent
        self.messagesReceived = messagesReceived
        self.bytesSent = bytesSent
        self.bytesReceived = bytesReceived
        self.errorCount = errorCount
        self.totalConnectionTime = totalConnectionTime
        self.lastResetTime = lastResetTime
    }
    
    /// 重置统计信息
    public mutating func reset() {
        connectionCount = 0
        successfulConnections = 0
        failedConnections = 0
        disconnectionCount = 0
        reconnectionCount = 0
        messagesSent = 0
        messagesReceived = 0
        bytesSent = 0
        bytesReceived = 0
        errorCount = 0
        totalConnectionTime = 0
        lastResetTime = Date()
    }
    
    /// 更新连接统计
    public mutating func recordConnection(successful: Bool, duration: TimeInterval = 0) {
        connectionCount += 1
        if successful {
            successfulConnections += 1
            totalConnectionTime += duration
        } else {
            failedConnections += 1
        }
    }
    
    /// 更新断开连接统计
    public mutating func recordDisconnection() {
        disconnectionCount += 1
    }
    
    /// 更新重连统计
    public mutating func recordReconnection() {
        reconnectionCount += 1
    }
    
    /// 更新消息统计
    public mutating func recordMessage(sent: Bool, bytes: Int64) {
        if sent {
            messagesSent += 1
            bytesSent += bytes
        } else {
            messagesReceived += 1
            bytesReceived += bytes
        }
    }
    
    /// 更新错误统计
    public mutating func recordError() {
        errorCount += 1
    }
}

// MARK: - Connection Events

/// 连接事件
public enum ConnectionEvent: Hashable {
    case connecting(deviceId: String, connectionType: String)
    case connected(connectionInfo: ConnectionInfo)
    case disconnecting(connectionId: String, reason: DisconnectionReason)
    case disconnected(connectionId: String, reason: DisconnectionReason)
    case reconnecting(connectionId: String, attempt: Int)
    case reconnected(connectionInfo: ConnectionInfo)
    case connectionFailed(deviceId: String, error: ConnectionError)
    case qualityChanged(connectionId: String, quality: ConnectionQuality)
    case statisticsUpdated(connectionId: String, statistics: ConnectionStatistics)
    case parameterUpdated(connectionId: String, parameters: ConnectionParameters)
    case messageReceived(connectionId: String, message: Any)
    case messageSent(connectionId: String, message: Any)
    case error(connectionId: String, error: ConnectionError)
    
    public var connectionId: String? {
        switch self {
        case .connecting(let deviceId, _):
            return deviceId
        case .connected(let info):
            return info.connectionId
        case .disconnecting(let id, _),
             .disconnected(let id, _),
             .reconnecting(let id, _),
             .qualityChanged(let id, _),
             .statisticsUpdated(let id, _),
             .parameterUpdated(let id, _),
             .messageReceived(let id, _),
             .messageSent(let id, _),
             .error(let id, _):
            return id
        case .reconnected(let info):
            return info.connectionId
        case .connectionFailed(let deviceId, _):
            return deviceId
        }
    }
    
    public var eventType: String {
        switch self {
        case .connecting: return "connecting"
        case .connected: return "connected"
        case .disconnecting: return "disconnecting"
        case .disconnected: return "disconnected"
        case .reconnecting: return "reconnecting"
        case .reconnected: return "reconnected"
        case .connectionFailed: return "connection_failed"
        case .qualityChanged: return "quality_changed"
        case .statisticsUpdated: return "statistics_updated"
        case .parameterUpdated: return "parameter_updated"
        case .messageReceived: return "message_received"
        case .messageSent: return "message_sent"
        case .error: return "error"
        }
    }
}

/// 连接错误
public enum ConnectionError: Error, LocalizedError, Hashable {
    case timeout
    case authenticationFailed
    case networkUnavailable
    case deviceNotFound
    case deviceBusy
    case protocolError(String)
    case configurationError(String)
    case resourceUnavailable(String)
    case permissionDenied
    case unsupportedOperation(String)
    case invalidState(String)
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .timeout:
            return "连接超时"
        case .authenticationFailed:
            return "认证失败"
        case .networkUnavailable:
            return "网络不可用"
        case .deviceNotFound:
            return "设备未找到"
        case .deviceBusy:
            return "设备忙碌"
        case .protocolError(let message):
            return "协议错误: \(message)"
        case .configurationError(let message):
            return "配置错误: \(message)"
        case .resourceUnavailable(let message):
            return "资源不可用: \(message)"
        case .permissionDenied:
            return "权限被拒绝"
        case .unsupportedOperation(let operation):
            return "不支持的操作: \(operation)"
        case .invalidState(let state):
            return "无效状态: \(state)"
        case .unknown(let message):
            return "未知错误: \(message)"
        }
    }
    
    public var errorCode: Int {
        switch self {
        case .timeout: return 1001
        case .authenticationFailed: return 1002
        case .networkUnavailable: return 1003
        case .deviceNotFound: return 1004
        case .deviceBusy: return 1005
        case .protocolError: return 1006
        case .configurationError: return 1007
        case .resourceUnavailable: return 1008
        case .permissionDenied: return 1009
        case .unsupportedOperation: return 1010
        case .invalidState: return 1011
        case .unknown: return 1999
        }
    }
}

/// 断开连接原因
public enum DisconnectionReason: String, Codable, CaseIterable {
    case userRequested = "user_requested"
    case timeout = "timeout"
    case networkError = "network_error"
    case deviceError = "device_error"
    case protocolError = "protocol_error"
    case authenticationError = "authentication_error"
    case resourceExhausted = "resource_exhausted"
    case systemShutdown = "system_shutdown"
    case unknown = "unknown"
    
    public var localizedDescription: String {
        switch self {
        case .userRequested: return "用户请求断开"
        case .timeout: return "连接超时"
        case .networkError: return "网络错误"
        case .deviceError: return "设备错误"
        case .protocolError: return "协议错误"
        case .authenticationError: return "认证错误"
        case .resourceExhausted: return "资源耗尽"
        case .systemShutdown: return "系统关闭"
        case .unknown: return "未知原因"
        }
    }
}

// MARK: - Connection Pool Models

/// 连接池配置
public struct ConnectionPoolConfiguration: Codable {
    /// 最大连接数
    public var maxConnections: Int
    
    /// 最小连接数
    public var minConnections: Int
    
    /// 连接空闲超时时间（秒）
    public var idleTimeout: TimeInterval
    
    /// 连接获取超时时间（秒）
    public var acquisitionTimeout: TimeInterval
    
    /// 连接验证间隔（秒）
    public var validationInterval: TimeInterval
    
    /// 是否启用连接验证
    public var enableValidation: Bool
    
    /// 是否启用连接池监控
    public var enableMonitoring: Bool
    
    /// 连接池名称
    public var poolName: String
    
    public init(
        maxConnections: Int = 10,
        minConnections: Int = 1,
        idleTimeout: TimeInterval = 300,
        acquisitionTimeout: TimeInterval = 30,
        validationInterval: TimeInterval = 60,
        enableValidation: Bool = true,
        enableMonitoring: Bool = true,
        poolName: String = "default-pool"
    ) {
        self.maxConnections = max(1, maxConnections)
        self.minConnections = max(0, min(minConnections, maxConnections))
        self.idleTimeout = max(0, idleTimeout)
        self.acquisitionTimeout = max(0, acquisitionTimeout)
        self.validationInterval = max(0, validationInterval)
        self.enableValidation = enableValidation
        self.enableMonitoring = enableMonitoring
        self.poolName = poolName
    }
}

/// 连接池统计信息
public struct ConnectionPoolStatistics: Codable {
    /// 活跃连接数
    public let activeConnections: Int
    
    /// 空闲连接数
    public let idleConnections: Int
    
    /// 总连接数
    public let totalConnections: Int
    
    /// 等待连接的请求数
    public let pendingRequests: Int
    
    /// 连接获取总次数
    public let totalAcquisitions: Int
    
    /// 连接获取成功次数
    public let successfulAcquisitions: Int
    
    /// 连接获取失败次数
    public let failedAcquisitions: Int
    
    /// 连接创建总次数
    public let totalCreations: Int
    
    /// 连接销毁总次数
    public let totalDestructions: Int
    
    /// 平均连接获取时间（毫秒）
    public let averageAcquisitionTime: TimeInterval
    
    /// 平均连接使用时间（毫秒）
    public let averageUsageTime: TimeInterval
    
    /// 连接池创建时间
    public let poolCreatedAt: Date
    
    /// 统计信息更新时间
    public let lastUpdated: Date
    
    public init(
        activeConnections: Int = 0,
        idleConnections: Int = 0,
        totalConnections: Int = 0,
        pendingRequests: Int = 0,
        totalAcquisitions: Int = 0,
        successfulAcquisitions: Int = 0,
        failedAcquisitions: Int = 0,
        totalCreations: Int = 0,
        totalDestructions: Int = 0,
        averageAcquisitionTime: TimeInterval = 0,
        averageUsageTime: TimeInterval = 0,
        poolCreatedAt: Date = Date(),
        lastUpdated: Date = Date()
    ) {
        self.activeConnections = activeConnections
        self.idleConnections = idleConnections
        self.totalConnections = totalConnections
        self.pendingRequests = pendingRequests
        self.totalAcquisitions = totalAcquisitions
        self.successfulAcquisitions = successfulAcquisitions
        self.failedAcquisitions = failedAcquisitions
        self.totalCreations = totalCreations
        self.totalDestructions = totalDestructions
        self.averageAcquisitionTime = averageAcquisitionTime
        self.averageUsageTime = averageUsageTime
        self.poolCreatedAt = poolCreatedAt
        self.lastUpdated = lastUpdated
    }
    
    /// 连接获取成功率
    public var acquisitionSuccessRate: Double {
        guard totalAcquisitions > 0 else { return 0 }
        return Double(successfulAcquisitions) / Double(totalAcquisitions)
    }
    
    /// 连接池利用率
    public var utilizationRate: Double {
        guard totalConnections > 0 else { return 0 }
        return Double(activeConnections) / Double(totalConnections)
    }
}