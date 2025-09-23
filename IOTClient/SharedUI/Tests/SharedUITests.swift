//
//  SharedUITests.swift
//  SharedUITests
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import XCTest
import UIKit
import SwiftUI
@testable import SharedUI

// MARK: - SharedUITestCase

/// SharedUI 测试基类
class SharedUITestCase: XCTestCase {
    
    var themeManager: ThemeManager!
    var testWindow: UIWindow!
    
    override func setUp() {
        super.setUp()
        themeManager = ThemeManager.shared
        testWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        testWindow.makeKeyAndVisible()
    }
    
    override func tearDown() {
        themeManager = nil
        testWindow = nil
        super.tearDown()
    }
    
    /// 创建测试视图控制器
    func createTestViewController() -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .white
        return viewController
    }
    
    /// 添加视图控制器到测试窗口
    func addToTestWindow(_ viewController: UIViewController) {
        testWindow.rootViewController = viewController
        testWindow.layoutIfNeeded()
    }
}

// MARK: - Theme Tests

class ThemeTests: SharedUITestCase {
    
    func testLightTheme() {
        let lightTheme = LightTheme()
        
        XCTAssertEqual(lightTheme.colorPalette.primary, UIColor.systemBlue)
        XCTAssertEqual(lightTheme.colorPalette.background, UIColor.systemBackground)
        XCTAssertEqual(lightTheme.typography.title.pointSize, 20)
        XCTAssertEqual(lightTheme.spacing.medium, 16)
    }
    
    func testDarkTheme() {
        let darkTheme = DarkTheme()
        
        XCTAssertEqual(darkTheme.colorPalette.primary, UIColor.systemBlue)
        XCTAssertEqual(darkTheme.colorPalette.background, UIColor.systemBackground)
        XCTAssertEqual(darkTheme.typography.title.pointSize, 20)
        XCTAssertEqual(darkTheme.spacing.medium, 16)
    }
    
    func testThemeManager() {
        // 测试默认主题
        XCTAssertNotNil(themeManager.currentTheme)
        
        // 测试主题切换
        let initialTheme = themeManager.currentTheme
        themeManager.setTheme(DarkTheme())
        XCTAssertNotEqual(themeManager.currentTheme.colorPalette.background, initialTheme.colorPalette.background)
        
        // 测试主题保存
        themeManager.saveCurrentTheme()
        let savedTheme = themeManager.loadSavedTheme()
        XCTAssertNotNil(savedTheme)
    }
    
