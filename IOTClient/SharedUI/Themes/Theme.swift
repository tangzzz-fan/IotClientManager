//
//  Theme.swift
//  SharedUI
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import UIKit
import SwiftUI

// MARK: - Theme Protocol

/// 主题协议，定义应用主题的基本接口
protocol Theme {
    var name: String { get }
    var colors: ColorPalette { get }
    var typography: Typography { get }
    var spacing: Spacing { get }
    var cornerRadius: CornerRadius { get }
    var shadows: Shadows { get }
    var animations: Animations { get }
}

// MARK: - Color Palette

/// 颜色调色板
struct ColorPalette {
    // MARK: - Primary Colors
    let primary: UIColor
    let primaryVariant: UIColor
    let secondary: UIColor
    let secondaryVariant: UIColor
    
    // MARK: - Background Colors
    let background: UIColor
    let surface: UIColor
    let surfaceVariant: UIColor
    
    // MARK: - Text Colors
    let onPrimary: UIColor
    let onSecondary: UIColor
    let onBackground: UIColor
    let onSurface: UIColor
    
    // MARK: - Status Colors
    let success: UIColor
    let warning: UIColor
    let error: UIColor
    let info: UIColor
    
    // MARK: - Neutral Colors
    let neutral50: UIColor
    let neutral100: UIColor
    let neutral200: UIColor
    let neutral300: UIColor
    let neutral400: UIColor
    let neutral500: UIColor
    let neutral600: UIColor
    let neutral700: UIColor
    let neutral800: UIColor
    let neutral900: UIColor
    
    // MARK: - Device Status Colors
    let deviceOnline: UIColor
    let deviceOffline: UIColor
    let deviceConnecting: UIColor
    let deviceError: UIColor
    
    // MARK: - Interactive Colors
    let buttonPrimary: UIColor
    let buttonSecondary: UIColor
    let buttonDisabled: UIColor
    let link: UIColor
    let linkVisited: UIColor
    
    // MARK: - Border Colors
    let border: UIColor
    let borderFocus: UIColor
    let borderError: UIColor
    let divider: UIColor
}

// MARK: - Typography

/// 字体排版系统
struct Typography {
    // MARK: - Display Fonts
    let displayLarge: UIFont
    let displayMedium: UIFont
    let displaySmall: UIFont
    
    // MARK: - Headline Fonts
    let headlineLarge: UIFont
    let headlineMedium: UIFont
    let headlineSmall: UIFont
    
    // MARK: - Title Fonts
    let titleLarge: UIFont
    let titleMedium: UIFont
    let titleSmall: UIFont
    
    // MARK: - Body Fonts
    let bodyLarge: UIFont
    let bodyMedium: UIFont
    let bodySmall: UIFont
    
    // MARK: - Label Fonts
    let labelLarge: UIFont
    let labelMedium: UIFont
    let labelSmall: UIFont
    
    // MARK: - Specialized Fonts
    let caption: UIFont
    let overline: UIFont
    let button: UIFont
    let code: UIFont
}

// MARK: - Spacing

/// 间距系统
struct Spacing {
    let xs: CGFloat      // 4pt
    let sm: CGFloat      // 8pt
    let md: CGFloat      // 16pt
    let lg: CGFloat      // 24pt
    let xl: CGFloat      // 32pt
    let xxl: CGFloat     // 48pt
    let xxxl: CGFloat    // 64pt
    
    // MARK: - Component Specific Spacing
    let buttonPadding: UIEdgeInsets
    let cardPadding: UIEdgeInsets
    let listItemPadding: UIEdgeInsets
    let sectionSpacing: CGFloat
    let itemSpacing: CGFloat
}

// MARK: - Corner Radius

/// 圆角系统
struct CornerRadius {
    let none: CGFloat     // 0pt
    let xs: CGFloat       // 2pt
    let sm: CGFloat       // 4pt
    let md: CGFloat       // 8pt
    let lg: CGFloat       // 12pt
    let xl: CGFloat       // 16pt
    let xxl: CGFloat      // 24pt
    let full: CGFloat     // 9999pt (完全圆形)
    
    // MARK: - Component Specific Radius
    let button: CGFloat
    let card: CGFloat
    let input: CGFloat
    let modal: CGFloat
}

