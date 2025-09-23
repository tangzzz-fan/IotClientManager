//
//  DeviceDiscovery.swift
//  ConnectivityLayer
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine

/// 设备发现协议
/// 定义了设备扫描和发现的统一接口
public protocol DeviceDiscovery {
    
    // MARK: - Associated Types
    
    /// 发现的设备信息类型
    associatedtype DiscoveredDevice
    
    /// 扫描配置类型
    associatedtype ScanConfiguration
    
    // MARK: - Properties
    
    /// 发现服务标识符
    var discoveryId: String { get }
    
    /// 发现服务名称
    var discoveryName: String { get }
    
    /// 当前扫描状态
    var scanState: ScanState { get }
    
    /// 扫描状态发布者
    var scanStatePublisher: AnyPublisher<ScanState, Never> { get }
    
    /// 发现的设备发布者
    var discoveredDevicePublisher: AnyPublisher<DiscoveredDevice, Never> { get }
    
    /// 设备丢失发布者
    var deviceLostPublisher: AnyPublisher<String, Never> { get }
    
    /// 扫描错误发布者
    var scanErrorPublisher: AnyPublisher<DiscoveryError, Never> { get }
    
    /// 支持的设备类型
    var supportedDeviceTypes: Set<String> { get }
    
    /// 是否支持后台扫描
    var supportsBackgroundScanning: Bool { get }
    
    /// 扫描范围（米）
    var scanRange: Double? { get }
    
    // MARK: - Scanning Control
    
    /// 开始扫描设备
    /// - Parameter configuration: 扫描配置
    /// - Returns: 扫描结果的发布者
    func startScanning(with configuration: ScanConfiguration?) -> AnyPublisher<Void, DiscoveryError>
    
    /// 停止扫描设备
    /// - Returns: 停止扫描结果的发布者
    func stopScanning() -> AnyPublisher<Void, DiscoveryError>
    
    /// 暂停扫描
    /// - Returns: 暂停扫描结果的发布者
    func pauseScanning() -> AnyPublisher<Void, DiscoveryError>
    
    /// 恢复扫描
    /// - Returns: 恢复扫描结果的发布者
    func resumeScanning() -> AnyPublisher<Void, DiscoveryError>
    
    /// 刷新扫描（重新开始）
    /// - Returns: 刷新扫描结果的发布者
    func refreshScan() -> AnyPublisher<Void, DiscoveryError>
    
    // MARK: - Device Management
    
    /// 获取已发现的设备列表
    /// - Returns: 已发现的设备数组
    func getDiscoveredDevices() -> [DiscoveredDevice]
    
    /// 根据标识符获取设备
    /// - Parameter deviceId: 设备标识符
    /// - Returns: 设备信息（如果存在）
    func getDevice(by deviceId: String) -> DiscoveredDevice?
    
    /// 清除已发现的设备列表
    func clearDiscoveredDevices()
    
    /// 移除特定设备
    /// - Parameter deviceId: 设备标识符
    /// - Returns: 是否成功移除
    func removeDevice(deviceId: String) -> Bool
    
    // MARK: - Filtering
    
    /// 设置设备过滤器
    /// - Parameter filter: 设备过滤器
    func setDeviceFilter(_ filter: DeviceFilter?)
    
    /// 获取当前设备过滤器
    /// - Returns: 当前过滤器
    func getCurrentFilter() -> DeviceFilter?
    
    /// 按设备类型过滤
    /// - Parameter deviceTypes: 设备类型集合
    func filterByDeviceTypes(_ deviceTypes: Set<String>)
    
    /// 按信号强度过滤
    /// - Parameter minRSSI: 最小信号强度
    func filterBySignalStrength(minRSSI: Int)
    
    /// 按距离过滤
    /// - Parameter maxDistance: 最大距离（米）
    func filterByDistance(maxDistance: Double)
    
    // MARK: - Configuration
    
    /// 更新扫描配置
    /// - Parameter configuration: 新的扫描配置
    /// - Returns: 配置更新结果的发布者
    func updateScanConfiguration(_ configuration: ScanConfiguration) -> AnyPublisher<Void, DiscoveryError>
    
    /// 获取当前扫描配置
    /// - Returns: 当前扫描配置
    func getCurrentScanConfiguration() -> ScanConfiguration?
    
    // MARK: - Statistics
    
    /// 获取扫描统计信息
    /// - Returns: 扫描统计信息
    func getScanStatistics() -> ScanStatistics
    
    /// 重置扫描统计信息
    func resetScanStatistics()
}

// MARK: - Scan State

/// 扫描状态枚举
public enum ScanState: String, CaseIterable {
    case idle = "idle"
    case starting = "starting"
    case scanning = "scanning"
    case paused = "paused"
    case stopping = "stopping"
    case failed = "failed"
    
    /// 状态显示名称
    public var displayName: String {
        switch self {
        case .idle:
            return "空闲"
        case .starting:
            return "启动中"
        case .scanning:
            return "扫描中"
        case .paused:
            return "已暂停"
        case .stopping:
            return "停止中"
        case .failed:
            return "扫描失败"
        }
    }
    
