//
//  BatteryPowered.swift
//  DomainLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

/// 电池供电设备协议
/// 定义了电池相关的属性和状态管理
public protocol BatteryPowered {
    /// 电池电量百分比（0-100）
    var batteryLevel: Int { get set }
    
    /// 是否正在充电
    var isCharging: Bool { get set }
    
    /// 电池状态
    var batteryStatus: BatteryStatus { get set }
    
    /// 电池容量（mAh）
    var batteryCapacity: Int { get }
    
    /// 电池电压（V）
    var batteryVoltage: Double? { get set }
    
    /// 电池温度（摄氏度）
    var batteryTemperature: Double? { get set }
    
    /// 充电开始时间
    var chargingStartedAt: Date? { get set }
    
    /// 预计充满时间
    var estimatedChargingTime: TimeInterval? { get }
    
    /// 电池循环次数
    var batteryCycleCount: Int? { get set }
    
    /// 电池健康度百分比（0-100）
    var batteryHealth: Int? { get set }
    
    /// 电池状态变化的发布者
    var batteryStatusPublisher: AnyPublisher<BatteryStatus, Never> { get }
}

/// 电池状态枚举
public enum BatteryStatus: String, CaseIterable, Codable {
    case normal = "normal"
    case low = "low"
    case critical = "critical"
    case charging = "charging"
    case charged = "charged"
    case error = "error"
    case unknown = "unknown"
    
    /// 电池状态的显示名称
    public var displayName: String {
        switch self {
        case .normal:
            return "正常"
        case .low:
            return "电量低"
        case .critical:
            return "电量严重不足"
        case .charging:
            return "充电中"
        case .charged:
            return "已充满"
        case .error:
            return "电池异常"
        case .unknown:
            return "未知状态"
        }
    }
    
    /// 是否需要充电
    public var needsCharging: Bool {
        return self == .low || self == .critical
    }
    
    /// 是否为充电相关状态
    public var isChargingRelated: Bool {
        return self == .charging || self == .charged
    }
}

/// 电池警告级别
public enum BatteryWarningLevel: Int, CaseIterable {
    case none = 0
    case low = 20
    case critical = 10
    case emergency = 5
    
    /// 警告级别的显示名称
    public var displayName: String {
        switch self {
        case .none:
            return "正常"
        case .low:
            return "电量低"
        case .critical:
            return "电量严重不足"
        case .emergency:
            return "电量紧急"
        }
    }
    
    /// 警告颜色（用于UI显示）
    public var colorName: String {
        switch self {
        case .none:
            return "green"
        case .low:
            return "yellow"
        case .critical:
            return "orange"
        case .emergency:
            return "red"
        }
    }
}

/// BatteryPowered协议的默认实现
public extension BatteryPowered {
    /// 电池警告级别
    var batteryWarningLevel: BatteryWarningLevel {
        switch batteryLevel {
        case 0..<5:
            return .emergency
        case 5..<10:
            return .critical
        case 10..<20:
            return .low
        default:
            return .none
        }
    }
    
    /// 电池状态描述
    var batteryDescription: String {
        let levelText = "\(batteryLevel)%"
        let statusText = isCharging ? "充电中" : batteryStatus.displayName
        return "\(levelText) - \(statusText)"
    }
    
    /// 更新电池状态
    mutating func updateBatteryStatus() {
        if isCharging {
            batteryStatus = batteryLevel >= 100 ? .charged : .charging
            if chargingStartedAt == nil {
                chargingStartedAt = Date()
            }
        } else {
            chargingStartedAt = nil
            switch batteryLevel {
            case 0..<10:
                batteryStatus = .critical
            case 10..<20:
                batteryStatus = .low
            case 100:
                batteryStatus = .charged
            default:
                batteryStatus = .normal
            }
        }
    }
    
    /// 预计剩余使用时间（基于当前电量和平均功耗）
    func estimatedRemainingTime(averagePowerConsumption: Double) -> TimeInterval? {
        guard !isCharging, batteryLevel > 0, averagePowerConsumption > 0 else {
            return nil
        }
        
        let remainingCapacity = Double(batteryCapacity) * Double(batteryLevel) / 100.0
        return remainingCapacity / averagePowerConsumption * 3600 // 转换为秒
    }
    
    /// 检查是否需要立即充电
    var needsImmediateCharging: Bool {
        return batteryWarningLevel == .emergency || batteryWarningLevel == .critical
    }
    
    /// 充电进度百分比（基于充电时间估算）
    var chargingProgress: Double? {
        guard isCharging,
              let startTime = chargingStartedAt,
              let estimatedTime = estimatedChargingTime,
              estimatedTime > 0 else {
            return nil
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        let progress = min(elapsedTime / estimatedTime, 1.0)
        return progress
    }
}