// MARK: - Shadows

/// 阴影系统
struct Shadows {
    let none: ShadowStyle
    let xs: ShadowStyle
    let sm: ShadowStyle
    let md: ShadowStyle
    let lg: ShadowStyle
    let xl: ShadowStyle
    
    // MARK: - Component Specific Shadows
    let card: ShadowStyle
    let button: ShadowStyle
    let modal: ShadowStyle
    let floating: ShadowStyle
}

/// 阴影样式
struct ShadowStyle {
    let color: UIColor
    let offset: CGSize
    let radius: CGFloat
    let opacity: Float
}

// MARK: - Animations

/// 动画系统
struct Animations {
    let fast: TimeInterval        // 0.15s
    let normal: TimeInterval      // 0.3s
    let slow: TimeInterval        // 0.5s
    
    // MARK: - Easing Functions
    let easeIn: UIView.AnimationOptions
    let easeOut: UIView.AnimationOptions
    let easeInOut: UIView.AnimationOptions
    let spring: UIView.AnimationOptions
    
    // MARK: - Component Specific Animations
    let buttonPress: TimeInterval
    let modalPresent: TimeInterval
    let pageTransition: TimeInterval
    let loadingSpinner: TimeInterval
}

// MARK: - Light Theme

/// 浅色主题
struct LightTheme: Theme {
    let name = "Light"
    
    let colors = ColorPalette(
        // Primary Colors
        primary: UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0),        // #007AFF
        primaryVariant: UIColor(red: 0.0, green: 0.4, blue: 0.85, alpha: 1.0), // #0066D9
        secondary: UIColor(red: 0.35, green: 0.35, blue: 0.81, alpha: 1.0),     // #5856CF
        secondaryVariant: UIColor(red: 0.3, green: 0.3, blue: 0.7, alpha: 1.0), // #4C4CB3
        
        // Background Colors
        background: UIColor.systemBackground,
        surface: UIColor.secondarySystemBackground,
        surfaceVariant: UIColor.tertiarySystemBackground,
        
        // Text Colors
        onPrimary: UIColor.white,
        onSecondary: UIColor.white,
        onBackground: UIColor.label,
        onSurface: UIColor.label,
        
        // Status Colors
        success: UIColor.systemGreen,
        warning: UIColor.systemOrange,
        error: UIColor.systemRed,
        info: UIColor.systemBlue,
        