    /// 是否为活跃扫描状态
    public var isActiveScanning: Bool {
        return self == .scanning
    }
    
    /// 是否为过渡状态
    public var isTransitioning: Bool {
        return self == .starting || self == .stopping
    }
    
    /// 是否可以开始扫描
    public var canStartScanning: Bool {
        return self == .idle || self == .failed
    }
    
    /// 是否可以停止扫描
    public var canStopScanning: Bool {
        return self == .scanning || self == .paused
    }
    
    /// 是否可以暂停扫描
    public var canPauseScanning: Bool {
        return self == .scanning
    }
    
    /// 是否可以恢复扫描
    public var canResumeScanning: Bool {
        return self == .paused
    }
}

// MARK: - Discovery Error

/// 设备发现错误类型
public enum DiscoveryError: Error, LocalizedError {
    case scanStartFailed(String)
    case scanStopFailed(String)
    case bluetoothUnavailable
    case bluetoothUnauthorized
    case bluetoothPoweredOff
    case wifiUnavailable
    case networkPermissionDenied
    case locationPermissionDenied
    case invalidConfiguration(String)
    case deviceNotFound(String)
    case scanTimeout
    case resourceBusy
    case hardwareError(String)
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .scanStartFailed(let reason):
            return "扫描启动失败: \(reason)"
        case .scanStopFailed(let reason):
            return "扫描停止失败: \(reason)"
        case .bluetoothUnavailable:
            return "蓝牙不可用"
        case .bluetoothUnauthorized:
            return "蓝牙权限未授权"
        case .bluetoothPoweredOff:
            return "蓝牙未开启"
        case .wifiUnavailable:
            return "WiFi不可用"
        case .networkPermissionDenied:
            return "网络权限被拒绝"
        case .locationPermissionDenied:
            return "位置权限被拒绝"
        case .invalidConfiguration(let reason):
            return "配置无效: \(reason)"
        case .deviceNotFound(let deviceId):
            return "设备未找到: \(deviceId)"
        case .scanTimeout:
            return "扫描超时"
        case .resourceBusy:
            return "资源忙碌"
        case .hardwareError(let reason):
            return "硬件错误: \(reason)"
        case .unknown(let error):
            return "未知错误: \(error.localizedDescription)"
        }
    }
    
    /// 错误代码
    public var errorCode: Int {
        switch self {
        case .scanStartFailed:
            return 2001
        case .scanStopFailed:
            return 2002
        case .bluetoothUnavailable:
            return 2003
        case .bluetoothUnauthorized:
            return 2004
        case .bluetoothPoweredOff:
            return 2005
        case .wifiUnavailable:
            return 2006
        case .networkPermissionDenied:
            return 2007
        case .locationPermissionDenied:
            return 2008
        case .invalidConfiguration:
            return 2009
        case .deviceNotFound:
            return 2010
        case .scanTimeout:
            return 2011
        case .resourceBusy:
            return 2012
        case .hardwareError:
            return 2013
        case .unknown:
            return 2999
        }
    }
    
    /// 是否为可重试错误
    public var isRetryable: Bool {
        switch self {
        case .scanStartFailed, .scanStopFailed, .scanTimeout, .resourceBusy, .hardwareError, .unknown:
            return true
        case .bluetoothUnavailable, .bluetoothUnauthorized, .bluetoothPoweredOff, .wifiUnavailable, .networkPermissionDenied, .locationPermissionDenied, .invalidConfiguration, .deviceNotFound:
            return false
        }
    }
}

// MARK: - Device Filter

/// 设备过滤器
public struct DeviceFilter {
    /// 设备类型过滤
    public let deviceTypes: Set<String>?
    
    /// 最小信号强度
    public let minRSSI: Int?
    
    /// 最大距离（米）
    public let maxDistance: Double?
    
    /// 设备名称模式
    public let namePattern: String?
    
    /// 制造商过滤
    public let manufacturers: Set<String>?
    
    /// 服务UUID过滤
    public let serviceUUIDs: Set<String>?
    
    /// 自定义过滤条件
    public let customFilter: ((Any) -> Bool)?
    
    public init(
        deviceTypes: Set<String>? = nil,
        minRSSI: Int? = nil,
        maxDistance: Double? = nil,
        namePattern: String? = nil,
        manufacturers: Set<String>? = nil,
        serviceUUIDs: Set<String>? = nil,
        customFilter: ((Any) -> Bool)? = nil
    ) {
        self.deviceTypes = deviceTypes
        self.minRSSI = minRSSI
        self.maxDistance = maxDistance
        self.namePattern = namePattern
        self.manufacturers = manufacturers
        self.serviceUUIDs = serviceUUIDs
        self.customFilter = customFilter
    }
    
    /// 创建空过滤器（不过滤任何设备）
    public static var none: DeviceFilter {
        return DeviceFilter()
    }
    
    /// 创建仅按设备类型过滤的过滤器
    public static func deviceTypes(_ types: Set<String>) -> DeviceFilter {
        return DeviceFilter(deviceTypes: types)
    }
    
