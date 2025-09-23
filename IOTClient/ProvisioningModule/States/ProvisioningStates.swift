//
//  ProvisioningStates.swift
//  ProvisioningModule
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

// MARK: - Provisioning State Protocol

/// 配网状态协议
protocol ProvisioningState {
    /// 状态名称
    var name: String { get }
    
    /// 状态描述
    var description: String { get }
    
    /// 是否可以取消
    var canCancel: Bool { get }
    
    /// 是否是最终状态
    var isFinalState: Bool { get }
    
    /// 进入状态时的处理
    func enter(context: ProvisioningContext) -> AnyPublisher<ProvisioningEvent, ProvisioningError>
    
    /// 退出状态时的处理
    func exit(context: ProvisioningContext)
    
    /// 处理事件
    func handle(event: ProvisioningEvent, context: ProvisioningContext) -> ProvisioningState?
    
    /// 获取下一个可能的状态
    func possibleNextStates() -> [ProvisioningState.Type]
}

// MARK: - Base Provisioning State

/// 配网状态基类
open class BaseProvisioningState: ProvisioningState {
    
    public let name: String
    public let description: String
    public let canCancel: Bool
    public let isFinalState: Bool
    
    public init(name: String, description: String, canCancel: Bool = true, isFinalState: Bool = false) {
        self.name = name
        self.description = description
        self.canCancel = canCancel
        self.isFinalState = isFinalState
    }
    
    open func enter(context: ProvisioningContext) -> AnyPublisher<ProvisioningEvent, ProvisioningError> {
        return Empty().eraseToAnyPublisher()
    }
    
    open func exit(context: ProvisioningContext) {
        // 默认实现为空
    }
    
    open func handle(event: ProvisioningEvent, context: ProvisioningContext) -> ProvisioningState? {
        return nil
    }
    
    open func possibleNextStates() -> [ProvisioningState.Type] {
        return []
    }
}

// MARK: - Idle State

/// 空闲状态
class IdleState: BaseProvisioningState {
    
    init() {
        super.init(
            name: "idle",
            description: "等待开始配网",
            canCancel: false
        )
    }
    
    override func handle(event: ProvisioningEvent, context: ProvisioningContext) -> ProvisioningState? {
        switch event {
        case .startProvisioning:
            return ScanningState()
        default:
            return nil
        }
    }
    
    override func possibleNextStates() -> [ProvisioningState.Type] {
        return [ScanningState.self]
    }
}

// MARK: - Scanning State

/// 扫描状态
class ScanningState: BaseProvisioningState {
    
    init() {
        super.init(
            name: "scanning",
            description: "扫描可配网设备"
        )
    }
    
    override func enter(context: ProvisioningContext) -> AnyPublisher<ProvisioningEvent, ProvisioningError> {
        return context.scanningService.startScanning()
            .map { devices in
                if devices.isEmpty {
                    return ProvisioningEvent.scanTimeout
                } else {
                    return ProvisioningEvent.devicesFound(devices)
                }
            }
            .catch { error in
                Just(ProvisioningEvent.scanFailed(error))
            }
            .eraseToAnyPublisher()
    }
    
    override func exit(context: ProvisioningContext) {
        context.scanningService.stopScanning()
    }
    
    override func handle(event: ProvisioningEvent, context: ProvisioningContext) -> ProvisioningState? {
        switch event {
        case .devicesFound(let devices):
            context.discoveredDevices = devices
            return DeviceSelectionState()
        case .scanTimeout:
            return ScanTimeoutState()
        case .scanFailed:
            return ErrorState(error: ProvisioningError.scanFailed)
        case .cancel:
            return CancelledState()
        default:
            return nil
        }
    }
    
    override func possibleNextStates() -> [ProvisioningState.Type] {
        return [DeviceSelectionState.self, ScanTimeoutState.self, ErrorState.self, CancelledState.self]
    }
}

// MARK: - Device Selection State

/// 设备选择状态
class DeviceSelectionState: BaseProvisioningState {
    
    init() {
        super.init(
            name: "deviceSelection",
            description: "选择要配网的设备"
        )
    }
    