        // Neutral Colors
        neutral50: UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0),
        neutral100: UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0),
        neutral200: UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0),
        neutral300: UIColor(red: 0.87, green: 0.87, blue: 0.87, alpha: 1.0),
        neutral400: UIColor(red: 0.74, green: 0.74, blue: 0.74, alpha: 1.0),
        neutral500: UIColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1.0),
        neutral600: UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0),
        neutral700: UIColor(red: 0.38, green: 0.38, blue: 0.38, alpha: 1.0),
        neutral800: UIColor(red: 0.26, green: 0.26, blue: 0.26, alpha: 1.0),
        neutral900: UIColor(red: 0.09, green: 0.09, blue: 0.09, alpha: 1.0),
        
        // Device Status Colors
        deviceOnline: UIColor.systemGreen,
        deviceOffline: UIColor.systemGray,
        deviceConnecting: UIColor.systemOrange,
        deviceError: UIColor.systemRed,
        
        // Interactive Colors
        buttonPrimary: UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0),
        buttonSecondary: UIColor.systemGray5,
        buttonDisabled: UIColor.systemGray4,
        link: UIColor.systemBlue,
        linkVisited: UIColor.systemPurple,
        
        // Border Colors
        border: UIColor.separator,
        borderFocus: UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0),
        borderError: UIColor.systemRed,
        divider: UIColor.separator
    )
    
    let typography = Typography(
        // Display Fonts
        displayLarge: UIFont.systemFont(ofSize: 57, weight: .regular),
        displayMedium: UIFont.systemFont(ofSize: 45, weight: .regular),
        displaySmall: UIFont.systemFont(ofSize: 36, weight: .regular),
        
        // Headline Fonts
        headlineLarge: UIFont.systemFont(ofSize: 32, weight: .regular),
        headlineMedium: UIFont.systemFont(ofSize: 28, weight: .regular),
        headlineSmall: UIFont.systemFont(ofSize: 24, weight: .regular),
        
        // Title Fonts
        titleLarge: UIFont.systemFont(ofSize: 22, weight: .regular),
        titleMedium: UIFont.systemFont(ofSize: 16, weight: .medium),
        titleSmall: UIFont.systemFont(ofSize: 14, weight: .medium),
        
        // Body Fonts
        bodyLarge: UIFont.systemFont(ofSize: 16, weight: .regular),
        bodyMedium: UIFont.systemFont(ofSize: 14, weight: .regular),
        bodySmall: UIFont.systemFont(ofSize: 12, weight: .regular),
        
        // Label Fonts
        labelLarge: UIFont.systemFont(ofSize: 14, weight: .medium),
        labelMedium: UIFont.systemFont(ofSize: 12, weight: .medium),
        labelSmall: UIFont.systemFont(ofSize: 11, weight: .medium),
        
        // Specialized Fonts
        caption: UIFont.systemFont(ofSize: 12, weight: .regular),
        overline: UIFont.systemFont(ofSize: 10, weight: .regular),
        button: UIFont.systemFont(ofSize: 14, weight: .medium),
        code: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    )
    
    let spacing = Spacing(
        xs: 4,
        sm: 8,
        md: 16,
        lg: 24,
        xl: 32,
        xxl: 48,
        xxxl: 64,
        buttonPadding: UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24),
        cardPadding: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
        listItemPadding: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16),
        sectionSpacing: 32,
        itemSpacing: 16
    )
    
    let cornerRadius = CornerRadius(
        none: 0,
        xs: 2,
        sm: 4,
        md: 8,
        lg: 12,
        xl: 16,
        xxl: 24,
        full: 9999,
        button: 8,
        card: 12,
        input: 8,
        modal: 16
    )
    
    let shadows = Shadows(
        none: ShadowStyle(color: .clear, offset: .zero, radius: 0, opacity: 0),
        xs: ShadowStyle(color: .black, offset: CGSize(width: 0, height: 1), radius: 2, opacity: 0.05),
        sm: ShadowStyle(color: .black, offset: CGSize(width: 0, height: 1), radius: 3, opacity: 0.1),
        md: ShadowStyle(color: .black, offset: CGSize(width: 0, height: 4), radius: 6, opacity: 0.1),
        lg: ShadowStyle(color: .black, offset: CGSize(width: 0, height: 10), radius: 15, opacity: 0.1),
        xl: ShadowStyle(color: .black, offset: CGSize(width: 0, height: 20), radius: 25, opacity: 0.1),
        card: ShadowStyle(color: .black, offset: CGSize(width: 0, height: 2), radius: 4, opacity: 0.1),
        button: ShadowStyle(color: .black, offset: CGSize(width: 0, height: 1), radius: 2, opacity: 0.1),
        modal: ShadowStyle(color: .black, offset: CGSize(width: 0, height: 8), radius: 16, opacity: 0.15),
        floating: ShadowStyle(color: .black, offset: CGSize(width: 0, height: 4), radius: 8, opacity: 0.12)
    )
    
    let animations = Animations(
        fast: 0.15,
        normal: 0.3,
        slow: 0.5,
        easeIn: .curveEaseIn,
        easeOut: .curveEaseOut,
        easeInOut: .curveEaseInOut,
        spring: [.curveEaseInOut, .allowUserInteraction],
        buttonPress: 0.1,
        modalPresent: 0.3,
        pageTransition: 0.35,
        loadingSpinner: 1.0
    )
}

// MARK: - Dark Theme

/// 深色主题
struct DarkTheme: Theme {
    let name = "Dark"
    
