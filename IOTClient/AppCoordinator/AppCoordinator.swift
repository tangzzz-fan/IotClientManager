//
//  AppCoordinator.swift
//  IOTClient
//
//  Created by Tang Tango on 2025/1/4.
//

import UIKit
import Combine

/// 应用程序协调器 - 负责管理应用的整体架构和模块协调
class AppCoordinator {
    
    // MARK: - Singleton
    
    static let shared = AppCoordinator()
    
    // MARK: - Properties
    
    private var window: UIWindow?
    private var cancellables = Set<AnyCancellable>()
    
    // 核心模块
    private let deviceControlModule = DeviceControlModule.shared
    private let provisioningModule = ProvisioningModule.shared
    private let persistenceLayer = PersistenceLayer.shared
    
    // 连接管理器
    private let bleManager = BLEManager.shared
    private let mqttClientManager = MQTTClientManager.shared
    private let connectivityLayerManager = ConnectivityLayerManager.shared
    
    // 应用状态
    private var isInitialized = false
    
    // MARK: - Initialization
    
    private init() {
        setupNotifications()
    }
    
    // MARK: - Public Methods
    
    /// 启动应用程序
    /// - Parameter window: 主窗口
    func start(with window: UIWindow) {
        self.window = window
        
        // 初始化所有模块
        initializeModules()
        
        // 设置根视图控制器
        setupRootViewController()
        
        // 标记为已初始化
        isInitialized = true
        
        print("[AppCoordinator] 应用程序启动完成")
    }
    
    /// 关闭应用程序
    func shutdown() {
        guard isInitialized else { return }
        
        print("[AppCoordinator] 开始关闭应用程序...")
        
        // 关闭所有模块
        shutdownModules()
        
        // 清理资源
        cleanup()
        
        isInitialized = false
        
        print("[AppCoordinator] 应用程序关闭完成")
    }
    
    /// 获取应用程序状态
    func getApplicationStatus() -> ApplicationStatus {
        return ApplicationStatus(
            isInitialized: isInitialized,
            deviceControlModuleStatus: deviceControlModule.getModuleStatus(),
            provisioningModuleStatus: provisioningModule.getModuleStatus(),
            persistenceLayerStatus: persistenceLayer.getLayerStatus(),
            bleManagerStatus: bleManager.isInitialized ? .connected : .disconnected,
            mqttClientStatus: mqttClientManager.isConnected ? .connected : .disconnected,
            connectivityLayerStatus: connectivityLayerManager.getStatus()
        )
    }
    
    // MARK: - Private Methods
    
    /// 初始化所有模块
    private func initializeModules() {
        print("[AppCoordinator] 开始初始化模块...")
        
        // 1. 初始化持久化层
        persistenceLayer.initialize()
        
        // 2. 初始化连接管理器
        bleManager.initialize()
        mqttClientManager.initialize()
        connectivityLayerManager.initialize()
        
        // 3. 初始化设备控制模块
        deviceControlModule.initialize()
        
        // 4. 初始化配网模块
        provisioningModule.initialize()
        
        print("[AppCoordinator] 模块初始化完成")
    }
    
    /// 关闭所有模块
    private func shutdownModules() {
        // 按相反顺序关闭模块
        provisioningModule.shutdown()
        deviceControlModule.shutdown()
        
        connectivityLayerManager.shutdown()
        mqttClientManager.disconnect()
        bleManager.shutdown()
        
        persistenceLayer.shutdown()
    }
    
    /// 设置根视图控制器
    private func setupRootViewController() {
        guard let window = window else { return }
        
        // 创建主视图控制器
        let mainViewController = MainViewController()
        let navigationController = UINavigationController(rootViewController: mainViewController)
        
        // 设置窗口
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
    
    /// 设置通知监听
    private func setupNotifications() {
        // 监听应用生命周期事件
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppDidEnterBackground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleAppWillEnterForeground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.handleAppWillTerminate()
            }
            .store(in: &cancellables)
    }
    
    /// 清理资源
    private func cleanup() {
        cancellables.removeAll()
        window = nil
    }
    
    // MARK: - App Lifecycle Handlers
    
    private func handleAppDidEnterBackground() {
        print("[AppCoordinator] 应用进入后台")
        // 可以在这里暂停一些不必要的操作
    }
    
    private func handleAppWillEnterForeground() {
        print("[AppCoordinator] 应用即将进入前台")
        // 可以在这里恢复一些操作
    }
    
    private func handleAppWillTerminate() {
        print("[AppCoordinator] 应用即将终止")
        shutdown()
    }
}

// MARK: - Supporting Types

/// 应用程序状态
struct ApplicationStatus {
    let isInitialized: Bool
    let deviceControlModuleStatus: DeviceControlModuleStatus
    let provisioningModuleStatus: ProvisioningModuleStatus
    let persistenceLayerStatus: PersistenceLayerStatus
    let bleManagerStatus: ConnectionStatus
    let mqttClientStatus: ConnectionStatus
    let connectivityLayerStatus: ConnectivityLayerStatus
}

/// 连接状态
enum ConnectionStatus {
    case connected
    case disconnected
    case connecting
    case error(String)
}

// MARK: - Extensions for Module Status (临时定义，确保编译通过)

extension DeviceControlModule {
    func getModuleStatus() -> DeviceControlModuleStatus {
        return DeviceControlModuleStatus(
            isInitialized: true,
            activeControllers: controllers.count,
            isDiscovering: false
        )
    }
}

extension ProvisioningModule {
    func getModuleStatus() -> ProvisioningModuleStatus {
        return ProvisioningModuleStatus(
            isInitialized: true,
            activeProvisioningSessions: 0
        )
    }
}

extension PersistenceLayer {
    func getLayerStatus() -> PersistenceLayerStatus {
        return PersistenceLayerStatus(
            isInitialized: true,
            databaseConnected: true
        )
    }
}

/// 模块状态定义
struct DeviceControlModuleStatus {
    let isInitialized: Bool
    let activeControllers: Int
    let isDiscovering: Bool
}

struct ProvisioningModuleStatus {
    let isInitialized: Bool
    let activeProvisioningSessions: Int
}

struct PersistenceLayerStatus {
    let isInitialized: Bool
    let databaseConnected: Bool
}