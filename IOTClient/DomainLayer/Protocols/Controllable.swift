//
//  Controllable.swift
//  DomainLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

/// 可控制设备协议
/// 定义了设备控制相关的方法和状态管理
public protocol Controllable {
    /// 设备当前状态
    var deviceState: DeviceState { get set }
    
    /// 支持的控制命令列表
    var supportedCommands: [DeviceCommand] { get }
    
    /// 当前正在执行的命令
    var currentCommand: DeviceCommand? { get set }
    
    /// 命令执行状态
    var commandExecutionState: CommandExecutionState { get set }
    
    /// 最后执行的命令
    var lastExecutedCommand: DeviceCommand? { get set }
    
    /// 最后命令执行时间
    var lastCommandExecutedAt: Date? { get set }
    
    /// 设备状态变化的发布者
    var deviceStatePublisher: AnyPublisher<DeviceState, Never> { get }
    
    /// 命令执行状态变化的发布者
    var commandExecutionPublisher: AnyPublisher<CommandExecutionState, Never> { get }
    
    /// 执行设备命令
    /// - Parameter command: 要执行的命令
    /// - Returns: 命令执行结果的发布者
    func executeCommand(_ command: DeviceCommand) -> AnyPublisher<CommandResult, DeviceError>
    
    /// 取消当前正在执行的命令
    func cancelCurrentCommand() -> AnyPublisher<Void, DeviceError>
    
    /// 检查是否支持指定命令
    /// - Parameter command: 要检查的命令
    /// - Returns: 是否支持该命令
    func supportsCommand(_ command: DeviceCommand) -> Bool
}

/// 设备状态枚举
public enum DeviceState: String, CaseIterable, Codable {
    case idle = "idle"
    case working = "working"
    case paused = "paused"
    case error = "error"
    case maintenance = "maintenance"
    case updating = "updating"
    case offline = "offline"
    
    /// 设备状态的显示名称
    public var displayName: String {
        switch self {
        case .idle:
            return "空闲"
        case .working:
            return "工作中"
        case .paused:
            return "已暂停"
        case .error:
            return "错误"
        case .maintenance:
            return "维护中"
        case .updating:
            return "更新中"
        case .offline:
            return "离线"
        }
    }
    
    /// 是否可以接收新命令
    public var canReceiveCommands: Bool {
        return self == .idle || self == .paused
    }
    
    /// 是否为活跃状态
    public var isActive: Bool {
        return self == .working
    }
}

/// 设备命令枚举
public enum DeviceCommand: String, CaseIterable, Codable {
    // 通用命令
    case start = "start"
    case stop = "stop"
    case pause = "pause"
    case resume = "resume"
    case reset = "reset"
    case reboot = "reboot"
    
    // 扫地机器人命令
    case startCleaning = "start_cleaning"
    case returnToBase = "return_to_base"
    case spotCleaning = "spot_cleaning"
    case edgeCleaning = "edge_cleaning"
    
    // 泳池机器人命令
    case startPoolCleaning = "start_pool_cleaning"
    case waterOnlyMode = "water_only_mode"
    case floorOnlyMode = "floor_only_mode"
    case fullCleaningMode = "full_cleaning_mode"
    
    // 储能设备命令
    case startCharging = "start_charging"
    case stopCharging = "stop_charging"
    case startDischarging = "start_discharging"
    case stopDischarging = "stop_discharging"
    
    // 智能插座命令
    case turnOn = "turn_on"
    case turnOff = "turn_off"
    case toggle = "toggle"
    
    // 智能灯具命令
    case setBrightness = "set_brightness"
    case setColor = "set_color"
    case setColorTemperature = "set_color_temperature"
    
    /// 命令的显示名称
    public var displayName: String {
        switch self {
        case .start:
            return "启动"
        case .stop:
            return "停止"
        case .pause:
            return "暂停"
        case .resume:
            return "继续"
        case .reset:
            return "重置"
        case .reboot:
            return "重启"
        case .startCleaning:
            return "开始清扫"
        case .returnToBase:
            return "回充"
        case .spotCleaning:
            return "定点清扫"
        case .edgeCleaning:
            return "沿边清扫"
        case .startPoolCleaning:
            return "开始清洁泳池"
        case .waterOnlyMode:
            return "仅清洁水面"
        case .floorOnlyMode:
            return "仅清洁池底"
        case .fullCleaningMode:
            return "全面清洁"
        case .startCharging:
            return "开始充电"
        case .stopCharging:
            return "停止充电"
        case .startDischarging:
            return "开始放电"
        case .stopDischarging:
            return "停止放电"
        case .turnOn:
            return "开启"
        case .turnOff:
            return "关闭"
        case .toggle:
            return "切换"
        case .setBrightness:
            return "设置亮度"
        case .setColor:
            return "设置颜色"
        case .setColorTemperature:
            return "设置色温"
        }
    }
}

/// 命令执行状态
public enum CommandExecutionState: String, CaseIterable, Codable {
    case idle = "idle"
    case executing = "executing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    /// 执行状态的显示名称
    public var displayName: String {
        switch self {
        case .idle:
            return "空闲"
        case .executing:
            return "执行中"
        case .completed:
            return "已完成"
        case .failed:
            return "执行失败"
        case .cancelled:
            return "已取消"
        }
    }
    
    /// 是否为终止状态
    public var isTerminal: Bool {
        return self == .completed || self == .failed || self == .cancelled
    }
}

/// 命令执行结果
public struct CommandResult: Codable {
    /// 命令
    public let command: DeviceCommand
    
    /// 执行是否成功
    public let success: Bool
    
    /// 结果消息
    public let message: String?
    
    /// 执行时间戳
    public let timestamp: Date
    
    /// 额外数据
    public let data: [String: Any]?
    
    public init(command: DeviceCommand, success: Bool, message: String? = nil, data: [String: Any]? = nil) {
        self.command = command
        self.success = success
        self.message = message
        self.timestamp = Date()
        self.data = data
    }
}

/// 设备错误类型
public enum DeviceError: Error, LocalizedError {
    case commandNotSupported(DeviceCommand)
    case deviceOffline
    case deviceBusy
    case commandTimeout
    case communicationError(String)
    case invalidParameter(String)
    case deviceError(String)
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .commandNotSupported(let command):
            return "不支持的命令: \(command.displayName)"
        case .deviceOffline:
            return "设备离线"
        case .deviceBusy:
            return "设备忙碌中"
        case .commandTimeout:
            return "命令执行超时"
        case .communicationError(let message):
            return "通信错误: \(message)"
        case .invalidParameter(let message):
            return "参数错误: \(message)"
        case .deviceError(let message):
            return "设备错误: \(message)"
        case .unknown(let message):
            return "未知错误: \(message)"
        }
    }
}

/// Controllable协议的默认实现
public extension Controllable {
    /// 检查是否支持指定命令
    func supportsCommand(_ command: DeviceCommand) -> Bool {
        return supportedCommands.contains(command)
    }
    
    /// 更新命令执行状态
    mutating func updateCommandExecutionState(_ state: CommandExecutionState, command: DeviceCommand? = nil) {
        commandExecutionState = state
        if let command = command {
            currentCommand = command
        }
        
        if state.isTerminal {
            lastExecutedCommand = currentCommand
            lastCommandExecutedAt = Date()
            currentCommand = nil
        }
    }
    
    /// 检查设备是否可以执行新命令
    var canExecuteCommand: Bool {
        return deviceState.canReceiveCommands && commandExecutionState != .executing
    }
}