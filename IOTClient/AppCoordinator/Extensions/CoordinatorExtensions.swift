//
//  CoordinatorExtensions.swift
//  AppCoordinator
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import UIKit
import Combine

// MARK: - UIViewController Extensions

extension UIViewController {
    
    /// 获取关联的协调器
    var coordinator: Coordinator? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.coordinator) as? Coordinator
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.coordinator, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 设置协调器
    func setCoordinator(_ coordinator: Coordinator) {
        self.coordinator = coordinator
    }
    
    /// 获取导航协调器
    var navigationCoordinator: NavigationCoordinatorProtocol? {
        return coordinator as? NavigationCoordinatorProtocol
    }
    
    /// 获取模块协调器
    var moduleCoordinator: ModuleCoordinatorProtocol? {
        return coordinator as? ModuleCoordinatorProtocol
    }
    
    /// 获取流程协调器
    var flowCoordinator: FlowCoordinatorProtocol? {
        return coordinator as? FlowCoordinatorProtocol
    }
    
    /// 安全地执行协调器操作
    func performCoordinatorAction<T>(_ action: (Coordinator) -> T?) -> T? {
        guard let coordinator = coordinator else {
            print("⚠️ No coordinator found for \(type(of: self))")
            return nil
        }
        return action(coordinator)
    }
    
    /// 发送协调器消息
    func sendCoordinatorMessage(_ message: CoordinatorMessage) {
        coordinator?.handleMessage(message)
    }
    
    /// 请求导航
    func requestNavigation(to destination: String, animated: Bool = true, parameters: [String: Any] = [:]) {
        let path = NavigationPath(
            destination: destination,
            animated: animated,
            parameters: parameters
        )
        
        navigationCoordinator?.navigate(to: path)
    }
    
    /// 请求返回
    func requestGoBack(animated: Bool = true) {
        navigationCoordinator?.pop(animated: animated)
    }
    
    /// 请求模态展示
    func requestPresentModal(_ viewController: UIViewController, animated: Bool = true) {
        navigationCoordinator?.presentModal(viewController, animated: animated)
    }
    
    /// 请求关闭模态
    func requestDismissModal(animated: Bool = true) {
        navigationCoordinator?.dismissModal(animated: animated)
    }
}

// MARK: - UINavigationController Extensions

extension UINavigationController {
    
    /// 获取导航协调器
    var navigationCoordinator: NavigationCoordinatorProtocol? {
        return coordinator as? NavigationCoordinatorProtocol
    }
    
    /// 安全推入视图控制器
    func safePush(_ viewController: UIViewController, animated: Bool = true) {
        guard !viewControllers.contains(viewController) else {
            print("⚠️ View controller already in navigation stack")
            return
        }
        
        pushViewController(viewController, animated: animated)
    }
    
    /// 安全弹出视图控制器
    @discardableResult
    func safePop(animated: Bool = true) -> UIViewController? {
        guard viewControllers.count > 1 else {
            print("⚠️ Cannot pop root view controller")
            return nil
        }
        
        return popViewController(animated: animated)
    }
    
    /// 安全弹出到指定视图控制器
    @discardableResult
    func safePop(to viewController: UIViewController, animated: Bool = true) -> [UIViewController]? {
        guard viewControllers.contains(viewController) else {
            print("⚠️ View controller not found in navigation stack")
            return nil
        }
        
        return popToViewController(viewController, animated: animated)
    }
    
    /// 获取导航栈深度
    var stackDepth: Int {
        return viewControllers.count
    }
    
    /// 检查是否可以返回
    var canGoBack: Bool {
        return viewControllers.count > 1
    }
}

// MARK: - UITabBarController Extensions

extension UITabBarController {
    
    /// 获取标签页协调器
    var tabCoordinator: TabCoordinatorProtocol? {
        return coordinator as? TabCoordinatorProtocol
    }
    
    /// 安全设置选中标签页
    func safeSelectTab(at index: Int, animated: Bool = false) {
        guard index >= 0 && index < (viewControllers?.count ?? 0) else {
            print("⚠️ Invalid tab index: \(index)")
            return
        }
        
        selectedIndex = index
    }
    
