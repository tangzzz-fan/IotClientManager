//
//  DeviceCommands.swift
//  DeviceControlModule
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

// MARK: - Base Command Classes

/// 基础设备命令
open class BaseDeviceCommand: DeviceCommandProtocol {
    public let commandId: String
    public let commandType: DeviceCommandType
    public let targetDeviceId: String
    public let parameters: [String: Any]
    public let priority: CommandPriority
    public let timeout: TimeInterval
    public let retryCount: Int
    public let createdAt: Date
    
    private var cancellables = Set<AnyCancellable>()
    private var isExecuting = false
    private var isCancelled = false
    
    public init(commandId: String = UUID().uuidString, commandType: DeviceCommandType, targetDeviceId: String, parameters: [String: Any] = [:], priority: CommandPriority = .normal, timeout: TimeInterval = 30.0, retryCount: Int = 3) {
        self.commandId = commandId
        self.commandType = commandType
        self.targetDeviceId = targetDeviceId
        self.parameters = parameters
        self.priority = priority
        self.timeout = timeout
        self.retryCount = retryCount
        self.createdAt = Date()
    }
    
    open func execute() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        guard !isCancelled else {
            return Fail(error: DeviceControlError.commandExecutionFailed("Command was cancelled"))
                .eraseToAnyPublisher()
        }
        
        guard validateParameters() else {
            return Fail(error: DeviceControlError.invalidParameters("Invalid command parameters"))
                .eraseToAnyPublisher()
        }
        
        isExecuting = true
        
        return executeInternal()
            .timeout(.seconds(timeout), scheduler: DispatchQueue.main)
            .catch { error -> AnyPublisher<DeviceCommandResult, DeviceControlError> in
                if error is DeviceControlError {
                    return Fail(error: error as! DeviceControlError).eraseToAnyPublisher()
                } else {
                    return Fail(error: DeviceControlError.commandTimeout("Command execution timeout")).eraseToAnyPublisher()
                }
            }
            .handleEvents(receiveCompletion: { [weak self] _ in
                self?.isExecuting = false
            })
            .eraseToAnyPublisher()
    }
    
    open func executeInternal() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        // 子类需要重写此方法实现具体的执行逻辑
        return Fail(error: DeviceControlError.commandNotSupported("Command execution not implemented"))
            .eraseToAnyPublisher()
    }
    
    public func cancel() {
        isCancelled = true
        isExecuting = false
        cancellables.removeAll()
    }
    
    open func validateParameters() -> Bool {
        // 基础验证逻辑，子类可以重写
        return true
    }
    
    public func getDescription() -> String {
        return "\(commandType.displayName) - 设备: \(targetDeviceId)"
    }
}

/// 可重试命令
open class RetryableCommand: BaseDeviceCommand {
    private var currentRetryCount = 0
    
    public override func execute() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        return executeWithRetry()
    }
    
    private func executeWithRetry() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        return super.execute()
            .catch { [weak self] error -> AnyPublisher<DeviceCommandResult, DeviceControlError> in
                guard let self = self else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
                
                if self.currentRetryCount < self.retryCount {
                    self.currentRetryCount += 1
                    
                    // 指数退避延迟
                    let delay = pow(2.0, Double(self.currentRetryCount))
                    
                    return Just(())
                        .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
                        .flatMap { _ in
                            self.executeWithRetry()
                        }
                        .eraseToAnyPublisher()
                } else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Specific Command Implementations

/// 开关命令
public class SwitchCommand: RetryableCommand {
    public let isOn: Bool
    
    public init(deviceId: String, isOn: Bool, priority: CommandPriority = .normal) {
        self.isOn = isOn
        let commandType: DeviceCommandType = isOn ? .switchOn : .switchOff
        let parameters = ["state": isOn]
        
        super.init(
            commandType: commandType,
            targetDeviceId: deviceId,
            parameters: parameters,
            priority: priority
        )
    }
    
    public override func executeInternal() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        // 模拟开关命令执行
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(DeviceControlError.commandExecutionFailed("Command instance deallocated")))
                return
            }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                let result = DeviceCommandResult(
                    commandId: self.commandId,
                    deviceId: self.targetDeviceId,
                    success: true,
                    resultData: ["state": self.isOn],
                    executionTime: 0.5
                )
                promise(.success(result))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public override func validateParameters() -> Bool {
        return parameters["state"] != nil
    }
}

/// 调光命令
public class DimmingCommand: RetryableCommand {
    public let brightness: Int
    
