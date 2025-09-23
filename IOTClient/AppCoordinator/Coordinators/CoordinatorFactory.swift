//
//  CoordinatorFactory.swift
//  AppCoordinator
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import UIKit
import Combine

// MARK: - Coordinator Factory Implementation

/// 协调器工厂实现
public final class CoordinatorFactory: CoordinatorFactoryProtocol {
    
    // MARK: - Properties
    
    private let deepLinkHandler: DeepLinkHandlerProtocol
    private let navigationService: NavigationServiceProtocol
    
    // MARK: - Initialization
    
    public init(
        deepLinkHandler: DeepLinkHandlerProtocol,
        navigationService: NavigationServiceProtocol
    ) {
        self.deepLinkHandler = deepLinkHandler
        self.navigationService = navigationService
    }
    
    // MARK: - Coordinator Factory Protocol
    
    public func createAppCoordinator(window: UIWindow) -> AppCoordinatorProtocol {
        return AppCoordinator(
            window: window,
            coordinatorFactory: self,
            deepLinkHandler: deepLinkHandler,
            navigationService: navigationService
        )
    }
    
    public func createNavigationCoordinator(
        identifier: String?,
        navigationController: UINavigationController?
    ) -> NavigationCoordinatorProtocol {
        let navController = navigationController ?? UINavigationController()
        return NavigationCoordinator(
            identifier: identifier,
            navigationController: navController
        )
    }
    
    public func createTabCoordinator(
        identifier: String?,
        navigationController: UINavigationController?
    ) -> TabCoordinatorProtocol {
        let navController = navigationController ?? UINavigationController()
        return TabCoordinator(
            identifier: identifier,
            navigationController: navController
        )
    }
    
    public func createModuleCoordinator(
        type: ModuleType,
        identifier: String?,
        navigationController: UINavigationController?,
        configuration: ModuleConfiguration?
    ) -> ModuleCoordinatorProtocol {
        let navController = navigationController ?? UINavigationController()
        return ModuleCoordinator(
            moduleType: type,
            identifier: identifier,
            navigationController: navController,
            configuration: configuration
        )
    }
    
    public func createFlowCoordinator(
        type: FlowType,
        identifier: String?,
        navigationController: UINavigationController?
    ) -> FlowCoordinatorProtocol {
        let navController = navigationController ?? UINavigationController()
        return FlowCoordinator(
            flowType: type,
            identifier: identifier,
            navigationController: navController
        )
    }
}

// MARK: - Deep Link Handler Implementation

/// 深度链接处理器实现
public final class DeepLinkHandler: DeepLinkHandlerProtocol {
    
    // MARK: - Properties
    
    private var handlers: [String: (URL) -> DeepLinkResult] = [:]
    private let supportedSchemes = ["iotclient", "https"]
    
    // MARK: - Initialization
    
    public init() {
        setupDefaultHandlers()
    }
    
    // MARK: - Deep Link Handler Protocol
    
    public func handleDeepLink(_ url: URL) -> DeepLinkResult {
        print("🔗 Processing deep link: \(url.absoluteString)")
        
        // 验证URL格式
        guard isValidDeepLink(url) else {
            return .error("Invalid deep link format")
        }
        
        // 提取深度链接信息
        let deepLinkInfo = extractDeepLinkInfo(from: url)
        
        // 检查是否需要认证
        if requiresAuthentication(deepLinkInfo) {
            return .requiresAuthentication
        }
        
        // 检查是否需要权限
        if let requiredPermission = getRequiredPermission(deepLinkInfo) {
            return .requiresPermission(requiredPermission)
        }
        
        // 查找对应的处理器
        if let handler = handlers[deepLinkInfo.path] {
            return handler(url)
        }
        
        // 尝试通用处理
        return handleGenericDeepLink(deepLinkInfo)
    }
    
    public func registerHandler(for path: String, handler: @escaping (URL) -> DeepLinkResult) {
        handlers[path] = handler
        print("✅ Registered deep link handler for path: \(path)")
    }
    
    public func unregisterHandler(for path: String) {
        handlers.removeValue(forKey: path)
        print("✅ Unregistered deep link handler for path: \(path)")
    }
    
