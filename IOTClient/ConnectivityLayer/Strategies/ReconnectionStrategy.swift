//
//  ReconnectionStrategy.swift
//  ConnectivityLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

/// 重连策略参数
public struct ReconnectionParameters {
    /// 目标服务标识符
    public let serviceId: String
    
    /// 原始连接配置
    public let originalConfiguration: Any
    
    /// 断开连接的原因
    public let disconnectionReason: DisconnectionReason
    
    /// 最大重连次数
    public let maxRetries: Int
    
    /// 重连间隔策略
    public let intervalStrategy: ReconnectionIntervalStrategy
    
    /// 是否允许降级连接
    public let allowDegradedConnection: Bool
    
    /// 重连条件
    public let reconnectionConditions: [ReconnectionCondition]
    
    public init(
        serviceId: String,
        originalConfiguration: Any,
        disconnectionReason: DisconnectionReason,
        maxRetries: Int = 5,
        intervalStrategy: ReconnectionIntervalStrategy = .exponentialBackoff(initial: 1.0, multiplier: 2.0, maximum: 60.0),
        allowDegradedConnection: Bool = false,
        reconnectionConditions: [ReconnectionCondition] = []
    ) {
        self.serviceId = serviceId
        self.originalConfiguration = originalConfiguration
        self.disconnectionReason = disconnectionReason
        self.maxRetries = maxRetries
        self.intervalStrategy = intervalStrategy
        self.allowDegradedConnection = allowDegradedConnection
        self.reconnectionConditions = reconnectionConditions
    }
}

/// 重连结果
public struct ReconnectionResult {
    /// 重连是否成功
    public let isSuccessful: Bool
    
    /// 实际重连次数
    public let attemptCount: Int
    
    /// 总重连时间
    public let totalDuration: TimeInterval
    
    /// 最终连接状态
    public let finalConnectionState: ConnectionState
    
    /// 使用的连接配置
    public let usedConfiguration: Any?
    
    /// 重连详情
    public let reconnectionDetails: [ReconnectionAttemptDetail]
    
    /// 错误信息（如果失败）
    public let error: Error?
    
    public init(
        isSuccessful: Bool,
        attemptCount: Int,
        totalDuration: TimeInterval,
        finalConnectionState: ConnectionState,
        usedConfiguration: Any? = nil,
        reconnectionDetails: [ReconnectionAttemptDetail] = [],
        error: Error? = nil
    ) {
        self.isSuccessful = isSuccessful
        self.attemptCount = attemptCount
        self.totalDuration = totalDuration
        self.finalConnectionState = finalConnectionState
        self.usedConfiguration = usedConfiguration
        self.reconnectionDetails = reconnectionDetails
        self.error = error
    }
}

/// 断开连接原因
public enum DisconnectionReason: String, CaseIterable, Codable {
    case networkLost = "networkLost"
    case serverError = "serverError"
    case timeout = "timeout"
    case authenticationFailed = "authenticationFailed"
    case protocolError = "protocolError"
    case userInitiated = "userInitiated"
    case systemShutdown = "systemShutdown"
    case deviceError = "deviceError"
    case unknown = "unknown"
    
    public var displayName: String {
        switch self {
        case .networkLost:
            return "网络丢失"
        case .serverError:
            return "服务器错误"
        case .timeout:
            return "连接超时"
        case .authenticationFailed:
            return "认证失败"
        case .protocolError:
            return "协议错误"
        case .userInitiated:
            return "用户主动断开"
        case .systemShutdown:
            return "系统关闭"
        case .deviceError:
            return "设备错误"
        case .unknown:
            return "未知原因"
        }
    }
    
    /// 是否应该自动重连
    public var shouldAutoReconnect: Bool {
        switch self {
        case .networkLost, .serverError, .timeout, .protocolError, .deviceError, .unknown:
            return true
        case .authenticationFailed, .userInitiated, .systemShutdown:
            return false
        }
    }
}