    public init(deviceId: String, brightness: Int, priority: CommandPriority = .normal) {
        self.brightness = max(0, min(100, brightness))
        let parameters = ["brightness": self.brightness]
        
        super.init(
            commandType: .setBrightness,
            targetDeviceId: deviceId,
            parameters: parameters,
            priority: priority
        )
    }
    
    public override func executeInternal() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(DeviceControlError.commandExecutionFailed("Command instance deallocated")))
                return
            }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
                let result = DeviceCommandResult(
                    commandId: self.commandId,
                    deviceId: self.targetDeviceId,
                    success: true,
                    resultData: ["brightness": self.brightness],
                    executionTime: 0.3
                )
                promise(.success(result))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public override func validateParameters() -> Bool {
        guard let brightness = parameters["brightness"] as? Int else {
            return false
        }
        return brightness >= 0 && brightness <= 100
    }
}

/// 颜色控制命令
public class ColorCommand: RetryableCommand {
    public let color: DeviceColor
    
    public init(deviceId: String, color: DeviceColor, priority: CommandPriority = .normal) {
        self.color = color
        let parameters: [String: Any] = [
            "color": [
                "red": color.red,
                "green": color.green,
                "blue": color.blue,
                "alpha": color.alpha
            ]
        ]
        
        super.init(
            commandType: .setColor,
            targetDeviceId: deviceId,
            parameters: parameters,
            priority: priority
        )
    }
    
    public override func executeInternal() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(DeviceControlError.commandExecutionFailed("Command instance deallocated")))
                return
            }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.4) {
                let result = DeviceCommandResult(
                    commandId: self.commandId,
                    deviceId: self.targetDeviceId,
                    success: true,
                    resultData: [
                        "color": [
                            "red": self.color.red,
                            "green": self.color.green,
                            "blue": self.color.blue,
                            "alpha": self.color.alpha
                        ]
                    ],
                    executionTime: 0.4
                )
                promise(.success(result))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public override func validateParameters() -> Bool {
        guard let colorDict = parameters["color"] as? [String: Any],
              let red = colorDict["red"] as? Int,
              let green = colorDict["green"] as? Int,
              let blue = colorDict["blue"] as? Int else {
            return false
        }
        
        return red >= 0 && red <= 255 &&
               green >= 0 && green <= 255 &&
               blue >= 0 && blue <= 255
    }
}

/// 温度控制命令
public class TemperatureCommand: RetryableCommand {
    public let temperature: Double
    
    public init(deviceId: String, temperature: Double, priority: CommandPriority = .normal) {
        self.temperature = temperature
        let parameters = ["temperature": temperature]
        
        super.init(
            commandType: .setTemperature,
            targetDeviceId: deviceId,
            parameters: parameters,
            priority: priority
        )
    }
    
    public override func executeInternal() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(DeviceControlError.commandExecutionFailed("Command instance deallocated")))
                return
            }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.6) {
                let result = DeviceCommandResult(
                    commandId: self.commandId,
                    deviceId: self.targetDeviceId,
                    success: true,
                    resultData: ["temperature": self.temperature],
                    executionTime: 0.6
                )
                promise(.success(result))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public override func validateParameters() -> Bool {
        guard let temperature = parameters["temperature"] as? Double else {
            return false
        }
        // 假设温度范围为 -50°C 到 100°C
        return temperature >= -50.0 && temperature <= 100.0
    }
}

/// 场景命令
public class SceneCommand: RetryableCommand {
    public let sceneId: String
    
    public init(deviceId: String, sceneId: String, priority: CommandPriority = .normal) {
        self.sceneId = sceneId
        let parameters = ["sceneId": sceneId]
        
        super.init(
            commandType: .setScene,
            targetDeviceId: deviceId,
            parameters: parameters,
            priority: priority
        )
    }
    
    public override func executeInternal() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(DeviceControlError.commandExecutionFailed("Command instance deallocated")))
                return
            }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) {
                let result = DeviceCommandResult(
                    commandId: self.commandId,
                    deviceId: self.targetDeviceId,
                    success: true,
                    resultData: ["sceneId": self.sceneId],
                    executionTime: 0.8
                )
                promise(.success(result))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public override func validateParameters() -> Bool {
        guard let sceneId = parameters["sceneId"] as? String else {
            return false
        }
        return !sceneId.isEmpty
    }
}

/// 定时命令
public class TimerCommand: RetryableCommand {
    public let timerConfig: TimerConfiguration
    
