//
//  SharedUIResources.swift
//  SharedUI
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import UIKit
import SwiftUI

// MARK: - Asset Manager

/// 资源管理器
public class SharedUIAssets {
    
    // MARK: - Bundle
    
    private static var bundle: Bundle {
        return Bundle(for: SharedUIAssets.self)
    }
    
    // MARK: - Images
    
    public enum Images {
        
        // MARK: - Device Icons
        
        public static let deviceLight = UIImage(systemName: "lightbulb") ?? UIImage()
        public static let deviceSwitch = UIImage(systemName: "switch.2") ?? UIImage()
        public static let deviceSensor = UIImage(systemName: "sensor") ?? UIImage()
        public static let deviceCamera = UIImage(systemName: "camera") ?? UIImage()
        public static let deviceLock = UIImage(systemName: "lock") ?? UIImage()
        public static let deviceThermostat = UIImage(systemName: "thermometer") ?? UIImage()
        public static let deviceUnknown = UIImage(systemName: "cube.box") ?? UIImage()
        
        // MARK: - Status Icons
        
        public static let statusOnline = UIImage(systemName: "checkmark.circle.fill") ?? UIImage()
        public static let statusOffline = UIImage(systemName: "xmark.circle.fill") ?? UIImage()
        public static let statusConnecting = UIImage(systemName: "arrow.clockwise.circle.fill") ?? UIImage()
        public static let statusError = UIImage(systemName: "exclamationmark.triangle.fill") ?? UIImage()
        public static let statusUnknown = UIImage(systemName: "questionmark.circle.fill") ?? UIImage()
        
        // MARK: - Navigation Icons
        
        public static let navigationBack = UIImage(systemName: "chevron.left") ?? UIImage()
        public static let navigationForward = UIImage(systemName: "chevron.right") ?? UIImage()
        public static let navigationUp = UIImage(systemName: "chevron.up") ?? UIImage()
        public static let navigationDown = UIImage(systemName: "chevron.down") ?? UIImage()
        public static let navigationClose = UIImage(systemName: "xmark") ?? UIImage()
        public static let navigationMenu = UIImage(systemName: "line.3.horizontal") ?? UIImage()
        
        // MARK: - Action Icons
        
        public static let actionAdd = UIImage(systemName: "plus") ?? UIImage()
        public static let actionEdit = UIImage(systemName: "pencil") ?? UIImage()
        public static let actionDelete = UIImage(systemName: "trash") ?? UIImage()
        public static let actionShare = UIImage(systemName: "square.and.arrow.up") ?? UIImage()
        public static let actionRefresh = UIImage(systemName: "arrow.clockwise") ?? UIImage()
        public static let actionSettings = UIImage(systemName: "gear") ?? UIImage()
        public static let actionSearch = UIImage(systemName: "magnifyingglass") ?? UIImage()
        public static let actionFilter = UIImage(systemName: "line.3.horizontal.decrease.circle") ?? UIImage()
        public static let actionSort = UIImage(systemName: "arrow.up.arrow.down") ?? UIImage()
        
        // MARK: - Battery Icons
        
        public static let battery0 = UIImage(systemName: "battery.0") ?? UIImage()
        public static let battery25 = UIImage(systemName: "battery.25") ?? UIImage()
        public static let battery50 = UIImage(systemName: "battery.50") ?? UIImage()
        public static let battery75 = UIImage(systemName: "battery.75") ?? UIImage()
        public static let battery100 = UIImage(systemName: "battery.100") ?? UIImage()
        
        // MARK: - Signal Icons
        
        public static let signalWeak = UIImage(systemName: "wifi.exclamationmark") ?? UIImage()
        public static let signalStrong = UIImage(systemName: "wifi") ?? UIImage()
        public static let signalNone = UIImage(systemName: "wifi.slash") ?? UIImage()
        
        // MARK: - Empty State Icons
        
        public static let emptyDevices = UIImage(systemName: "cube.box") ?? UIImage()
        public static let emptySearch = UIImage(systemName: "magnifyingglass") ?? UIImage()
        public static let emptyNetwork = UIImage(systemName: "wifi.slash") ?? UIImage()
        public static let emptyError = UIImage(systemName: "exclamationmark.triangle") ?? UIImage()
        
