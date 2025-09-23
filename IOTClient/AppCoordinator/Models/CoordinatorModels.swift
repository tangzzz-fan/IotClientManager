//
//  CoordinatorModels.swift
//  AppCoordinator
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import UIKit
import Foundation

// MARK: - Coordinator Types

/// 协调器类型
enum CoordinatorType: String, CaseIterable {
    case app = "app"
    case navigation = "navigation"
    case tab = "tab"
    case module = "module"
    case flow = "flow"
    case modal = "modal"
    case split = "split"
    
    var displayName: String {
        switch self {
        case .app: return "应用协调器"
        case .navigation: return "导航协调器"
        case .tab: return "标签页协调器"
        case .module: return "模块协调器"
        case .flow: return "流程协调器"
        case .modal: return "模态协调器"
        case .split: return "分割视图协调器"
        }
    }
}

/// 协调器状态
enum CoordinatorState: String, CaseIterable {
    case idle = "idle"
    case starting = "starting"
    case active = "active"
    case paused = "paused"
    case stopping = "stopping"
    case stopped = "stopped"
    case error = "error"
    
    var displayName: String {
        switch self {
        case .idle: return "空闲"
        case .starting: return "启动中"
        case .active: return "活跃"
        case .paused: return "暂停"
        case .stopping: return "停止中"
        case .stopped: return "已停止"
        case .error: return "错误"
        }
    }
    
    var isActive: Bool {
        return self == .active
    }
    
    var canTransitionTo: [CoordinatorState] {
        switch self {
        case .idle:
            return [.starting]
        case .starting:
            return [.active, .error, .stopped]
        case .active:
            return [.paused, .stopping, .error]
        case .paused:
            return [.active, .stopping, .error]
        case .stopping:
            return [.stopped, .error]
        case .stopped:
            return [.starting]
        case .error:
            return [.starting, .stopped]
        }
    }
}

// MARK: - Module Types

/// 模块类型
enum ModuleType: String, CaseIterable {
    case deviceProvisioning = "device_provisioning"
    case deviceControl = "device_control"
    case deviceManagement = "device_management"
    case userProfile = "user_profile"
    case settings = "settings"
    case analytics = "analytics"
    case notifications = "notifications"
    case security = "security"
    
    var displayName: String {
        switch self {
        case .deviceProvisioning: return "设备配网"
        case .deviceControl: return "设备控制"
        case .deviceManagement: return "设备管理"
        case .userProfile: return "用户资料"
        case .settings: return "设置"
        case .analytics: return "分析"
        case .notifications: return "通知"
        case .security: return "安全"
        }
    }
    
    var iconName: String {
        switch self {
        case .deviceProvisioning: return "plus.circle"
        case .deviceControl: return "slider.horizontal.3"
        case .deviceManagement: return "list.bullet"
        case .userProfile: return "person.circle"
        case .settings: return "gear"
        case .analytics: return "chart.bar"
        case .notifications: return "bell"
        case .security: return "lock.shield"
        }
    }
}

/// 模块状态
enum ModuleState: String, CaseIterable {
    case uninitialized = "uninitialized"
    case initializing = "initializing"
    case initialized = "initialized"
    case configuring = "configuring"
    case configured = "configured"
    case activating = "activating"
    case active = "active"
    case deactivating = "deactivating"
    case inactive = "inactive"
    case error = "error"
    
    var displayName: String {
        switch self {
        case .uninitialized: return "未初始化"
        case .initializing: return "初始化中"
        case .initialized: return "已初始化"
        case .configuring: return "配置中"
        case .configured: return "已配置"
        case .activating: return "激活中"
        case .active: return "活跃"
        case .deactivating: return "停用中"
        case .inactive: return "非活跃"
        case .error: return "错误"
        }
    }
    
    var isActive: Bool {
        return self == .active
    }
}

// MARK: - Flow Types

