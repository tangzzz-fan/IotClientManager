//
//  AppCoordinator.swift
//  AppCoordinator
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import UIKit
import Combine

// MARK: - Base Coordinator Implementation

/// 基础协调器实现
open class BaseCoordinator: NSObject, Coordinator {
    
    // MARK: - Properties
    
    public let identifier: String
    public let type: CoordinatorType
    public weak var parent: Coordinator?
    public var children: [Coordinator] = []
    public let navigationController: UINavigationController
    
    private let stateSubject = CurrentValueSubject<CoordinatorState, Never>(.idle)
    public var state: CoordinatorState {
        return stateSubject.value
    }
    
    public var statePublisher: AnyPublisher<CoordinatorState, Never> {
        return stateSubject.eraseToAnyPublisher()
    }
    
    public var onFinish: ((Coordinator) -> Void)?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(
        identifier: String? = nil,
        type: CoordinatorType,
        navigationController: UINavigationController
    ) {
        self.identifier = identifier ?? UUID().uuidString
        self.type = type
        self.navigationController = navigationController
        super.init()
        
        setupStateObservation()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Coordinator Protocol
    
    open func start() {
        guard canTransition(to: .starting) else {
            print("⚠️ Cannot start coordinator \(identifier) from state \(state)")
            return
        }
        
        setState(.starting)
        
        // 子类重写此方法实现具体启动逻辑
        coordinatorWillStart()
        
        // 启动完成后设置为活跃状态
        DispatchQueue.main.async { [weak self] in
            self?.setState(.active)
            self?.coordinatorDidStart()
        }
    }
    
    open func stop() {
        guard canTransition(to: .stopping) else {
            print("⚠️ Cannot stop coordinator \(identifier) from state \(state)")
            return
        }
        
        setState(.stopping)
        coordinatorWillStop()
        
        // 停止所有子协调器
        removeAllChildren()
        
        setState(.stopped)
        coordinatorDidStop()
        
        // 通知父协调器
        onFinish?(self)
    }
    
    public func addChild(_ coordinator: Coordinator) {
        guard !children.contains(where: { $0.identifier == coordinator.identifier }) else {
            print("⚠️ Child coordinator \(coordinator.identifier) already exists")
            return
        }
        
        coordinator.parent = self
        children.append(coordinator)
        
        print("✅ Added child coordinator \(coordinator.identifier) to \(identifier)")
    }
    
    public func removeChild(_ coordinator: Coordinator) {
        children.removeAll { $0.identifier == coordinator.identifier }
        coordinator.parent = nil
        
        print("✅ Removed child coordinator \(coordinator.identifier) from \(identifier)")
    }
    
    public func removeAllChildren() {
        for child in children {
            child.stop()
        }
        children.removeAll()
    }
    
    open func handleDeepLink(_ url: URL) -> Bool {
        // 首先尝试让子协调器处理
        for child in children {
            if child.handleDeepLink(url) {
                return true
            }
        }
        
        // 子类可以重写此方法实现具体的深度链接处理
        return false
    }
    
    open func handleNotification(_ notification: [AnyHashable: Any]) -> Bool {
        // 首先尝试让子协调器处理
        for child in children {
            if child.handleNotification(notification) {
                return true
            }
        }
        
        // 子类可以重写此方法实现具体的通知处理
        return false
    }
    
    // MARK: - State Management
    
    private func setState(_ newState: CoordinatorState) {
        let oldState = state
        guard canTransition(to: newState) else {
            print("⚠️ Invalid state transition from \(oldState) to \(newState) for coordinator \(identifier)")
            return
        }
        
        stateSubject.send(newState)
        print("🔄 Coordinator \(identifier) state changed: \(oldState.displayName) -> \(newState.displayName)")
    }
    
    private func canTransition(to newState: CoordinatorState) -> Bool {
        return state.canTransitionTo.contains(newState)
    }
    
    private func setupStateObservation() {
        statePublisher
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    open func handleStateChange(_ state: CoordinatorState) {
        // 子类可以重写此方法处理状态变化
    }
    
    // MARK: - Lifecycle Methods
    
    open func coordinatorWillStart() {
        // 子类可以重写此方法
    }
    
    open func coordinatorDidStart() {
        // 子类可以重写此方法
    }
    
    open func coordinatorWillStop() {
        // 子类可以重写此方法
    }
    
    open func coordinatorDidStop() {
        // 子类可以重写此方法
    }
}

// MARK: - App Coordinator Implementation

/// 应用主协调器实现
public final class AppCoordinator: BaseCoordinator, AppCoordinatorProtocol {
    
    // MARK: - Properties
    
    public var window: UIWindow?
    public private(set) var activeCoordinator: Coordinator?
    
    private let coordinatorFactory: CoordinatorFactoryProtocol
    private let deepLinkHandler: DeepLinkHandlerProtocol
    private let navigationService: NavigationServiceProtocol
    
    private var appStateSubject = CurrentValueSubject<AppState, Never>(.launching)
    private var isAuthenticatedSubject = CurrentValueSubject<Bool, Never>(false)
    
    // MARK: - Initialization
    
    public init(
        window: UIWindow,
        coordinatorFactory: CoordinatorFactoryProtocol,
        deepLinkHandler: DeepLinkHandlerProtocol,
        navigationService: NavigationServiceProtocol
    ) {
        self.window = window
        self.coordinatorFactory = coordinatorFactory
        self.deepLinkHandler = deepLinkHandler
        self.navigationService = navigationService
        
        let rootNavigationController = UINavigationController()
        super.init(identifier: "app-coordinator", type: .app, navigationController: rootNavigationController)
        
        setupWindow()
        setupObservations()
    }
    
    // MARK: - App Coordinator Protocol
    
    public func startApp() {
        print("🚀 Starting IOTClient App")
        
        appStateSubject.send(.launching)
        showLaunchScreen()
        
        // 模拟启动过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.appStateSubject.send(.initializing)
            self?.initializeApp()
        }
    }
    
    public func showLaunchScreen() {
        let launchViewController = createLaunchViewController()
        navigationController.setViewControllers([launchViewController], animated: false)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
    
    public func showMainInterface() {
        appStateSubject.send(.ready)
        
        let tabCoordinator = coordinatorFactory.createTabCoordinator()
        addChild(tabCoordinator)
        activeCoordinator = tabCoordinator
        
        navigationController.setViewControllers([tabCoordinator.navigationController], animated: true)
        tabCoordinator.start()
    }
    
    public func showLogin() {
        appStateSubject.send(.authenticating)
        
        let loginViewController = createLoginViewController()
        let loginNavigationController = UINavigationController(rootViewController: loginViewController)
        
        navigationController.present(loginNavigationController, animated: true)
    }
    
    public func showDeviceProvisioning() {
        let provisioningCoordinator = coordinatorFactory.createFlowCoordinator(
            type: .deviceSetup,
            navigationController: UINavigationController()
        )
        
        addChild(provisioningCoordinator)
        activeCoordinator = provisioningCoordinator
        
        navigationController.present(provisioningCoordinator.navigationController, animated: true)
        provisioningCoordinator.start()
        
        // 设置完成回调
        provisioningCoordinator.onFinish = { [weak self] coordinator in
            self?.removeChild(coordinator)
            self?.navigationController.dismiss(animated: true)
            self?.activeCoordinator = nil
        }
    }
    
    public func showDeviceControl(deviceId: String?) {
        let deviceControlCoordinator = coordinatorFactory.createModuleCoordinator(
            type: .deviceControl,
            navigationController: UINavigationController()
        )
        
        addChild(deviceControlCoordinator)
        activeCoordinator = deviceControlCoordinator
        
        // 如果指定了设备ID，传递给协调器
        if let deviceId = deviceId {
            // 这里可以通过消息系统或配置传递设备ID
            print("📱 Opening device control for device: \(deviceId)")
        }
        
        navigationController.present(deviceControlCoordinator.navigationController, animated: true)
        deviceControlCoordinator.start()
        
        // 设置完成回调
        deviceControlCoordinator.onFinish = { [weak self] coordinator in
            self?.removeChild(coordinator)
            self?.navigationController.dismiss(animated: true)
            self?.activeCoordinator = nil
        }
    }
    
    public func showSettings() {
        let settingsCoordinator = coordinatorFactory.createModuleCoordinator(
            type: .settings,
            navigationController: UINavigationController()
        )
        
        addChild(settingsCoordinator)
        
        navigationController.present(settingsCoordinator.navigationController, animated: true)
        settingsCoordinator.start()
        
        // 设置完成回调
        settingsCoordinator.onFinish = { [weak self] coordinator in
            self?.removeChild(coordinator)
            self?.navigationController.dismiss(animated: true)
        }
    }
    
    public func handleAppStateChange(_ state: AppState) {
        appStateSubject.send(state)
        
        switch state {
        case .launching:
            showLaunchScreen()
        case .initializing:
            initializeApp()
        case .authenticating:
            showLogin()
        case .ready:
            showMainInterface()
        case .backgrounded:
            handleAppDidEnterBackground()
        case .suspended:
            handleAppWillSuspend()
        case .terminating:
            handleAppWillTerminate()
        case .error:
            handleAppError()
        }
    }
    
    public func handleAuthenticationStateChange(_ isAuthenticated: Bool) {
        isAuthenticatedSubject.send(isAuthenticated)
        
        if isAuthenticated {
            showMainInterface()
        } else {
            showLogin()
        }
    }
    
    // MARK: - Deep Link Handling
    
    public override func handleDeepLink(_ url: URL) -> Bool {
        print("🔗 Handling deep link: \(url.absoluteString)")
        
        // 首先让深度链接处理器处理
        let result = deepLinkHandler.handleDeepLink(url)
        
        switch result {
        case .handled:
            return true
        case .notHandled:
            // 尝试让子协调器处理
            return super.handleDeepLink(url)
        case .error(let message):
            print("❌ Deep link error: \(message)")
            return false
        case .requiresAuthentication:
            showLogin()
            return true
        case .requiresPermission(let permission):
            print("🔒 Deep link requires permission: \(permission)")
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func setupWindow() {
        window?.backgroundColor = .systemBackground
    }
    
    private func setupObservations() {
        // 监听应用状态变化
        appStateSubject
            .sink { [weak self] state in
                print("📱 App state changed to: \(state.displayName)")
                self?.notifyChildrenOfAppStateChange(state)
            }
            .store(in: &cancellables)
        
        // 监听认证状态变化
        isAuthenticatedSubject
            .sink { [weak self] isAuthenticated in
                print("🔐 Authentication state changed: \(isAuthenticated ? "Authenticated" : "Not Authenticated")")
                self?.notifyChildrenOfAuthStateChange(isAuthenticated)
            }
            .store(in: &cancellables)
    }
    
    private func initializeApp() {
        // 初始化各种服务和模块
        print("⚙️ Initializing app services...")
        
        // 模拟初始化过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            // 检查用户认证状态
            let isAuthenticated = self?.checkAuthenticationStatus() ?? false
            self?.handleAuthenticationStateChange(isAuthenticated)
        }
    }
    
    private func checkAuthenticationStatus() -> Bool {
        // 这里应该检查实际的认证状态
        // 暂时返回false，需要用户登录
        return false
    }
    
    private func createLaunchViewController() -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "IOTClient"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "智能设备管理平台"
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.startAnimating()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        viewController.view.addSubview(imageView)
        viewController.view.addSubview(titleLabel)
        viewController.view.addSubview(subtitleLabel)
        viewController.view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor, constant: -100),
            imageView.widthAnchor.constraint(equalToConstant: 120),
            imageView.heightAnchor.constraint(equalToConstant: 120),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -32),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -32),
            
