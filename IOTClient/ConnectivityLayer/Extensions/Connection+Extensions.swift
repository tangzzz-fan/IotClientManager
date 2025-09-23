//
//  Connection+Extensions.swift
//  ConnectivityLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

// MARK: - ConnectionInfo Extensions

extension ConnectionInfo {
    
    /// 是否已连接
    public var isConnected: Bool {
        return state == .connected
    }
    
    /// 是否正在连接
    public var isConnecting: Bool {
        return state == .connecting
    }
    
    /// 是否已断开连接
    public var isDisconnected: Bool {
        return state == .disconnected
    }
    
    /// 连接持续时间
    public var connectionDuration: TimeInterval {
        guard let lastActive = lastActiveAt else { return 0 }
        return lastActive.timeIntervalSince(createdAt)
    }
    
    /// 空闲时间
    public var idleTime: TimeInterval {
        guard let lastActive = lastActiveAt else {
            return Date().timeIntervalSince(createdAt)
        }
        return Date().timeIntervalSince(lastActive)
    }
    
    /// 更新最后活跃时间
    public mutating func updateLastActiveTime() {
        lastActiveAt = Date()
        lastUpdated = Date()
    }
    
    /// 更新连接状态
    public mutating func updateState(_ newState: ConnectionState) {
        state = newState
        lastUpdated = Date()
        if newState == .connected || newState == .connecting {
            updateLastActiveTime()
        }
    }
    
    /// 更新连接质量
    public mutating func updateQuality(_ newQuality: ConnectionQuality) {
        quality = newQuality
        lastUpdated = Date()
        updateLastActiveTime()
    }
    
    /// 更新连接参数
    public mutating func updateParameters(_ newParameters: ConnectionParameters) {
        parameters = newParameters
        lastUpdated = Date()
    }
    
    /// 添加元数据
    public mutating func setMetadata(key: String, value: Any) {
        _metadata[key] = value
        lastUpdated = Date()
    }
    
    /// 获取元数据
    public func getMetadata<T>(key: String, as type: T.Type) -> T? {
        return _metadata[key] as? T
    }
    
    /// 移除元数据
    public mutating func removeMetadata(key: String) {
        _metadata.removeValue(forKey: key)
        lastUpdated = Date()
    }
    
    /// 清空元数据
    public mutating func clearMetadata() {
        _metadata.removeAll()
        lastUpdated = Date()
    }
    
    /// 创建连接摘要
    public func createSummary() -> ConnectionSummary {
        return ConnectionSummary(
            connectionId: connectionId,
            deviceId: deviceId,
            connectionType: connectionType,
            state: state,
            qualityLevel: quality.qualityLevel,
            qualityScore: quality.qualityScore,
            connectionDuration: connectionDuration,
            idleTime: idleTime,
            successRate: statistics.connectionSuccessRate,
            lastUpdated: lastUpdated
        )
    }
    
    /// 验证连接信息
    public func validate() -> ValidationResult {
        var issues: [ValidationIssue] = []
        
        // 验证基本信息
        if connectionId.isEmpty {
            issues.append(ValidationIssue(level: .error, message: "连接ID不能为空"))
        }
        
        if deviceId.isEmpty {
            issues.append(ValidationIssue(level: .error, message: "设备ID不能为空"))
        }
        
        if connectionType.isEmpty {
            issues.append(ValidationIssue(level: .error, message: "连接类型不能为空"))
        }
        
        // 验证参数
        if parameters.connectionTimeout <= 0 {
            issues.append(ValidationIssue(level: .warning, message: "连接超时时间应大于0"))
        }
        
        if parameters.maxReconnectAttempts < 0 {
            issues.append(ValidationIssue(level: .warning, message: "最大重连次数不能为负数"))
        }
        
        // 验证质量
        if quality.stability < 0 || quality.stability > 1 {
            issues.append(ValidationIssue(level: .error, message: "连接稳定性应在0-1之间"))
        }
        
        if quality.packetLoss < 0 || quality.packetLoss > 1 {
            issues.append(ValidationIssue(level: .error, message: "丢包率应在0-1之间"))
        }
        
        // 验证时间
        if createdAt > Date() {
            issues.append(ValidationIssue(level: .error, message: "创建时间不能是未来时间"))
        }
        
        if lastUpdated < createdAt {
            issues.append(ValidationIssue(level: .error, message: "最后更新时间不能早于创建时间"))
        }
        
        return ValidationResult(isValid: issues.filter { $0.level == .error }.isEmpty, issues: issues)
    }
}