/// 流程类型
enum FlowType: String, CaseIterable {
    case onboarding = "onboarding"
    case deviceSetup = "device_setup"
    case userRegistration = "user_registration"
    case passwordReset = "password_reset"
    case deviceConfiguration = "device_configuration"
    case troubleshooting = "troubleshooting"
    case dataExport = "data_export"
    case accountDeletion = "account_deletion"
    
    var displayName: String {
        switch self {
        case .onboarding: return "引导流程"
        case .deviceSetup: return "设备设置"
        case .userRegistration: return "用户注册"
        case .passwordReset: return "密码重置"
        case .deviceConfiguration: return "设备配置"
        case .troubleshooting: return "故障排除"
        case .dataExport: return "数据导出"
        case .accountDeletion: return "账户删除"
        }
    }
    
    var estimatedSteps: Int {
        switch self {
        case .onboarding: return 5
        case .deviceSetup: return 7
        case .userRegistration: return 4
        case .passwordReset: return 3
        case .deviceConfiguration: return 6
        case .troubleshooting: return 8
        case .dataExport: return 3
        case .accountDeletion: return 4
        }
    }
}

/// 流程步骤
struct FlowStep: Codable, Equatable {
    let id: String
    let title: String
    let description: String?
    let stepNumber: Int
    let totalSteps: Int
    let isOptional: Bool
    let canSkip: Bool
    let canGoBack: Bool
    let estimatedDuration: TimeInterval?
    let requiredData: [String]?
    let validationRules: [String]?
    
    init(
        id: String,
        title: String,
        description: String? = nil,
        stepNumber: Int,
        totalSteps: Int,
        isOptional: Bool = false,
        canSkip: Bool = false,
        canGoBack: Bool = true,
        estimatedDuration: TimeInterval? = nil,
        requiredData: [String]? = nil,
        validationRules: [String]? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.stepNumber = stepNumber
        self.totalSteps = totalSteps
        self.isOptional = isOptional
        self.canSkip = canSkip
        self.canGoBack = canGoBack
        self.estimatedDuration = estimatedDuration
        self.requiredData = requiredData
        self.validationRules = validationRules
    }
    
    var progress: Double {
        return Double(stepNumber) / Double(totalSteps)
    }
    
    var isFirstStep: Bool {
        return stepNumber == 1
    }
    
    var isLastStep: Bool {
        return stepNumber == totalSteps
    }
}

/// 流程结果
struct FlowResult: Codable {
    let flowType: FlowType
    let isSuccessful: Bool
    let completedSteps: [String]
    let skippedSteps: [String]
    let data: [String: Any]
    let startTime: Date
    let endTime: Date
    let error: String?
    
    private enum CodingKeys: String, CodingKey {
        case flowType, isSuccessful, completedSteps, skippedSteps
        case startTime, endTime, error
    }
    
    init(
        flowType: FlowType,
        isSuccessful: Bool,
        completedSteps: [String] = [],
        skippedSteps: [String] = [],
        data: [String: Any] = [:],
        startTime: Date,
        endTime: Date = Date(),
        error: String? = nil
    ) {
        self.flowType = flowType
        self.isSuccessful = isSuccessful
        self.completedSteps = completedSteps
        self.skippedSteps = skippedSteps
        self.data = data
        self.startTime = startTime
        self.endTime = endTime
        self.error = error
    }
    
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
    
    var completionRate: Double {
        let totalSteps = completedSteps.count + skippedSteps.count
        return totalSteps > 0 ? Double(completedSteps.count) / Double(totalSteps) : 0.0
    }
}

// MARK: - App State

/// 应用状态
enum AppState: String, CaseIterable {
    case launching = "launching"
    case initializing = "initializing"
    case authenticating = "authenticating"
    case ready = "ready"
    case backgrounded = "backgrounded"
    case suspended = "suspended"
    case terminating = "terminating"
    case error = "error"
    
    var displayName: String {
        switch self {
        case .launching: return "启动中"
        case .initializing: return "初始化中"
        case .authenticating: return "认证中"
        case .ready: return "就绪"
        case .backgrounded: return "后台运行"
        case .suspended: return "挂起"
        case .terminating: return "终止中"
        case .error: return "错误"
        }
    }
}

