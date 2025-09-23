//
//  ProvisioningProtocols.swift
//  ProvisioningModule
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

// MARK: - Provisioning Events

/// 配网事件
enum ProvisioningEvent {
    // 流程控制事件
    case startProvisioning
    case cancel
    case retry
    case restart
    
    // 扫描相关事件
    case devicesFound([ProvisionableDevice])
    case scanTimeout
    case scanFailed(Error)
    case rescan
    
    // 设备选择事件
    case deviceSelected(ProvisionableDevice)
    case selectDifferentDevice
    
    // 连接相关事件
    case deviceConnected
    case connectionFailed(Error)
    
    // 认证相关事件
    case authenticationSucceeded
    case authenticationFailed(Error)
    
    // 配置相关事件
    case configurationSucceeded
    case configurationFailed(Error)
    case reconfigure
    
    // 验证相关事件
    case verificationSucceeded
    case verificationFailed(Error)
    
    // 最终事件
    case completed
    case cancelled
    case failed(ProvisioningError)
}

// MARK: - Provisioning Errors

/// 配网错误
enum ProvisioningError: Error, LocalizedError {
    case scanFailed
    case noDevicesFound
    case deviceNotFound
    case noDeviceSelected
    case connectionTimeout
    case connectionFailed(Error)
    case authenticationFailed(Error)
    case noNetworkConfiguration
    case configurationFailed(Error)
    case verificationFailed(Error)
    case cancelled
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .scanFailed:
            return "设备扫描失败"
        case .noDevicesFound:
            return "未发现可配网设备"
        case .deviceNotFound:
            return "设备未找到"
        case .noDeviceSelected:
            return "未选择设备"
        case .connectionTimeout:
            return "连接超时"
        case .connectionFailed(let error):
            return "连接失败: \(error.localizedDescription)"
        case .authenticationFailed(let error):
            return "认证失败: \(error.localizedDescription)"
        case .noNetworkConfiguration:
            return "缺少网络配置"
        case .configurationFailed(let error):
            return "配置失败: \(error.localizedDescription)"
        case .verificationFailed(let error):
            return "验证失败: \(error.localizedDescription)"
        case .cancelled:
            return "配网已取消"
        case .unknown(let error):
            return "未知错误: \(error.localizedDescription)"
        }
    }
}

// MARK: - Provisioning Context

/// 配网上下文
class ProvisioningContext: ObservableObject {
    
    // MARK: - Services
    
    let scanningService: DeviceScanningService
    let connectionService: DeviceConnectionService
    let authenticationService: DeviceAuthenticationService
    let configurationService: DeviceConfigurationService
    let verificationService: DeviceVerificationService
    
    // MARK: - State Data
    
    @Published var discoveredDevices: [ProvisionableDevice] = []
    @Published var selectedDevice: ProvisionableDevice?
    @Published var networkConfiguration: NetworkConfiguration?
    @Published var provisioningProgress: ProvisioningProgress?
    
    // MARK: - Configuration
    
    var scanTimeout: TimeInterval = 30.0
    var connectionTimeout: TimeInterval = 15.0
    var authenticationTimeout: TimeInterval = 10.0
    var configurationTimeout: TimeInterval = 30.0
    var verificationTimeout: TimeInterval = 20.0
    
    // MARK: - Initialization
    
    init(
        scanningService: DeviceScanningService,
        connectionService: DeviceConnectionService,
        authenticationService: DeviceAuthenticationService,
        configurationService: DeviceConfigurationService,
        verificationService: DeviceVerificationService
    ) {
        self.scanningService = scanningService
        self.connectionService = connectionService
        self.authenticationService = authenticationService
        self.configurationService = configurationService
        self.verificationService = verificationService
    }
    
    // MARK: - Methods
    
    /// 清理资源
    func cleanup() {
        scanningService.stopScanning()
        connectionService.disconnect()
        discoveredDevices.removeAll()
        selectedDevice = nil
        networkConfiguration = nil
        provisioningProgress = nil
    }
    
    /// 保存已配网设备
    func saveProvisionedDevice(_ device: ProvisionableDevice) {
        // 实现设备保存逻辑
        // 可以保存到 Core Data 或其他持久化存储
    }
}

// MARK: - Device Scanning Service

