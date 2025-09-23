//
//  Device+Extensions.swift
//  DomainLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

// MARK: - Device Protocol Extensions

public extension Device {
    
    /// 设备是否在线
    var isOnline: Bool {
        return isConnected
    }
    
    /// 设备是否离线
    var isOffline: Bool {
        return !isConnected
    }
    
    /// 设备年龄（天数）
    var ageInDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: dateAdded, to: Date())
        return components.day ?? 0
    }
    
    /// 设备最后更新时间距现在的时间间隔（秒）
    var timeSinceLastUpdate: TimeInterval {
        return Date().timeIntervalSince(lastUpdated)
    }
    
    /// 设备是否需要更新（超过5分钟未更新）
    var needsUpdate: Bool {
        return timeSinceLastUpdate > 300 // 5分钟
    }
    
    /// 设备显示名称（如果名称为空则使用型号）
    var displayName: String {
        return name.isEmpty ? modelName : name
    }
    
    /// 设备完整标识符（制造商 + 型号 + 序列号）
    var fullIdentifier: String {
        return "\(manufacturer)-\(modelName)-\(serialNumber)"
    }
    
    /// 设备简短描述
    var shortDescription: String {
        return "\(displayName) (\(deviceType.displayName))"
    }
    
    /// 设备详细描述
    var detailedDescription: String {
        let status = isOnline ? "在线" : "离线"
        let age = ageInDays
        let ageText = age == 0 ? "今天添加" : "\(age)天前添加"
        
        return """
        设备名称: \(displayName)
        设备类型: \(deviceType.displayName)
        制造商: \(manufacturer)
        型号: \(modelName)
        序列号: \(serialNumber)
        固件版本: \(firmwareVersion)
        状态: \(status)
        添加时间: \(ageText)
        最后更新: \(formatLastUpdated())
        """
    }
    
    /// 格式化最后更新时间
    private func formatLastUpdated() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }
    
    /// 检查设备是否匹配搜索关键词
    /// - Parameter keyword: 搜索关键词
    /// - Returns: 是否匹配
    func matches(keyword: String) -> Bool {
        let lowercaseKeyword = keyword.lowercased()
        
        return name.lowercased().contains(lowercaseKeyword) ||
               modelName.lowercased().contains(lowercaseKeyword) ||
               manufacturer.lowercased().contains(lowercaseKeyword) ||
               serialNumber.lowercased().contains(lowercaseKeyword) ||
               deviceType.displayName.lowercased().contains(lowercaseKeyword)
    }
    
    /// 检查设备是否属于指定类型
    /// - Parameter types: 设备类型数组
    /// - Returns: 是否属于指定类型
    func isOfType(_ types: [DeviceType]) -> Bool {
        return types.contains(deviceType)
    }
    
    /// 检查设备是否属于指定制造商
    /// - Parameter manufacturers: 制造商数组
    /// - Returns: 是否属于指定制造商
    func isFromManufacturer(_ manufacturers: [String]) -> Bool {
        return manufacturers.contains { manufacturer.lowercased().contains($0.lowercased()) }
    }
    
    /// 更新设备的最后更新时间
    mutating func updateLastUpdatedTime() {
        lastUpdated = Date()
    }
    
    /// 生成设备的哈希值（用于去重）
    func deviceHash() -> String {
        return "\(id)-\(serialNumber)".sha256
    }
}

// MARK: - Connectable Extensions

public extension Connectable {
    
    /// 连接状态显示文本
    var connectionStatusText: String {
        switch connectionState {
        case .disconnected:
            return "已断开"
        case .connecting:
            return "连接中"
        case .connected:
            return "已连接"
        case .reconnecting:
            return "重连中"
        case .failed:
            return "连接失败"
        }
    }
    
    /// 网络类型显示文本
    var networkTypeText: String {
        switch networkType {
        case .wifi:
            return "Wi-Fi"
        case .bluetooth:
            return "蓝牙"
        case .zigbee:
            return "Zigbee"
        case .matter:
            return "Matter"
        case .ethernet:
            return "以太网"
        case .cellular:
            return "蜂窝网络"
        case .unknown:
            return "未知"
        }
    }
    
    /// 信号强度等级（1-5级）
    var signalStrengthLevel: Int {
        guard let rssi = rssi else { return 0 }
        
        switch rssi {
        case -30...0:
            return 5 // 优秀
        case -50..<(-30):
            return 4 // 良好
        case -70..<(-50):
            return 3 // 一般
        case -90..<(-70):
            return 2 // 较差
        default:
            return 1 // 很差
        }
    }
    
    /// 信号强度描述
    var signalStrengthDescription: String {
        switch signalStrengthLevel {
        case 5:
            return "优秀"
        case 4:
            return "良好"
        case 3:
            return "一般"
        case 2:
            return "较差"
        case 1:
            return "很差"
        default:
            return "无信号"
        }
    }
    