// MARK: - Navigation Models

/// 导航路径
struct NavigationPath: Codable, Equatable {
    let components: [String]
    let parameters: [String: String]?
    let fragment: String?
    
    init(components: [String], parameters: [String: String]? = nil, fragment: String? = nil) {
        self.components = components
        self.parameters = parameters
        self.fragment = fragment
    }
    
    init(path: String) {
        let url = URL(string: path) ?? URL(string: "/")!
        self.components = url.pathComponents.filter { $0 != "/" }
        
        var params: [String: String] = [:]
        if let query = url.query {
            let queryItems = URLComponents(string: "?" + query)?.queryItems ?? []
            for item in queryItems {
                params[item.name] = item.value
            }
        }
        self.parameters = params.isEmpty ? nil : params
        self.fragment = url.fragment
    }
    
    var pathString: String {
        return "/" + components.joined(separator: "/")
    }
    
    var fullPath: String {
        var path = pathString
        
        if let parameters = parameters, !parameters.isEmpty {
            let queryItems = parameters.map { "\($0.key)=\($0.value)" }
            path += "?" + queryItems.joined(separator: "&")
        }
        
        if let fragment = fragment {
            path += "#" + fragment
        }
        
        return path
    }
}

/// 导航历史项
struct NavigationHistoryItem: Codable {
    let id: String
    let path: NavigationPath
    let timestamp: Date
    let coordinatorType: CoordinatorType
    let coordinatorId: String
    let metadata: [String: String]?
    
    init(
        path: NavigationPath,
        coordinatorType: CoordinatorType,
        coordinatorId: String,
        metadata: [String: String]? = nil
    ) {
        self.id = UUID().uuidString
        self.path = path
        self.timestamp = Date()
        self.coordinatorType = coordinatorType
        self.coordinatorId = coordinatorId
        self.metadata = metadata
    }
}

/// 导航请求
struct NavigationRequest {
    let path: NavigationPath
    let animated: Bool
    let source: String?
    let metadata: [String: Any]?
    let timestamp: Date
    
    init(
        path: NavigationPath,
        animated: Bool = true,
        source: String? = nil,
        metadata: [String: Any]? = nil
    ) {
        self.path = path
        self.animated = animated
        self.source = source
        self.metadata = metadata
        self.timestamp = Date()
    }
}

/// 导航拦截结果
enum NavigationInterceptResult {
    case allow
    case deny(reason: String)
    case redirect(to: NavigationPath)
    case modify(request: NavigationRequest)
}

// MARK: - Deep Link Models

/// 深度链接信息
struct DeepLinkInfo {
    let url: URL
    let scheme: String
    let host: String?
    let path: String
    let parameters: [String: String]
    let fragment: String?
    let timestamp: Date
    
    init(url: URL) {
        self.url = url
        self.scheme = url.scheme ?? ""
        self.host = url.host
        self.path = url.path
        
        var params: [String: String] = [:]
        if let query = url.query {
            let queryItems = URLComponents(string: "?" + query)?.queryItems ?? []
            for item in queryItems {
                params[item.name] = item.value ?? ""
            }
        }
        self.parameters = params
        self.fragment = url.fragment
        self.timestamp = Date()
    }
}

/// 深度链接结果
enum DeepLinkResult {
    case handled
    case notHandled
    case error(String)
    case requiresAuthentication
    case requiresPermission(String)
}

// MARK: - Module Configuration

/// 模块配置
struct ModuleConfiguration: Codable {
    let moduleType: ModuleType
    let isEnabled: Bool
    let priority: Int
    let dependencies: [ModuleType]
    let settings: [String: Any]
    let resources: [String: String]?
    let permissions: [String]?
    
    private enum CodingKeys: String, CodingKey {
        case moduleType, isEnabled, priority, dependencies
        case resources, permissions
    }
    
