//
//  CoordinatorProtocols.swift
//  AppCoordinator
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import UIKit
import Combine

// MARK: - Base Coordinator Protocol

/// 基础协调器协议，定义了所有协调器的通用接口
protocol Coordinator: AnyObject {
    /// 协调器的唯一标识符
    var identifier: String { get }
    
    /// 协调器的类型
    var type: CoordinatorType { get }
    
    /// 父协调器
    var parent: Coordinator? { get set }
    
    /// 子协调器列表
    var children: [Coordinator] { get set }
    
    /// 导航控制器
    var navigationController: UINavigationController { get }
    
    /// 协调器状态
    var state: CoordinatorState { get }
    
    /// 协调器状态发布者
    var statePublisher: AnyPublisher<CoordinatorState, Never> { get }
    
    /// 启动协调器
    func start()
    
    /// 停止协调器
    func stop()
    
    /// 添加子协调器
    func addChild(_ coordinator: Coordinator)
    
    /// 移除子协调器
    func removeChild(_ coordinator: Coordinator)
    
    /// 移除所有子协调器
    func removeAllChildren()
    
    /// 处理深度链接
    func handleDeepLink(_ url: URL) -> Bool
    
    /// 处理通知
    func handleNotification(_ notification: [AnyHashable: Any]) -> Bool
    
    /// 协调器完成回调
    var onFinish: ((Coordinator) -> Void)? { get set }
}

// MARK: - App Coordinator Protocol

/// 应用主协调器协议
protocol AppCoordinatorProtocol: Coordinator {
    /// 应用窗口
    var window: UIWindow? { get set }
    
    /// 当前活动的协调器
    var activeCoordinator: Coordinator? { get }
    
    /// 启动应用
    func startApp()
    
    /// 显示启动屏幕
    func showLaunchScreen()
    
    /// 显示主界面
    func showMainInterface()
    
    /// 显示登录界面
    func showLogin()
    
    /// 显示设备配网界面
    func showDeviceProvisioning()
    
    /// 显示设备控制界面
    func showDeviceControl(deviceId: String?)
    
    /// 显示设置界面
    func showSettings()
    
    /// 处理应用状态变化
    func handleAppStateChange(_ state: AppState)
    
    /// 处理用户认证状态变化
    func handleAuthenticationStateChange(_ isAuthenticated: Bool)
}

// MARK: - Navigation Coordinator Protocol

/// 导航协调器协议
protocol NavigationCoordinatorProtocol: Coordinator {
    /// 推入视图控制器
    func push(_ viewController: UIViewController, animated: Bool)
    
    /// 弹出视图控制器
    func pop(animated: Bool)
    
    /// 弹出到根视图控制器
    func popToRoot(animated: Bool)
    
    /// 弹出到指定视图控制器
    func popTo(_ viewController: UIViewController, animated: Bool)
    
    /// 模态展示视图控制器
    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?)
    
    /// 关闭模态视图控制器
    func dismiss(animated: Bool, completion: (() -> Void)?)
    
    /// 设置根视图控制器
    func setRoot(_ viewController: UIViewController, animated: Bool)
    
    /// 替换当前视图控制器
    func replace(with viewController: UIViewController, animated: Bool)
}

// MARK: - Tab Coordinator Protocol

/// 标签页协调器协议
protocol TabCoordinatorProtocol: Coordinator {
    /// 标签页控制器
    var tabBarController: UITabBarController { get }
    
    /// 标签页协调器列表
    var tabCoordinators: [Coordinator] { get set }
    
    /// 当前选中的标签页索引
    var selectedIndex: Int { get set }
    
    /// 选中标签页
    func selectTab(at index: Int)
    
    /// 添加标签页
    func addTab(_ coordinator: Coordinator, at index: Int?)
    
    /// 移除标签页
    func removeTab(at index: Int)
    
    /// 更新标签页徽章
    func updateTabBadge(at index: Int, value: String?)
    
    /// 标签页选择变化回调
    var onTabSelectionChanged: ((Int) -> Void)? { get set }
}

