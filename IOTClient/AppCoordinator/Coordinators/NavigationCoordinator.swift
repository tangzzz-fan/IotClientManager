//
//  NavigationCoordinator.swift
//  AppCoordinator
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import UIKit
import Combine

// MARK: - Navigation Coordinator Implementation

/// 导航协调器实现
public final class NavigationCoordinator: BaseCoordinator, NavigationCoordinatorProtocol {
    
    // MARK: - Properties
    
    private var navigationHistory: [NavigationHistoryItem] = []
    private var navigationInterceptors: [NavigationInterceptor] = []
    private let maxHistoryCount = 50
    
    private var navigationRequestSubject = PassthroughSubject<NavigationRequest, Never>()
    public var navigationRequestPublisher: AnyPublisher<NavigationRequest, Never> {
        return navigationRequestSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    public override init(
        identifier: String? = nil,
        type: CoordinatorType = .navigation,
        navigationController: UINavigationController
    ) {
        super.init(identifier: identifier, type: type, navigationController: navigationController)
        setupNavigationController()
    }
    
    // MARK: - Navigation Coordinator Protocol
    
    public func push(_ viewController: UIViewController, animated: Bool) {
        let request = NavigationRequest(
            type: .push,
            viewController: viewController,
            animated: animated
        )
        
        guard processNavigationRequest(request) else {
            print("❌ Navigation request blocked: push \(viewController)")
            return
        }
        
        navigationController.pushViewController(viewController, animated: animated)
        addToHistory(request)
        
        print("➡️ Pushed view controller: \(String(describing: type(of: viewController)))")
    }
    
    public func pop(animated: Bool) -> UIViewController? {
        let request = NavigationRequest(
            type: .pop,
            animated: animated
        )
        
        guard processNavigationRequest(request) else {
            print("❌ Navigation request blocked: pop")
            return nil
        }
        
        let poppedViewController = navigationController.popViewController(animated: animated)
        addToHistory(request)
        
        if let popped = poppedViewController {
            print("⬅️ Popped view controller: \(String(describing: type(of: popped)))")
        }
        
        return poppedViewController
    }
    
    public func popToRoot(animated: Bool) -> [UIViewController]? {
        let request = NavigationRequest(
            type: .popToRoot,
            animated: animated
        )
        
        guard processNavigationRequest(request) else {
            print("❌ Navigation request blocked: popToRoot")
            return nil
        }
        
        let poppedViewControllers = navigationController.popToRootViewController(animated: animated)
        addToHistory(request)
        
        if let popped = poppedViewControllers {
            print("⬅️ Popped to root, removed \(popped.count) view controllers")
        }
        
        return poppedViewControllers
    }
    
    public func popTo(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        let request = NavigationRequest(
            type: .popTo,
            viewController: viewController,
            animated: animated
        )
        
        guard processNavigationRequest(request) else {
            print("❌ Navigation request blocked: popTo \(viewController)")
            return nil
        }
        
        let poppedViewControllers = navigationController.popToViewController(viewController, animated: animated)
        addToHistory(request)
        
        if let popped = poppedViewControllers {
            print("⬅️ Popped to \(String(describing: type(of: viewController))), removed \(popped.count) view controllers")
        }
        
        return poppedViewControllers
    }
    
    public func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        let request = NavigationRequest(
            type: .present,
            viewController: viewController,
            animated: animated
        )
        
        guard processNavigationRequest(request) else {
            print("❌ Navigation request blocked: present \(viewController)")
            completion?()
            return
        }
        
        navigationController.present(viewController, animated: animated, completion: completion)
        addToHistory(request)
        
        print("⬆️ Presented view controller: \(String(describing: type(of: viewController)))")
    }
    
    public func dismiss(animated: Bool, completion: (() -> Void)?) {
        let request = NavigationRequest(
            type: .dismiss,
            animated: animated
        )
        
        guard processNavigationRequest(request) else {
            print("❌ Navigation request blocked: dismiss")
            completion?()
            return
        }
        
        navigationController.dismiss(animated: animated, completion: completion)
        addToHistory(request)
        
        print("⬇️ Dismissed presented view controller")
    }
    