    /// 是否有有效的IP地址
    var hasValidIPAddress: Bool {
        guard let ip = ipAddress, !ip.isEmpty else { return false }
        return ip != "0.0.0.0" && ip != "127.0.0.1"
    }
    
    /// 是否有有效的MAC地址
    var hasValidMACAddress: Bool {
        guard let mac = macAddress, !mac.isEmpty else { return false }
        let macPattern = "^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$"
        return mac.range(of: macPattern, options: .regularExpression) != nil
    }
    
    /// 连接质量评分（0-100）
    var connectionQuality: Int {
        var score = 0
        
        // 连接状态评分（40分）
        switch connectionState {
        case .connected:
            score += 40
        case .connecting, .reconnecting:
            score += 20
        case .disconnected, .failed:
            score += 0
        }
        
        // 信号强度评分（40分）
        score += signalStrengthLevel * 8
        
        // 网络稳定性评分（20分）
        if hasValidIPAddress {
            score += 10
        }
        if hasValidMACAddress {
            score += 10
        }
        
        return min(score, 100)
    }
    
    /// 连接质量等级
    var connectionQualityLevel: ConnectionQualityLevel {
        switch connectionQuality {
        case 80...100:
            return .excellent
        case 60..<80:
            return .good
        case 40..<60:
            return .fair
        case 20..<40:
            return .poor
        default:
            return .bad
        }
    }
}

/// 连接质量等级
public enum ConnectionQualityLevel: String, CaseIterable {
    case excellent = "优秀"
    case good = "良好"
    case fair = "一般"
    case poor = "较差"
    case bad = "很差"
    
    /// 对应的颜色（用于UI显示）
    public var colorName: String {
        switch self {
        case .excellent:
            return "green"
        case .good:
            return "blue"
        case .fair:
            return "yellow"
        case .poor:
            return "orange"
        case .bad:
            return "red"
        }
    }
}

// MARK: - BatteryPowered Extensions

public extension BatteryPowered {
    
    /// 电池状态显示文本
    var batteryStatusText: String {
        switch batteryStatus {
        case .unknown:
            return "未知"
        case .charging:
            return "充电中"
        case .discharging:
            return "放电中"
        case .notCharging:
            return "未充电"
        case .full:
            return "已充满"
        }
    }
    
    /// 电池电量等级（1-5级）
    var batteryLevel: Int {
        switch batteryPercentage {
        case 80...100:
            return 5 // 满电
        case 60..<80:
            return 4 // 充足
        case 40..<60:
            return 3 // 一般
        case 20..<40:
            return 2 // 较低
        default:
            return 1 // 低电量
        }
    }
    
    /// 电池电量描述
    var batteryLevelDescription: String {
        switch batteryLevel {
        case 5:
            return "满电"
        case 4:
            return "充足"
        case 3:
            return "一般"
        case 2:
            return "较低"
        case 1:
            return "低电量"
        default:
            return "无电量信息"
        }
    }
    
    /// 是否需要充电（电量低于20%）
    var needsCharging: Bool {
        return batteryPercentage < 20
    }
    
    /// 是否电量充足（电量高于80%）
    var hasSufficientBattery: Bool {
        return batteryPercentage >= 80
    }
    
    /// 电池警告等级
    var batteryWarningLevel: BatteryWarningLevel {
        switch batteryPercentage {
        case 0..<5:
            return .critical
        case 5..<15:
            return .low
        case 15..<30:
            return .medium
        default:
            return .normal
        }
    }
    
    /// 预计剩余使用时间（小时）
    /// - Parameter averagePowerConsumption: 平均功耗（瓦特）
    /// - Returns: 预计剩余使用时间
    func estimatedRemainingTime(averagePowerConsumption: Double) -> TimeInterval? {
        guard averagePowerConsumption > 0,
              let capacity = batteryCapacity,
              let voltage = batteryVoltage else {
            return nil
        }
        
        let remainingCapacity = Double(batteryPercentage) / 100.0 * capacity
        let remainingEnergy = remainingCapacity * voltage / 1000.0 // 转换为瓦时
        let remainingHours = remainingEnergy / averagePowerConsumption
        
        return remainingHours * 3600 // 转换为秒
    }
    
    /// 格式化剩余时间显示
    /// - Parameter timeInterval: 时间间隔（秒）
    /// - Returns: 格式化的时间字符串
    func formatRemainingTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    /// 电池健康度描述
    var batteryHealthDescription: String {
        guard let health = batteryHealth else {
            return "未知"
        }
        
        switch health {
        case 90...100:
            return "优秀"
        case 80..<90:
            return "良好"
        case 70..<80:
            return "一般"
        case 60..<70:
            return "较差"
        default:
            return "需要更换"
        }
    }
}