// MARK: - Module Coordinator Protocol

/// 模块协调器协议
protocol ModuleCoordinatorProtocol: Coordinator {
    /// 模块类型
    var moduleType: ModuleType { get }
    
    /// 模块状态
    var moduleState: ModuleState { get }
    
    /// 模块配置
    var configuration: ModuleConfiguration? { get set }
    
    /// 初始化模块
    func initializeModule()
    
    /// 配置模块
    func configureModule(_ configuration: ModuleConfiguration)
    
    /// 激活模块
    func activateModule()
    
    /// 停用模块
    func deactivateModule()
    
    /// 重置模块
    func resetModule()
    
    /// 模块间通信
    func sendMessage(_ message: ModuleMessage, to moduleType: ModuleType)
    
    /// 接收模块消息
    func receiveMessage(_ message: ModuleMessage)
    
    /// 模块状态变化回调
    var onModuleStateChanged: ((ModuleState) -> Void)? { get set }
}

// MARK: - Flow Coordinator Protocol

/// 流程协调器协议
protocol FlowCoordinatorProtocol: Coordinator {
    /// 流程类型
    var flowType: FlowType { get }
    
    /// 当前流程步骤
    var currentStep: FlowStep { get }
    
    /// 流程步骤历史
    var stepHistory: [FlowStep] { get }
    
    /// 流程数据
    var flowData: [String: Any] { get set }
    
    /// 开始流程
    func startFlow()
    
    /// 进入下一步
    func nextStep()
    
    /// 返回上一步
    func previousStep()
    
    /// 跳转到指定步骤
    func goToStep(_ step: FlowStep)
    
    /// 完成流程
    func completeFlow()
    
    /// 取消流程
    func cancelFlow()
    
    /// 重置流程
    func resetFlow()
    
    /// 流程步骤变化回调
    var onStepChanged: ((FlowStep) -> Void)? { get set }
    
    /// 流程完成回调
    var onFlowCompleted: ((FlowResult) -> Void)? { get set }
}

// MARK: - Coordinator Factory Protocol

/// 协调器工厂协议
protocol CoordinatorFactoryProtocol {
    /// 创建应用协调器
    func createAppCoordinator(window: UIWindow) -> AppCoordinatorProtocol
    
    /// 创建导航协调器
    func createNavigationCoordinator(navigationController: UINavigationController) -> NavigationCoordinatorProtocol
    
    /// 创建标签页协调器
    func createTabCoordinator() -> TabCoordinatorProtocol
    
    /// 创建模块协调器
    func createModuleCoordinator(type: ModuleType, navigationController: UINavigationController) -> ModuleCoordinatorProtocol
    
    /// 创建流程协调器
    func createFlowCoordinator(type: FlowType, navigationController: UINavigationController) -> FlowCoordinatorProtocol
}

// MARK: - Coordinator Delegate Protocol

/// 协调器代理协议
protocol CoordinatorDelegate: AnyObject {
    /// 协调器将要启动
    func coordinatorWillStart(_ coordinator: Coordinator)
    
    /// 协调器已经启动
    func coordinatorDidStart(_ coordinator: Coordinator)
    
    /// 协调器将要停止
    func coordinatorWillStop(_ coordinator: Coordinator)
    
    /// 协调器已经停止
    func coordinatorDidStop(_ coordinator: Coordinator)
    
    /// 协调器状态变化
    func coordinator(_ coordinator: Coordinator, didChangeState state: CoordinatorState)
    
    /// 协调器发生错误
    func coordinator(_ coordinator: Coordinator, didEncounterError error: CoordinatorError)
}

// MARK: - Deep Link Handler Protocol

/// 深度链接处理器协议
protocol DeepLinkHandlerProtocol {
    /// 支持的URL方案
    var supportedSchemes: [String] { get }
    
    /// 处理深度链接
    func handleDeepLink(_ url: URL) -> DeepLinkResult
    
    /// 解析深度链接
    func parseDeepLink(_ url: URL) -> DeepLinkInfo?
    