    init(
        moduleType: ModuleType,
        isEnabled: Bool = true,
        priority: Int = 0,
        dependencies: [ModuleType] = [],
        settings: [String: Any] = [:],
        resources: [String: String]? = nil,
        permissions: [String]? = nil
    ) {
        self.moduleType = moduleType
        self.isEnabled = isEnabled
        self.priority = priority
        self.dependencies = dependencies
        self.settings = settings
        self.resources = resources
        self.permissions = permissions
    }
}

// MARK: - Messages

/// 模块消息类型
enum ModuleMessageType: String, CaseIterable {
    case dataUpdate = "data_update"
    case stateChange = "state_change"
    case userAction = "user_action"
    case systemEvent = "system_event"
    case error = "error"
    case notification = "notification"
    case request = "request"
    case response = "response"
}

/// 模块消息
struct ModuleMessage {
    let id: String
    let type: ModuleMessageType
    let sender: ModuleType
    let recipient: ModuleType?
    let payload: [String: Any]
    let timestamp: Date
    let priority: MessagePriority
    let requiresResponse: Bool
    let correlationId: String?
    
    init(
        type: ModuleMessageType,
        sender: ModuleType,
        recipient: ModuleType? = nil,
        payload: [String: Any] = [:],
        priority: MessagePriority = .normal,
        requiresResponse: Bool = false,
        correlationId: String? = nil
    ) {
        self.id = UUID().uuidString
        self.type = type
        self.sender = sender
        self.recipient = recipient
        self.payload = payload
        self.timestamp = Date()
        self.priority = priority
        self.requiresResponse = requiresResponse
        self.correlationId = correlationId
    }
}

/// 协调器消息类型
enum CoordinatorMessageType: String, CaseIterable {
    case navigationRequest = "navigation_request"
    case stateChange = "state_change"
    case dataSync = "data_sync"
    case userInteraction = "user_interaction"
    case systemNotification = "system_notification"
    case error = "error"
    case lifecycle = "lifecycle"
    case configuration = "configuration"
}

/// 协调器消息
struct CoordinatorMessage {
    let id: String
    let type: CoordinatorMessageType
    let sender: String
    let recipient: String?
    let payload: [String: Any]
    let timestamp: Date
    let priority: MessagePriority
    
    init(
        type: CoordinatorMessageType,
        sender: String,
        recipient: String? = nil,
        payload: [String: Any] = [:],
        priority: MessagePriority = .normal
    ) {
        self.id = UUID().uuidString
        self.type = type
        self.sender = sender
        self.recipient = recipient
        self.payload = payload
        self.timestamp = Date()
        self.priority = priority
    }
}

/// 消息优先级
enum MessagePriority: Int, CaseIterable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
    
    var displayName: String {
        switch self {
        case .low: return "低"
        case .normal: return "普通"
        case .high: return "高"
        case .critical: return "紧急"
        }
    }
}

// MARK: - Errors

/// 协调器错误
enum CoordinatorError: Error, LocalizedError {
    case invalidState(current: CoordinatorState, expected: CoordinatorState)
    case invalidTransition(from: CoordinatorState, to: CoordinatorState)
    case childCoordinatorNotFound(identifier: String)
    case parentCoordinatorNotSet
    case navigationControllerNotSet
    case moduleNotInitialized(ModuleType)
    case moduleConfigurationInvalid(ModuleType)
    case deepLinkNotSupported(URL)
    case deepLinkInvalid(URL)
    case flowStepInvalid(FlowStep)
    case flowDataMissing([String])
    case permissionDenied(String)
    case networkError(Error)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidState(let current, let expected):
            return "协调器状态无效：当前状态 \(current.displayName)，期望状态 \(expected.displayName)"
        case .invalidTransition(let from, let to):
            return "协调器状态转换无效：从 \(from.displayName) 到 \(to.displayName)"
        case .childCoordinatorNotFound(let identifier):
            return "未找到子协调器：\(identifier)"
        case .parentCoordinatorNotSet:
            return "父协调器未设置"
        case .navigationControllerNotSet:
            return "导航控制器未设置"
        case .moduleNotInitialized(let moduleType):
            return "模块未初始化：\(moduleType.displayName)"
        case .moduleConfigurationInvalid(let moduleType):
            return "模块配置无效：\(moduleType.displayName)"
        case .deepLinkNotSupported(let url):
            return "不支持的深度链接：\(url.absoluteString)"
        case .deepLinkInvalid(let url):
            return "无效的深度链接：\(url.absoluteString)"
        case .flowStepInvalid(let step):
            return "无效的流程步骤：\(step.title)"
        case .flowDataMissing(let keys):
            return "流程数据缺失：\(keys.joined(separator: ", "))"
        case .permissionDenied(let permission):
            return "权限被拒绝：\(permission)"
        case .networkError(let error):
            return "网络错误：\(error.localizedDescription)"
        case .unknown(let error):
            return "未知错误：\(error.localizedDescription)"
        }
    }
}