            activityIndicator.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            activityIndicator.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor)
        ])
        
        return viewController
    }
    
    private func createLoginViewController() -> UIViewController {
        let viewController = UIViewController()
        viewController.title = "登录"
        viewController.view.backgroundColor = .systemBackground
        
        let titleLabel = UILabel()
        titleLabel.text = "欢迎使用 IOTClient"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "请登录您的账户以继续"
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let loginButton = UIButton(type: .system)
        loginButton.setTitle("登录", for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        loginButton.backgroundColor = .systemBlue
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 12
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        let skipButton = UIButton(type: .system)
        skipButton.setTitle("跳过登录", for: .normal)
        skipButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        
        skipButton.addTarget(self, action: #selector(skipLoginButtonTapped), for: .touchUpInside)
        
        viewController.view.addSubview(titleLabel)
        viewController.view.addSubview(subtitleLabel)
        viewController.view.addSubview(loginButton)
        viewController.view.addSubview(skipButton)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor, constant: -100),
            titleLabel.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -32),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -32),
            
            loginButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 48),
            loginButton.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 32),
            loginButton.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -32),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            skipButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 16),
            skipButton.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor)
        ])
        
        return viewController
    }
    
    @objc private func loginButtonTapped() {
        // 模拟登录过程
        print("🔐 User tapped login button")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.navigationController.dismiss(animated: true) {
                self?.handleAuthenticationStateChange(true)
            }
        }
    }
    
    @objc private func skipLoginButtonTapped() {
        print("⏭️ User skipped login")
        
        navigationController.dismiss(animated: true) { [weak self] in
            self?.handleAuthenticationStateChange(true)
        }
    }
    
    private func notifyChildrenOfAppStateChange(_ state: AppState) {
        for child in children {
            if let moduleCoordinator = child as? ModuleCoordinatorProtocol {
                // 通知模块协调器应用状态变化
                let message = ModuleMessage(
                    type: .systemEvent,
                    sender: .settings, // 使用settings作为系统消息发送者
                    payload: ["appState": state.rawValue]
                )
                moduleCoordinator.receiveMessage(message)
            }
        }
    }
    
    private func notifyChildrenOfAuthStateChange(_ isAuthenticated: Bool) {
        for child in children {
            if let moduleCoordinator = child as? ModuleCoordinatorProtocol {
                // 通知模块协调器认证状态变化
                let message = ModuleMessage(
                    type: .systemEvent,
                    sender: .settings, // 使用settings作为系统消息发送者
                    payload: ["isAuthenticated": isAuthenticated]
                )
                moduleCoordinator.receiveMessage(message)
            }
        }
    }
    
    private func handleAppDidEnterBackground() {
        print("📱 App entered background")
        // 通知所有子协调器应用进入后台
    }
    
    private func handleAppWillSuspend() {
        print("📱 App will suspend")
        // 保存应用状态
    }
    
    private func handleAppWillTerminate() {
        print("📱 App will terminate")
        // 清理资源
        stop()
    }
    
    private func handleAppError() {
        print("❌ App encountered error")
        // 显示错误界面或重启应用
    }
}