    /// 验证深度链接
    func validateDeepLink(_ url: URL) -> Bool
}

// MARK: - Navigation Service Protocol

/// 导航服务协议
protocol NavigationServiceProtocol {
    /// 当前协调器
    var currentCoordinator: Coordinator? { get }
    
    /// 导航历史
    var navigationHistory: [NavigationHistoryItem] { get }
    
    /// 导航到指定路径
    func navigate(to path: NavigationPath, animated: Bool)
    
    /// 导航到指定URL
    func navigate(to url: URL, animated: Bool)
    
    /// 返回上一页
    func goBack(animated: Bool)
    
    /// 返回到根页面
    func goToRoot(animated: Bool)
    
    /// 清除导航历史
    func clearHistory()
    
    /// 注册导航拦截器
    func registerInterceptor(_ interceptor: NavigationInterceptor)
    
    /// 移除导航拦截器
    func removeInterceptor(_ interceptor: NavigationInterceptor)
}

// MARK: - Navigation Interceptor Protocol

/// 导航拦截器协议
protocol NavigationInterceptor {
    /// 拦截器优先级
    var priority: Int { get }
    
    /// 拦截导航
    func intercept(navigation: NavigationRequest) -> NavigationInterceptResult
}

// MARK: - Coordinator Communication Protocol

/// 协调器通信协议
protocol CoordinatorCommunicationProtocol {
    /// 发送消息
    func sendMessage(_ message: CoordinatorMessage, to coordinator: Coordinator)
    
    /// 广播消息
    func broadcastMessage(_ message: CoordinatorMessage)
    
    /// 订阅消息
    func subscribeToMessages(of type: CoordinatorMessageType) -> AnyPublisher<CoordinatorMessage, Never>
    
    /// 取消订阅
    func unsubscribeFromMessages(of type: CoordinatorMessageType)
}

// MARK: - Coordinator Lifecycle Protocol

/// 协调器生命周期协议
protocol CoordinatorLifecycleProtocol {
    /// 协调器将要启动
    func coordinatorWillStart()
    
    /// 协调器已经启动
    func coordinatorDidStart()
    
    /// 协调器将要进入前台
    func coordinatorWillEnterForeground()
    
    /// 协调器已经进入前台
    func coordinatorDidEnterForeground()
    
    /// 协调器将要进入后台
    func coordinatorWillEnterBackground()
    
    /// 协调器已经进入后台
    func coordinatorDidEnterBackground()
    
    /// 协调器将要停止
    func coordinatorWillStop()
    
    /// 协调器已经停止
    func coordinatorDidStop()
    
    /// 协调器内存警告
    func coordinatorDidReceiveMemoryWarning()
}

// MARK: - Coordinator Analytics Protocol

/// 协调器分析协议
protocol CoordinatorAnalyticsProtocol {
    /// 记录页面访问
    func trackPageView(_ page: String, parameters: [String: Any]?)
    
    /// 记录用户行为
    func trackUserAction(_ action: String, parameters: [String: Any]?)
    
    /// 记录导航事件
    func trackNavigation(from: String, to: String, parameters: [String: Any]?)
    
    /// 记录错误事件
    func trackError(_ error: Error, context: [String: Any]?)
    
    /// 记录性能指标
    func trackPerformance(_ metric: String, value: Double, parameters: [String: Any]?)
}

// MARK: - Coordinator Security Protocol

/// 协调器安全协议
protocol CoordinatorSecurityProtocol {
    /// 验证访问权限
    func validateAccess(to resource: String) -> Bool
    
    /// 检查用户权限
    func checkUserPermission(_ permission: Permission) -> Bool
    
    /// 验证深度链接安全性
    func validateDeepLinkSecurity(_ url: URL) -> Bool
    
    /// 加密敏感数据
    func encryptSensitiveData(_ data: Data) -> Data?
    
    /// 解密敏感数据
    func decryptSensitiveData(_ encryptedData: Data) -> Data?
    
    /// 记录安全事件
    func logSecurityEvent(_ event: SecurityEvent)
}