    public init(deviceId: String, timerConfig: TimerConfiguration, priority: CommandPriority = .normal) {
        self.timerConfig = timerConfig
        let parameters: [String: Any] = [
            "timerId": timerConfig.timerId,
            "name": timerConfig.name,
            "triggerTime": timerConfig.triggerTime.timeIntervalSince1970,
            "repeatMode": timerConfig.repeatMode.rawValue,
            "isEnabled": timerConfig.isEnabled
        ]
        
        super.init(
            commandType: .setTimer,
            targetDeviceId: deviceId,
            parameters: parameters,
            priority: priority
        )
    }
    
    public override func executeInternal() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(DeviceControlError.commandExecutionFailed("Command instance deallocated")))
                return
            }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                let result = DeviceCommandResult(
                    commandId: self.commandId,
                    deviceId: self.targetDeviceId,
                    success: true,
                    resultData: [
                        "timerId": self.timerConfig.timerId,
                        "status": "configured"
                    ],
                    executionTime: 0.2
                )
                promise(.success(result))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public override func validateParameters() -> Bool {
        guard let timerId = parameters["timerId"] as? String,
              let name = parameters["name"] as? String,
              let triggerTime = parameters["triggerTime"] as? TimeInterval,
              let repeatMode = parameters["repeatMode"] as? String else {
            return false
        }
        
        return !timerId.isEmpty && !name.isEmpty && triggerTime > 0 && !repeatMode.isEmpty
    }
}

/// 状态查询命令
public class StatusCommand: BaseDeviceCommand {
    public init(deviceId: String, priority: CommandPriority = .normal) {
        super.init(
            commandType: .getStatus,
            targetDeviceId: deviceId,
            parameters: [:],
            priority: priority,
            timeout: 10.0
        )
    }
    
    public override func executeInternal() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(DeviceControlError.commandExecutionFailed("Command instance deallocated")))
                return
            }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                let result = DeviceCommandResult(
                    commandId: self.commandId,
                    deviceId: self.targetDeviceId,
                    success: true,
                    resultData: [
                        "connectionState": "connected",
                        "controlState": "idle",
                        "batteryLevel": 85,
                        "signalStrength": 75,
                        "lastUpdateTime": Date().timeIntervalSince1970
                    ],
                    executionTime: 0.1
                )
                promise(.success(result))
            }
        }
        .eraseToAnyPublisher()
    }
}

/// 自定义命令
public class CustomCommand: RetryableCommand {
    public let customParameters: [String: Any]
    
    public init(deviceId: String, customCommandType: String, customParameters: [String: Any], priority: CommandPriority = .normal) {
        self.customParameters = customParameters
        var parameters = customParameters
        parameters["customCommandType"] = customCommandType
        
        super.init(
            commandType: .custom,
            targetDeviceId: deviceId,
            parameters: parameters,
            priority: priority
        )
    }
    
    public override func executeInternal() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(DeviceControlError.commandExecutionFailed("Command instance deallocated")))
                return
            }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                let result = DeviceCommandResult(
                    commandId: self.commandId,
                    deviceId: self.targetDeviceId,
                    success: true,
                    resultData: self.customParameters,
                    executionTime: 1.0
                )
                promise(.success(result))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public override func validateParameters() -> Bool {
        guard let customCommandType = parameters["customCommandType"] as? String else {
            return false
        }
        return !customCommandType.isEmpty
    }
}

// MARK: - Composite Commands

/// 复合命令（批量执行多个命令）
public class CompositeCommand: BaseDeviceCommand {
    public let subCommands: [BaseDeviceCommand]
    public let executionMode: BatchExecutionMode
    
    public init(deviceId: String, subCommands: [BaseDeviceCommand], executionMode: BatchExecutionMode = .sequential, priority: CommandPriority = .normal) {
        self.subCommands = subCommands
        self.executionMode = executionMode
        
        let parameters: [String: Any] = [
            "subCommandCount": subCommands.count,
            "executionMode": executionMode.rawValue
        ]
        
        super.init(
            commandType: .custom,
            targetDeviceId: deviceId,
            parameters: parameters,
            priority: priority,
            timeout: 60.0
        )
    }
    