    public func canHandle(_ url: URL) -> Bool {
        return isValidDeepLink(url)
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultHandlers() {
        // 设备相关
        registerHandler(for: "/device") { url in
            return self.handleDeviceDeepLink(url)
        }
        
        registerHandler(for: "/device/list") { _ in
            return .handled
        }
        
        registerHandler(for: "/device/control") { url in
            return self.handleDeviceControlDeepLink(url)
        }
        
        // 配网相关
        registerHandler(for: "/provisioning") { _ in
            return .handled
        }
        
        registerHandler(for: "/provisioning/start") { _ in
            return .handled
        }
        
        // 设置相关
        registerHandler(for: "/settings") { _ in
            return .handled
        }
        
        registerHandler(for: "/settings/account") { _ in
            return .requiresAuthentication
        }
        
        // 帮助和支持
        registerHandler(for: "/help") { _ in
            return .handled
        }
        
        registerHandler(for: "/support") { _ in
            return .handled
        }
    }
    
    private func isValidDeepLink(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else {
            return false
        }
        
        return supportedSchemes.contains(scheme)
    }
    
    private func extractDeepLinkInfo(from url: URL) -> DeepLinkInfo {
        let path = url.path.isEmpty ? "/" : url.path
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        
        var parameters: [String: String] = [:]
        for item in queryItems {
            parameters[item.name] = item.value
        }
        
        return DeepLinkInfo(
            url: url,
            scheme: url.scheme ?? "",
            host: url.host ?? "",
            path: path,
            parameters: parameters
        )
    }
    
    private func requiresAuthentication(_ info: DeepLinkInfo) -> Bool {
        let authRequiredPaths = [
            "/settings/account",
            "/device/control",
            "/user/profile"
        ]
        
        return authRequiredPaths.contains(info.path)
    }
    
    private func getRequiredPermission(_ info: DeepLinkInfo) -> Permission? {
        switch info.path {
        case "/device/control":
            return Permission(type: "device_control", description: "设备控制权限")
        case "/provisioning/start":
            return Permission(type: "bluetooth", description: "蓝牙权限")
        default:
            return nil
        }
    }
    
    private func handleGenericDeepLink(_ info: DeepLinkInfo) -> DeepLinkResult {
        // 通用深度链接处理逻辑
        if info.path.hasPrefix("/device/") {
            return handleDeviceDeepLink(info.url)
        } else if info.path.hasPrefix("/settings/") {
            return .handled
        } else {
            return .notHandled
        }
    }
    
    private func handleDeviceDeepLink(_ url: URL) -> DeepLinkResult {
        let info = extractDeepLinkInfo(from: url)
        
        if let deviceId = info.parameters["id"] {
            print("📱 Deep link to device: \(deviceId)")
            return .handled
        }
        
        return .handled
    }
    
    private func handleDeviceControlDeepLink(_ url: URL) -> DeepLinkResult {
        let info = extractDeepLinkInfo(from: url)
        
        if let deviceId = info.parameters["deviceId"] {
            print("🎛️ Deep link to device control: \(deviceId)")
            return .handled
        }
        
        return .notHandled
    }
}

// MARK: - Navigation Service Implementation

/// 导航服务实现
public final class NavigationService: NavigationServiceProtocol {
    
    // MARK: - Properties
    
    private weak var rootCoordinator: Coordinator?
    private var navigationStack: [NavigationPath] = []
    private let maxStackSize = 50
    
