//
//  DeviceControllers.swift
//  DeviceControlModule
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine
import UIKit

// MARK: - Base Device Controller

/// 基础设备控制器
open class BaseDeviceController: DeviceControllerProtocol {
    public let controllerId: String
    public let deviceId: String
    public var controlState: DeviceControlState = .idle
    
    private let controlService: DeviceControlServiceProtocol
    private let commandFactory: CommandFactoryProtocol
    private var cancellables = Set<AnyCancellable>()
    private let stateSubject = CurrentValueSubject<DeviceControlState, Never>(.idle)
    
    public init(
        controllerId: String = UUID().uuidString,
        deviceId: String,
        controlService: DeviceControlServiceProtocol,
        commandFactory: CommandFactoryProtocol = DeviceCommandFactory()
    ) {
        self.controllerId = controllerId
        self.deviceId = deviceId
        self.controlService = controlService
        self.commandFactory = commandFactory
        
        setupStateBinding()
    }
    
    private func setupStateBinding() {
        stateSubject
            .sink { [weak self] newState in
                self?.controlState = newState
            }
            .store(in: &cancellables)
    }
    
    public func executeCommand(_ command: DeviceCommandProtocol) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        guard controlState != .busy else {
            return Fail(error: DeviceControlError.controllerBusy("Controller is currently busy"))
                .eraseToAnyPublisher()
        }
        
        stateSubject.send(.busy)
        
        return controlService.executeCommand(command)
            .handleEvents(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        self?.stateSubject.send(.idle)
                    case .failure:
                        self?.stateSubject.send(.error)
                    }
                }
            )
            .eraseToAnyPublisher()
    }
    
    public func getDeviceStatus() -> AnyPublisher<DeviceStatus, DeviceControlError> {
        return controlService.getDeviceStatus(deviceId)
    }
    
    public func startMonitoring() {
        controlService.startMonitoring(deviceId)
    }
    
    public func stopMonitoring() {
        controlService.stopMonitoring(deviceId)
    }
    
    public func getControlStatePublisher() -> AnyPublisher<DeviceControlState, Never> {
        return stateSubject.eraseToAnyPublisher()
    }
    
    deinit {
        stopMonitoring()
    }
}

// MARK: - Light Controller

/// 灯光控制器
public class LightController: BaseDeviceController {
    private var currentBrightness: Int = 0
    private var currentColor: DeviceColor = DeviceColor(red: 255, green: 255, blue: 255)
    private var isOn: Bool = false
    
    public override init(
        controllerId: String = UUID().uuidString,
        deviceId: String,
        controlService: DeviceControlServiceProtocol,
        commandFactory: CommandFactoryProtocol = DeviceCommandFactory()
    ) {
        super.init(
            controllerId: controllerId,
            deviceId: deviceId,
            controlService: controlService,
            commandFactory: commandFactory
        )
    }
    
    /// 开关灯
    public func switchLight(isOn: Bool) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let command = commandFactory.createSwitchCommand(deviceId: deviceId, isOn: isOn)
        