    let colors = ColorPalette(
        // Primary Colors
        primary: UIColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 1.0),        // #0A84FF
        primaryVariant: UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0),   // #3399FF
        secondary: UIColor(red: 0.75, green: 0.35, blue: 0.95, alpha: 1.0),     // #BF5AF2
        secondaryVariant: UIColor(red: 0.8, green: 0.4, blue: 1.0, alpha: 1.0), // #CC66FF
        
        // Background Colors
        background: UIColor.systemBackground,
        surface: UIColor.secondarySystemBackground,
        surfaceVariant: UIColor.tertiarySystemBackground,
        
        // Text Colors
        onPrimary: UIColor.black,
        onSecondary: UIColor.black,
        onBackground: UIColor.label,
        onSurface: UIColor.label,
        
        // Status Colors
        success: UIColor.systemGreen,
        warning: UIColor.systemOrange,
        error: UIColor.systemRed,
        info: UIColor.systemBlue,
        
        // Neutral Colors
        neutral50: UIColor(red: 0.09, green: 0.09, blue: 0.09, alpha: 1.0),
        neutral100: UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0),
        neutral200: UIColor(red: 0.23, green: 0.23, blue: 0.23, alpha: 1.0),
        neutral300: UIColor(red: 0.32, green: 0.32, blue: 0.32, alpha: 1.0),
        neutral400: UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0),
        neutral500: UIColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1.0),
        neutral600: UIColor(red: 0.74, green: 0.74, blue: 0.74, alpha: 1.0),
        neutral700: UIColor(red: 0.87, green: 0.87, blue: 0.87, alpha: 1.0),
        neutral800: UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0),
        neutral900: UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0),
        
        // Device Status Colors
        deviceOnline: UIColor.systemGreen,
        deviceOffline: UIColor.systemGray,
        deviceConnecting: UIColor.systemOrange,
        deviceError: UIColor.systemRed,
        
        // Interactive Colors
        buttonPrimary: UIColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 1.0),
        buttonSecondary: UIColor.systemGray5,
        buttonDisabled: UIColor.systemGray4,
        link: UIColor.systemBlue,
        linkVisited: UIColor.systemPurple,
        
        // Border Colors
        border: UIColor.separator,
        borderFocus: UIColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 1.0),
        borderError: UIColor.systemRed,
        divider: UIColor.separator
    )
    
    // Typography remains the same as light theme
    let typography = LightTheme().typography
    let spacing = LightTheme().spacing
    let cornerRadius = LightTheme().cornerRadius
    
    let shadows = Shadows(
        none: ShadowStyle(color: .clear, offset: .zero, radius: 0, opacity: 0),
        xs: ShadowStyle(color: .black, offset: CGSize(width: 0, height: 1), radius: 2, opacity: 0.3),
        sm: ShadowStyle(color: .black, offset: CGSize(width: 0, height: 1), radius: 3, opacity: 0.4),
        md: ShadowStyle(color: .black, offset: CGSize(width: 0, height: 4), radius: 6, opacity: 0.4),
        lg: ShadowStyle(color: .black, offset: CGSize(width: 0, height: 10), radius: 15, opacity: 0.4),
        xl: ShadowStyle(color: .black, offset: CGSize(width: 0, height: 20), radius: 25, opacity: 0.4),
        card: ShadowStyle(color: .black, offset: CGSize(width: 0, height: 2), radius: 4, opacity: 0.3),
        button: ShadowStyle(color: .black, offset: CGSize(width: 0, height: 1), radius: 2, opacity: 0.3),
        modal: ShadowStyle(color: .black, offset: CGSize(width: 0, height: 8), radius: 16, opacity: 0.5),
        floating: ShadowStyle(color: .black, offset: CGSize(width: 0, height: 4), radius: 8, opacity: 0.4)
    )
    
    let animations = LightTheme().animations
}

// MARK: - Theme Manager

/// 主题管理器
class ThemeManager: ObservableObject {
    
    static let shared = ThemeManager()
    
    @Published private(set) var currentTheme: Theme
    
    private let userDefaults = UserDefaults.standard
    private let themeKey = "selected_theme"
    
    // MARK: - Available Themes
    
    private let availableThemes: [String: Theme] = [
        "light": LightTheme(),
        "dark": DarkTheme()
    ]
    
    // MARK: - Initialization
    
