//
//  DeviceControlExtensions.swift
//  DeviceControlModule
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine
import UIKit

// MARK: - DeviceType Extensions

extension DeviceType {
    /// 获取设备类型的显示名称
    public var displayName: String {
        switch self {
        case .light:
            return "智能灯"
        case .switch:
            return "智能开关"
        case .sensor:
            return "传感器"
        case .thermostat:
            return "温控器"
        case .camera:
            return "摄像头"
        case .speaker:
            return "智能音箱"
        case .lock:
            return "智能门锁"
        case .gateway:
            return "网关"
        case .unknown:
            return "未知设备"
        }
    }
    
    /// 获取设备类型的图标名称
    public var iconName: String {
        switch self {
        case .light:
            return "lightbulb"
        case .switch:
            return "switch.2"
        case .sensor:
            return "sensor"
        case .thermostat:
            return "thermometer"
        case .camera:
            return "camera"
        case .speaker:
            return "speaker.wave.2"
        case .lock:
            return "lock"
        case .gateway:
            return "wifi.router"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    /// 获取设备类型的颜色
    public var themeColor: UIColor {
        switch self {
        case .light:
            return .systemYellow
        case .switch:
            return .systemBlue
        case .sensor:
            return .systemGreen
        case .thermostat:
            return .systemOrange
        case .camera:
            return .systemPurple
        case .speaker:
            return .systemIndigo
        case .lock:
            return .systemBrown
        case .gateway:
            return .systemGray
        case .unknown:
            return .systemGray2
        }
    }
}

// MARK: - DeviceConnectionState Extensions

extension DeviceConnectionState {
    /// 获取连接状态的显示名称
    public var displayName: String {
        switch self {
        case .disconnected:
            return "已断开"
        case .connecting:
            return "连接中"
        case .connected:
            return "已连接"
        case .reconnecting:
            return "重连中"
        case .error:
            return "连接错误"
        }
    }
    
    /// 获取连接状态的颜色
    public var statusColor: UIColor {
        switch self {
        case .disconnected:
            return .systemRed
        case .connecting, .reconnecting:
            return .systemOrange
        case .connected:
            return .systemGreen
        case .error:
            return .systemRed
        }
    }
    
    /// 是否为活跃状态
    public var isActive: Bool {
        switch self {
        case .connected:
            return true
        default:
            return false
        }
    }
}

// MARK: - DeviceControlState Extensions

extension DeviceControlState {
    /// 获取控制状态的显示名称
    public var displayName: String {
        switch self {
        case .idle:
            return "空闲"
        case .busy:
            return "忙碌"
        case .error:
            return "错误"
        }
    }
    
    /// 获取控制状态的颜色
    public var statusColor: UIColor {
        switch self {
        case .idle:
            return .systemGreen
        case .busy:
            return .systemOrange
        case .error:
            return .systemRed
        }
    }
}

// MARK: - CommandStatus Extensions

extension CommandStatus {
    /// 获取命令状态的显示名称
    public var displayName: String {
        switch self {
        case .pending:
            return "等待中"
        case .executing:
            return "执行中"
        case .completed:
            return "已完成"
        case .failed:
            return "执行失败"
        case .cancelled:
            return "已取消"
        case .timeout:
            return "超时"
        }
    }
    
    /// 获取命令状态的颜色
    public var statusColor: UIColor {
        switch self {
        case .pending:
            return .systemGray
        case .executing:
            return .systemBlue
        case .completed:
            return .systemGreen
        case .failed, .timeout:
            return .systemRed
        case .cancelled:
            return .systemOrange
        }
    }
    
    /// 是否为终态
    public var isFinalState: Bool {
        switch self {
        case .completed, .failed, .cancelled, .timeout:
            return true
        case .pending, .executing:
            return false
        }
    }
}

// MARK: - DeviceCommandType Extensions

extension DeviceCommandType {
    /// 获取命令类型的显示名称
    public var displayName: String {
        switch self {
        case .switchOn:
            return "开启"
        case .switchOff:
            return "关闭"
        case .setBrightness:
            return "设置亮度"
        case .setColor:
            return "设置颜色"
        case .setTemperature:
            return "设置温度"
        case .setScene:
            return "设置场景"
        case .setTimer:
            return "设置定时"
        case .getStatus:
            return "获取状态"
        case .custom:
            return "自定义命令"
        }
    }
    
    /// 获取命令类型的图标
    public var iconName: String {
        switch self {
        case .switchOn:
            return "power"
        case .switchOff:
            return "power"
        case .setBrightness:
            return "sun.max"
        case .setColor:
            return "paintpalette"
        case .setTemperature:
            return "thermometer"
        case .setScene:
            return "theatermasks"
        case .setTimer:
            return "timer"
        case .getStatus:
            return "info.circle"
        case .custom:
            return "gear"
        }
    }
}

// MARK: - CommandPriority Extensions

extension CommandPriority {
    /// 获取优先级的显示名称
    public var displayName: String {
        switch self {
        case .low:
            return "低"
        case .normal:
            return "普通"
        case .high:
            return "高"
        case .critical:
            return "紧急"
        }
    }
    
    /// 获取优先级的颜色
    public var priorityColor: UIColor {
        switch self {
        case .low:
            return .systemGray
        case .normal:
            return .systemBlue
        case .high:
            return .systemOrange
        case .critical:
            return .systemRed
        }
    }
    
    /// 获取优先级的数值（用于排序）
    public var numericValue: Int {
        switch self {
        case .low:
            return 1
        case .normal:
            return 2
        case .high:
            return 3
        case .critical:
            return 4
        }
    }
}

// MARK: - DeviceColor Extensions

extension DeviceColor {
    /// 转换为UIColor
    public var uiColor: UIColor {
        return UIColor(red: CGFloat(red) / 255.0,
                      green: CGFloat(green) / 255.0,
                      blue: CGFloat(blue) / 255.0,
                      alpha: 1.0)
    }
    
    /// 从UIColor创建DeviceColor
    public static func from(uiColor: UIColor) -> DeviceColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return DeviceColor(
            red: Int(red * 255),
            green: Int(green * 255),
            blue: Int(blue * 255)
        )
    }
    
    /// 预定义颜色
    public static let white = DeviceColor(red: 255, green: 255, blue: 255)
    public static let red = DeviceColor(red: 255, green: 0, blue: 0)
    public static let green = DeviceColor(red: 0, green: 255, blue: 0)
    public static let blue = DeviceColor(red: 0, green: 0, blue: 255)
    public static let yellow = DeviceColor(red: 255, green: 255, blue: 0)
    public static let purple = DeviceColor(red: 128, green: 0, blue: 128)
    public static let orange = DeviceColor(red: 255, green: 165, blue: 0)
    public static let pink = DeviceColor(red: 255, green: 192, blue: 203)
    
    /// 获取颜色的十六进制字符串
    public var hexString: String {
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
    
    /// 从十六进制字符串创建颜色
    public static func from(hexString: String) -> DeviceColor? {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        return DeviceColor(red: Int(r), green: Int(g), blue: Int(b))
    }
}

// MARK: - DeviceControlError Extensions

extension DeviceControlError {
    /// 获取用户友好的错误描述
    public var userFriendlyDescription: String {
        switch self {
        case .deviceNotFound:
            return "找不到指定的设备"
        case .deviceNotConnected:
            return "设备未连接"
        case .commandExecutionFailed:
            return "命令执行失败"
        case .invalidCommand:
            return "无效的命令"
        case .timeout:
            return "操作超时"
        case .authenticationFailed:
            return "设备认证失败"
        case .insufficientPermissions:
            return "权限不足"
        case .deviceBusy:
            return "设备正忙"
        case .networkError:
            return "网络连接错误"
        case .invalidParameters:
            return "参数无效"
        case .serviceUnavailable:
            return "服务不可用"
        case .controllerBusy:
            return "控制器正忙"
        case .controllerNotInitialized:
            return "控制器未初始化"
        case .queueFull:
            return "命令队列已满"
        case .commandNotSupported:
            return "设备不支持此命令"
        case .unknown:
            return "未知错误"
        }
    }
    
    /// 获取错误的建议解决方案
    public var suggestedSolution: String {
        switch self {
        case .deviceNotFound:
            return "请检查设备是否已添加到系统中"
        case .deviceNotConnected:
            return "请检查设备连接状态并重新连接"
        case .commandExecutionFailed:
            return "请稍后重试或检查设备状态"
        case .invalidCommand:
            return "请检查命令参数是否正确"
        case .timeout:
            return "请检查网络连接并重试"
        case .authenticationFailed:
            return "请重新进行设备认证"
        case .insufficientPermissions:
            return "请检查设备权限设置"
        case .deviceBusy:
            return "请等待设备完成当前操作后重试"
        case .networkError:
            return "请检查网络连接状态"
        case .invalidParameters:
            return "请检查输入参数的有效性"
        case .serviceUnavailable:
            return "服务暂时不可用，请稍后重试"
        case .controllerBusy:
            return "控制器正在处理其他命令，请稍后重试"
        case .controllerNotInitialized:
            return "请重新初始化控制器"
        case .queueFull:
            return "命令队列已满，请稍后重试"
        case .commandNotSupported:
            return "此设备不支持该操作"
        case .unknown:
            return "请联系技术支持"
        }
    }
}

// MARK: - Date Extensions for Device Control

extension Date {
    /// 格式化为设备控制日志时间
    public var deviceControlTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: self)
    }
    