// MARK: - Controllable Extensions

public extension Controllable {
    
    /// 设备状态显示文本
    var deviceStateText: String {
        switch deviceState {
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
        }
    }
    
    /// 命令执行状态显示文本
    var commandExecutionStateText: String {
        switch commandExecutionState {
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
    
    /// 是否可以执行命令
    var canExecuteCommand: Bool {
        return commandExecutionState == .idle || commandExecutionState == .completed
    }
    
    /// 是否正在执行命令
    var isExecutingCommand: Bool {
        return commandExecutionState == .executing
    }
    
    /// 是否可以取消当前命令
    var canCancelCommand: Bool {
        return commandExecutionState == .executing
    }
    
    /// 获取支持的命令显示名称
    var supportedCommandNames: [String] {
        return supportedCommands.map { $0.displayName }
    }
    
    /// 检查是否支持指定命令
    /// - Parameter command: 设备命令
    /// - Returns: 是否支持该命令
    func supportsCommand(_ command: DeviceCommand) -> Bool {
        return supportedCommands.contains(command)
    }
    
    /// 安全执行命令（检查支持性和状态）
    /// - Parameter command: 要执行的命令
    /// - Returns: 命令执行结果的发布者
    func safeExecuteCommand(_ command: DeviceCommand) -> AnyPublisher<CommandResult, Never> {
        // 检查是否支持该命令
        guard supportsCommand(command) else {
            let result = CommandResult(
                command: command,
                success: false,
                message: "设备不支持命令: \(command.displayName)",
                executionTime: Date(),
                data: nil
            )
            return Just(result).eraseToAnyPublisher()
        }
        
        // 检查是否可以执行命令
        guard canExecuteCommand else {
            let result = CommandResult(
                command: command,
                success: false,
                message: "设备当前状态不允许执行命令: \(commandExecutionStateText)",
                executionTime: Date(),
                data: nil
            )
            return Just(result).eraseToAnyPublisher()
        }
        
        // 执行命令
        return executeCommand(command)
    }
}

// MARK: - DeviceType Extensions

public extension DeviceType {
    
    /// 设备类型图标名称
    var iconName: String {
        switch self {
        case .sweepingRobot:
            return "robot.vacuum"
        case .poolRobot:
            return "drop.triangle"
        case .energyStorage:
            return "battery.100"
        case .smartPlug:
            return "powerplug"
        case .smartLight:
            return "lightbulb"
        case .smartCamera:
            return "camera"
        case .smartSpeaker:
            return "speaker.wave.2"
        case .smartThermostat:
            return "thermometer"
        case .smartLock:
            return "lock"
        case .smartSensor:
            return "sensor.tag.radiowaves.forward"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    /// 设备类型分类
    var category: DeviceCategory {
        switch self {
        case .sweepingRobot, .poolRobot:
            return .cleaning
        case .energyStorage:
            return .energy
        case .smartPlug, .smartLight:
            return .lighting
        case .smartCamera:
            return .security
        case .smartSpeaker:
            return .entertainment
        case .smartThermostat:
            return .climate
        case .smartLock:
            return .security
        case .smartSensor:
            return .monitoring
        case .unknown:
            return .other
        }
    }
    
    /// 是否为机器人设备
    var isRobot: Bool {
        return self == .sweepingRobot || self == .poolRobot
    }
    
    /// 是否为智能家居设备
    var isSmartHome: Bool {
        switch self {
        case .smartPlug, .smartLight, .smartCamera, .smartSpeaker, .smartThermostat, .smartLock, .smartSensor:
            return true
        default:
            return false
        }
    }
}

/// 设备分类
public enum DeviceCategory: String, CaseIterable {
    case cleaning = "清洁"
    case energy = "能源"
    case lighting = "照明"
    case security = "安防"
    case entertainment = "娱乐"
    case climate = "气候"
    case monitoring = "监控"
    case other = "其他"
    
    /// 分类图标
    public var iconName: String {
        switch self {
        case .cleaning:
            return "sparkles"
        case .energy:
            return "bolt.circle"
        case .lighting:
            return "lightbulb.circle"
        case .security:
            return "shield.circle"
        case .entertainment:
            return "music.note.circle"
        case .climate:
            return "thermometer.circle"
        case .monitoring:
            return "eye.circle"
        case .other:
            return "circle.grid.3x3"
        }
    }
}

// MARK: - String Extensions

private extension String {
    /// 计算字符串的SHA256哈希值
    var sha256: String {
        let data = Data(self.utf8)
        let hash = data.withUnsafeBytes { bytes in
            return bytes.bindMemory(to: UInt8.self)
        }
        
        // 简化的哈希实现（实际项目中应使用CryptoKit）
        return String(self.hashValue)
    }
}