    /// 创建仅按信号强度过滤的过滤器
    public static func signalStrength(minRSSI: Int) -> DeviceFilter {
        return DeviceFilter(minRSSI: minRSSI)
    }
    
    /// 创建仅按距离过滤的过滤器
    public static func distance(maxDistance: Double) -> DeviceFilter {
        return DeviceFilter(maxDistance: maxDistance)
    }
}

// MARK: - Scan Statistics

/// 扫描统计信息
public struct ScanStatistics {
    /// 扫描开始时间
    public let scanStartTime: Date?
    
    /// 总扫描时长（秒）
    public let totalScanDuration: TimeInterval
    
    /// 扫描次数
    public let scanCount: Int
    
    /// 发现的设备总数
    public let devicesDiscovered: Int
    
    /// 当前活跃设备数
    public let activeDevices: Int
    
    /// 设备丢失次数
    public let devicesLost: Int
    
    /// 平均发现时间（秒）
    public let averageDiscoveryTime: TimeInterval?
    
    /// 最强信号强度
    public let strongestRSSI: Int?
    
    /// 最弱信号强度
    public let weakestRSSI: Int?
    
    /// 平均信号强度
    public let averageRSSI: Double?
    
    /// 按设备类型分组的统计
    public let deviceTypeStats: [String: Int]
    
    /// 扫描错误次数
    public let errorCount: Int
    
    /// 最后更新时间
    public let lastUpdated: Date
    
    public init(
        scanStartTime: Date? = nil,
        totalScanDuration: TimeInterval = 0,
        scanCount: Int = 0,
        devicesDiscovered: Int = 0,
        activeDevices: Int = 0,
        devicesLost: Int = 0,
        averageDiscoveryTime: TimeInterval? = nil,
        strongestRSSI: Int? = nil,
        weakestRSSI: Int? = nil,
        averageRSSI: Double? = nil,
        deviceTypeStats: [String: Int] = [:],
        errorCount: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.scanStartTime = scanStartTime
        self.totalScanDuration = totalScanDuration
        self.scanCount = scanCount
        self.devicesDiscovered = devicesDiscovered
        self.activeDevices = activeDevices
        self.devicesLost = devicesLost
        self.averageDiscoveryTime = averageDiscoveryTime
        self.strongestRSSI = strongestRSSI
        self.weakestRSSI = weakestRSSI
        self.averageRSSI = averageRSSI
        self.deviceTypeStats = deviceTypeStats
        self.errorCount = errorCount
        self.lastUpdated = lastUpdated
    }
    
    /// 设备发现率（每分钟）
    public var discoveryRate: Double {
        guard totalScanDuration > 0 else { return 0.0 }
        return Double(devicesDiscovered) / (totalScanDuration / 60.0)
    }
    
    /// 设备保持率
    public var deviceRetentionRate: Double {
        guard devicesDiscovered > 0 else { return 0.0 }
        return Double(activeDevices) / Double(devicesDiscovered)
    }
    
    /// 扫描成功率
    public var scanSuccessRate: Double {
        guard scanCount > 0 else { return 0.0 }
        let successfulScans = scanCount - errorCount
        return Double(successfulScans) / Double(scanCount)
    }
}

// MARK: - Default Implementation

public extension DeviceDiscovery {
    
    /// 默认扫描范围
    var scanRange: Double? {
        return nil // 无限制
    }
    
    /// 默认支持后台扫描
    var supportsBackgroundScanning: Bool {
        return false
    }
    
    /// 默认暂停扫描实现
    func pauseScanning() -> AnyPublisher<Void, DiscoveryError> {
        return Fail(error: DiscoveryError.scanStopFailed("暂停扫描功能未实现"))
            .eraseToAnyPublisher()
    }
    
    /// 默认恢复扫描实现
    func resumeScanning() -> AnyPublisher<Void, DiscoveryError> {
        return Fail(error: DiscoveryError.scanStartFailed("恢复扫描功能未实现"))
            .eraseToAnyPublisher()
    }
    
    /// 默认刷新扫描实现
    func refreshScan() -> AnyPublisher<Void, DiscoveryError> {
        return stopScanning()
            .flatMap { _ in
                return self.startScanning(with: self.getCurrentScanConfiguration())
            }
            .eraseToAnyPublisher()
    }
    
    /// 默认移除设备实现
    func removeDevice(deviceId: String) -> Bool {
        // 子类可以重写此方法
        return false
    }
    
    /// 默认按设备类型过滤实现
    func filterByDeviceTypes(_ deviceTypes: Set<String>) {
        let filter = DeviceFilter.deviceTypes(deviceTypes)
        setDeviceFilter(filter)
    }
    
    /// 默认按信号强度过滤实现
    func filterBySignalStrength(minRSSI: Int) {
        let filter = DeviceFilter.signalStrength(minRSSI: minRSSI)
        setDeviceFilter(filter)
    }
    
    /// 默认按距离过滤实现
    func filterByDistance(maxDistance: Double) {
        let filter = DeviceFilter.distance(maxDistance: maxDistance)
        setDeviceFilter(filter)
    }
    
    /// 默认重置统计信息实现
    func resetScanStatistics() {
        // 子类可以重写此方法
    }
}