/// 设备扫描服务协议
protocol DeviceScanningService {
    /// 开始扫描
    func startScanning() -> AnyPublisher<[ProvisionableDevice], Error>
    
    /// 停止扫描
    func stopScanning()
    
    /// 扫描状态
    var isScanning: Bool { get }
    
    /// 扫描结果流
    var scanResults: AnyPublisher<[ProvisionableDevice], Never> { get }
}

// MARK: - Device Connection Service

/// 设备连接服务协议
protocol DeviceConnectionService {
    /// 连接到设备
    func connect(to device: ProvisionableDevice) -> AnyPublisher<Void, Error>
    
    /// 断开连接
    func disconnect()
    
    /// 连接状态
    var isConnected: Bool { get }
    
    /// 当前连接的设备
    var connectedDevice: ProvisionableDevice? { get }
    
    /// 连接状态流
    var connectionStatus: AnyPublisher<ConnectionStatus, Never> { get }
}

// MARK: - Device Authentication Service

/// 设备认证服务协议
protocol DeviceAuthenticationService {
    /// 认证设备
    func authenticate() -> AnyPublisher<AuthenticationResult, Error>
    
    /// 认证状态
    var isAuthenticated: Bool { get }
    
    /// 认证信息
    var authenticationInfo: AuthenticationInfo? { get }
}

// MARK: - Device Configuration Service

/// 设备配置服务协议
protocol DeviceConfigurationService {
    /// 配置设备
    func configure(with configuration: NetworkConfiguration) -> AnyPublisher<ConfigurationResult, Error>
    
    /// 获取设备信息
    func getDeviceInfo() -> AnyPublisher<DeviceInfo, Error>
    
    /// 设置设备参数
    func setDeviceParameters(_ parameters: [String: Any]) -> AnyPublisher<Void, Error>
    
    /// 配置进度
    var configurationProgress: AnyPublisher<Float, Never> { get }
}

// MARK: - Device Verification Service

/// 设备验证服务协议
protocol DeviceVerificationService {
    /// 验证设备连接
    func verify() -> AnyPublisher<VerificationResult, Error>
    
    /// 测试网络连接
    func testNetworkConnection() -> AnyPublisher<NetworkTestResult, Error>
    
    /// 验证设备功能
    func verifyDeviceFunctionality() -> AnyPublisher<FunctionalityTestResult, Error>
}

// MARK: - Provisioning Manager Protocol

/// 配网管理器协议
protocol ProvisioningManagerProtocol: ObservableObject {
    /// 当前状态
    var currentState: ProvisioningState { get }
    
    /// 配网进度
    var progress: ProvisioningProgress? { get }
    
    /// 是否正在配网
    var isProvisioning: Bool { get }
    
    /// 开始配网
    func startProvisioning(with configuration: NetworkConfiguration) -> AnyPublisher<ProvisioningResult, ProvisioningError>
    
    /// 取消配网
    func cancelProvisioning()
    
    /// 重试配网
    func retryProvisioning()
    
    /// 处理事件
    func handleEvent(_ event: ProvisioningEvent)
    
    /// 状态变化流
    var stateChanges: AnyPublisher<ProvisioningState, Never> { get }
    
    /// 事件流
    var events: AnyPublisher<ProvisioningEvent, Never> { get }
}

// MARK: - Provisioning Delegate

/// 配网代理协议
protocol ProvisioningDelegate: AnyObject {
    /// 状态改变
    func provisioningManager(_ manager: ProvisioningManagerProtocol, didChangeState state: ProvisioningState)
    
    /// 进度更新
    func provisioningManager(_ manager: ProvisioningManagerProtocol, didUpdateProgress progress: ProvisioningProgress)
    
    /// 发现设备
    func provisioningManager(_ manager: ProvisioningManagerProtocol, didDiscoverDevices devices: [ProvisionableDevice])
    
    /// 配网完成
    func provisioningManager(_ manager: ProvisioningManagerProtocol, didCompleteWith result: ProvisioningResult)
    
    /// 配网失败
    func provisioningManager(_ manager: ProvisioningManagerProtocol, didFailWith error: ProvisioningError)
    
    /// 配网取消
    func provisioningManagerDidCancel(_ manager: ProvisioningManagerProtocol)
}