    override func handle(event: ProvisioningEvent, context: ProvisioningContext) -> ProvisioningState? {
        switch event {
        case .deviceSelected(let device):
            context.selectedDevice = device
            return ConnectingState()
        case .rescan:
            return ScanningState()
        case .cancel:
            return CancelledState()
        default:
            return nil
        }
    }
    
    override func possibleNextStates() -> [ProvisioningState.Type] {
        return [ConnectingState.self, ScanningState.self, CancelledState.self]
    }
}

// MARK: - Connecting State

/// 连接状态
class ConnectingState: BaseProvisioningState {
    
    init() {
        super.init(
            name: "connecting",
            description: "连接到设备"
        )
    }
    
    override func enter(context: ProvisioningContext) -> AnyPublisher<ProvisioningEvent, ProvisioningError> {
        guard let device = context.selectedDevice else {
            return Fail(error: ProvisioningError.noDeviceSelected)
                .eraseToAnyPublisher()
        }
        
        return context.connectionService.connect(to: device)
            .map { _ in ProvisioningEvent.deviceConnected }
            .catch { error in
                Just(ProvisioningEvent.connectionFailed(error))
            }
            .eraseToAnyPublisher()
    }
    
    override func handle(event: ProvisioningEvent, context: ProvisioningContext) -> ProvisioningState? {
        switch event {
        case .deviceConnected:
            return AuthenticatingState()
        case .connectionFailed:
            return ConnectionFailedState()
        case .cancel:
            return CancellingState()
        default:
            return nil
        }
    }
    
    override func possibleNextStates() -> [ProvisioningState.Type] {
        return [AuthenticatingState.self, ConnectionFailedState.self, CancellingState.self]
    }
}

// MARK: - Authenticating State

/// 认证状态
class AuthenticatingState: BaseProvisioningState {
    
    init() {
        super.init(
            name: "authenticating",
            description: "设备认证中"
        )
    }
    
    override func enter(context: ProvisioningContext) -> AnyPublisher<ProvisioningEvent, ProvisioningError> {
        return context.authenticationService.authenticate()
            .map { _ in ProvisioningEvent.authenticationSucceeded }
            .catch { error in
                Just(ProvisioningEvent.authenticationFailed(error))
            }
            .eraseToAnyPublisher()
    }
    
    override func handle(event: ProvisioningEvent, context: ProvisioningContext) -> ProvisioningState? {
        switch event {
        case .authenticationSucceeded:
            return ConfiguringState()
        case .authenticationFailed:
            return AuthenticationFailedState()
        case .cancel:
            return CancellingState()
        default:
            return nil
        }
    }
    
    override func possibleNextStates() -> [ProvisioningState.Type] {
        return [ConfiguringState.self, AuthenticationFailedState.self, CancellingState.self]
    }
}

// MARK: - Configuring State

/// 配置状态
class ConfiguringState: BaseProvisioningState {
    
    init() {
        super.init(
            name: "configuring",
            description: "配置设备网络"
        )
    }
    
    override func enter(context: ProvisioningContext) -> AnyPublisher<ProvisioningEvent, ProvisioningError> {
        guard let config = context.networkConfiguration else {
            return Fail(error: ProvisioningError.noNetworkConfiguration)
                .eraseToAnyPublisher()
        }
        
        return context.configurationService.configure(with: config)
            .map { _ in ProvisioningEvent.configurationSucceeded }
            .catch { error in
                Just(ProvisioningEvent.configurationFailed(error))
            }
            .eraseToAnyPublisher()
    }
    
    override func handle(event: ProvisioningEvent, context: ProvisioningContext) -> ProvisioningState? {
        switch event {
        case .configurationSucceeded:
            return VerifyingState()
        case .configurationFailed:
            return ConfigurationFailedState()
        case .cancel:
            return CancellingState()
        default:
            return nil
        }
    }
    
    override func possibleNextStates() -> [ProvisioningState.Type] {
        return [VerifyingState.self, ConfigurationFailedState.self, CancellingState.self]
    }
}

// MARK: - Verifying State

/// 验证状态
class VerifyingState: BaseProvisioningState {
    
    init() {
        super.init(
            name: "verifying",
            description: "验证设备连接"
        )
    }
    