    public func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        let request = NavigationRequest(
            type: .setViewControllers,
            viewControllers: viewControllers,
            animated: animated
        )
        
        guard processNavigationRequest(request) else {
            print("❌ Navigation request blocked: setViewControllers")
            return
        }
        
        navigationController.setViewControllers(viewControllers, animated: animated)
        addToHistory(request)
        
        print("🔄 Set view controllers: \(viewControllers.count) controllers")
    }
    
    public func addNavigationInterceptor(_ interceptor: NavigationInterceptor) {
        navigationInterceptors.append(interceptor)
        print("✅ Added navigation interceptor")
    }
    
    public func removeNavigationInterceptor(_ interceptor: NavigationInterceptor) {
        navigationInterceptors.removeAll { $0.identifier == interceptor.identifier }
        print("✅ Removed navigation interceptor")
    }
    
    public func getNavigationHistory() -> [NavigationHistoryItem] {
        return navigationHistory
    }
    
    public func clearNavigationHistory() {
        navigationHistory.removeAll()
        print("🗑️ Cleared navigation history")
    }
    
    // MARK: - Private Methods
    
    private func setupNavigationController() {
        navigationController.delegate = self
        
        // 设置导航栏样式
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.navigationBar.tintColor = .systemBlue
    }
    
    private func processNavigationRequest(_ request: NavigationRequest) -> Bool {
        // 发布导航请求事件
        navigationRequestSubject.send(request)
        
        // 检查所有拦截器
        for interceptor in navigationInterceptors {
            let result = interceptor.shouldIntercept(request)
            
            switch result {
            case .allow:
                continue
            case .block(let reason):
                print("🚫 Navigation blocked by interceptor: \(reason)")
                return false
            case .redirect(let newRequest):
                print("🔄 Navigation redirected by interceptor")
                return processNavigationRequest(newRequest)
            case .requiresPermission(let permission):
                print("🔒 Navigation requires permission: \(permission)")
                return false
            }
        }
        
        return true
    }
    
    private func addToHistory(_ request: NavigationRequest) {
        let historyItem = NavigationHistoryItem(
            request: request,
            timestamp: Date(),
            viewControllerStack: navigationController.viewControllers.map { String(describing: type(of: $0)) }
        )
        
        navigationHistory.append(historyItem)
        
        // 限制历史记录数量
        if navigationHistory.count > maxHistoryCount {
            navigationHistory.removeFirst(navigationHistory.count - maxHistoryCount)
        }
    }
}

// MARK: - UINavigationControllerDelegate

extension NavigationCoordinator: UINavigationControllerDelegate {
    
    public func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        print("🔄 Will show view controller: \(String(describing: type(of: viewController)))")
    }
    
    public func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        print("✅ Did show view controller: \(String(describing: type(of: viewController)))")
    }
}

// MARK: - Tab Coordinator Implementation

/// 标签页协调器实现
public final class TabCoordinator: BaseCoordinator, TabCoordinatorProtocol {
    
    // MARK: - Properties
    
    public private(set) var tabBarController: UITabBarController
    private var tabCoordinators: [Int: Coordinator] = [:]
    