// MARK: - ConnectionParameters Extensions

extension ConnectionParameters {
    
    /// 创建高性能配置
    public static func highPerformance() -> ConnectionParameters {
        return ConnectionParameters(
            connectionTimeout: 15.0,
            readTimeout: 5.0,
            writeTimeout: 5.0,
            heartbeatInterval: 30.0,
            reconnectInterval: 2.0,
            maxReconnectAttempts: 5,
            autoReconnect: true,
            enableHeartbeat: true,
            bufferSize: 16384,
            priority: .high,
            qos: .realTime
        )
    }
    
    /// 创建低功耗配置
    public static func lowPower() -> ConnectionParameters {
        return ConnectionParameters(
            connectionTimeout: 60.0,
            readTimeout: 30.0,
            writeTimeout: 30.0,
            heartbeatInterval: 300.0,
            reconnectInterval: 10.0,
            maxReconnectAttempts: 2,
            autoReconnect: true,
            enableHeartbeat: false,
            bufferSize: 4096,
            priority: .low,
            qos: .bestEffort
        )
    }
    
    /// 创建可靠性配置
    public static func reliable() -> ConnectionParameters {
        return ConnectionParameters(
            connectionTimeout: 45.0,
            readTimeout: 15.0,
            writeTimeout: 15.0,
            heartbeatInterval: 60.0,
            reconnectInterval: 5.0,
            maxReconnectAttempts: 10,
            autoReconnect: true,
            enableHeartbeat: true,
            bufferSize: 8192,
            priority: .normal,
            qos: .guaranteed
        )
    }
    
    /// 验证参数
    public func validate() -> ValidationResult {
        var issues: [ValidationIssue] = []
        
        if connectionTimeout <= 0 {
            issues.append(ValidationIssue(level: .error, message: "连接超时时间必须大于0"))
        }
        
        if readTimeout <= 0 {
            issues.append(ValidationIssue(level: .error, message: "读取超时时间必须大于0"))
        }
        
        if writeTimeout <= 0 {
            issues.append(ValidationIssue(level: .error, message: "写入超时时间必须大于0"))
        }
        
        if heartbeatInterval <= 0 {
            issues.append(ValidationIssue(level: .error, message: "心跳间隔必须大于0"))
        }
        
        if reconnectInterval <= 0 {
            issues.append(ValidationIssue(level: .error, message: "重连间隔必须大于0"))
        }
        
        if maxReconnectAttempts < 0 {
            issues.append(ValidationIssue(level: .error, message: "最大重连次数不能为负数"))
        }
        
        if bufferSize <= 0 {
            issues.append(ValidationIssue(level: .error, message: "缓冲区大小必须大于0"))
        }
        
        // 警告检查
        if connectionTimeout > 300 {
            issues.append(ValidationIssue(level: .warning, message: "连接超时时间过长，可能影响用户体验"))
        }
        
        if maxReconnectAttempts > 20 {
            issues.append(ValidationIssue(level: .warning, message: "最大重连次数过多，可能消耗过多资源"))
        }
        
        if bufferSize > 65536 {
            issues.append(ValidationIssue(level: .warning, message: "缓冲区大小过大，可能消耗过多内存"))
        }
        
        return ValidationResult(isValid: issues.filter { $0.level == .error }.isEmpty, issues: issues)
    }
    
    /// 优化参数
    public func optimized(for connectionType: String) -> ConnectionParameters {
        var optimized = self
        
        switch connectionType.lowercased() {
        case "ble":
            optimized.connectionTimeout = min(connectionTimeout, 30.0)
            optimized.heartbeatInterval = max(heartbeatInterval, 120.0)
            optimized.bufferSize = min(bufferSize, 4096)
            optimized.qos = .bestEffort
            
        case "mqtt":
            optimized.enableHeartbeat = true
            optimized.heartbeatInterval = max(heartbeatInterval, 60.0)
            optimized.qos = .reliable
            
        case "zigbee":
            optimized.connectionTimeout = min(connectionTimeout, 45.0)
            optimized.maxReconnectAttempts = max(maxReconnectAttempts, 5)
            optimized.qos = .reliable
            
        case "matter":
            optimized.connectionTimeout = min(connectionTimeout, 60.0)
            optimized.qos = .guaranteed
            optimized.priority = .high
            
        default:
            break
        }
        
        return optimized
    }
}

