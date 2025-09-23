//
//  CommunicationService.swift
//  ConnectivityLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

/// 通信服务协议
/// 定义了所有通信方式的统一接口
public protocol CommunicationService {
    
    // MARK: - Associated Types
    
    /// 连接配置类型
    associatedtype Configuration
    
    /// 消息类型
    associatedtype Message
    
    // MARK: - Properties
    
    /// 服务标识符
    var serviceId: String { get }
    
    /// 服务名称
    var serviceName: String { get }
    
    /// 当前连接状态
    var connectionState: ConnectionState { get }
    
    /// 连接状态发布者
    var connectionStatePublisher: AnyPublisher<ConnectionState, Never> { get }
    
    /// 接收到的消息发布者
    var messagePublisher: AnyPublisher<Message, Never> { get }
    
    /// 错误发布者
    var errorPublisher: AnyPublisher<CommunicationError, Never> { get }
    
    /// 是否支持自动重连
    var supportsAutoReconnect: Bool { get }
    
    /// 最大重连次数
    var maxReconnectAttempts: Int { get set }
    
    /// 重连间隔（秒）
    var reconnectInterval: TimeInterval { get set }
    
    // MARK: - Connection Management
    
    /// 连接到服务
    /// - Parameter configuration: 连接配置
    /// - Returns: 连接结果的发布者
    func connect(with configuration: Configuration) -> AnyPublisher<Void, CommunicationError>
    
    /// 断开连接
    /// - Returns: 断开连接结果的发布者
    func disconnect() -> AnyPublisher<Void, CommunicationError>
    
    /// 重新连接
    /// - Returns: 重连结果的发布者
    func reconnect() -> AnyPublisher<Void, CommunicationError>
    
    /// 检查连接状态
    /// - Returns: 连接检查结果的发布者
    func checkConnection() -> AnyPublisher<Bool, Never>
    
    // MARK: - Message Handling
    
    /// 发送消息
    /// - Parameters:
    ///   - message: 要发送的消息
    ///   - timeout: 超时时间（可选）
    /// - Returns: 发送结果的发布者
    func sendMessage(_ message: Message, timeout: TimeInterval?) -> AnyPublisher<Void, CommunicationError>
    
    /// 发送消息并等待响应
    /// - Parameters:
    ///   - message: 要发送的消息
    ///   - timeout: 超时时间
    /// - Returns: 响应消息的发布者
    func sendMessageWithResponse(_ message: Message, timeout: TimeInterval) -> AnyPublisher<Message, CommunicationError>
    
    /// 订阅特定主题或频道
    /// - Parameter topic: 主题或频道标识
    /// - Returns: 订阅结果的发布者
    func subscribe(to topic: String) -> AnyPublisher<Void, CommunicationError>
    
    /// 取消订阅
    /// - Parameter topic: 主题或频道标识
    /// - Returns: 取消订阅结果的发布者
    func unsubscribe(from topic: String) -> AnyPublisher<Void, CommunicationError>
    
    // MARK: - Configuration
    
    /// 更新服务配置
    /// - Parameter configuration: 新的配置
    /// - Returns: 配置更新结果的发布者
    func updateConfiguration(_ configuration: Configuration) -> AnyPublisher<Void, CommunicationError>
    
    /// 获取当前配置
    /// - Returns: 当前配置
    func getCurrentConfiguration() -> Configuration?
    
    // MARK: - Diagnostics
    
    /// 获取连接诊断信息
    /// - Returns: 诊断信息
    func getDiagnostics() -> ConnectionDiagnostics
    
    /// 获取服务统计信息
    /// - Returns: 统计信息
    func getStatistics() -> ServiceStatistics
    
    /// 重置统计信息
    func resetStatistics()
}

// MARK: - Connection State

/// 连接状态枚举
public enum ConnectionState: String, CaseIterable {
    case disconnected = "disconnected"
    case connecting = "connecting"
    case connected = "connected"
    case reconnecting = "reconnecting"
    case failed = "failed"
    case suspended = "suspended"
    