/// 重连间隔策略
public enum ReconnectionIntervalStrategy {
    case fixed(TimeInterval)
    case linear(initial: TimeInterval, increment: TimeInterval, maximum: TimeInterval)
    case exponentialBackoff(initial: TimeInterval, multiplier: Double, maximum: TimeInterval)
    case fibonacci(initial: TimeInterval, maximum: TimeInterval)
    case custom((Int) -> TimeInterval)
    
    /// 计算指定重连次数的间隔时间
    public func calculateInterval(for attempt: Int) -> TimeInterval {
        switch self {
        case .fixed(let interval):
            return interval
            
        case .linear(let initial, let increment, let maximum):
            let interval = initial + Double(attempt - 1) * increment
            return min(interval, maximum)
            
        case .exponentialBackoff(let initial, let multiplier, let maximum):
            let interval = initial * pow(multiplier, Double(attempt - 1))
            return min(interval, maximum)
            
        case .fibonacci(let initial, let maximum):
            let fibValue = fibonacci(n: attempt)
            let interval = initial * Double(fibValue)
            return min(interval, maximum)
            
        case .custom(let calculator):
            return calculator(attempt)
        }
    }
    
    private func fibonacci(n: Int) -> Int {
        if n <= 1 { return n }
        var a = 0, b = 1
        for _ in 2...n {
            let temp = a + b
            a = b
            b = temp
        }
        return b
    }
}

/// 重连条件
public struct ReconnectionCondition {
    /// 条件名称
    public let name: String
    
    /// 条件检查函数
    public let check: () -> Bool
    
    /// 条件描述
    public let description: String
    
    public init(name: String, description: String, check: @escaping () -> Bool) {
        self.name = name
        self.description = description
        self.check = check
    }
    
    /// 预定义条件：网络可用
    public static var networkAvailable: ReconnectionCondition {
        return ReconnectionCondition(
            name: "networkAvailable",
            description: "网络连接可用"
        ) {
            // 简化的网络检查
            return true // 实际实现中应该检查网络状态
        }
    }
    
    /// 预定义条件：非低电量模式
    public static var notInLowPowerMode: ReconnectionCondition {
        return ReconnectionCondition(
            name: "notInLowPowerMode",
            description: "设备不处于低电量模式"
        ) {
            return !ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }
    
    /// 预定义条件：应用在前台
    public static var appInForeground: ReconnectionCondition {
        return ReconnectionCondition(
            name: "appInForeground",
            description: "应用在前台运行"
        ) {
            // 实际实现中应该检查应用状态
            return true
        }
    }
}

/// 重连尝试详情
public struct ReconnectionAttemptDetail {
    /// 尝试序号
    public let attemptNumber: Int
    
    /// 尝试开始时间
    public let startTime: Date
    
    /// 尝试结束时间
    public let endTime: Date
    
    /// 尝试结果
    public let result: ConnectionAttemptResult
    
    /// 使用的配置
    public let configuration: Any?
    
    /// 错误信息
    public let error: Error?
    
    /// 网络状态
    public let networkState: NetworkState
    
    /// 额外信息
    public let metadata: [String: Any]
    
    /// 尝试持续时间
    public var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
    
    public init(
        attemptNumber: Int,
        startTime: Date,
        endTime: Date,
        result: ConnectionAttemptResult,
        configuration: Any? = nil,
        error: Error? = nil,
        networkState: NetworkState = .unknown,
        metadata: [String: Any] = [:]
    ) {
        self.attemptNumber = attemptNumber
        self.startTime = startTime
        self.endTime = endTime
        self.result = result
        self.configuration = configuration
        self.error = error
        self.networkState = networkState
        self.metadata = metadata
    }
}

/// 网络状态
public enum NetworkState: String, CaseIterable, Codable {
    case connected = "connected"
    case disconnected = "disconnected"
    case connecting = "connecting"
    case unstable = "unstable"
    case unknown = "unknown"
    