    private init() {
        let savedThemeName = userDefaults.string(forKey: themeKey) ?? "light"
        self.currentTheme = availableThemes[savedThemeName] ?? LightTheme()
        
        // 监听系统外观变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemAppearanceChanged),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    // MARK: - Public Methods
    
    /// 设置主题
    func setTheme(_ themeName: String) {
        guard let theme = availableThemes[themeName] else { return }
        
        currentTheme = theme
        userDefaults.set(themeName, forKey: themeKey)
        
        // 发送主题变更通知
        NotificationCenter.default.post(
            name: .themeDidChange,
            object: theme
        )
    }
    
    /// 切换到浅色主题
    func setLightTheme() {
        setTheme("light")
    }
    
    /// 切换到深色主题
    func setDarkTheme() {
        setTheme("dark")
    }
    
    /// 跟随系统主题
    func followSystemTheme() {
        let interfaceStyle = UITraitCollection.current.userInterfaceStyle
        switch interfaceStyle {
        case .dark:
            setDarkTheme()
        case .light, .unspecified:
            setLightTheme()
        @unknown default:
            setLightTheme()
        }
    }
    
    /// 获取可用主题列表
    func getAvailableThemes() -> [String] {
        return Array(availableThemes.keys)
    }
    
    // MARK: - Private Methods
    
    @objc private func systemAppearanceChanged() {
        // 如果用户设置了跟随系统，则自动切换主题
        let followsSystem = userDefaults.bool(forKey: "follow_system_theme")
        if followsSystem {
            followSystemTheme()
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let themeDidChange = Notification.Name("ThemeDidChange")
}

// MARK: - SwiftUI Extensions

#if canImport(SwiftUI)
import SwiftUI

/// SwiftUI颜色扩展
extension ColorPalette {
    
    // MARK: - SwiftUI Color Conversions
    
    var primaryColor: Color { Color(primary) }
    var primaryVariantColor: Color { Color(primaryVariant) }
    var secondaryColor: Color { Color(secondary) }
    var secondaryVariantColor: Color { Color(secondaryVariant) }
    
    var backgroundColor: Color { Color(background) }
    var surfaceColor: Color { Color(surface) }
    var surfaceVariantColor: Color { Color(surfaceVariant) }
    
    var onPrimaryColor: Color { Color(onPrimary) }
    var onSecondaryColor: Color { Color(onSecondary) }
    var onBackgroundColor: Color { Color(onBackground) }
    var onSurfaceColor: Color { Color(onSurface) }
    
    var successColor: Color { Color(success) }
    var warningColor: Color { Color(warning) }
    var errorColor: Color { Color(error) }
    var infoColor: Color { Color(info) }
    
    var deviceOnlineColor: Color { Color(deviceOnline) }
    var deviceOfflineColor: Color { Color(deviceOffline) }
    var deviceConnectingColor: Color { Color(deviceConnecting) }
    var deviceErrorColor: Color { Color(deviceError) }
}

/// SwiftUI字体扩展
extension Typography {
    
    // MARK: - SwiftUI Font Conversions
    
    var displayLargeFont: Font { Font(displayLarge) }
    var displayMediumFont: Font { Font(displayMedium) }
    var displaySmallFont: Font { Font(displaySmall) }
    
    var headlineLargeFont: Font { Font(headlineLarge) }
    var headlineMediumFont: Font { Font(headlineMedium) }
    var headlineSmallFont: Font { Font(headlineSmall) }
    
    var titleLargeFont: Font { Font(titleLarge) }
    var titleMediumFont: Font { Font(titleMedium) }
    var titleSmallFont: Font { Font(titleSmall) }
    
    var bodyLargeFont: Font { Font(bodyLarge) }
    var bodyMediumFont: Font { Font(bodyMedium) }
    var bodySmallFont: Font { Font(bodySmall) }
    
    var labelLargeFont: Font { Font(labelLarge) }
    var labelMediumFont: Font { Font(labelMedium) }
    var labelSmallFont: Font { Font(labelSmall) }
    
    var captionFont: Font { Font(caption) }
    var overlineFont: Font { Font(overline) }
    var buttonFont: Font { Font(button) }
    var codeFont: Font { Font(code) }
}

/// SwiftUI环境值扩展
struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = LightTheme()
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

/// SwiftUI视图扩展
extension View {
    func themed(_ theme: Theme) -> some View {
        self.environment(\.theme, theme)
    }
}

#endif