    private var selectedIndexSubject = CurrentValueSubject<Int, Never>(0)
    public var selectedIndexPublisher: AnyPublisher<Int, Never> {
        return selectedIndexSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    public override init(
        identifier: String? = nil,
        type: CoordinatorType = .tab,
        navigationController: UINavigationController
    ) {
        self.tabBarController = UITabBarController()
        super.init(identifier: identifier, type: type, navigationController: navigationController)
        
        setupTabBarController()
    }
    
    // MARK: - Tab Coordinator Protocol
    
    public func setupTabs() {
        var viewControllers: [UIViewController] = []
        
        // 设备列表标签
        let deviceListCoordinator = createDeviceListCoordinator()
        addChild(deviceListCoordinator)
        tabCoordinators[0] = deviceListCoordinator
        viewControllers.append(deviceListCoordinator.navigationController)
        
        // 设备配网标签
        let provisioningCoordinator = createProvisioningCoordinator()
        addChild(provisioningCoordinator)
        tabCoordinators[1] = provisioningCoordinator
        viewControllers.append(provisioningCoordinator.navigationController)
        
        // 设备控制标签
        let deviceControlCoordinator = createDeviceControlCoordinator()
        addChild(deviceControlCoordinator)
        tabCoordinators[2] = deviceControlCoordinator
        viewControllers.append(deviceControlCoordinator.navigationController)
        
        // 设置标签
        let settingsCoordinator = createSettingsCoordinator()
        addChild(settingsCoordinator)
        tabCoordinators[3] = settingsCoordinator
        viewControllers.append(settingsCoordinator.navigationController)
        
        tabBarController.setViewControllers(viewControllers, animated: false)
        
        // 启动所有标签协调器
        for coordinator in tabCoordinators.values {
            coordinator.start()
        }
        
        print("✅ Setup \(viewControllers.count) tabs")
    }
    
    public func selectTab(at index: Int, animated: Bool) {
        guard index >= 0 && index < tabBarController.viewControllers?.count ?? 0 else {
            print("❌ Invalid tab index: \(index)")
            return
        }
        
        tabBarController.selectedIndex = index
        selectedIndexSubject.send(index)
        
        print("📑 Selected tab at index: \(index)")
    }
    
    public func addTab(_ viewController: UIViewController, at index: Int?) {
        var viewControllers = tabBarController.viewControllers ?? []
        
        if let index = index, index >= 0 && index <= viewControllers.count {
            viewControllers.insert(viewController, at: index)
        } else {
            viewControllers.append(viewController)
        }
        
        tabBarController.setViewControllers(viewControllers, animated: true)
        
        print("✅ Added tab at index: \(index ?? viewControllers.count - 1)")
    }
    
    public func removeTab(at index: Int) {
        guard var viewControllers = tabBarController.viewControllers,
              index >= 0 && index < viewControllers.count else {
            print("❌ Invalid tab index for removal: \(index)")
            return
        }
        
        // 停止并移除对应的协调器
        if let coordinator = tabCoordinators[index] {
            coordinator.stop()
            removeChild(coordinator)
            tabCoordinators.removeValue(forKey: index)
        }
        
        viewControllers.remove(at: index)
        tabBarController.setViewControllers(viewControllers, animated: true)
        
        // 重新映射剩余的协调器索引
        let remainingCoordinators = tabCoordinators
        tabCoordinators.removeAll()
        
        for (oldIndex, coordinator) in remainingCoordinators {
            let newIndex = oldIndex > index ? oldIndex - 1 : oldIndex
            tabCoordinators[newIndex] = coordinator
        }
        
        print("✅ Removed tab at index: \(index)")
    }
    
    public func updateTabBadge(at index: Int, badge: String?) {
        guard let viewControllers = tabBarController.viewControllers,
              index >= 0 && index < viewControllers.count else {
            print("❌ Invalid tab index for badge update: \(index)")
            return
        }
        
        viewControllers[index].tabBarItem.badgeValue = badge
        
        if let badge = badge {
            print("🔴 Updated tab \(index) badge: \(badge)")
        } else {
            print("✅ Cleared tab \(index) badge")
        }
    }
    
    public func setTabEnabled(at index: Int, enabled: Bool) {
        guard let viewControllers = tabBarController.viewControllers,
              index >= 0 && index < viewControllers.count else {
            print("❌ Invalid tab index for enabled state: \(index)")
            return
        }
        
        viewControllers[index].tabBarItem.isEnabled = enabled
        
        print("🔄 Tab \(index) enabled state: \(enabled)")
    }
    
    // MARK: - Coordinator Lifecycle
    
    public override func coordinatorWillStart() {
        super.coordinatorWillStart()
        setupTabs()
        
        // 将标签栏控制器设置为导航控制器的根视图控制器
        navigationController.setViewControllers([tabBarController], animated: false)
    }
    
    public override func coordinatorWillStop() {
        super.coordinatorWillStop()
        
        // 停止所有标签协调器
        for coordinator in tabCoordinators.values {
            coordinator.stop()
        }
        tabCoordinators.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func setupTabBarController() {
        tabBarController.delegate = self
        
        // 设置标签栏样式
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        
        tabBarController.tabBar.standardAppearance = appearance
        tabBarController.tabBar.scrollEdgeAppearance = appearance
        tabBarController.tabBar.tintColor = .systemBlue
        tabBarController.tabBar.unselectedItemTintColor = .systemGray
    }
    
    private func createDeviceListCoordinator() -> Coordinator {
        let navigationController = UINavigationController()
        let coordinator = NavigationCoordinator(
            identifier: "device-list-nav",
            navigationController: navigationController
        )
        
        // 创建设备列表视图控制器
        let deviceListViewController = createDeviceListViewController()
        navigationController.setViewControllers([deviceListViewController], animated: false)
        
        // 设置标签栏项
        navigationController.tabBarItem = UITabBarItem(
            title: "设备",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        
        return coordinator
    }
    
    private func createProvisioningCoordinator() -> Coordinator {
        let navigationController = UINavigationController()
        let coordinator = NavigationCoordinator(
            identifier: "provisioning-nav",
            navigationController: navigationController
        )
        
        // 创建配网视图控制器
        let provisioningViewController = createProvisioningViewController()
        navigationController.setViewControllers([provisioningViewController], animated: false)
        
        // 设置标签栏项
        navigationController.tabBarItem = UITabBarItem(
            title: "配网",
            image: UIImage(systemName: "plus.circle"),
            selectedImage: UIImage(systemName: "plus.circle.fill")
        )
        
        return coordinator
    }
    
    private func createDeviceControlCoordinator() -> Coordinator {
        let navigationController = UINavigationController()
        let coordinator = NavigationCoordinator(
            identifier: "device-control-nav",
            navigationController: navigationController
        )
        
        // 创建设备控制视图控制器
        let deviceControlViewController = createDeviceControlViewController()
        navigationController.setViewControllers([deviceControlViewController], animated: false)
        
        // 设置标签栏项
        navigationController.tabBarItem = UITabBarItem(
            title: "控制",
            image: UIImage(systemName: "slider.horizontal.3"),
            selectedImage: UIImage(systemName: "slider.horizontal.3")
        )
        
        return coordinator
    }
    
    private func createSettingsCoordinator() -> Coordinator {
        let navigationController = UINavigationController()
        let coordinator = NavigationCoordinator(
            identifier: "settings-nav",
            navigationController: navigationController
        )
        
        // 创建设置视图控制器
        let settingsViewController = createSettingsViewController()
        navigationController.setViewControllers([settingsViewController], animated: false)
        
        // 设置标签栏项
        navigationController.tabBarItem = UITabBarItem(
            title: "设置",
            image: UIImage(systemName: "gear"),
            selectedImage: UIImage(systemName: "gear")
        )
        
        return coordinator
    }
    
    private func createDeviceListViewController() -> UIViewController {
        let viewController = UIViewController()
        viewController.title = "我的设备"
        viewController.view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "设备列表"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        viewController.view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])
        
        return viewController
    }
    
    private func createProvisioningViewController() -> UIViewController {
        let viewController = UIViewController()
        viewController.title = "设备配网"
        viewController.view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "设备配网"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        viewController.view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])
        
        return viewController
    }
    
    private func createDeviceControlViewController() -> UIViewController {
        let viewController = UIViewController()
        viewController.title = "设备控制"
        viewController.view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "设备控制"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        viewController.view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])
        
        return viewController
    }
    
    private func createSettingsViewController() -> UIViewController {
        let viewController = UIViewController()
        viewController.title = "设置"
        viewController.view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "应用设置"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        viewController.view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])
        
        return viewController
    }
}

// MARK: - UITabBarControllerDelegate

extension TabCoordinator: UITabBarControllerDelegate {
    
    public func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelect viewController: UIViewController
    ) -> Bool {
        // 可以在这里添加标签切换的拦截逻辑
        return true
    }
    
    public func tabBarController(
        _ tabBarController: UITabBarController,
        didSelect viewController: UIViewController
    ) {
        let selectedIndex = tabBarController.selectedIndex
        selectedIndexSubject.send(selectedIndex)
        
        print("📑 Tab selected at index: \(selectedIndex)")
    }
}