    /// 安全添加标签页
    func safeAddTab(_ viewController: UIViewController, at index: Int? = nil) {
        var controllers = viewControllers ?? []
        
        if let index = index, index >= 0 && index <= controllers.count {
            controllers.insert(viewController, at: index)
        } else {
            controllers.append(viewController)
        }
        
        viewControllers = controllers
    }
    
    /// 安全移除标签页
    func safeRemoveTab(at index: Int) {
        guard var controllers = viewControllers,
              index >= 0 && index < controllers.count else {
            print("⚠️ Invalid tab index for removal: \(index)")
            return
        }
        
        controllers.remove(at: index)
        viewControllers = controllers
        
        // 调整选中索引
        if selectedIndex >= controllers.count {
            selectedIndex = max(0, controllers.count - 1)
        }
    }
    
    /// 更新标签页徽章
    func updateTabBadge(at index: Int, value: String?) {
        guard let tabBar = tabBar.items,
              index >= 0 && index < tabBar.count else {
            print("⚠️ Invalid tab index for badge update: \(index)")
            return
        }
        
        tabBar[index].badgeValue = value
    }
    
    /// 启用/禁用标签页
    func setTabEnabled(_ enabled: Bool, at index: Int) {
        guard let tabBar = tabBar.items,
              index >= 0 && index < tabBar.count else {
            print("⚠️ Invalid tab index for enable/disable: \(index)")
            return
        }
        
        tabBar[index].isEnabled = enabled
    }
}

// MARK: - Coordinator Extensions

extension Coordinator {
    
    /// 查找子协调器
    func findChildCoordinator<T: Coordinator>(ofType type: T.Type) -> T? {
        return childCoordinators.first { $0 is T } as? T
    }
    
    /// 查找子协调器（通过标识符）
    func findChildCoordinator(withIdentifier identifier: String) -> Coordinator? {
        return childCoordinators.first { $0.identifier == identifier }
    }
    
    /// 移除所有子协调器
    func removeAllChildCoordinators() {
        childCoordinators.forEach { $0.stop() }
        childCoordinators.removeAll()
    }
    
    /// 移除指定类型的子协调器
    func removeChildCoordinators<T: Coordinator>(ofType type: T.Type) {
        let coordinatorsToRemove = childCoordinators.filter { $0 is T }
        coordinatorsToRemove.forEach { coordinator in
            coordinator.stop()
            removeChildCoordinator(coordinator)
        }
    }
    
    /// 获取协调器层级路径
    var hierarchyPath: String {
        var path = identifier
        var current = parent
        
        while let parent = current {
            path = "\(parent.identifier)/\(path)"
            current = parent.parent
        }
        
        return path
    }
    
    /// 获取根协调器
    var rootCoordinator: Coordinator {
        var current: Coordinator = self
        while let parent = current.parent {
            current = parent
        }
        return current
    }
    
    /// 检查是否为根协调器
    var isRootCoordinator: Bool {
        return parent == nil
    }
    
    /// 获取协调器深度
    var depth: Int {
        var depth = 0
        var current = parent
        
        while current != nil {
            depth += 1
            current = current?.parent
        }
        
        return depth
    }
    
    /// 广播消息给所有子协调器
    func broadcastMessage(_ message: CoordinatorMessage) {
        childCoordinators.forEach { $0.handleMessage(message) }
    }
    
    /// 向上传递消息
    func bubbleUpMessage(_ message: CoordinatorMessage) {
        parent?.handleMessage(message)
    }
    
    /// 安全执行操作
    func safeExecute(_ operation: () throws -> Void) {
        do {
            try operation()
        } catch {
            print("❌ Error in coordinator \(identifier): \(error.localizedDescription)")
        }
    }
    
    /// 延迟执行操作
    func delayedExecute(after delay: TimeInterval, operation: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            operation()
        }
    }
}

// MARK: - Publisher Extensions for Coordinators

extension Publisher {
    
    /// 在主队列上接收
    func receiveOnMainQueue() -> Publishers.ReceiveOn<Self, DispatchQueue> {
        return receive(on: DispatchQueue.main)
    }
    
    /// 协调器超时处理
    func coordinatorTimeout(
        _ interval: TimeInterval,
        scheduler: DispatchQueue = .main,
        customError: CoordinatorError? = nil
    ) -> Publishers.Timeout<Self, DispatchQueue> {
        return timeout(.seconds(interval), scheduler: scheduler, customError: { customError })
    }
    