    public var displayName: String {
        switch self {
        case .connected:
            return "已连接"
        case .disconnected:
            return "已断开"
        case .connecting:
            return "连接中"
        case .unstable:
            return "不稳定"
        case .unknown:
            return "未知"
        }
    }
}

/// 连接状态（从CommunicationService导入）
public enum ConnectionState: String, CaseIterable, Codable {
    case disconnected = "disconnected"
    case connecting = "connecting"
    case connected = "connected"
    case reconnecting = "reconnecting"
    case failed = "failed"
    
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
        }
    }
}

/// 重连策略实现
public final class ReconnectionStrategy: ConnectionStrategy {
    
    // MARK: - ConnectionStrategy Properties
    
    public let strategyId: String = "reconnection-strategy"
    public let strategyName: String = "自动重连策略"
    public let strategyDescription: String = "提供智能的自动重连功能，支持多种重连间隔策略和条件检查"
    public let supportedProtocols: Set<String> = ["MQTT", "BLE", "Zigbee", "Matter", "HTTP", "WebSocket"]
    public let priority: Int = 100 // 中等优先级
    public var isEnabled: Bool = true
    
    public typealias ConnectionParameters = ReconnectionParameters
    public typealias ConnectionResult = ReconnectionResult
    
    // MARK: - Private Properties
    
    private var configuration: ConnectionStrategyConfiguration
    private var activeReconnections = [String: ReconnectionSession]()
    private let reconnectionQueue = DispatchQueue(label: "reconnection-strategy", qos: .utility)
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(configuration: ConnectionStrategyConfiguration = ConnectionStrategyConfiguration()) {
        self.configuration = configuration
    }
    
    // MARK: - ConnectionStrategy Implementation
    