    /// 状态显示名称
    public var displayName: String {
        switch self {
        case .disconnected:
            return "已断开"
        case .connecting:
            return "连接中"
        case .connected:
            return "已连接"
        case .reconnecting:
            return "重连中"
        case .failed:
            return "连接失败"
        case .suspended:
            return "已暂停"
        }
    }
    
    /// 是否为活跃状态
    public var isActive: Bool {
        return self == .connected
    }
    
    /// 是否为过渡状态
    public var isTransitioning: Bool {
        return self == .connecting || self == .reconnecting
    }
    
    /// 是否可以发送消息
    public var canSendMessage: Bool {
        return self == .connected
    }
}

// MARK: - Communication Error

/// 通信错误类型
public enum CommunicationError: Error, LocalizedError {
    case connectionFailed(String)
    case connectionTimeout
    case connectionLost
    case authenticationFailed(String)
    case invalidConfiguration(String)
    case messageEncodingFailed(String)
    case messageDecodingFailed(String)
    case messageSendFailed(String)
    case subscriptionFailed(String)
    case networkUnavailable
    case serviceUnavailable(String)
    case rateLimitExceeded
    case invalidMessage(String)
    case timeout(String)
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .connectionFailed(let reason):
            return "连接失败: \(reason)"
        case .connectionTimeout:
            return "连接超时"
        case .connectionLost:
            return "连接丢失"
        case .authenticationFailed(let reason):
            return "认证失败: \(reason)"
        case .invalidConfiguration(let reason):
            return "配置无效: \(reason)"
        case .messageEncodingFailed(let reason):
            return "消息编码失败: \(reason)"
        case .messageDecodingFailed(let reason):
            return "消息解码失败: \(reason)"
        case .messageSendFailed(let reason):
            return "消息发送失败: \(reason)"
        case .subscriptionFailed(let reason):
            return "订阅失败: \(reason)"
        case .networkUnavailable:
            return "网络不可用"
        case .serviceUnavailable(let reason):
            return "服务不可用: \(reason)"
        case .rateLimitExceeded:
            return "请求频率超限"
        case .invalidMessage(let reason):
            return "无效消息: \(reason)"
        case .timeout(let operation):
            return "操作超时: \(operation)"
        case .unknown(let error):
            return "未知错误: \(error.localizedDescription)"
        }
    }
    
    /// 错误代码
    public var errorCode: Int {
        switch self {
        case .connectionFailed:
            return 1001
        case .connectionTimeout:
            return 1002
        case .connectionLost:
            return 1003
        case .authenticationFailed:
            return 1004
        case .invalidConfiguration:
            return 1005
        case .messageEncodingFailed:
            return 2001
        case .messageDecodingFailed:
            return 2002
        case .messageSendFailed:
            return 2003
        case .subscriptionFailed:
            return 2004
        case .networkUnavailable:
            return 3001
        case .serviceUnavailable:
            return 3002
        case .rateLimitExceeded:
            return 3003
        case .invalidMessage:
            return 4001
        case .timeout:
            return 5001
        case .unknown:
            return 9999
        }
    }
    
    /// 是否为可重试错误
    public var isRetryable: Bool {
        switch self {
        case .connectionTimeout, .connectionLost, .networkUnavailable, .serviceUnavailable, .timeout:
            return true
        case .connectionFailed, .authenticationFailed, .invalidConfiguration, .messageEncodingFailed, .messageDecodingFailed, .invalidMessage:
            return false
        case .messageSendFailed, .subscriptionFailed, .rateLimitExceeded, .unknown:
            return true
        }
    }
}

// MARK: - Diagnostics

/// 连接诊断信息
public struct ConnectionDiagnostics {
    /// 连接状态
    public let connectionState: ConnectionState
    
    /// 连接时长（秒）
    public let connectionDuration: TimeInterval?
    
    /// 最后连接时间
    public let lastConnectedAt: Date?
    
    /// 最后断开时间
    public let lastDisconnectedAt: Date?
    
    /// 重连次数
    public let reconnectCount: Int
    
    /// 最后错误
    public let lastError: CommunicationError?
    