    override func enter(context: ProvisioningContext) -> AnyPublisher<ProvisioningEvent, ProvisioningError> {
        return context.verificationService.verify()
            .map { _ in ProvisioningEvent.verificationSucceeded }
            .catch { error in
                Just(ProvisioningEvent.verificationFailed(error))
            }
            .eraseToAnyPublisher()
    }
    
    override func handle(event: ProvisioningEvent, context: ProvisioningContext) -> ProvisioningState? {
        switch event {
        case .verificationSucceeded:
            return CompletedState()
        case .verificationFailed:
            return VerificationFailedState()
        case .cancel:
            return CancellingState()
        default:
            return nil
        }
    }
    
    override func possibleNextStates() -> [ProvisioningState.Type] {
        return [CompletedState.self, VerificationFailedState.self, CancellingState.self]
    }
}

// MARK: - Error States

/// 扫描超时状态
class ScanTimeoutState: BaseProvisioningState {
    
    init() {
        super.init(
            name: "scanTimeout",
            description: "扫描超时"
        )
    }
    
    override func handle(event: ProvisioningEvent, context: ProvisioningContext) -> ProvisioningState? {
        switch event {
        case .retry:
            return ScanningState()
        case .cancel:
            return CancelledState()
        default:
            return nil
        }
    }
    
    override func possibleNextStates() -> [ProvisioningState.Type] {
        return [ScanningState.self, CancelledState.self]
    }
}

/// 连接失败状态
class ConnectionFailedState: BaseProvisioningState {
    
    init() {
        super.init(
            name: "connectionFailed",
            description: "连接失败"
        )
    }
    
    override func handle(event: ProvisioningEvent, context: ProvisioningContext) -> ProvisioningState? {
        switch event {
        case .retry:
            return ConnectingState()
        case .selectDifferentDevice:
            return DeviceSelectionState()
        case .cancel:
            return CancelledState()
        default:
            return nil
        }
    }
    
    override func possibleNextStates() -> [ProvisioningState.Type] {
        return [ConnectingState.self, DeviceSelectionState.self, CancelledState.self]
    }
}

/// 认证失败状态
class AuthenticationFailedState: BaseProvisioningState {
    
    init() {
        super.init(
            name: "authenticationFailed",
            description: "认证失败"
        )
    }
    
    override func handle(event: ProvisioningEvent, context: ProvisioningContext) -> ProvisioningState? {
        switch event {
        case .retry:
            return AuthenticatingState()
        case .selectDifferentDevice:
            return DeviceSelectionState()
        case .cancel:
            return CancelledState()
        default:
            return nil
        }
    }
    
    override func possibleNextStates() -> [ProvisioningState.Type] {
        return [AuthenticatingState.self, DeviceSelectionState.self, CancelledState.self]
    }
}

/// 配置失败状态
class ConfigurationFailedState: BaseProvisioningState {
    
    init() {
        super.init(
            name: "configurationFailed",
            description: "配置失败"
        )
    }
    
    override func handle(event: ProvisioningEvent, context: ProvisioningContext) -> ProvisioningState? {
        switch event {
        case .retry:
            return ConfiguringState()
        case .reconfigure:
            return ConfiguringState() // 可以重新配置
        case .cancel:
            return CancelledState()
        default:
            return nil
        }
    }
    
    override func possibleNextStates() -> [ProvisioningState.Type] {
        return [ConfiguringState.self, CancelledState.self]
    }
}

/// 验证失败状态
class VerificationFailedState: BaseProvisioningState {
    
    init() {
        super.init(
            name: "verificationFailed",
            description: "验证失败"
        )
    }
    
    override func handle(event: ProvisioningEvent, context: ProvisioningContext) -> ProvisioningState? {
        switch event {
        case .retry:
            return VerifyingState()
        case .reconfigure:
            return ConfiguringState()
        case .cancel:
            return CancelledState()
        default:
            return nil
        }
    }
    
    override func possibleNextStates() -> [ProvisioningState.Type] {
        return [VerifyingState.self, ConfiguringState.self, CancelledState.self]
    }
}

/// 通用错误状态
class ErrorState: BaseProvisioningState {
    
    let error: ProvisioningError
    
    init(error: ProvisioningError) {
        self.error = error
        super.init(
            name: "error",
            description: "配网出错: \(error.localizedDescription)"
        )
    }
    
