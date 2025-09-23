//
//  ProvisioningExtensions.swift
//  ProvisioningModule
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import Foundation
import Combine
import UIKit
import Network
import SystemConfiguration

// MARK: - Publisher Extensions

extension Publisher {
    
    /// 在指定时间后超时
    func timeout(_ interval: TimeInterval, scheduler: DispatchQueue = .main) -> Publishers.Timeout<Self, DispatchQueue> {
        return self.timeout(.seconds(interval), scheduler: scheduler)
    }
    
    /// 重试指定次数
    func retry(_ times: Int, delay: TimeInterval = 1.0) -> AnyPublisher<Output, Failure> {
        return self.catch { error -> AnyPublisher<Output, Failure> in
            if times > 0 {
                return Just(())
                    .delay(for: .seconds(delay), scheduler: DispatchQueue.global())
                    .flatMap { _ in
                        self.retry(times - 1, delay: delay)
                    }
                    .eraseToAnyPublisher()
            } else {
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 在后台队列执行，在主队列接收
    func backgroundToMain() -> AnyPublisher<Output, Failure> {
        return self
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - String Extensions

extension String {
    
    /// 验证是否为有效的WiFi SSID
    var isValidSSID: Bool {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 32
    }
    
    /// 验证是否为有效的WiFi密码
    var isValidWiFiPassword: Bool {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 8 && trimmed.count <= 63
    }
    
    /// 验证是否为有效的IP地址
    var isValidIPAddress: Bool {
        let parts = self.split(separator: ".").compactMap { Int($0) }
        return parts.count == 4 && parts.allSatisfy { $0 >= 0 && $0 <= 255 }
    }
    
    /// 验证是否为有效的MAC地址
    var isValidMACAddress: Bool {
        let pattern = "^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: self.count)
        return regex?.firstMatch(in: self, options: [], range: range) != nil
    }
    
    /// 生成设备友好的名称
    var deviceFriendlyName: String {
        return self
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
    
    /// 转换为十六进制字符串
    var hexString: String {
        return self.data(using: .utf8)?.hexString ?? ""
    }
    
    /// 从十六进制字符串创建
    init?(hexString: String) {
        guard let data = Data(hexString: hexString) else { return nil }
        guard let string = String(data: data, encoding: .utf8) else { return nil }
        self = string
    }
}

// MARK: - Data Extensions

extension Data {
    
    /// 转换为十六进制字符串
    var hexString: String {
        return self.map { String(format: "%02x", $0) }.joined()
    }
    
    /// 从十六进制字符串创建Data
    init?(hexString: String) {
        let cleanHex = hexString.replacingOccurrences(of: " ", with: "")
        guard cleanHex.count % 2 == 0 else { return nil }
        
        var data = Data()
        var index = cleanHex.startIndex
        
        while index < cleanHex.endIndex {
            let nextIndex = cleanHex.index(index, offsetBy: 2)
            let byteString = String(cleanHex[index..<nextIndex])
            guard let byte = UInt8(byteString, radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        
        self = data
    }
    
    /// 转换为JSON对象
    func toJSONObject() -> Any? {
        return try? JSONSerialization.jsonObject(with: self, options: [])
    }
    
    /// 从JSON对象创建Data
    static func fromJSONObject(_ object: Any) -> Data? {
        return try? JSONSerialization.data(withJSONObject: object, options: [])
    }
}

// MARK: - Date Extensions

extension Date {
    
    /// 是否在指定时间间隔内
    func isWithin(_ interval: TimeInterval, of date: Date = Date()) -> Bool {
        return abs(self.timeIntervalSince(date)) <= interval
    }
    
    /// 格式化为配网日志时间戳
    var provisioningTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: self)
    }
    
    /// 相对时间描述
    var relativeTimeDescription: String {
        let interval = Date().timeIntervalSince(self)
        
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

// MARK: - TimeInterval Extensions

extension TimeInterval {
    
    /// 转换为人类可读的持续时间
    var durationDescription: String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)秒"
        }
    }
    
    /// 转换为毫秒
    var milliseconds: Int {
        return Int(self * 1000)
    }
}

// MARK: - Array Extensions

extension Array where Element == ProvisionableDevice {
    
    /// 按信号强度排序
    func sortedBySignalStrength() -> [ProvisionableDevice] {
        return self.sorted { device1, device2 in
            let rssi1 = device1.rssi ?? -100
            let rssi2 = device2.rssi ?? -100
            return rssi1 > rssi2
        }
    }
    
    /// 按发现时间排序
    func sortedByDiscoveryTime() -> [ProvisionableDevice] {
        return self.sorted { $0.discoveredAt > $1.discoveredAt }
    }
    
    /// 按设备类型分组
    func groupedByType() -> [DeviceType: [ProvisionableDevice]] {
        return Dictionary(grouping: self) { $0.type }
    }
    
    /// 过滤支持特定能力的设备
    func supporting(_ capability: DeviceCapability) -> [ProvisionableDevice] {
        return self.filter { $0.capabilities.contains(capability) }
    }
    
    /// 过滤最近发现的设备
    func recentlyDiscovered(within interval: TimeInterval = 300) -> [ProvisionableDevice] {
        let cutoffTime = Date().addingTimeInterval(-interval)
        return self.filter { $0.discoveredAt > cutoffTime }
    }
}

// MARK: - Dictionary Extensions

extension Dictionary where Key == String, Value == Any {
    
    /// 安全获取字符串值
    func stringValue(for key: String) -> String? {
        return self[key] as? String
    }
    
    /// 安全获取整数值
    func intValue(for key: String) -> Int? {
        if let value = self[key] as? Int {
            return value
        } else if let stringValue = self[key] as? String {
            return Int(stringValue)
        }
        return nil
    }
    
    /// 安全获取布尔值
    func boolValue(for key: String) -> Bool? {
        if let value = self[key] as? Bool {
            return value
        } else if let stringValue = self[key] as? String {
            return Bool(stringValue)
        } else if let intValue = self[key] as? Int {
            return intValue != 0
        }
        return nil
    }
    
    /// 转换为查询字符串
    var queryString: String {
        return self.compactMap { key, value in
            guard let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let encodedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return nil
            }
            return "\(encodedKey)=\(encodedValue)"
        }.joined(separator: "&")
    }
}

// MARK: - Error Extensions

extension Error {
    
    /// 转换为ProvisioningError
    var asProvisioningError: ProvisioningError {
        if let provisioningError = self as? ProvisioningError {
            return provisioningError
        } else {
            return .unknown(self.localizedDescription)
        }
    }
    
    /// 是否为网络错误
    var isNetworkError: Bool {
        if let urlError = self as? URLError {
            return [.notConnectedToInternet, .networkConnectionLost, .timedOut].contains(urlError.code)
        }
        return false
    }
    
    /// 是否为超时错误
    var isTimeoutError: Bool {
        if let urlError = self as? URLError {
            return urlError.code == .timedOut
        }
        return false
    }
}

// MARK: - UIDevice Extensions

extension UIDevice {
    
    /// 设备型号
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value))!)
        }
        return identifier
    }
    
    /// 是否支持蓝牙
    var supportsBluetoothLE: Bool {
        return true // 现代iOS设备都支持BLE
    }
    
    /// 是否支持WiFi
    var supportsWiFi: Bool {
        return true // 所有iOS设备都支持WiFi
    }
}