    /// 网络延迟（毫秒）
    public let latency: Double?
    
    /// 信号强度（如适用）
    public let signalStrength: Int?
    
    /// 额外诊断信息
    public let additionalInfo: [String: Any]
    
    public init(
        connectionState: ConnectionState,
        connectionDuration: TimeInterval? = nil,
        lastConnectedAt: Date? = nil,
        lastDisconnectedAt: Date? = nil,
        reconnectCount: Int = 0,
        lastError: CommunicationError? = nil,
        latency: Double? = nil,
        signalStrength: Int? = nil,
        additionalInfo: [String: Any] = [:]
    ) {
        self.connectionState = connectionState
        self.connectionDuration = connectionDuration
        self.lastConnectedAt = lastConnectedAt
        self.lastDisconnectedAt = lastDisconnectedAt
        self.reconnectCount = reconnectCount
        self.lastError = lastError
        self.latency = latency
        self.signalStrength = signalStrength
        self.additionalInfo = additionalInfo
    }
}

/// 服务统计信息
public struct ServiceStatistics {
    /// 发送消息数量
    public let messagesSent: Int
    
    /// 接收消息数量
    public let messagesReceived: Int
    
    /// 发送字节数
    public let bytesSent: Int64
    
    /// 接收字节数
    public let bytesReceived: Int64
    
    /// 连接次数
    public let connectionAttempts: Int
    
    /// 成功连接次数
    public let successfulConnections: Int
    
    /// 连接失败次数
    public let failedConnections: Int
    
    /// 平均延迟（毫秒）
    public let averageLatency: Double?
    
    /// 统计开始时间
    public let statisticsStartTime: Date
    
    /// 最后更新时间
    public let lastUpdated: Date
    
    public init(
        messagesSent: Int = 0,
        messagesReceived: Int = 0,
        bytesSent: Int64 = 0,
        bytesReceived: Int64 = 0,
        connectionAttempts: Int = 0,
        successfulConnections: Int = 0,
        failedConnections: Int = 0,
        averageLatency: Double? = nil,
        statisticsStartTime: Date = Date(),
        lastUpdated: Date = Date()
    ) {
        self.messagesSent = messagesSent
        self.messagesReceived = messagesReceived
        self.bytesSent = bytesSent
        self.bytesReceived = bytesReceived
        self.connectionAttempts = connectionAttempts
        self.successfulConnections = successfulConnections
        self.failedConnections = failedConnections
        self.averageLatency = averageLatency
        self.statisticsStartTime = statisticsStartTime
        self.lastUpdated = lastUpdated
    }
    
    /// 连接成功率
    public var connectionSuccessRate: Double {
        guard connectionAttempts > 0 else { return 0.0 }
        return Double(successfulConnections) / Double(connectionAttempts)
    }
    
    /// 总消息数
    public var totalMessages: Int {
        return messagesSent + messagesReceived
    }
    
    /// 总字节数
    public var totalBytes: Int64 {
        return bytesSent + bytesReceived
    }
}

// MARK: - Default Implementation

public extension CommunicationService {
    
    /// 默认最大重连次数
    var maxReconnectAttempts: Int {
        get { return 3 }
        set { /* 子类可以重写 */ }
    }
    
    /// 默认重连间隔
    var reconnectInterval: TimeInterval {
        get { return 5.0 }
        set { /* 子类可以重写 */ }
    }
    
    /// 默认支持自动重连
    var supportsAutoReconnect: Bool {
        return true
    }
    
    /// 默认发送消息实现（不等待响应）
    func sendMessage(_ message: Message, timeout: TimeInterval? = nil) -> AnyPublisher<Void, CommunicationError> {
        return sendMessageWithResponse(message, timeout: timeout ?? 30.0)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    /// 默认连接检查实现
    func checkConnection() -> AnyPublisher<Bool, Never> {
        return Just(connectionState.isActive)
            .eraseToAnyPublisher()
    }
    
    /// 默认重置统计信息实现
    func resetStatistics() {
        // 子类可以重写此方法
    }
}