    public override func executeInternal() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        switch executionMode {
        case .sequential:
            return executeSequentially()
        case .parallel:
            return executeInParallel()
        case .conditional:
            return executeConditionally()
        }
    }
    
    private func executeSequentially() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let startTime = Date()
        
        return subCommands.publisher
            .flatMap(maxPublishers: .max(1)) { command in
                command.execute()
            }
            .collect()
            .map { results in
                let executionTime = Date().timeIntervalSince(startTime)
                let successCount = results.filter { $0.success }.count
                
                return DeviceCommandResult(
                    commandId: self.commandId,
                    deviceId: self.targetDeviceId,
                    success: successCount == results.count,
                    resultData: [
                        "subResults": results.map { result in
                            [
                                "commandId": result.commandId,
                                "success": result.success,
                                "executionTime": result.executionTime
                            ]
                        },
                        "successCount": successCount,
                        "totalCount": results.count
                    ],
                    executionTime: executionTime
                )
            }
            .eraseToAnyPublisher()
    }
    
    private func executeInParallel() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let startTime = Date()
        
        return Publishers.MergeMany(subCommands.map { $0.execute() })
            .collect()
            .map { results in
                let executionTime = Date().timeIntervalSince(startTime)
                let successCount = results.filter { $0.success }.count
                
                return DeviceCommandResult(
                    commandId: self.commandId,
                    deviceId: self.targetDeviceId,
                    success: successCount == results.count,
                    resultData: [
                        "subResults": results.map { result in
                            [
                                "commandId": result.commandId,
                                "success": result.success,
                                "executionTime": result.executionTime
                            ]
                        },
                        "successCount": successCount,
                        "totalCount": results.count,
                        "executionMode": "parallel"
                    ],
                    executionTime: executionTime
                )
            }
            .eraseToAnyPublisher()
    }
    
    private func executeConditionally() -> AnyPublisher<DeviceCommandResult, DeviceControlError> {
        let startTime = Date()
        var executedCommands: [DeviceCommandResult] = []
        
        return subCommands.publisher
            .flatMap(maxPublishers: .max(1)) { command -> AnyPublisher<DeviceCommandResult, DeviceControlError> in
                return command.execute()
                    .handleEvents(receiveOutput: { result in
                        executedCommands.append(result)
                    })
                    .flatMap { result -> AnyPublisher<DeviceCommandResult, DeviceControlError> in
                        // 如果命令失败，停止执行后续命令
                        if !result.success {
                            return Fail(error: DeviceControlError.commandExecutionFailed("Conditional execution stopped due to failure"))
                                .eraseToAnyPublisher()
                        }
                        return Just(result)
                            .setFailureType(to: DeviceControlError.self)
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .collect()
            .map { results in
                let executionTime = Date().timeIntervalSince(startTime)
                
                return DeviceCommandResult(
                    commandId: self.commandId,
                    deviceId: self.targetDeviceId,
                    success: true,
                    resultData: [
                        "subResults": executedCommands.map { result in
                            [
                                "commandId": result.commandId,
                                "success": result.success,
                                "executionTime": result.executionTime
                            ]
                        },
                        "executedCount": executedCommands.count,
                        "totalCount": self.subCommands.count,
                        "executionMode": "conditional"
                    ],
                    executionTime: executionTime
                )
            }
            .catch { error in
                let executionTime = Date().timeIntervalSince(startTime)
                
                return Just(DeviceCommandResult(
                    commandId: self.commandId,
                    deviceId: self.targetDeviceId,
                    success: false,
                    resultData: [
                        "subResults": executedCommands.map { result in
                            [
                                "commandId": result.commandId,
                                "success": result.success,
                                "executionTime": result.executionTime
                            ]
                        },
                        "executedCount": executedCommands.count,
                        "totalCount": self.subCommands.count,
                        "executionMode": "conditional",
                        "failureReason": error.localizedDescription
                    ],
                    errorCode: "CONDITIONAL_EXECUTION_FAILED",
                    errorMessage: error.localizedDescription,
                    executionTime: executionTime
                ))
            }
            .eraseToAnyPublisher()
    }
    
    public override func validateParameters() -> Bool {
        return !subCommands.isEmpty && subCommands.allSatisfy { $0.validateParameters() }
    }
    
    public override func cancel() {
        super.cancel()
        subCommands.forEach { $0.cancel() }
    }
}

// MARK: - Command Factory Implementation

/// 命令工厂实现
public class DeviceCommandFactory: CommandFactoryProtocol {
    public init() {}
    
    public func createSwitchCommand(deviceId: String, isOn: Bool) -> DeviceCommand {
        let switchCommand = SwitchCommand(deviceId: deviceId, isOn: isOn)
        return DeviceCommand(
            commandType: switchCommand.commandType,
            targetDeviceId: switchCommand.targetDeviceId,
            parameters: switchCommand.parameters,
            priority: switchCommand.priority
        )
    }
    
    public func createDimmingCommand(deviceId: String, brightness: Int) -> DeviceCommand {
        let dimmingCommand = DimmingCommand(deviceId: deviceId, brightness: brightness)
        return DeviceCommand(
            commandType: dimmingCommand.commandType,
            targetDeviceId: dimmingCommand.targetDeviceId,
            parameters: dimmingCommand.parameters,
            priority: dimmingCommand.priority
        )
    }
    
    public func createColorCommand(deviceId: String, color: DeviceColor) -> DeviceCommand {
        let colorCommand = ColorCommand(deviceId: deviceId, color: color)
        return DeviceCommand(
            commandType: colorCommand.commandType,
            targetDeviceId: colorCommand.targetDeviceId,
            parameters: colorCommand.parameters,
            priority: colorCommand.priority
        )
    }
    
    public func createTemperatureCommand(deviceId: String, temperature: Double) -> DeviceCommand {
        let temperatureCommand = TemperatureCommand(deviceId: deviceId, temperature: temperature)
        return DeviceCommand(
            commandType: temperatureCommand.commandType,
            targetDeviceId: temperatureCommand.targetDeviceId,
            parameters: temperatureCommand.parameters,
            priority: temperatureCommand.priority
        )
    }
    
    public func createSceneCommand(deviceId: String, sceneId: String) -> DeviceCommand {
        let sceneCommand = SceneCommand(deviceId: deviceId, sceneId: sceneId)
        return DeviceCommand(
            commandType: sceneCommand.commandType,
            targetDeviceId: sceneCommand.targetDeviceId,
            parameters: sceneCommand.parameters,
            priority: sceneCommand.priority
        )
    }
    
    public func createTimerCommand(deviceId: String, timerConfig: TimerConfiguration) -> DeviceCommand {
        let timerCommand = TimerCommand(deviceId: deviceId, timerConfig: timerConfig)
        return DeviceCommand(
            commandType: timerCommand.commandType,
            targetDeviceId: timerCommand.targetDeviceId,
            parameters: timerCommand.parameters,
            priority: timerCommand.priority
        )
    }
    
    public func createCustomCommand(deviceId: String, commandType: DeviceCommandType, parameters: [String: Any]) -> DeviceCommand {
        return DeviceCommand(
            commandType: commandType,
            targetDeviceId: deviceId,
            parameters: parameters,
            priority: .normal
        )
    }
    
    public func createBatchCommand(commands: [DeviceCommand]) -> BatchCommand {
        return BatchCommand(commands: commands)
    }
    
    public func validateCommandParameters(_ command: DeviceCommand) -> Bool {
        return command.validateParameters()
    }
    
    public func getCommandTemplate(for commandType: DeviceCommandType) -> CommandTemplate? {
        switch commandType {
        case .switchOn, .switchOff:
            return CommandTemplate(
                templateId: "switch_template",
                commandType: commandType,
                name: "开关控制",
                description: "控制设备的开关状态",
                parameterSchema: [
                    "state": ParameterDefinition(
                        name: "state",
                        type: .boolean,
                        required: true,
                        description: "开关状态"
                    )
                ],
                defaultValues: ["state": commandType == .switchOn]
            )
            
        case .setBrightness:
            return CommandTemplate(
                templateId: "brightness_template",
                commandType: commandType,
                name: "亮度控制",
                description: "控制设备的亮度",
                parameterSchema: [
                    "brightness": ParameterDefinition(
                        name: "brightness",
                        type: .integer,
                        required: true,
                        validation: ParameterValidation(minValue: 0, maxValue: 100),
                        description: "亮度值 (0-100)"
                    )
                ],
                defaultValues: ["brightness": 50]
            )
            
        case .setColor:
            return CommandTemplate(
                templateId: "color_template",
                commandType: commandType,
                name: "颜色控制",
                description: "控制设备的颜色",
                parameterSchema: [
                    "color": ParameterDefinition(
                        name: "color",
                        type: .object,
                        required: true,
                        description: "RGB颜色值"
                    )
                ]
            )
            
        case .setTemperature:
            return CommandTemplate(
                templateId: "temperature_template",
                commandType: commandType,
                name: "温度控制",
                description: "控制设备的温度",
                parameterSchema: [
                    "temperature": ParameterDefinition(
                        name: "temperature",
                        type: .double,
                        required: true,
                        validation: ParameterValidation(minValue: -50, maxValue: 100),
                        description: "温度值 (°C)"
                    )
                ],
                defaultValues: ["temperature": 20.0]
            )
            
        default:
            return nil
        }
    }
}