// MARK: - Network Reachability Extensions

extension NetworkReachability {
    
    /// 检查网络连接状态
    static func checkConnectivity() -> NetworkConnectivityStatus {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return .unknown
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return .unknown
        }
        
        if flags.contains(.reachable) && !flags.contains(.connectionRequired) {
            return .connected
        } else if flags.contains(.reachable) && flags.contains(.connectionOnDemand) {
            return .connectedOnDemand
        } else {
            return .disconnected
        }
    }
}

// MARK: - Network Connectivity Status

enum NetworkConnectivityStatus {
    case connected
    case connectedOnDemand
    case disconnected
    case unknown
    
    var isConnected: Bool {
        return self == .connected || self == .connectedOnDemand
    }
    
    var displayName: String {
        switch self {
        case .connected:
            return "已连接"
        case .connectedOnDemand:
            return "按需连接"
        case .disconnected:
            return "未连接"
        case .unknown:
            return "未知"
        }
    }
}

// MARK: - Network Reachability Helper

class NetworkReachability {
    // 网络可达性检查的辅助类
}

// MARK: - Validation Extensions

extension NetworkConfiguration {
    
    /// 验证网络配置是否有效
    var isValid: Bool {
        guard ssid.isValidSSID else { return false }
        
        if securityType.requiresPassword {
            guard let password = password, password.isValidWiFiPassword else {
                return false
            }
        }
        
        if let staticIP = staticIP {
            guard staticIP.isValid else { return false }
        }
        
        return true
    }
    