        // MARK: - Helper Methods
        
        /// 获取设备图标
        public static func deviceIcon(for type: String) -> UIImage {
            switch type.lowercased() {
            case "light", "灯泡":
                return deviceLight
            case "switch", "开关":
                return deviceSwitch
            case "sensor", "传感器":
                return deviceSensor
            case "camera", "摄像头":
                return deviceCamera
            case "lock", "门锁":
                return deviceLock
            case "thermostat", "温控器":
                return deviceThermostat
            default:
                return deviceUnknown
            }
        }
        
        /// 获取状态图标
        public static func statusIcon(for status: String) -> UIImage {
            switch status.lowercased() {
            case "online", "在线":
                return statusOnline
            case "offline", "离线":
                return statusOffline
            case "connecting", "连接中":
                return statusConnecting
            case "error", "错误":
                return statusError
            default:
                return statusUnknown
            }
        }
        
        /// 获取电池图标
        public static func batteryIcon(for level: Float) -> UIImage {
            switch level {
            case 0.0...0.2:
                return battery0
            case 0.2...0.4:
                return battery25
            case 0.4...0.6:
                return battery50
            case 0.6...0.8:
                return battery75
            default:
                return battery100
            }
        }
        
        /// 获取信号图标
        public static func signalIcon(for strength: Float) -> UIImage {
            switch strength {
            case 0.0...0.3:
                return signalWeak
            case 0.3...1.0:
                return signalStrong
            default:
                return signalNone
            }
        }
    }
    
    // MARK: - Colors
    
    public enum Colors {
        
        // MARK: - Brand Colors
        
        public static let brandPrimary = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0) // #007AFF
        public static let brandSecondary = UIColor(red: 0.35, green: 0.35, blue: 0.81, alpha: 1.0) // #5856CF
        public static let brandAccent = UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0) // #FF9500
        
        // MARK: - Semantic Colors
        
        public static let success = UIColor.systemGreen
        public static let warning = UIColor.systemOrange
        public static let error = UIColor.systemRed
        public static let info = UIColor.systemBlue
        
        // MARK: - Device Status Colors
        
        public static let deviceOnline = UIColor.systemGreen
        public static let deviceOffline = UIColor.systemGray
        public static let deviceConnecting = UIColor.systemOrange
        public static let deviceError = UIColor.systemRed
        
        // MARK: - Neutral Colors
        
        public static let neutral50 = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
        public static let neutral100 = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        public static let neutral200 = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)
        public static let neutral300 = UIColor(red: 0.87, green: 0.87, blue: 0.87, alpha: 1.0)
        public static let neutral400 = UIColor(red: 0.74, green: 0.74, blue: 0.74, alpha: 1.0)
        public static let neutral500 = UIColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1.0)
        public static let neutral600 = UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0)
        public static let neutral700 = UIColor(red: 0.38, green: 0.38, blue: 0.38, alpha: 1.0)
        public static let neutral800 = UIColor(red: 0.26, green: 0.26, blue: 0.26, alpha: 1.0)
        public static let neutral900 = UIColor(red: 0.09, green: 0.09, blue: 0.09, alpha: 1.0)
    }
    
    // MARK: - Fonts
    
    public enum Fonts {
        
        // MARK: - System Fonts
        
        public static let displayLarge = UIFont.systemFont(ofSize: 57, weight: .regular)
        public static let displayMedium = UIFont.systemFont(ofSize: 45, weight: .regular)
        public static let displaySmall = UIFont.systemFont(ofSize: 36, weight: .regular)
        
        public static let headlineLarge = UIFont.systemFont(ofSize: 32, weight: .regular)
        public static let headlineMedium = UIFont.systemFont(ofSize: 28, weight: .regular)
        public static let headlineSmall = UIFont.systemFont(ofSize: 24, weight: .regular)
        
        public static let titleLarge = UIFont.systemFont(ofSize: 22, weight: .regular)
        public static let titleMedium = UIFont.systemFont(ofSize: 16, weight: .medium)
        public static let titleSmall = UIFont.systemFont(ofSize: 14, weight: .medium)
        
        public static let bodyLarge = UIFont.systemFont(ofSize: 16, weight: .regular)
        public static let bodyMedium = UIFont.systemFont(ofSize: 14, weight: .regular)
        public static let bodySmall = UIFont.systemFont(ofSize: 12, weight: .regular)
        
        public static let labelLarge = UIFont.systemFont(ofSize: 14, weight: .medium)
        public static let labelMedium = UIFont.systemFont(ofSize: 12, weight: .medium)
        public static let labelSmall = UIFont.systemFont(ofSize: 11, weight: .medium)
        
        public static let caption = UIFont.systemFont(ofSize: 12, weight: .regular)
        public static let overline = UIFont.systemFont(ofSize: 10, weight: .regular)
        public static let button = UIFont.systemFont(ofSize: 14, weight: .medium)
        
        // MARK: - Specialized Fonts
        
        public static let code = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        public static let rounded = UIFont.roundedSystemFont(ofSize: 16, weight: .regular)
    }
    
    // MARK: - Spacing
    
    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
        public static let xxxl: CGFloat = 64
    }
    
    // MARK: - Corner Radius
    
    public enum CornerRadius {
        public static let none: CGFloat = 0
        public static let xs: CGFloat = 2
        public static let sm: CGFloat = 4
        public static let md: CGFloat = 8
        public static let lg: CGFloat = 12
        public static let xl: CGFloat = 16
        public static let xxl: CGFloat = 24
        public static let full: CGFloat = 9999
    }
    
    // MARK: - Animation Duration
    
    public enum AnimationDuration {
        public static let fast: TimeInterval = 0.15
        public static let normal: TimeInterval = 0.3
        public static let slow: TimeInterval = 0.5
    }
}