    override func handle(event: ProvisioningEvent, context: ProvisioningContext) -> ProvisioningState? {
        switch event {
        case .retry:
            return IdleState()
        case .cancel:
            return CancelledState()
        default:
            return nil
        }
    }
    
    override func possibleNextStates() -> [ProvisioningState.Type] {
        return [IdleState.self, CancelledState.self]
    }
}

// MARK: - Final States

/// 取消中状态
class CancellingState: BaseProvisioningState {
    
    init() {
        super.init(
            name: "cancelling",
            description: "正在取消配网",
            canCancel: false
        )
    }
    
    override func enter(context: ProvisioningContext) -> AnyPublisher<ProvisioningEvent, ProvisioningError> {
        // 执行清理操作
        context.cleanup()
        
        return Just(ProvisioningEvent.cancelled)
            .setFailureType(to: ProvisioningError.self)
            .eraseToAnyPublisher()
    }
    
    override func handle(event: ProvisioningEvent, context: ProvisioningContext) -> ProvisioningState? {
        switch event {
        case .cancelled:
            return CancelledState()
        default:
            return nil
        }
    }
    
    override func possibleNextStates() -> [ProvisioningState.Type] {
        return [CancelledState.self]
    }
}

/// 已取消状态
class CancelledState: BaseProvisioningState {
    
    init() {
        super.init(
            name: "cancelled",
            description: "配网已取消",
            canCancel: false,
            isFinalState: true
        )
    }
    
    override func handle(event: ProvisioningEvent, context: ProvisioningContext) -> ProvisioningState? {
        switch event {
        case .restart:
            return IdleState()
        default:
            return nil
        }
    }
    
    override func possibleNextStates() -> [ProvisioningState.Type] {
        return [IdleState.self]
    }
}

/// 完成状态
class CompletedState: BaseProvisioningState {
    
    init() {
        super.init(
            name: "completed",
            description: "配网完成",
            canCancel: false,
            isFinalState: true
        )
    }
    
    override func enter(context: ProvisioningContext) -> AnyPublisher<ProvisioningEvent, ProvisioningError> {
        // 保存配网结果
        if let device = context.selectedDevice {
            context.saveProvisionedDevice(device)
        }
        
        return Empty().eraseToAnyPublisher()
    }
    
    override func handle(event: ProvisioningEvent, context: ProvisioningContext) -> ProvisioningState? {
        switch event {
        case .restart:
            return IdleState()
        default:
            return nil
        }
    }
    
    override func possibleNextStates() -> [ProvisioningState.Type] {
        return [IdleState.self]
    }
}

// MARK: - State Factory

/// 状态工厂
class ProvisioningStateFactory {
    
    /// 创建初始状态
    static func createInitialState() -> ProvisioningState {
        return IdleState()
    }
    
    /// 根据名称创建状态
    static func createState(named name: String) -> ProvisioningState? {
        switch name {
        case "idle":
            return IdleState()
        case "scanning":
            return ScanningState()
        case "deviceSelection":
            return DeviceSelectionState()
        case "connecting":
            return ConnectingState()
        case "authenticating":
            return AuthenticatingState()
        case "configuring":
            return ConfiguringState()
        case "verifying":
            return VerifyingState()
        case "scanTimeout":
            return ScanTimeoutState()
        case "connectionFailed":
            return ConnectionFailedState()
        case "authenticationFailed":
            return AuthenticationFailedState()
        case "configurationFailed":
            return ConfigurationFailedState()
        case "verificationFailed":
            return VerificationFailedState()
        case "cancelling":
            return CancellingState()
        case "cancelled":
            return CancelledState()
        case "completed":
            return CompletedState()
        default:
            return nil
        }
    }
    
    /// 获取所有可用状态
    static func allStates() -> [ProvisioningState.Type] {
        return [
            IdleState.self,
            ScanningState.self,
            DeviceSelectionState.self,
            ConnectingState.self,
            AuthenticatingState.self,
            ConfiguringState.self,
            VerifyingState.self,
            ScanTimeoutState.self,
            ConnectionFailedState.self,
            AuthenticationFailedState.self,
            ConfigurationFailedState.self,
            VerificationFailedState.self,
            ErrorState.self,
            CancellingState.self,
            CancelledState.self,
            CompletedState.self
        ]
    }
}