    func testThemeNotification() {
        let expectation = XCTestExpectation(description: "Theme change notification")
        
        let observer = NotificationCenter.default.addObserver(
            forName: .themeDidChange,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        
        themeManager.setTheme(DarkTheme())
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
}

// MARK: - Base Components Tests

class BaseComponentsTests: SharedUITestCase {
    
    func testBaseViewController() {
        let viewController = BaseViewController()
        addToTestWindow(viewController)
        
        XCTAssertNotNil(viewController.view)
        XCTAssertEqual(viewController.view.backgroundColor, themeManager.currentTheme.colorPalette.background)
    }
    
    func testThemedButton() {
        let button = ThemedButton(type: .system)
        button.setTitle("Test Button", for: .normal)
        button.style = .primary
        
        let viewController = createTestViewController()
        viewController.view.addSubview(button)
        addToTestWindow(viewController)
        
        XCTAssertEqual(button.titleLabel?.text, "Test Button")
        XCTAssertEqual(button.backgroundColor, themeManager.currentTheme.colorPalette.primary)
    }
    
    func testThemedTextField() {
        let textField = ThemedTextField()
        textField.placeholder = "Test Placeholder"
        
        let viewController = createTestViewController()
        viewController.view.addSubview(textField)
        addToTestWindow(viewController)
        
        XCTAssertEqual(textField.placeholder, "Test Placeholder")
        XCTAssertNotNil(textField.layer.borderColor)
    }
    
    func testThemedCardView() {
        let cardView = ThemedCardView()
        cardView.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        
        let viewController = createTestViewController()
        viewController.view.addSubview(cardView)
        addToTestWindow(viewController)
        
        XCTAssertEqual(cardView.backgroundColor, themeManager.currentTheme.colorPalette.surface)
        XCTAssertGreaterThan(cardView.layer.cornerRadius, 0)
    }
    
    func testLoadingView() {
        let loadingView = LoadingView()
        loadingView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        
        let viewController = createTestViewController()
        viewController.view.addSubview(loadingView)
        addToTestWindow(viewController)
        
        XCTAssertTrue(loadingView.activityIndicator.isAnimating)
        
        loadingView.stopAnimating()
        XCTAssertFalse(loadingView.activityIndicator.isAnimating)
    }
    
    func testEmptyStateView() {
        let emptyStateView = EmptyStateView()
        emptyStateView.configure(
            image: UIImage(systemName: "cube.box"),
            title: "No Data",
            message: "No data available",
            actionTitle: "Retry"
        ) {
            // Action handler
        }
        
        let viewController = createTestViewController()
        viewController.view.addSubview(emptyStateView)
        addToTestWindow(viewController)
        
        XCTAssertEqual(emptyStateView.titleLabel.text, "No Data")
        XCTAssertEqual(emptyStateView.messageLabel.text, "No data available")
        XCTAssertEqual(emptyStateView.actionButton.title(for: .normal), "Retry")
    }
}

// MARK: - Device Components Tests

class DeviceComponentsTests: SharedUITestCase {
    
    func testDeviceStatusIndicator() {
        let indicator = DeviceStatusIndicator()
        indicator.status = .online
        
        let viewController = createTestViewController()
        viewController.view.addSubview(indicator)
        addToTestWindow(viewController)
        
        XCTAssertEqual(indicator.backgroundColor, themeManager.currentTheme.colorPalette.success)
        
        indicator.status = .offline
        XCTAssertEqual(indicator.backgroundColor, themeManager.currentTheme.colorPalette.onSurface.withAlphaComponent(0.3))
    }
    
    func testDeviceCardView() {
        let deviceInfo = DeviceInfo(
            id: "test-device",
            name: "Test Device",
            type: "Light",
            location: "Living Room",
            status: .online,
            batteryLevel: 0.8,
            signalStrength: 0.9,
            lastOnline: Date()
        )
        
        let cardView = DeviceCardView()
        cardView.configure(with: deviceInfo)
        cardView.frame = CGRect(x: 0, y: 0, width: 300, height: 120)
        
        let viewController = createTestViewController()
        viewController.view.addSubview(cardView)
        addToTestWindow(viewController)
        
        XCTAssertEqual(cardView.nameLabel.text, "Test Device")
        XCTAssertEqual(cardView.typeLabel.text, "Light")
        XCTAssertEqual(cardView.locationLabel.text, "Living Room")
    }
    
    func testBatteryIndicatorView() {
        let batteryView = BatteryIndicatorView()
        batteryView.batteryLevel = 0.5
        
        let viewController = createTestViewController()
        viewController.view.addSubview(batteryView)
        addToTestWindow(viewController)
        
        XCTAssertEqual(batteryView.batteryLevel, 0.5)
    }
    
    func testSignalStrengthView() {
        let signalView = SignalStrengthView()
        signalView.signalStrength = 0.8
        
        let viewController = createTestViewController()
        viewController.view.addSubview(signalView)
        addToTestWindow(viewController)
        
        XCTAssertEqual(signalView.signalStrength, 0.8)
    }
}

// MARK: - Extensions Tests

class ExtensionsTests: SharedUITestCase {
    
    func testUIViewExtensions() {
        let view = UIView()
        view.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        
        // 测试圆角
        view.setCornerRadius(10)
        XCTAssertEqual(view.layer.cornerRadius, 10)
        
        // 测试边框
        view.setBorder(width: 2, color: .red)
        XCTAssertEqual(view.layer.borderWidth, 2)
        XCTAssertEqual(view.layer.borderColor, UIColor.red.cgColor)
        
        // 测试阴影
        view.setShadow(color: .black, opacity: 0.5, offset: CGSize(width: 2, height: 2), radius: 4)
        XCTAssertEqual(view.layer.shadowOpacity, 0.5)
        XCTAssertEqual(view.layer.shadowOffset, CGSize(width: 2, height: 2))
        XCTAssertEqual(view.layer.shadowRadius, 4)
    }
    
    func testUIColorExtensions() {
        // 测试十六进制颜色
        let color = UIColor(hex: "#FF0000")
        XCTAssertNotNil(color)
        
        let hexString = UIColor.red.toHexString()
        XCTAssertTrue(hexString.hasPrefix("#"))
        
        // 测试颜色调整
        let lighterColor = UIColor.red.lighter(by: 0.2)
        XCTAssertNotEqual(lighterColor, UIColor.red)
        
        let darkerColor = UIColor.red.darker(by: 0.2)
        XCTAssertNotEqual(darkerColor, UIColor.red)
    }
    
    func testUIFontExtensions() {
        let boldFont = UIFont.systemFont(ofSize: 16).bold()
        XCTAssertNotEqual(boldFont, UIFont.systemFont(ofSize: 16))
        
        let italicFont = UIFont.systemFont(ofSize: 16).italic()
        XCTAssertNotEqual(italicFont, UIFont.systemFont(ofSize: 16))
        
        let resizedFont = UIFont.systemFont(ofSize: 16).withSize(20)
        XCTAssertEqual(resizedFont.pointSize, 20)
    }
    
    func testUIImageExtensions() {
        // 测试颜色图像
        let colorImage = UIImage.from(color: .red, size: CGSize(width: 10, height: 10))
        XCTAssertNotNil(colorImage)
        
        // 测试图像调整大小
        let originalImage = UIImage(systemName: "star")!
        let resizedImage = originalImage.resized(to: CGSize(width: 50, height: 50))
        XCTAssertNotNil(resizedImage)
        
        // 测试圆形图像
        let circularImage = originalImage.circularImage()
        XCTAssertNotNil(circularImage)
    }
}

// MARK: - Resources Tests

class ResourcesTests: SharedUITestCase {
    
    func testSharedUIAssets() {
        // 测试图像资源
        XCTAssertNotNil(SharedUIAssets.Images.deviceLight)
        XCTAssertNotNil(SharedUIAssets.Images.statusOnline)
        XCTAssertNotNil(SharedUIAssets.Images.actionAdd)
        
        // 测试颜色资源
        XCTAssertNotNil(SharedUIAssets.Colors.brandPrimary)
        XCTAssertNotNil(SharedUIAssets.Colors.success)
        XCTAssertNotNil(SharedUIAssets.Colors.neutral500)
        
        // 测试字体资源
        XCTAssertNotNil(SharedUIAssets.Fonts.titleLarge)
        XCTAssertNotNil(SharedUIAssets.Fonts.bodyMedium)
        XCTAssertNotNil(SharedUIAssets.Fonts.code)
        
        // 测试辅助方法
        let deviceIcon = SharedUIAssets.Images.deviceIcon(for: "light")
        XCTAssertEqual(deviceIcon, SharedUIAssets.Images.deviceLight)
        
        let statusIcon = SharedUIAssets.Images.statusIcon(for: "online")
        XCTAssertEqual(statusIcon, SharedUIAssets.Images.statusOnline)
        
        let batteryIcon = SharedUIAssets.Images.batteryIcon(for: 0.5)
        XCTAssertEqual(batteryIcon, SharedUIAssets.Images.battery50)
    }
    
    func testSharedUIStrings() {
        // 测试通用字符串
        XCTAssertFalse(SharedUIStrings.ok.isEmpty)
        XCTAssertFalse(SharedUIStrings.cancel.isEmpty)
        XCTAssertFalse(SharedUIStrings.loading.isEmpty)
        
        // 测试设备字符串
        XCTAssertFalse(SharedUIStrings.deviceOnline.isEmpty)
        XCTAssertFalse(SharedUIStrings.deviceOffline.isEmpty)
        
        // 测试空状态字符串
        XCTAssertFalse(SharedUIStrings.emptyDevicesTitle.isEmpty)
        XCTAssertFalse(SharedUIStrings.emptySearchTitle.isEmpty)
        
        // 测试辅助方法
        let statusString = SharedUIStrings.deviceStatusString(for: "online")
        XCTAssertEqual(statusString, SharedUIStrings.deviceOnline)
    }
    
    func testSharedUIConstants() {
        // 测试布局常量
        XCTAssertEqual(SharedUIConstants.Layout.minimumTouchTarget, 44)
        XCTAssertEqual(SharedUIConstants.Layout.defaultCornerRadius, 8)
        
        // 测试设备常量
        XCTAssertEqual(SharedUIConstants.Device.cardHeight, 120)
        XCTAssertEqual(SharedUIConstants.Device.iconSize, 48)
        
        // 测试按钮常量
        XCTAssertEqual(SharedUIConstants.Button.defaultHeight, 44)
        XCTAssertEqual(SharedUIConstants.Button.minimumWidth, 88)
    }
}

// MARK: - Performance Tests

class SharedUIPerformanceTests: SharedUITestCase {
    
    func testThemeManagerPerformance() {
        measure {
            for _ in 0..<1000 {
                themeManager.setTheme(LightTheme())
                themeManager.setTheme(DarkTheme())
            }
        }
    }
    
    func testThemedButtonCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                let button = ThemedButton(type: .system)
                button.style = .primary
                button.setTitle("Test", for: .normal)
            }
        }
    }
    
    func testDeviceCardViewPerformance() {
        let deviceInfo = DeviceInfo(
            id: "test-device",
            name: "Test Device",
            type: "Light",
            location: "Living Room",
            status: .online,
            batteryLevel: 0.8,
            signalStrength: 0.9,
            lastOnline: Date()
        )
        
        measure {
            for _ in 0..<100 {
                let cardView = DeviceCardView()
                cardView.configure(with: deviceInfo)
            }
        }
    }
    
    func testUIViewExtensionsPerformance() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        
        measure {
            for _ in 0..<1000 {
                view.setCornerRadius(10)
                view.setBorder(width: 1, color: .gray)
                view.setShadow(color: .black, opacity: 0.1, offset: CGSize(width: 0, height: 2), radius: 4)
            }
        }
    }
}