    /// 获取相对时间描述
    public var relativeTimeString: String {
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

// MARK: - Publisher Extensions for Device Control

extension Publisher {
    /// 添加设备控制超时
    public func deviceControlTimeout(_ timeout: TimeInterval) -> Publishers.Timeout<Self, DispatchQueue> {
        return self.timeout(.seconds(timeout), scheduler: DispatchQueue.main)
    }
    
    /// 添加设备控制重试
    public func deviceControlRetry(_ maxRetries: Int, delay: TimeInterval = 1.0) -> Publishers.Retry<Self> {
        return self.retry(maxRetries)
    }
}

// MARK: - String Extensions for Device Control

extension String {
    /// 验证设备ID格式
    public var isValidDeviceId: Bool {
        let regex = "^[A-Za-z0-9_-]{8,32}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: self)
    }
    
    /// 验证命令ID格式
    public var isValidCommandId: Bool {
        let regex = "^[A-Za-z0-9_-]{8,64}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: self)
    }
    
    /// 生成设备控制相关的UUID
    public static func generateDeviceControlId(prefix: String = "") -> String {
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return prefix.isEmpty ? uuid : "\(prefix)_\(uuid)"
    }
}

// MARK: - Array Extensions for Device Control

extension Array where Element == DeviceCommand {
    /// 按优先级排序
    public func sortedByPriority() -> [DeviceCommand] {
        return self.sorted { $0.priority.numericValue > $1.priority.numericValue }
    }
    
    /// 按创建时间排序
    public func sortedByCreationTime() -> [DeviceCommand] {
        return self.sorted { $0.createdAt < $1.createdAt }
    }
    
    /// 过滤指定设备的命令
    public func commands(for deviceId: String) -> [DeviceCommand] {
        return self.filter { $0.targetDeviceId == deviceId }
    }
    
    /// 过滤指定类型的命令
    public func commands(of type: DeviceCommandType) -> [DeviceCommand] {
        return self.filter { $0.commandType == type }
    }
}

// MARK: - Dictionary Extensions for Device Control

extension Dictionary where Key == String {
    /// 安全获取字符串值
    public func safeStringValue(for key: String) -> String? {
        return self[key] as? String
    }
    
    /// 安全获取整数值
    public func safeIntValue(for key: String) -> Int? {
        if let value = self[key] as? Int {
            return value
        } else if let stringValue = self[key] as? String {
            return Int(stringValue)
        }
        return nil
    }
    
    /// 安全获取双精度值
    public func safeDoubleValue(for key: String) -> Double? {
        if let value = self[key] as? Double {
            return value
        } else if let stringValue = self[key] as? String {
            return Double(stringValue)
        }
        return nil
    }
    
    /// 安全获取布尔值
    public func safeBoolValue(for key: String) -> Bool? {
        if let value = self[key] as? Bool {
            return value
        } else if let stringValue = self[key] as? String {
            return Bool(stringValue)
        }
        return nil
    }
}

// MARK: - Utility Classes

/// 设备控制工具类
public class DeviceControlUtils {
    /// 验证设备命令参数
    public static func validateCommandParameters(_ parameters: [String: Any], for commandType: DeviceCommandType) -> Bool {
        switch commandType {
        case .switchOn, .switchOff:
            return parameters["isOn"] is Bool
        case .setBrightness:
            guard let brightness = parameters["brightness"] as? Int else { return false }
            return brightness >= 0 && brightness <= 100
        case .setColor:
            guard let red = parameters["red"] as? Int,
                  let green = parameters["green"] as? Int,
                  let blue = parameters["blue"] as? Int else { return false }
            return red >= 0 && red <= 255 && green >= 0 && green <= 255 && blue >= 0 && blue <= 255
        case .setTemperature:
            guard let temperature = parameters["temperature"] as? Double else { return false }
            return temperature >= -50 && temperature <= 100
        case .setScene:
            return parameters["sceneId"] is String
        case .setTimer:
            return parameters["duration"] is TimeInterval
        case .getStatus:
            return true // 状态查询不需要特殊参数
        case .custom:
            return true // 自定义命令参数由具体实现验证
        }
    }
    
    /// 生成命令执行摘要
    public static func generateExecutionSummary(for result: DeviceCommandResult) -> String {
        let status = result.success ? "成功" : "失败"
        let executionTime = String(format: "%.2f", result.executionTime)
        return "命令执行\(status)，耗时\(executionTime)秒"
    }
    
    /// 计算命令执行统计
    public static func calculateExecutionStats(for results: [DeviceCommandResult]) -> (successRate: Double, averageTime: Double, totalCommands: Int) {
        let totalCommands = results.count
        let successfulCommands = results.filter { $0.success }.count
        let successRate = totalCommands > 0 ? Double(successfulCommands) / Double(totalCommands) : 0.0
        let averageTime = totalCommands > 0 ? results.map { $0.executionTime }.reduce(0, +) / Double(totalCommands) : 0.0
        
        return (successRate: successRate, averageTime: averageTime, totalCommands: totalCommands)
    }
}

/// 设备控制日志工具
public class DeviceControlLogger {
    public enum LogLevel {
        case debug, info, warning, error
        
        var prefix: String {
            switch self {
            case .debug: return "[DEBUG]"
            case .info: return "[INFO]"
            case .warning: return "[WARNING]"
            case .error: return "[ERROR]"
            }
        }
    }
    
    public static func log(_ message: String, level: LogLevel = .info, deviceId: String? = nil, commandId: String? = nil) {
        let timestamp = Date().deviceControlTimeString
        var logMessage = "\(timestamp) \(level.prefix) \(message)"
        
        if let deviceId = deviceId {
            logMessage += " [Device: \(deviceId)]"
        }
        
        if let commandId = commandId {
            logMessage += " [Command: \(commandId)]"
        }
        
        print(logMessage)
    }
    
    public static func logCommandExecution(_ command: DeviceCommandProtocol, result: DeviceCommandResult) {
        let status = result.success ? "SUCCESS" : "FAILED"
        let message = "Command \(command.commandType.displayName) \(status) in \(String(format: "%.2f", result.executionTime))s"
        log(message, level: result.success ? .info : .error, deviceId: command.targetDeviceId, commandId: command.commandId)
    }
    
    public static func logDeviceStateChange(_ deviceId: String, from oldState: DeviceConnectionState, to newState: DeviceConnectionState) {
        let message = "Device state changed from \(oldState.displayName) to \(newState.displayName)"
        log(message, level: .info, deviceId: deviceId)
    }
}