        return executeCommand(command)
            .handleEvents(receiveOutput: { [weak self] result in
                if result.success {
                    self?.isOn = isOn
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// 调节亮度
    public func setBrightness(_ brightness: Int) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let clampedBrightness = max(0, min(100, brightness))
        let command = commandFactory.createDimmingCommand(deviceId: deviceId, brightness: clampedBrightness)
        
        return executeCommand(command)
            .handleEvents(receiveOutput: { [weak self] result in
                if result.success {
                    self?.currentBrightness = clampedBrightness
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// 设置颜色
    public func setColor(_ color: DeviceColor) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let command = commandFactory.createColorCommand(deviceId: deviceId, color: color)
        
        return executeCommand(command)
            .handleEvents(receiveOutput: { [weak self] result in
                if result.success {
                    self?.currentColor = color
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// 设置场景
    public func setScene(_ sceneId: String) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let command = commandFactory.createSceneCommand(deviceId: deviceId, sceneId: sceneId)
        return executeCommand(command)
    }
    
    /// 获取当前状态
    public func getCurrentLightState() -> (isOn: Bool, brightness: Int, color: DeviceColor) {
        return (isOn: isOn, brightness: currentBrightness, color: currentColor)
    }
    
    /// 渐变调光
    public func fadeTobrightness(_ targetBrightness: Int, duration: TimeInterval) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let steps = max(1, Int(duration * 10)) // 每100ms一步
        let stepSize = (targetBrightness - currentBrightness) / steps
        
        return Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .scan(currentBrightness) { current, _ in
                let next = current + stepSize
                return (stepSize > 0) ? min(next, targetBrightness) : max(next, targetBrightness)
            }
            .prefix(steps)
            .flatMap { [weak self] brightness -> AnyPublisher<DeviceCommandResult, DeviceControlError> in
                guard let self = self else {
                    return Fail(error: DeviceControlError.controllerNotInitialized("Controller deallocated"))
                        .eraseToAnyPublisher()
                }
                return self.setBrightness(brightness)
            }
            .last()
            .eraseToAnyPublisher()
    }
}

// MARK: - Switch Controller

/// 开关控制器
public class SwitchController: BaseDeviceController {
    private var isOn: Bool = false
    
    /// 切换开关状态
    public func toggle() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        return switchTo(!isOn)
    }
    
    /// 设置开关状态
    public func switchTo(_ state: Bool) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let command = commandFactory.createSwitchCommand(deviceId: deviceId, isOn: state)
        
        return executeCommand(command)
            .handleEvents(receiveOutput: { [weak self] result in
                if result.success {
                    self?.isOn = state
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// 获取当前开关状态
    public func getCurrentState() -> Bool {
        return isOn
    }
}

// MARK: - Thermostat Controller

/// 温控器控制器
public class ThermostatController: BaseDeviceController {
    private var currentTemperature: Double = 20.0
    private var targetTemperature: Double = 22.0
    private var isHeating: Bool = false
    private var isCooling: Bool = false
    
    /// 设置目标温度
    public func setTargetTemperature(_ temperature: Double) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let command = commandFactory.createTemperatureCommand(deviceId: deviceId, temperature: temperature)
        
        return executeCommand(command)
            .handleEvents(receiveOutput: { [weak self] result in
                if result.success {
                    self?.targetTemperature = temperature
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// 调整温度（相对调整）
    public func adjustTemperature(by delta: Double) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let newTarget = targetTemperature + delta
        return setTargetTemperature(newTarget)
    }
    
    /// 设置加热模式
    public func setHeatingMode(_ enabled: Bool) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let parameters = ["heatingMode": enabled]
        let command = commandFactory.createCustomCommand(
            deviceId: deviceId,
            commandType: .custom,
            parameters: parameters
        )
        
        return executeCommand(command)
            .handleEvents(receiveOutput: { [weak self] result in
                if result.success {
                    self?.isHeating = enabled
                    if enabled {
                        self?.isCooling = false
                    }
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// 设置制冷模式
    public func setCoolingMode(_ enabled: Bool) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let parameters = ["coolingMode": enabled]
        let command = commandFactory.createCustomCommand(
            deviceId: deviceId,
            commandType: .custom,
            parameters: parameters
        )
        
        return executeCommand(command)
            .handleEvents(receiveOutput: { [weak self] result in
                if result.success {
                    self?.isCooling = enabled
                    if enabled {
                        self?.isHeating = false
                    }
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// 获取当前温控状态
    public func getCurrentThermostatState() -> (current: Double, target: Double, isHeating: Bool, isCooling: Bool) {
        return (current: currentTemperature, target: targetTemperature, isHeating: isHeating, isCooling: isCooling)
    }
}

// MARK: - Sensor Controller

/// 传感器控制器
public class SensorController: BaseDeviceController {
    private var sensorReadings: [String: Any] = [:]
    private var lastReadingTime: Date = Date()
    
    /// 读取传感器数据
    public func readSensorData() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let command = commandFactory.createCustomCommand(
            deviceId: deviceId,
            commandType: .getStatus,
            parameters: ["readSensors": true]
        )
        
        return executeCommand(command)
            .handleEvents(receiveOutput: { [weak self] result in
                if result.success, let data = result.resultData {
                    self?.sensorReadings = data
                    self?.lastReadingTime = Date()
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// 获取特定传感器读数
    public func getSensorReading(for sensorType: String) -> Any? {
        return sensorReadings[sensorType]
    }
    
    /// 获取所有传感器读数
    public func getAllSensorReadings() -> [String: Any] {
        return sensorReadings
    }
    
    /// 获取最后读取时间
    public func getLastReadingTime() -> Date {
        return lastReadingTime
    }
    
    /// 设置传感器采样间隔
    public func setSamplingInterval(_ interval: TimeInterval) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let parameters = ["samplingInterval": interval]
        let command = commandFactory.createCustomCommand(
            deviceId: deviceId,
            commandType: .custom,
            parameters: parameters
        )
        
        return executeCommand(command)
    }
}

// MARK: - Camera Controller

/// 摄像头控制器
public class CameraController: BaseDeviceController {
    private var isRecording: Bool = false
    private var currentResolution: String = "1080p"
    private var currentFrameRate: Int = 30
    
    /// 开始录制
    public func startRecording() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let parameters = ["action": "startRecording"]
        let command = commandFactory.createCustomCommand(
            deviceId: deviceId,
            commandType: .custom,
            parameters: parameters
        )
        
        return executeCommand(command)
            .handleEvents(receiveOutput: { [weak self] result in
                if result.success {
                    self?.isRecording = true
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// 停止录制
    public func stopRecording() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let parameters = ["action": "stopRecording"]
        let command = commandFactory.createCustomCommand(
            deviceId: deviceId,
            commandType: .custom,
            parameters: parameters
        )
        
        return executeCommand(command)
            .handleEvents(receiveOutput: { [weak self] result in
                if result.success {
                    self?.isRecording = false
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// 拍照
    public func takeSnapshot() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let parameters = ["action": "takeSnapshot"]
        let command = commandFactory.createCustomCommand(
            deviceId: deviceId,
            commandType: .custom,
            parameters: parameters
        )
        
        return executeCommand(command)
    }
    
    /// 设置分辨率
    public func setResolution(_ resolution: String) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let parameters = ["resolution": resolution]
        let command = commandFactory.createCustomCommand(
            deviceId: deviceId,
            commandType: .custom,
            parameters: parameters
        )
        
        return executeCommand(command)
            .handleEvents(receiveOutput: { [weak self] result in
                if result.success {
                    self?.currentResolution = resolution
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// 设置帧率
    public func setFrameRate(_ frameRate: Int) -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let parameters = ["frameRate": frameRate]
        let command = commandFactory.createCustomCommand(
            deviceId: deviceId,
            commandType: .custom,
            parameters: parameters
        )
        
        return executeCommand(command)
            .handleEvents(receiveOutput: { [weak self] result in
                if result.success {
                    self?.currentFrameRate = frameRate
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// 获取当前摄像头状态
    public func getCurrentCameraState() -> (isRecording: Bool, resolution: String, frameRate: Int) {
        return (isRecording: isRecording, resolution: currentResolution, frameRate: currentFrameRate)
    }
}

// MARK: - Multi-Device Controller

/// 多设备控制器
public class MultiDeviceController {
    private var deviceControllers: [String: BaseDeviceController] = [:]
    private let controlService: DeviceControlServiceProtocol
    private let commandFactory: CommandFactoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        controlService: DeviceControlServiceProtocol,
        commandFactory: CommandFactoryProtocol = DeviceCommandFactory()
    ) {
        self.controlService = controlService
        self.commandFactory = commandFactory
    }
    
    /// 添加设备控制器
    public func addDeviceController(_ controller: BaseDeviceController) {
        deviceControllers[controller.deviceId] = controller
    }
    
    /// 移除设备控制器
    public func removeDeviceController(deviceId: String) {
        deviceControllers.removeValue(forKey: deviceId)
    }
    
    /// 获取设备控制器
    public func getDeviceController(deviceId: String) -> BaseDeviceController? {
        return deviceControllers[deviceId]
    }
    
    /// 获取特定类型的设备控制器
    public func getDeviceController<T: BaseDeviceController>(deviceId: String, type: T.Type) -> T? {
        return deviceControllers[deviceId] as? T
    }
    
    /// 批量执行命令
    public func executeBatchCommands(_ commands: [DeviceCommandProtocol]) -> AnyPublisher<[DeviceCommandResult], DeviceControlError> {
        let batchCommand = commandFactory.createBatchCommand(commands: commands.compactMap { $0 as? DeviceCommand })
        
        return controlService.executeCommand(batchCommand)
            .map { result in
                // 解析批量命令结果
                if let subResults = result.resultData["subResults"] as? [[String: Any]] {
                    return subResults.compactMap { resultDict in
                        guard let commandId = resultDict["commandId"] as? String,
                              let success = resultDict["success"] as? Bool,
                              let executionTime = resultDict["executionTime"] as? TimeInterval else {
                            return nil
                        }
                        
                        return DeviceCommandResult(
                            commandId: commandId,
                            deviceId: "", // 需要从原始命令中获取
                            success: success,
                            resultData: [:],
                            executionTime: executionTime
                        )
                    }
                }
                return [result]
            }
            .eraseToAnyPublisher()
    }
    
    /// 同步所有设备状态
    public func syncAllDeviceStates() -> AnyPublisher<[DeviceStatus], DeviceControlError> {
        let deviceIds = Array(deviceControllers.keys)
        
        return Publishers.MergeMany(
            deviceIds.map { deviceId in
                controlService.getDeviceStatus(deviceId)
            }
        )
        .collect()
        .eraseToAnyPublisher()
    }
    
    /// 开始监控所有设备
    public func startMonitoringAllDevices() {
        deviceControllers.values.forEach { controller in
            controller.startMonitoring()
        }
    }
    
    /// 停止监控所有设备
    public func stopMonitoringAllDevices() {
        deviceControllers.values.forEach { controller in
            controller.stopMonitoring()
        }
    }
    
    /// 获取所有设备的控制状态
    public func getAllControlStates() -> [String: DeviceControlState] {
        return deviceControllers.mapValues { $0.controlState }
    }
    
    /// 创建设备控制器工厂方法
    public func createDeviceController(for deviceInfo: DeviceInfo) -> BaseDeviceController? {
        switch deviceInfo.deviceType {
        case .light:
            return LightController(
                deviceId: deviceInfo.deviceId,
                controlService: controlService,
                commandFactory: commandFactory
            )
        case .switch:
            return SwitchController(
                deviceId: deviceInfo.deviceId,
                controlService: controlService,
                commandFactory: commandFactory
            )
        case .thermostat:
            return ThermostatController(
                deviceId: deviceInfo.deviceId,
                controlService: controlService,
                commandFactory: commandFactory
            )
        case .sensor:
            return SensorController(
                deviceId: deviceInfo.deviceId,
                controlService: controlService,
                commandFactory: commandFactory
            )
        case .camera:
            return CameraController(
                deviceId: deviceInfo.deviceId,
                controlService: controlService,
                commandFactory: commandFactory
            )
        default:
            return BaseDeviceController(
                deviceId: deviceInfo.deviceId,
                controlService: controlService,
                commandFactory: commandFactory
            )
        }
    }
}

// MARK: - Device Control Strategy Implementation

/// 设备控制策略实现
public class DeviceControlStrategy: DeviceControlStrategyProtocol {
    public let strategyType: ControlStrategyType
    
    public init(strategyType: ControlStrategyType) {
        self.strategyType = strategyType
    }
    
    public func shouldExecuteCommand(_ command: DeviceCommandProtocol, for device: DeviceInfo) -> Bool {
        switch strategyType {
        case .immediate:
            return true
        case .queued:
            return true // 总是允许入队
        case .scheduled:
            // 检查是否在允许的时间窗口内
            return isWithinAllowedTimeWindow()
        case .conditional:
            // 检查设备状态和条件
            return checkExecutionConditions(command, device)
        }
    }
    
    public func getExecutionPriority(_ command: DeviceCommandProtocol, for device: DeviceInfo) -> CommandPriority {
        switch strategyType {
        case .immediate:
            return .high
        case .queued:
            return command.priority
        case .scheduled:
            return .normal
        case .conditional:
            return evaluateConditionalPriority(command, device)
        }
    }
    
    public func getRetryPolicy(_ command: DeviceCommandProtocol, for device: DeviceInfo) -> (maxRetries: Int, retryDelay: TimeInterval) {
        switch strategyType {
        case .immediate:
            return (maxRetries: 1, retryDelay: 0.5)
        case .queued:
            return (maxRetries: 3, retryDelay: 1.0)
        case .scheduled:
            return (maxRetries: 2, retryDelay: 2.0)
        case .conditional:
            return (maxRetries: 5, retryDelay: 1.5)
        }
    }
    
    public func handleExecutionFailure(_ command: DeviceCommandProtocol, error: DeviceControlError, for device: DeviceInfo) {
        switch strategyType {
        case .immediate:
            // 立即策略失败时，记录错误
            print("Immediate execution failed for device \(device.deviceId): \(error.localizedDescription)")
        case .queued:
            // 队列策略失败时，可能需要重新入队
            print("Queued execution failed for device \(device.deviceId): \(error.localizedDescription)")
        case .scheduled:
            // 计划策略失败时，可能需要重新安排
            print("Scheduled execution failed for device \(device.deviceId): \(error.localizedDescription)")
        case .conditional:
            // 条件策略失败时，重新评估条件
            print("Conditional execution failed for device \(device.deviceId): \(error.localizedDescription)")
        }
    }
    
    private func isWithinAllowedTimeWindow() -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        // 假设允许的时间窗口是 6:00 - 22:00
        return hour >= 6 && hour <= 22
    }
    
    private func checkExecutionConditions(_ command: DeviceCommandProtocol, _ device: DeviceInfo) -> Bool {
        // 实现具体的条件检查逻辑
        // 例如：检查设备是否在线、电池电量是否充足等
        return true
    }
    
    private func evaluateConditionalPriority(_ command: DeviceCommandProtocol, _ device: DeviceInfo) -> CommandPriority {
        // 根据设备状态和命令类型评估优先级
        switch command.commandType {
        case .switchOn, .switchOff:
            return .high
        case .setBrightness, .setColor:
            return .normal
        case .setTemperature:
            return .high
        case .getStatus:
            return .low
        default:
            return .normal
        }
    }
}