    private var navigationEventSubject = PassthroughSubject<NavigationRequest, Never>()
    public var navigationEventPublisher: AnyPublisher<NavigationRequest, Never> {
        return navigationEventSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Navigation Service Protocol
    
    public func setRootCoordinator(_ coordinator: Coordinator) {
        rootCoordinator = coordinator
        print("🏠 Set root coordinator: \(coordinator.identifier)")
    }
    
    public func navigate(to path: NavigationPath) {
        guard let rootCoordinator = rootCoordinator else {
            print("❌ No root coordinator set for navigation")
            return
        }
        
        print("🧭 Navigating to: \(path.destination)")
        
        // 添加到导航栈
        addToNavigationStack(path)
        
        // 创建导航请求
        let request = NavigationRequest(
            type: .push,
            animated: path.animated
        )
        
        navigationEventSubject.send(request)
        
        // 执行导航
        performNavigation(path, from: rootCoordinator)
    }
    
    public func goBack() {
        guard !navigationStack.isEmpty else {
            print("⚠️ Navigation stack is empty, cannot go back")
            return
        }
        
        let currentPath = navigationStack.removeLast()
        print("⬅️ Going back from: \(currentPath.destination)")
        
        // 创建导航请求
        let request = NavigationRequest(
            type: .pop,
            animated: true
        )
        
        navigationEventSubject.send(request)
        
        // 执行返回导航
        if let rootCoordinator = rootCoordinator as? NavigationCoordinatorProtocol {
            rootCoordinator.pop(animated: true)
        }
    }
    
    public func popToRoot() {
        guard !navigationStack.isEmpty else {
            print("⚠️ Navigation stack is empty")
            return
        }
        
        navigationStack.removeAll()
        print("🏠 Popping to root")
        
        // 创建导航请求
        let request = NavigationRequest(
            type: .popToRoot,
            animated: true
        )
        
        navigationEventSubject.send(request)
        
        // 执行返回到根
        if let rootCoordinator = rootCoordinator as? NavigationCoordinatorProtocol {
            rootCoordinator.popToRoot(animated: true)
        }
    }
    
    public func getCurrentPath() -> NavigationPath? {
        return navigationStack.last
    }
    
    public func getNavigationStack() -> [NavigationPath] {
        return navigationStack
    }
    
    public func clearNavigationStack() {
        navigationStack.removeAll()
        print("🗑️ Cleared navigation stack")
    }
    
    // MARK: - Private Methods
    
    private func addToNavigationStack(_ path: NavigationPath) {
        navigationStack.append(path)
        
        // 限制栈大小
        if navigationStack.count > maxStackSize {
            navigationStack.removeFirst(navigationStack.count - maxStackSize)
        }
    }
    
    private func performNavigation(_ path: NavigationPath, from coordinator: Coordinator) {
        // 根据目标类型执行不同的导航逻辑
        switch path.destination {
        case "device-list":
            navigateToDeviceList(path, from: coordinator)
        case "device-provisioning":
            navigateToDeviceProvisioning(path, from: coordinator)
        case "device-control":
            navigateToDeviceControl(path, from: coordinator)
        case "settings":
            navigateToSettings(path, from: coordinator)
        default:
            print("⚠️ Unknown navigation destination: \(path.destination)")
        }
    }
    
    private func navigateToDeviceList(_ path: NavigationPath, from coordinator: Coordinator) {
        print("📱 Navigating to device list")
        // 实现设备列表导航逻辑
    }
    
    private func navigateToDeviceProvisioning(_ path: NavigationPath, from coordinator: Coordinator) {
        print("🔧 Navigating to device provisioning")
        // 实现设备配网导航逻辑
    }
    
    private func navigateToDeviceControl(_ path: NavigationPath, from coordinator: Coordinator) {
        print("🎛️ Navigating to device control")
        // 实现设备控制导航逻辑
    }
    
    private func navigateToSettings(_ path: NavigationPath, from coordinator: Coordinator) {
        print("⚙️ Navigating to settings")
        // 实现设置导航逻辑
    }
}

// MARK: - Default Navigation Interceptor

/// 默认导航拦截器
public final class DefaultNavigationInterceptor: NavigationInterceptor {
    
    public let identifier: String
    private let interceptCondition: (NavigationRequest) -> NavigationInterceptResult
    
    public init(
        identifier: String,
        interceptCondition: @escaping (NavigationRequest) -> NavigationInterceptResult
    ) {
        self.identifier = identifier
        self.interceptCondition = interceptCondition
    }
    
    public func shouldIntercept(_ request: NavigationRequest) -> NavigationInterceptResult {
        return interceptCondition(request)
    }
}

// MARK: - Coordinator Communication Hub

/// 协调器通信中心
public final class CoordinatorCommunicationHub: CoordinatorCommunicationProtocol {
    
    // MARK: - Properties
    
    private var subscribers: [String: (CoordinatorMessage) -> Void] = [:]
    private var messageQueue: [CoordinatorMessage] = []
    private let maxQueueSize = 200
    
    private var messageSubject = PassthroughSubject<CoordinatorMessage, Never>()
    public var messagePublisher: AnyPublisher<CoordinatorMessage, Never> {
        return messageSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Coordinator Communication Protocol
    
    public func sendMessage(_ message: CoordinatorMessage) {
        print("📡 Broadcasting coordinator message: \(message.type.rawValue)")
        
        // 添加到消息队列
        addToMessageQueue(message)
        
        // 发布消息
        messageSubject.send(message)
        
        // 通知订阅者
        for (_, handler) in subscribers {
            handler(message)
        }
    }
    
    public func subscribe(
        coordinatorId: String,
        handler: @escaping (CoordinatorMessage) -> Void
    ) {
        subscribers[coordinatorId] = handler
        print("✅ Coordinator \(coordinatorId) subscribed to communication hub")
    }
    
    public func unsubscribe(coordinatorId: String) {
        subscribers.removeValue(forKey: coordinatorId)
        print("✅ Coordinator \(coordinatorId) unsubscribed from communication hub")
    }
    
    public func getMessageHistory() -> [CoordinatorMessage] {
        return messageQueue
    }
    
    public func clearMessageHistory() {
        messageQueue.removeAll()
        print("🗑️ Cleared coordinator message history")
    }
    
    // MARK: - Private Methods
    
    private func addToMessageQueue(_ message: CoordinatorMessage) {
        messageQueue.append(message)
        
        // 限制队列大小
        if messageQueue.count > maxQueueSize {
            messageQueue.removeFirst(messageQueue.count - maxQueueSize)
        }
    }
}

// MARK: - Coordinator Analytics Service

/// 协调器分析服务
public final class CoordinatorAnalyticsService: CoordinatorAnalyticsProtocol {
    
    // MARK: - Properties
    
