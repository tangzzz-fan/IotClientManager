//
//  Device.swift
//  DomainLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation

/// 所有设备的基础协议
/// 定义了设备的通用属性和标识信息
public protocol Device {
    /// 设备唯一标识符
    var id: String { get }
    
    /// 设备名称（用户可自定义）
    var name: String { get set }
    
    /// 设备型号名称
    var modelName: String { get }
    
    /// 固件版本
    var firmwareVersion: String { get }
    
    /// 设备制造商
    var manufacturer: String { get }
    
    /// 设备序列号
    var serialNumber: String { get }
    
    /// 设备添加时间
    var dateAdded: Date { get }
    
    /// 设备最后更新时间
    var lastUpdated: Date { get set }
    
    /// 设备是否在线
    var isOnline: Bool { get set }
    
    /// 设备类型标识符（用于工厂方法创建）
    var deviceType: DeviceType { get }
}

/// 设备类型枚举
public enum DeviceType: String, CaseIterable, Codable {
    case sweepingRobot = "sweeping_robot"
    case poolRobot = "pool_robot"
    case energyStorage = "energy_storage"
    case smartPlug = "smart_plug"
    case smartLight = "smart_light"
    case smartCamera = "smart_camera"
    case unknown = "unknown"
    
    /// 设备类型的显示名称
    public var displayName: String {
        switch self {
        case .sweepingRobot:
            return "扫地机器人"
        case .poolRobot:
            return "泳池机器人"
        case .energyStorage:
            return "储能设备"
        case .smartPlug:
            return "智能插座"
        case .smartLight:
            return "智能灯具"
        case .smartCamera:
            return "智能摄像头"
        case .unknown:
            return "未知设备"
        }
    }
}

/// 设备协议的默认实现扩展
public extension Device {
    /// 设备的简短描述
    var description: String {
        return "\(name) (\(modelName))"
    }
    
    /// 检查设备是否需要固件更新
    func needsFirmwareUpdate(latestVersion: String) -> Bool {
        return firmwareVersion != latestVersion
    }
    
    /// 更新设备的最后更新时间
    mutating func updateLastModified() {
        lastUpdated = Date()
    }
}