// MARK: - ConnectionQuality Extensions

extension ConnectionQuality {
    
    /// 创建优秀质量
    public static func excellent() -> ConnectionQuality {
        return ConnectionQuality(
            signalStrength: -30.0,
            stability: 0.98,
            latency: 5.0,
            throughput: 10000.0,
            packetLoss: 0.001,
            errorRate: 0.001
        )
    }
    
    /// 创建良好质量
    public static func good() -> ConnectionQuality {
        return ConnectionQuality(
            signalStrength: -50.0,
            stability: 0.90,
            latency: 20.0,
            throughput: 5000.0,
            packetLoss: 0.01,
            errorRate: 0.01
        )
    }
    
    /// 创建一般质量
    public static func fair() -> ConnectionQuality {
        return ConnectionQuality(
            signalStrength: -70.0,
            stability: 0.75,
            latency: 50.0,
            throughput: 1000.0,
            packetLoss: 0.05,
            errorRate: 0.05
        )
    }
    
    /// 创建较差质量
    public static func poor() -> ConnectionQuality {
        return ConnectionQuality(
            signalStrength: -85.0,
            stability: 0.50,
            latency: 100.0,
            throughput: 500.0,
            packetLoss: 0.10,
            errorRate: 0.10
        )
    }
    
    /// 更新质量指标
    public mutating func updateMetrics(
        signalStrength: Double? = nil,
        stability: Double? = nil,
        latency: TimeInterval? = nil,
        throughput: Double? = nil,
        packetLoss: Double? = nil,
        errorRate: Double? = nil
    ) {
        if let strength = signalStrength {
            self.signalStrength = strength
        }
        if let stab = stability {
            self.stability = max(0, min(1, stab))
        }
        if let lat = latency {
            self.latency = max(0, lat)
        }
        if let through = throughput {
            self.throughput = max(0, through)
        }
        if let loss = packetLoss {
            self.packetLoss = max(0, min(1, loss))
        }
        if let error = errorRate {
            self.errorRate = max(0, min(1, error))
        }
    }
    
    /// 质量趋势分析
    public func compareTo(_ other: ConnectionQuality) -> QualityTrend {
        let scoreDiff = qualityScore - other.qualityScore
        
        if scoreDiff > 10 {
            return .improving
        } else if scoreDiff < -10 {
            return .degrading
        } else {
            return .stable
        }
    }
    
    /// 获取质量建议
    public func getImprovementSuggestions() -> [QualityImprovement] {
        var suggestions: [QualityImprovement] = []
        
        if stability < 0.8 {
            suggestions.append(.improveStability("考虑优化网络环境或设备位置"))
        }
        
        if latency > 100 {
            suggestions.append(.reduceLatency("检查网络延迟或设备响应时间"))
        }
        
        if throughput < 1000 {
            suggestions.append(.increaseThroughput("优化数据传输或网络带宽"))
        }
        
        if packetLoss > 0.05 {
            suggestions.append(.reducePacketLoss("检查网络连接质量"))
        }
        
        if errorRate > 0.05 {
            suggestions.append(.reduceErrors("检查设备状态或协议配置"))
        }
        
        if let strength = signalStrength, strength < -80 {
            suggestions.append(.improveSignal("改善设备位置或信号环境"))
        }
        
        return suggestions
    }
}

// MARK: - ConnectionStatistics Extensions

extension ConnectionStatistics {
    
    /// 创建性能报告
    public func createPerformanceReport() -> PerformanceReport {
        return PerformanceReport(
            connectionSuccessRate: connectionSuccessRate,
            messageSuccessRate: messageSuccessRate,
            averageConnectionTime: averageConnectionTime,
            totalDataTransferred: bytesSent + bytesReceived,
            errorFrequency: Double(errorCount) / Double(max(1, connectionCount)),
            reconnectionFrequency: Double(reconnectionCount) / Double(max(1, connectionCount)),
            reportGeneratedAt: Date()
        )
    }
    