    public func executeConnection(
        with parameters: ReconnectionParameters,
        context: ConnectionContext
    ) -> AnyPublisher<ReconnectionResult, ConnectionStrategyError> {
        
        guard isEnabled else {
            return Fail(error: ConnectionStrategyError.strategyDisabled("重连策略已禁用"))
                .eraseToAnyPublisher()
        }
        
        // 验证参数
        let validationResult = validateParameters(parameters)
        guard validationResult.isValid else {
            let errorMessage = validationResult.messages.map { $0.message }.joined(separator: ", ")
            return Fail(error: ConnectionStrategyError.invalidParameters(errorMessage))
                .eraseToAnyPublisher()
        }
        
        // 检查是否应该重连
        guard parameters.disconnectionReason.shouldAutoReconnect else {
            return Fail(error: ConnectionStrategyError.connectionFailed("断开原因不支持自动重连: \(parameters.disconnectionReason.displayName)"))
                .eraseToAnyPublisher()
        }
        
        return Future<ReconnectionResult, ConnectionStrategyError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.unknown(NSError(domain: "ReconnectionStrategy", code: -1, userInfo: [NSLocalizedDescriptionKey: "策略实例已释放"]))))
                return
            }
            
            self.reconnectionQueue.async {
                self.performReconnection(parameters: parameters, context: context, promise: promise)
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func validateParameters(_ parameters: ReconnectionParameters) -> ConnectionValidationResult {
        var messages: [ValidationMessage] = []
        var suggestions: [String] = []
        
        // 验证服务ID
        if parameters.serviceId.isEmpty {
            messages.append(ValidationMessage(
                level: .error,
                message: "服务ID不能为空",
                field: "serviceId"
            ))
        }
        
        // 验证最大重连次数
        if parameters.maxRetries < 0 {
            messages.append(ValidationMessage(
                level: .error,
                message: "最大重连次数不能为负数",
                field: "maxRetries"
            ))
        } else if parameters.maxRetries > 20 {
            messages.append(ValidationMessage(
                level: .warning,
                message: "最大重连次数过高，可能影响性能",
                field: "maxRetries"
            ))
            suggestions.append("建议将最大重连次数设置为5-10次")
        }
        
        // 验证重连条件
        if !parameters.reconnectionConditions.isEmpty {
            messages.append(ValidationMessage(
                level: .info,
                message: "已设置\(parameters.reconnectionConditions.count)个重连条件",
                field: "reconnectionConditions"
            ))
        }
        
        let isValid = !messages.contains { $0.level == .error }
        return ConnectionValidationResult(isValid: isValid, messages: messages, suggestions: suggestions)
    }
    
    public func estimateConnectionTime(
        with parameters: ReconnectionParameters,
        context: ConnectionContext
    ) -> TimeInterval {
        
        // 基于重连策略计算总时间
        var totalTime: TimeInterval = 0
        
        for attempt in 1...parameters.maxRetries {
            let interval = parameters.intervalStrategy.calculateInterval(for: attempt)
            totalTime += interval
            
            // 加上每次连接尝试的估算时间
            totalTime += 10.0 // 假设每次连接尝试需要10秒
        }
        
        return totalTime
    }
    
    public func getConfiguration() -> ConnectionStrategyConfiguration {
        return configuration
    }
    
    public func updateConfiguration(_ configuration: ConnectionStrategyConfiguration) {
        self.configuration = configuration
    }
    
    public func reset() {
        activeReconnections.removeAll()
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    
    /// 取消指定服务的重连
    public func cancelReconnection(for serviceId: String) {
        reconnectionQueue.async { [weak self] in
            self?.activeReconnections[serviceId]?.cancel()
            self?.activeReconnections.removeValue(forKey: serviceId)
        }
    }
    
    /// 获取活跃的重连会话
    public func getActiveReconnections() -> [String: ReconnectionSessionInfo] {
        return activeReconnections.mapValues { session in
            ReconnectionSessionInfo(
                serviceId: session.serviceId,
                startTime: session.startTime,
                currentAttempt: session.currentAttempt,
                maxAttempts: session.maxAttempts,
                nextAttemptTime: session.nextAttemptTime,
                state: session.state
            )
        }
    }
}

// MARK: - Private Implementation

private extension ReconnectionStrategy {
    
    func performReconnection(
        parameters: ReconnectionParameters,
        context: ConnectionContext,
        promise: @escaping (Result<ReconnectionResult, ConnectionStrategyError>) -> Void
    ) {
        
        let session = ReconnectionSession(
            serviceId: parameters.serviceId,
            parameters: parameters,
            context: context
        )
        
        activeReconnections[parameters.serviceId] = session
        
        executeReconnectionSession(session: session) { [weak self] result in
            self?.activeReconnections.removeValue(forKey: parameters.serviceId)
            promise(result)
        }
    }
    
    func executeReconnectionSession(
        session: ReconnectionSession,
        completion: @escaping (Result<ReconnectionResult, ConnectionStrategyError>) -> Void
    ) {
        
        session.state = .running
        var attemptDetails: [ReconnectionAttemptDetail] = []
        
        func attemptReconnection(attemptNumber: Int) {
            guard attemptNumber <= session.maxAttempts && !session.isCancelled else {
                let result = ReconnectionResult(
                    isSuccessful: false,
                    attemptCount: attemptNumber - 1,
                    totalDuration: Date().timeIntervalSince(session.startTime),
                    finalConnectionState: .failed,
                    reconnectionDetails: attemptDetails,
                    error: session.isCancelled ? 
                        NSError(domain: "ReconnectionStrategy", code: -2, userInfo: [NSLocalizedDescriptionKey: "重连已取消"]) :
                        NSError(domain: "ReconnectionStrategy", code: -3, userInfo: [NSLocalizedDescriptionKey: "达到最大重连次数"])
                )
                completion(.success(result))
                return
            }
            
            // 检查重连条件
            for condition in session.parameters.reconnectionConditions {
                if !condition.check() {
                    let result = ReconnectionResult(
                        isSuccessful: false,
                        attemptCount: attemptNumber - 1,
                        totalDuration: Date().timeIntervalSince(session.startTime),
                        finalConnectionState: .failed,
                        reconnectionDetails: attemptDetails,
                        error: NSError(domain: "ReconnectionStrategy", code: -4, userInfo: [NSLocalizedDescriptionKey: "重连条件不满足: \(condition.description)"])
                    )
                    completion(.success(result))
                    return
                }
            }
            
            session.currentAttempt = attemptNumber
            let startTime = Date()
            
            // 模拟连接尝试
            simulateConnectionAttempt(session: session) { [weak self] success, error in
                let endTime = Date()
                let result: ConnectionAttemptResult = success ? .success : .failed
                
                let attemptDetail = ReconnectionAttemptDetail(
                    attemptNumber: attemptNumber,
                    startTime: startTime,
                    endTime: endTime,
                    result: result,
                    configuration: session.parameters.originalConfiguration,
                    error: error,
                    networkState: .connected // 简化实现
                )
                
                attemptDetails.append(attemptDetail)
                
                if success {
                    // 重连成功
                    let finalResult = ReconnectionResult(
                        isSuccessful: true,
                        attemptCount: attemptNumber,
                        totalDuration: Date().timeIntervalSince(session.startTime),
                        finalConnectionState: .connected,
                        usedConfiguration: session.parameters.originalConfiguration,
                        reconnectionDetails: attemptDetails
                    )
                    completion(.success(finalResult))
                } else {
                    // 重连失败，计算下次尝试时间
                    let interval = session.parameters.intervalStrategy.calculateInterval(for: attemptNumber + 1)
                    session.nextAttemptTime = Date().addingTimeInterval(interval)
                    
                    // 延迟后进行下次尝试
                    DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                        attemptReconnection(attemptNumber: attemptNumber + 1)
                    }
                }
            }
        }
        
        // 开始第一次重连尝试
        attemptReconnection(attemptNumber: 1)
    }
    
    func simulateConnectionAttempt(
        session: ReconnectionSession,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        // 模拟连接过程
        let delay = Double.random(in: 1.0...3.0)
        let success = Double.random(in: 0...1) > 0.3 // 70%成功率
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if success {
                completion(true, nil)
            } else {
                let error = NSError(
                    domain: "ReconnectionStrategy",
                    code: -5,
                    userInfo: [NSLocalizedDescriptionKey: "模拟连接失败"]
                )
                completion(false, error)
            }
        }
    }
}