// MARK: - Provisioning UI Protocol

/// 配网UI协议
protocol ProvisioningUIProtocol {
    /// 显示扫描界面
    func showScanningUI()
    
    /// 显示设备选择界面
    func showDeviceSelectionUI(devices: [ProvisionableDevice])
    
    /// 显示连接界面
    func showConnectingUI(device: ProvisionableDevice)
    
    /// 显示配置界面
    func showConfigurationUI()
    
    /// 显示进度界面
    func showProgressUI(progress: ProvisioningProgress)
    
    /// 显示错误界面
    func showErrorUI(error: ProvisioningError, canRetry: Bool)
    
    /// 显示完成界面
    func showCompletionUI(result: ProvisioningResult)
    
    /// 隐藏UI
    func hideUI()
}

// MARK: - Device Factory Protocol

/// 设备工厂协议
protocol DeviceFactoryProtocol {
    /// 创建扫描服务
    func createScanningService(for deviceType: DeviceType) -> DeviceScanningService
    
    /// 创建连接服务
    func createConnectionService(for deviceType: DeviceType) -> DeviceConnectionService
    
    /// 创建认证服务
    func createAuthenticationService(for deviceType: DeviceType) -> DeviceAuthenticationService
    
    /// 创建配置服务
    func createConfigurationService(for deviceType: DeviceType) -> DeviceConfigurationService
    
    /// 创建验证服务
    func createVerificationService(for deviceType: DeviceType) -> DeviceVerificationService
    
    /// 支持的设备类型
    var supportedDeviceTypes: [DeviceType] { get }
}

// MARK: - Configuration Provider Protocol

/// 配置提供者协议
protocol ConfigurationProviderProtocol {
    /// 获取网络配置
    func getNetworkConfiguration() -> NetworkConfiguration?
    
    /// 获取设备配置
    func getDeviceConfiguration(for deviceType: DeviceType) -> DeviceConfiguration?
    
    /// 获取认证配置
    func getAuthenticationConfiguration() -> AuthenticationConfiguration?
    
    /// 保存配置
    func saveConfiguration(_ configuration: Any, for key: String)
    
    /// 加载配置
    func loadConfiguration(for key: String) -> Any?
}

// MARK: - Provisioning Logger Protocol

/// 配网日志协议
protocol ProvisioningLoggerProtocol {
    /// 记录状态变化
    func logStateChange(from: ProvisioningState, to: ProvisioningState)
    
    /// 记录事件
    func logEvent(_ event: ProvisioningEvent)
    
    /// 记录错误
    func logError(_ error: ProvisioningError)
    
    /// 记录调试信息
    func logDebug(_ message: String)
    
    /// 记录信息
    func logInfo(_ message: String)
    
    /// 记录警告
    func logWarning(_ message: String)
}

// MARK: - Provisioning Analytics Protocol

/// 配网分析协议
protocol ProvisioningAnalyticsProtocol {
    /// 记录配网开始
    func trackProvisioningStarted(deviceType: DeviceType)
    
    /// 记录配网完成
    func trackProvisioningCompleted(deviceType: DeviceType, duration: TimeInterval)
    
    /// 记录配网失败
    func trackProvisioningFailed(deviceType: DeviceType, error: ProvisioningError, duration: TimeInterval)
    
    /// 记录配网取消
    func trackProvisioningCancelled(deviceType: DeviceType, duration: TimeInterval)
    
    /// 记录状态持续时间
    func trackStateDuration(state: ProvisioningState, duration: TimeInterval)
    
    /// 记录重试次数
    func trackRetryCount(state: ProvisioningState, count: Int)
}

// MARK: - Provisioning Security Protocol

/// 配网安全协议
protocol ProvisioningSecurityProtocol {
    /// 生成安全密钥
    func generateSecurityKey() -> Data
    
    /// 加密数据
    func encrypt(data: Data, key: Data) throws -> Data
    
    /// 解密数据
    func decrypt(data: Data, key: Data) throws -> Data
    
    /// 验证签名
    func verifySignature(data: Data, signature: Data, publicKey: Data) -> Bool
    
    /// 生成签名
    func generateSignature(data: Data, privateKey: Data) throws -> Data
    
    /// 安全随机数
    func generateNonce() -> Data
}