// MARK: - Security Models

/// 权限
enum Permission: String, CaseIterable {
    case deviceControl = "device_control"
    case deviceManagement = "device_management"
    case userDataAccess = "user_data_access"
    case systemSettings = "system_settings"
    case networkAccess = "network_access"
    case locationAccess = "location_access"
    case cameraAccess = "camera_access"
    case microphoneAccess = "microphone_access"
    case notificationAccess = "notification_access"
    case analyticsAccess = "analytics_access"
    
    var displayName: String {
        switch self {
        case .deviceControl: return "设备控制"
        case .deviceManagement: return "设备管理"
        case .userDataAccess: return "用户数据访问"
        case .systemSettings: return "系统设置"
        case .networkAccess: return "网络访问"
        case .locationAccess: return "位置访问"
        case .cameraAccess: return "相机访问"
        case .microphoneAccess: return "麦克风访问"
        case .notificationAccess: return "通知访问"
        case .analyticsAccess: return "分析访问"
        }
    }
    
    var description: String {
        switch self {
        case .deviceControl: return "允许控制连接的设备"
        case .deviceManagement: return "允许添加、删除和配置设备"
        case .userDataAccess: return "允许访问用户个人数据"
        case .systemSettings: return "允许修改系统设置"
        case .networkAccess: return "允许访问网络资源"
        case .locationAccess: return "允许访问设备位置信息"
        case .cameraAccess: return "允许访问设备相机"
        case .microphoneAccess: return "允许访问设备麦克风"
        case .notificationAccess: return "允许发送通知"
        case .analyticsAccess: return "允许收集使用分析数据"
        }
    }
}

/// 安全事件
struct SecurityEvent {
    let id: String
    let type: SecurityEventType
    let description: String
    let severity: SecuritySeverity
    let timestamp: Date
    let userId: String?
    let deviceId: String?
    let ipAddress: String?
    let userAgent: String?
    let metadata: [String: Any]?
    
    init(
        type: SecurityEventType,
        description: String,
        severity: SecuritySeverity,
        userId: String? = nil,
        deviceId: String? = nil,
        ipAddress: String? = nil,
        userAgent: String? = nil,
        metadata: [String: Any]? = nil
    ) {
        self.id = UUID().uuidString
        self.type = type
        self.description = description
        self.severity = severity
        self.timestamp = Date()
        self.userId = userId
        self.deviceId = deviceId
        self.ipAddress = ipAddress
        self.userAgent = userAgent
        self.metadata = metadata
    }
}

/// 安全事件类型
enum SecurityEventType: String, CaseIterable {
    case unauthorizedAccess = "unauthorized_access"
    case permissionDenied = "permission_denied"
    case suspiciousActivity = "suspicious_activity"
    case dataExfiltration = "data_exfiltration"
    case maliciousDeepLink = "malicious_deep_link"
    case encryptionFailure = "encryption_failure"
    case authenticationFailure = "authentication_failure"
    case privilegeEscalation = "privilege_escalation"
}

/// 安全严重程度
enum SecuritySeverity: Int, CaseIterable {
    case info = 0
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
    
    var displayName: String {
        switch self {
        case .info: return "信息"
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        case .critical: return "严重"
        }
    }
}