// MARK: - Localization

/// 本地化字符串管理器
public class SharedUIStrings {
    
    private static var bundle: Bundle {
        return Bundle(for: SharedUIStrings.self)
    }
    
    // MARK: - Common Strings
    
    public static let ok = NSLocalizedString("OK", bundle: bundle, comment: "确定")
    public static let cancel = NSLocalizedString("Cancel", bundle: bundle, comment: "取消")
    public static let save = NSLocalizedString("Save", bundle: bundle, comment: "保存")
    public static let delete = NSLocalizedString("Delete", bundle: bundle, comment: "删除")
    public static let edit = NSLocalizedString("Edit", bundle: bundle, comment: "编辑")
    public static let done = NSLocalizedString("Done", bundle: bundle, comment: "完成")
    public static let close = NSLocalizedString("Close", bundle: bundle, comment: "关闭")
    public static let retry = NSLocalizedString("Retry", bundle: bundle, comment: "重试")
    public static let refresh = NSLocalizedString("Refresh", bundle: bundle, comment: "刷新")
    public static let loading = NSLocalizedString("Loading...", bundle: bundle, comment: "加载中...")
    
    // MARK: - Device Strings
    
    public static let deviceOnline = NSLocalizedString("Online", bundle: bundle, comment: "在线")
    public static let deviceOffline = NSLocalizedString("Offline", bundle: bundle, comment: "离线")
    public static let deviceConnecting = NSLocalizedString("Connecting", bundle: bundle, comment: "连接中")
    public static let deviceError = NSLocalizedString("Error", bundle: bundle, comment: "错误")
    public static let deviceUnknown = NSLocalizedString("Unknown", bundle: bundle, comment: "未知")
    
    // MARK: - Empty State Strings
    
    public static let emptyDevicesTitle = NSLocalizedString("No Devices", bundle: bundle, comment: "暂无设备")
    public static let emptyDevicesMessage = NSLocalizedString("No devices found. Add a device to get started.", bundle: bundle, comment: "未找到设备。添加设备以开始使用。")
    public static let emptySearchTitle = NSLocalizedString("No Results", bundle: bundle, comment: "无搜索结果")
    public static let emptySearchMessage = NSLocalizedString("No results found for your search.", bundle: bundle, comment: "未找到与您搜索相关的结果。")
    public static let emptyNetworkTitle = NSLocalizedString("No Connection", bundle: bundle, comment: "无网络连接")
    public static let emptyNetworkMessage = NSLocalizedString("Please check your network connection and try again.", bundle: bundle, comment: "请检查您的网络连接并重试。")
    
    // MARK: - Error Strings
    