    /// 比较统计信息
    public func compare(with other: ConnectionStatistics) -> StatisticsComparison {
        return StatisticsComparison(
            connectionSuccessRateDiff: connectionSuccessRate - other.connectionSuccessRate,
            messageSuccessRateDiff: messageSuccessRate - other.messageSuccessRate,
            averageConnectionTimeDiff: averageConnectionTime - other.averageConnectionTime,
            errorCountDiff: errorCount - other.errorCount,
            reconnectionCountDiff: reconnectionCount - other.reconnectionCount
        )
    }
    
    /// 获取健康状态
    public var healthStatus: HealthStatus {
        let successRate = connectionSuccessRate
        let errorFrequency = Double(errorCount) / Double(max(1, connectionCount))
        
        if successRate >= 0.95 && errorFrequency <= 0.05 {
            return .healthy
        } else if successRate >= 0.80 && errorFrequency <= 0.15 {
            return .warning
        } else {
            return .critical
        }
    }
    
    /// 获取性能等级
    public var performanceLevel: PerformanceLevel {
        let score = (connectionSuccessRate * 40) + 
                   (messageSuccessRate * 30) + 
                   (averageConnectionTime > 0 ? min(30, 30 / averageConnectionTime) : 0)
        
        switch score {
        case 80...100: return .excellent
        case 60..<80: return .good
        case 40..<60: return .average
        case 20..<40: return .poor
        default: return .bad
        }
    }
}

// MARK: - Supporting Types

/// 连接摘要
public struct ConnectionSummary: Codable {
    public let connectionId: String
    public let deviceId: String
    public let connectionType: String
    public let state: ConnectionState
    public let qualityLevel: QualityLevel
    public let qualityScore: Int
    public let connectionDuration: TimeInterval
    public let idleTime: TimeInterval
    public let successRate: Double
    public let lastUpdated: Date
}

/// 验证结果
public struct ValidationResult {
    public let isValid: Bool
    public let issues: [ValidationIssue]
    
    public var hasErrors: Bool {
        return issues.contains { $0.level == .error }
    }
    
    public var hasWarnings: Bool {
        return issues.contains { $0.level == .warning }
    }
}

/// 验证问题
public struct ValidationIssue {
    public let level: ValidationLevel
    public let message: String
}

/// 验证级别
public enum ValidationLevel {
    case error
    case warning
    case info
}

/// 质量趋势
public enum QualityTrend {
    case improving
    case stable
    case degrading
}

/// 质量改进建议
public enum QualityImprovement {
    case improveStability(String)
    case reduceLatency(String)
    case increaseThroughput(String)
    case reducePacketLoss(String)
    case reduceErrors(String)
    case improveSignal(String)
    
    public var suggestion: String {
        switch self {
        case .improveStability(let msg),
             .reduceLatency(let msg),
             .increaseThroughput(let msg),
             .reducePacketLoss(let msg),
             .reduceErrors(let msg),
             .improveSignal(let msg):
            return msg
        }
    }
}

/// 性能报告
public struct PerformanceReport: Codable {
    public let connectionSuccessRate: Double
    public let messageSuccessRate: Double
    public let averageConnectionTime: TimeInterval
    public let totalDataTransferred: Int64
    public let errorFrequency: Double
    public let reconnectionFrequency: Double
    public let reportGeneratedAt: Date
}

/// 统计信息比较
public struct StatisticsComparison {
    public let connectionSuccessRateDiff: Double
    public let messageSuccessRateDiff: Double
    public let averageConnectionTimeDiff: TimeInterval
    public let errorCountDiff: Int
    public let reconnectionCountDiff: Int
}

/// 健康状态
public enum HealthStatus: String, CaseIterable {
    case healthy = "healthy"
    case warning = "warning"
    case critical = "critical"
    
    public var localizedDescription: String {
        switch self {
        case .healthy: return "健康"
        case .warning: return "警告"
        case .critical: return "严重"
        }
    }
}

/// 性能等级
public enum PerformanceLevel: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case average = "average"
    case poor = "poor"
    case bad = "bad"
    
    public var localizedDescription: String {
        switch self {
        case .excellent: return "优秀"
        case .good: return "良好"
        case .average: return "一般"
        case .poor: return "较差"
        case .bad: return "很差"
        }
    }
}