    /// 协调器重试
    func coordinatorRetry(
        _ times: Int,
        delay: TimeInterval = 1.0
    ) -> Publishers.Delay<Publishers.Retry<Self>, DispatchQueue> {
        return retry(times)
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
    }
}

// MARK: - String Extensions for Coordinators

extension String {
    
    /// 生成协调器标识符
    static func generateCoordinatorId(prefix: String = "coordinator") -> String {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let random = Int.random(in: 1000...9999)
        return "\(prefix)_\(timestamp)_\(random)"
    }
    
    /// 验证协调器标识符格式
    var isValidCoordinatorId: Bool {
        let pattern = "^[a-zA-Z][a-zA-Z0-9_-]*$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: count)
        return regex?.firstMatch(in: self, options: [], range: range) != nil
    }
    
    /// 清理协调器标识符
    var cleanCoordinatorId: String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        return components(separatedBy: allowedCharacters.inverted).joined()
    }
}

// MARK: - Date Extensions for Coordinators

extension Date {
    
    /// 协调器时间戳
    var coordinatorTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: self)
    }
    
    /// 检查是否在指定时间间隔内
    func isWithin(_ interval: TimeInterval, of date: Date) -> Bool {
        return abs(timeIntervalSince(date)) <= interval
    }
    
    /// 获取相对时间描述
    var relativeTimeDescription: String {
        let now = Date()
        let interval = now.timeIntervalSince(self)
        
        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分钟前"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)小时前"
        } else {
            let days = Int(interval / 86400)
            return "\(days)天前"
        }
    }
}

// MARK: - Dictionary Extensions for Coordinators

extension Dictionary where Key == String {
    
    /// 安全获取字符串值
    func safeStringValue(for key: String) -> String? {
        return self[key] as? String
    }
    
    /// 安全获取整数值
    func safeIntValue(for key: String) -> Int? {
        if let value = self[key] as? Int {
            return value
        } else if let stringValue = self[key] as? String {
            return Int(stringValue)
        }
        return nil
    }
    
    /// 安全获取布尔值
    func safeBoolValue(for key: String) -> Bool? {
        if let value = self[key] as? Bool {
            return value
        } else if let stringValue = self[key] as? String {
            return Bool(stringValue)
        }
        return nil
    }
    
    /// 合并字典
    func merged(with other: [String: Value]) -> [String: Value] {
        var result = self
        for (key, value) in other {
            result[key] = value
        }
        return result
    }
}

// MARK: - Array Extensions for Coordinators

extension Array where Element: Coordinator {
    
    /// 查找协调器
    func findCoordinator(withIdentifier identifier: String) -> Element? {
        return first { $0.identifier == identifier }
    }
    
    /// 查找协调器（通过类型）
    func findCoordinator<T: Coordinator>(ofType type: T.Type) -> T? {
        return first { $0 is T } as? T
    }
    
    /// 移除协调器
    mutating func removeCoordinator(withIdentifier identifier: String) {
        removeAll { $0.identifier == identifier }
    }
    
    /// 按状态过滤
    func filtered(by state: CoordinatorState) -> [Element] {
        return filter { $0.state == state }
    }
    
    /// 按类型分组
    func grouped<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [T: [Element]] {
        return Dictionary(grouping: self) { $0[keyPath: keyPath] }
    }
}

// MARK: - Error Extensions for Coordinators

extension Error {
    
    /// 转换为协调器错误
    var asCoordinatorError: CoordinatorError {
        if let coordinatorError = self as? CoordinatorError {
            return coordinatorError
        } else {
            return .unknown(self.localizedDescription)
        }
    }
    
    /// 检查是否为网络错误
    var isNetworkError: Bool {
        if let urlError = self as? URLError {
            return urlError.code == .notConnectedToInternet ||
                   urlError.code == .networkConnectionLost ||
                   urlError.code == .timedOut
        }
        return false
    }
    
    /// 检查是否为超时错误
    var isTimeoutError: Bool {
        if let urlError = self as? URLError {
            return urlError.code == .timedOut
        }
        return false
    }
}

// MARK: - Notification Extensions for Coordinators

extension Notification.Name {
    
    // 协调器通知
    static let coordinatorDidStart = Notification.Name("coordinatorDidStart")
    static let coordinatorDidStop = Notification.Name("coordinatorDidStop")
    static let coordinatorStateDidChange = Notification.Name("coordinatorStateDidChange")
    static let coordinatorDidReceiveMessage = Notification.Name("coordinatorDidReceiveMessage")
    