    public static let errorGeneral = NSLocalizedString("An error occurred", bundle: bundle, comment: "发生错误")
    public static let errorNetwork = NSLocalizedString("Network error", bundle: bundle, comment: "网络错误")
    public static let errorTimeout = NSLocalizedString("Request timeout", bundle: bundle, comment: "请求超时")
    public static let errorUnauthorized = NSLocalizedString("Unauthorized access", bundle: bundle, comment: "未授权访问")
    public static let errorNotFound = NSLocalizedString("Resource not found", bundle: bundle, comment: "资源未找到")
    
    // MARK: - Helper Methods
    
    /// 获取本地化字符串
    public static func localizedString(for key: String, comment: String = "") -> String {
        return NSLocalizedString(key, bundle: bundle, comment: comment)
    }
    
    /// 获取设备状态字符串
    public static func deviceStatusString(for status: String) -> String {
        switch status.lowercased() {
        case "online":
            return deviceOnline
        case "offline":
            return deviceOffline
        case "connecting":
            return deviceConnecting
        case "error":
            return deviceError
        default:
            return deviceUnknown
        }
    }
}

// MARK: - Constants

/// 常量定义
public enum SharedUIConstants {
    
    // MARK: - Layout Constants
    
    public enum Layout {
        public static let minimumTouchTarget: CGFloat = 44
        public static let defaultCornerRadius: CGFloat = 8
        public static let defaultBorderWidth: CGFloat = 1
        public static let defaultShadowRadius: CGFloat = 4
        public static let defaultAnimationDuration: TimeInterval = 0.3
    }
    
    // MARK: - Device Constants
    
    public enum Device {
        public static let cardHeight: CGFloat = 120
        public static let cardSpacing: CGFloat = 16
        public static let iconSize: CGFloat = 48
        public static let statusIndicatorSize: CGFloat = 12
        public static let batteryIndicatorSize: CGFloat = 16
        public static let signalIndicatorSize: CGFloat = 16
    }
    
    // MARK: - Button Constants
    
    public enum Button {
        public static let defaultHeight: CGFloat = 44
        public static let largeHeight: CGFloat = 56
        public static let smallHeight: CGFloat = 32
        public static let minimumWidth: CGFloat = 88
    }
    
    // MARK: - Input Constants
    
    public enum Input {
        public static let defaultHeight: CGFloat = 44
        public static let largeHeight: CGFloat = 56
        public static let multilineMinHeight: CGFloat = 88
    }
}

// MARK: - SwiftUI Support

#if canImport(SwiftUI)
import SwiftUI

/// SwiftUI 资源扩展
@available(iOS 13.0, *)
public extension SharedUIAssets {
    
    enum SwiftUIImages {
        public static let deviceLight = Image(systemName: "lightbulb")
        public static let deviceSwitch = Image(systemName: "switch.2")
        public static let deviceSensor = Image(systemName: "sensor")
        public static let deviceCamera = Image(systemName: "camera")
        public static let deviceLock = Image(systemName: "lock")
        public static let deviceThermostat = Image(systemName: "thermometer")
        public static let deviceUnknown = Image(systemName: "cube.box")
        
        public static let statusOnline = Image(systemName: "checkmark.circle.fill")
        public static let statusOffline = Image(systemName: "xmark.circle.fill")
        public static let statusConnecting = Image(systemName: "arrow.clockwise.circle.fill")
        public static let statusError = Image(systemName: "exclamationmark.triangle.fill")
        public static let statusUnknown = Image(systemName: "questionmark.circle.fill")
    }
    
    enum SwiftUIColors {
        public static let brandPrimary = Color(Colors.brandPrimary)
        public static let brandSecondary = Color(Colors.brandSecondary)
        public static let brandAccent = Color(Colors.brandAccent)
        
        public static let success = Color(Colors.success)
        public static let warning = Color(Colors.warning)
        public static let error = Color(Colors.error)
        public static let info = Color(Colors.info)
        
        public static let deviceOnline = Color(Colors.deviceOnline)
        public static let deviceOffline = Color(Colors.deviceOffline)
        public static let deviceConnecting = Color(Colors.deviceConnecting)
        public static let deviceError = Color(Colors.deviceError)
    }
}

#endif