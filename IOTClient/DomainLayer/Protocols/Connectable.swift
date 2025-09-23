//
//  Connectable.swift
//  DomainLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

/// 可连接设备协议
/// 定义了设备连接状态和网络相关的属性
public protocol Connectable {
    /// 连接状态
    var connectionState: ConnectionState { get set }
    
    /// 信号强度（RSSI值，单位：dBm）
    var rssi: Int? { get set }
    
    /// 网络类型
    var networkType: NetworkType { get set }
    
    /// IP地址（如果适用）
    var ipAddress: String? { get set }
    
    /// MAC地址
    var macAddress: String? { get set }
    
    /// 最后连接时间
    var lastConnectedAt: Date? { get set }
    
    /// 连接超时时间（秒）
    var connectionTimeout: TimeInterval { get }
    
    /// 连接状态变化的发布者
    var connectionStatePublisher: AnyPublisher<ConnectionState, Never> { get }
}

/// 连接状态枚举
public enum ConnectionState: String, CaseIterable, Codable {
    case disconnected = "disconnected"
    case connecting = "connecting"
    case connected = "connected"
    case reconnecting = "reconnecting"
    case failed = "failed"
    
    /// 连接状态的显示名称
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
        case .failed:
            return "连接失败"
        }
    }
    
    /// 是否为活跃连接状态
    public var isActive: Bool {
        return self == .connected
    }
    
    /// 是否正在尝试连接
    public var isConnecting: Bool {
        return self == .connecting || self == .reconnecting
    }
}

/// 网络类型枚举
public enum NetworkType: String, CaseIterable, Codable {
    case wifi = "wifi"
    case bluetooth = "bluetooth"
    case zigbee = "zigbee"
    case matter = "matter"
    case cellular = "cellular"
    case ethernet = "ethernet"
    case unknown = "unknown"
    
    /// 网络类型的显示名称
    public var displayName: String {
        switch self {
        case .wifi:
            return "Wi-Fi"
        case .bluetooth:
            return "蓝牙"
        case .zigbee:
            return "Zigbee"
        case .matter:
            return "Matter"
        case .cellular:
            return "蜂窝网络"
        case .ethernet:
            return "以太网"
        case .unknown:
            return "未知"
        }
    }
}

/// Connectable协议的默认实现
public extension Connectable {
    /// 默认连接超时时间（30秒）
    var connectionTimeout: TimeInterval {
        return 30.0
    }
    
    /// 信号强度等级（1-4级）
    var signalStrength: Int {
        guard let rssi = rssi else { return 0 }
        
        switch rssi {
        case -50...0:
            return 4 // 优秀
        case -60..<(-50):
            return 3 // 良好
        case -70..<(-60):
            return 2 // 一般
        case -80..<(-70):
            return 1 // 较差
        default:
            return 0 // 很差或无信号
        }
    }
    
    /// 信号强度描述
    var signalStrengthDescription: String {
        switch signalStrength {
        case 4:
            return "优秀"
        case 3:
            return "良好"
        case 2:
            return "一般"
        case 1:
            return "较差"
        default:
            return "无信号"
        }
    }
    
    /// 更新连接状态
    mutating func updateConnectionState(_ newState: ConnectionState) {
        connectionState = newState
        if newState == .connected {
            lastConnectedAt = Date()
        }
    }
    
    /// 检查连接是否超时
    func isConnectionTimedOut() -> Bool {
        guard let lastConnected = lastConnectedAt else { return true }
        return Date().timeIntervalSince(lastConnected) > connectionTimeout
    }
}