    // 导航通知
    static let navigationDidStart = Notification.Name("navigationDidStart")
    static let navigationDidComplete = Notification.Name("navigationDidComplete")
    static let navigationDidFail = Notification.Name("navigationDidFail")
    
    // 模块通知
    static let moduleDidActivate = Notification.Name("moduleDidActivate")
    static let moduleDidDeactivate = Notification.Name("moduleDidDeactivate")
    static let moduleDidSuspend = Notification.Name("moduleDidSuspend")
    static let moduleDidResume = Notification.Name("moduleDidResume")
    
    // 流程通知
    static let flowDidStart = Notification.Name("flowDidStart")
    static let flowDidComplete = Notification.Name("flowDidComplete")
    static let flowDidCancel = Notification.Name("flowDidCancel")
    static let flowStepDidChange = Notification.Name("flowStepDidChange")
}

// MARK: - Associated Keys

private struct AssociatedKeys {
    static var coordinator = "coordinator"
}

// MARK: - Utility Functions

/// 生成唯一标识符
public func generateUniqueId(prefix: String = "id") -> String {
    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
    let random = Int.random(in: 10000...99999)
    return "\(prefix)_\(timestamp)_\(random)"
}

/// 安全执行主队列操作
public func safeMainQueueExecute(_ operation: @escaping () -> Void) {
    if Thread.isMainThread {
        operation()
    } else {
        DispatchQueue.main.async {
            operation()
        }
    }
}

/// 延迟执行操作
public func delayedExecute(after delay: TimeInterval, operation: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        operation()
    }
}

/// 计算协调器性能指标
public func calculateCoordinatorPerformance(
    startTime: Date,
    endTime: Date = Date()
) -> (duration: TimeInterval, description: String) {
    let duration = endTime.timeIntervalSince(startTime)
    let description: String
    
    if duration < 0.1 {
        description = "极快 (< 0.1s)"
    } else if duration < 0.5 {
        description = "快速 (< 0.5s)"
    } else if duration < 1.0 {
        description = "正常 (< 1.0s)"
    } else if duration < 3.0 {
        description = "较慢 (< 3.0s)"
    } else {
        description = "缓慢 (≥ 3.0s)"
    }
    
    return (duration, description)
}

/// 格式化内存使用量
public func formatMemoryUsage(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB, .useGB]
    formatter.countStyle = .memory
    return formatter.string(fromByteCount: bytes)
}

/// 检查协调器兼容性
public func checkCoordinatorCompatibility(
    _ coordinator: Coordinator,
    with otherCoordinator: Coordinator
) -> Bool {
    // 检查协调器类型兼容性
    let compatibleTypes: [CoordinatorType: [CoordinatorType]] = [
        .app: [.navigation, .tab, .module, .flow],
        .navigation: [.module, .flow],
        .tab: [.navigation, .module],
        .module: [.flow],
        .flow: []
    ]
    
    guard let allowedTypes = compatibleTypes[coordinator.type] else {
        return false
    }
    
    return allowedTypes.contains(otherCoordinator.type)
}

/// 验证协调器配置
public func validateCoordinatorConfiguration(_ coordinator: Coordinator) -> [String] {
    var issues: [String] = []
    
    // 检查标识符
    if coordinator.identifier.isEmpty {
        issues.append("协调器标识符不能为空")
    } else if !coordinator.identifier.isValidCoordinatorId {
        issues.append("协调器标识符格式无效")
    }
    
    // 检查状态
    if coordinator.state == .unknown {
        issues.append("协调器状态未知")
    }
    
    // 检查循环引用
    if hasCircularReference(coordinator) {
        issues.append("检测到循环引用")
    }
    
    return issues
}

/// 检查循环引用
private func hasCircularReference(_ coordinator: Coordinator) -> Bool {
    var visited: Set<String> = []
    
    func checkRecursive(_ current: Coordinator) -> Bool {
        if visited.contains(current.identifier) {
            return true
        }
        
        visited.insert(current.identifier)
        
        for child in current.childCoordinators {
            if checkRecursive(child) {
                return true
            }
        }
        
        visited.remove(current.identifier)
        return false
    }
    
    return checkRecursive(coordinator)
}