// MARK: - Supporting Types

/// 重连会话
private class ReconnectionSession {
    let serviceId: String
    let parameters: ReconnectionParameters
    let context: ConnectionContext
    let startTime: Date
    let maxAttempts: Int
    
    var currentAttempt: Int = 0
    var nextAttemptTime: Date?
    var state: ReconnectionSessionState = .pending
    var isCancelled: Bool = false
    
    init(serviceId: String, parameters: ReconnectionParameters, context: ConnectionContext) {
        self.serviceId = serviceId
        self.parameters = parameters
        self.context = context
        self.startTime = Date()
        self.maxAttempts = parameters.maxRetries
    }
    
    func cancel() {
        isCancelled = true
        state = .cancelled
    }
}

/// 重连会话状态
private enum ReconnectionSessionState {
    case pending
    case running
    case completed
    case cancelled
    case failed
}

/// 重连会话信息（公开）
public struct ReconnectionSessionInfo {
    public let serviceId: String
    public let startTime: Date
    public let currentAttempt: Int
    public let maxAttempts: Int
    public let nextAttemptTime: Date?
    public let state: String
    
    internal init(
        serviceId: String,
        startTime: Date,
        currentAttempt: Int,
        maxAttempts: Int,
        nextAttemptTime: Date?,
        state: ReconnectionSessionState
    ) {
        self.serviceId = serviceId
        self.startTime = startTime
        self.currentAttempt = currentAttempt
        self.maxAttempts = maxAttempts
        self.nextAttemptTime = nextAttemptTime
        self.state = {
            switch state {
            case .pending: return "等待中"
            case .running: return "运行中"
            case .completed: return "已完成"
            case .cancelled: return "已取消"
            case .failed: return "已失败"
            }
        }()
    }
}