    /// 获取验证错误信息
    var validationErrors: [String] {
        var errors: [String] = []
        
        if !ssid.isValidSSID {
            errors.append("无效的WiFi名称")
        }
        
        if securityType.requiresPassword {
            if password == nil {
                errors.append("需要WiFi密码")
            } else if let password = password, !password.isValidWiFiPassword {
                errors.append("WiFi密码长度必须在8-63个字符之间")
            }
        }
        
        if let staticIP = staticIP, !staticIP.isValid {
            errors.append("静态IP配置无效")
        }
        
        return errors
    }
}

extension DeviceConfiguration {
    
    /// 验证设备配置是否有效
    var isValid: Bool {
        return !deviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// 获取验证错误信息
    var validationErrors: [String] {
        var errors: [String] = []
        
        if deviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("设备名称不能为空")
        }
        
        return errors
    }
}

// MARK: - Logging Extensions

extension ProvisioningError {
    
    /// 获取错误的日志级别
    var logLevel: LogLevel {
        switch self {
        case .timeout, .cancelled:
            return .warning
        case .deviceNotFound, .unsupportedDevice:
            return .info
        default:
            return .error
        }
    }
    
    /// 获取错误的分类
    var category: String {
        switch self {
        case .deviceNotFound, .unsupportedDevice:
            return "Device"
        case .connectionFailed, .communicationFailed:
            return "Connection"
        case .authenticationFailed:
            return "Authentication"
        case .configurationFailed:
            return "Configuration"
        case .verificationFailed:
            return "Verification"
        case .timeout:
            return "Timeout"
        case .cancelled:
            return "User"
        case .serviceUnavailable:
            return "Service"
        case .unknown:
            return "Unknown"
        }
    }
}

// MARK: - Log Level

enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    
    var emoji: String {
        switch self {
        case .debug:
            return "🔍"
        case .info:
            return "ℹ️"
        case .warning:
            return "⚠️"
        case .error:
            return "❌"
        }
    }
}

// MARK: - Utility Functions

/// 生成唯一的设备ID
func generateDeviceID() -> String {
    return UUID().uuidString
}

/// 生成配网会话ID
func generateSessionID() -> String {
    let timestamp = Int(Date().timeIntervalSince1970)
    let random = Int.random(in: 1000...9999)
    return "session_\(timestamp)_\(random)"
}

/// 计算配网步骤的总体进度
func calculateOverallProgress(currentStep: Int, totalSteps: Int, currentStepProgress: Float) -> Float {
    guard totalSteps > 0 else { return 0.0 }
    
    let completedSteps = max(0, currentStep - 1)
    let stepWeight = 1.0 / Float(totalSteps)
    let completedProgress = Float(completedSteps) * stepWeight
    let currentProgress = currentStepProgress * stepWeight
    
    return min(1.0, completedProgress + currentProgress)
}

/// 估算剩余时间
func estimateRemainingTime(startTime: Date, currentProgress: Float) -> TimeInterval? {
    guard currentProgress > 0.0 && currentProgress < 1.0 else { return nil }
    
    let elapsedTime = Date().timeIntervalSince(startTime)
    let totalEstimatedTime = elapsedTime / TimeInterval(currentProgress)
    let remainingTime = totalEstimatedTime - elapsedTime
    
    return max(0, remainingTime)
}

/// 格式化字节大小
func formatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB, .useGB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
}

/// 格式化网络速度
func formatNetworkSpeed(_ bytesPerSecond: Double) -> String {
    let mbps = bytesPerSecond * 8 / 1_000_000 // 转换为Mbps
    return String(format: "%.1f Mbps", mbps)
}

/// 生成随机MAC地址
func generateRandomMACAddress() -> String {
    let bytes = (0..<6).map { _ in String(format: "%02x", Int.random(in: 0...255)) }
    return bytes.joined(separator: ":")
}

/// 验证设备兼容性
func checkDeviceCompatibility(_ device: ProvisionableDevice) -> [String] {
    var issues: [String] = []
    
    // 检查固件版本
    if let firmwareVersion = device.firmwareVersion {
        let version = firmwareVersion.split(separator: ".").compactMap { Int($0) }
        if version.count >= 2 && version[0] < 2 {
            issues.append("固件版本过低，建议升级到2.0以上")
        }
    }
    
    // 检查安全级别
    if device.securityLevel == .none {
        issues.append("设备未启用加密，存在安全风险")
    }
    
    // 检查信号强度
    if let rssi = device.rssi, rssi < -80 {
        issues.append("信号强度较弱，可能影响连接稳定性")
    }
    
    return issues
}