// MARK: - Mock Classes

/// 模拟主题
class MockTheme: Theme {
    let colorPalette = MockColorPalette()
    let typography = MockTypography()
    let spacing = MockSpacing()
    let cornerRadius = MockCornerRadius()
    let shadows = MockShadows()
    let animations = MockAnimations()
}

struct MockColorPalette: ColorPalette {
    let primary = UIColor.blue
    let secondary = UIColor.green
    let accent = UIColor.orange
    let background = UIColor.white
    let surface = UIColor.lightGray
    let onPrimary = UIColor.white
    let onSecondary = UIColor.white
    let onBackground = UIColor.black
    let onSurface = UIColor.black
    let success = UIColor.green
    let warning = UIColor.orange
    let error = UIColor.red
    let info = UIColor.blue
}

struct MockTypography: Typography {
    let largeTitle = UIFont.systemFont(ofSize: 34, weight: .regular)
    let title = UIFont.systemFont(ofSize: 20, weight: .semibold)
    let headline = UIFont.systemFont(ofSize: 17, weight: .semibold)
    let body = UIFont.systemFont(ofSize: 17, weight: .regular)
    let callout = UIFont.systemFont(ofSize: 16, weight: .regular)
    let subheadline = UIFont.systemFont(ofSize: 15, weight: .regular)
    let footnote = UIFont.systemFont(ofSize: 13, weight: .regular)
    let caption = UIFont.systemFont(ofSize: 12, weight: .regular)
}

struct MockSpacing: Spacing {
    let extraSmall: CGFloat = 4
    let small: CGFloat = 8
    let medium: CGFloat = 16
    let large: CGFloat = 24
    let extraLarge: CGFloat = 32
}

struct MockCornerRadius: CornerRadius {
    let small: CGFloat = 4
    let medium: CGFloat = 8
    let large: CGFloat = 12
    let extraLarge: CGFloat = 16
}

struct MockShadows: Shadows {
    let small = ShadowStyle(color: UIColor.black, opacity: 0.1, offset: CGSize(width: 0, height: 1), radius: 2)
    let medium = ShadowStyle(color: UIColor.black, opacity: 0.15, offset: CGSize(width: 0, height: 2), radius: 4)
    let large = ShadowStyle(color: UIColor.black, opacity: 0.2, offset: CGSize(width: 0, height: 4), radius: 8)
}

struct MockAnimations: Animations {
    let fast: TimeInterval = 0.15
    let normal: TimeInterval = 0.3
    let slow: TimeInterval = 0.5
    let spring = UISpringTimingParameters(dampingRatio: 0.8)
}