    private var events: [String: Any] = [:]
    private var metrics: [String: Double] = [:]
    private var userActions: [String: Int] = [:]
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Coordinator Analytics Protocol
    
    public func trackEvent(_ event: String, parameters: [String: Any]) {
        events[event] = parameters
        print("📊 Tracked event: \(event) with parameters: \(parameters)")
    }
    
    public func trackUserAction(_ action: String, coordinatorId: String) {
        let key = "\(coordinatorId)_\(action)"
        userActions[key] = (userActions[key] ?? 0) + 1
        print("👤 Tracked user action: \(action) in coordinator: \(coordinatorId)")
    }
    
    public func trackPerformanceMetric(_ metric: String, value: Double, coordinatorId: String) {
        let key = "\(coordinatorId)_\(metric)"
        metrics[key] = value
        print("⚡ Tracked performance metric: \(metric) = \(value) for coordinator: \(coordinatorId)")
    }
    
    public func getAnalyticsData() -> [String: Any] {
        return [
            "events": events,
            "metrics": metrics,
            "userActions": userActions,
            "timestamp": Date().timeIntervalSince1970
        ]
    }
    
    public func clearAnalyticsData() {
        events.removeAll()
        metrics.removeAll()
        userActions.removeAll()
        print("🗑️ Cleared analytics data")
    }
}

// MARK: - Coordinator Security Service

/// 协调器安全服务
public final class CoordinatorSecurityService: CoordinatorSecurityProtocol {
    
    // MARK: - Properties
    
    private var securityEvents: [SecurityEvent] = []
    private var permissions: [String: Permission] = [:]
    private let maxEventHistory = 1000
    
    // MARK: - Initialization
    
    public init() {
        setupDefaultPermissions()
    }
    
    // MARK: - Coordinator Security Protocol
    
    public func validateAccess(
        coordinatorId: String,
        action: String,
        context: [String: Any]
    ) -> Bool {
        let hasPermission = checkPermission(coordinatorId: coordinatorId, action: action)
        
        // 记录安全事件
        let event = SecurityEvent(
            type: hasPermission ? .accessGranted : .accessDenied,
            coordinatorId: coordinatorId,
            action: action,
            context: context,
            timestamp: Date(),
            severity: hasPermission ? .low : .medium
        )
        
        logSecurityEvent(event)
        
        return hasPermission
    }
    
    public func logSecurityEvent(_ event: SecurityEvent) {
        securityEvents.append(event)
        
        // 限制事件历史大小
        if securityEvents.count > maxEventHistory {
            securityEvents.removeFirst(securityEvents.count - maxEventHistory)
        }
        
        print("🔒 Security event: \(event.type.rawValue) for coordinator \(event.coordinatorId)")
        
        // 如果是高严重性事件，立即处理
        if event.severity == .high {
            handleHighSeverityEvent(event)
        }
    }
    
    public func checkPermission(coordinatorId: String, action: String) -> Bool {
        let permissionKey = "\(coordinatorId)_\(action)"
        return permissions[permissionKey] != nil
    }
    
    public func grantPermission(_ permission: Permission, to coordinatorId: String) {
        let permissionKey = "\(coordinatorId)_\(permission.type)"
        permissions[permissionKey] = permission
        
        let event = SecurityEvent(
            type: .permissionGranted,
            coordinatorId: coordinatorId,
            action: permission.type,
            context: ["permission": permission.description],
            timestamp: Date(),
            severity: .low
        )
        
        logSecurityEvent(event)
    }
    
    public func revokePermission(_ permissionType: String, from coordinatorId: String) {
        let permissionKey = "\(coordinatorId)_\(permissionType)"
        permissions.removeValue(forKey: permissionKey)
        
        let event = SecurityEvent(
            type: .permissionRevoked,
            coordinatorId: coordinatorId,
            action: permissionType,
            context: [:],
            timestamp: Date(),
            severity: .medium
        )
        
        logSecurityEvent(event)
    }
    
    public func getSecurityEvents() -> [SecurityEvent] {
        return securityEvents
    }
    
    public func clearSecurityEvents() {
        securityEvents.removeAll()
        print("🗑️ Cleared security events")
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultPermissions() {
        // 设置默认权限
        let defaultPermissions = [
            Permission(type: "navigation", description: "导航权限"),
            Permission(type: "view_access", description: "视图访问权限"),
            Permission(type: "basic_operations", description: "基础操作权限")
        ]
        
        for permission in defaultPermissions {
            permissions["default_\(permission.type)"] = permission
        }
    }
    
    private func handleHighSeverityEvent(_ event: SecurityEvent) {
        print("🚨 High severity security event detected: \(event.type.rawValue)")
        
        // 可以在这里实现额外的安全措施
        // 例如：通知管理员、暂停协调器、记录详细日志等
    }
}