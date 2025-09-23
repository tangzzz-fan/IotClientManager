//
//  DeviceComponents.swift
//  SharedUI
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import UIKit
import SwiftUI
import Combine

// MARK: - Device Status Indicator

/// 设备状态指示器
@IBDesignable
open class DeviceStatusIndicator: UIView {
    
    // MARK: - Device Status
    
    public enum Status {
        case online
        case offline
        case connecting
        case error
        case unknown
    }
    
    // MARK: - Properties
    
    @IBInspectable public var statusRawValue: Int = 0 {
        didSet {
            if let status = Status(rawValue: statusRawValue) {
                self.status = status
            }
        }
    }
    
    public var status: Status = .unknown {
        didSet {
            updateAppearance()
        }
    }
    
    @IBInspectable public var showPulse: Bool = true {
        didSet {
            updateAnimation()
        }
    }
    
    private var theme: Theme {
        return ThemeManager.shared.currentTheme
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var pulseLayer: CAShapeLayer?
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        setupObservers()
        updateAppearance()
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
        updatePulseLayer()
    }
    
    // MARK: - Setup Methods
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: .themeDidChange)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateAppearance()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateAppearance() {
        let color: UIColor
        
        switch status {
        case .online:
            color = theme.colors.deviceOnline
        case .offline:
            color = theme.colors.deviceOffline
        case .connecting:
            color = theme.colors.deviceConnecting
        case .error:
            color = theme.colors.deviceError
        case .unknown:
            color = theme.colors.neutral400
        }
        
        backgroundColor = color
        updateAnimation()
    }
    
    private func updateAnimation() {
        // 移除现有动画
        layer.removeAllAnimations()
        pulseLayer?.removeFromSuperlayer()
        pulseLayer = nil
        
        // 添加脉冲动画（仅对连接中状态）
        if showPulse && (status == .connecting || status == .online) {
            addPulseAnimation()
        }
    }
    
    private func updatePulseLayer() {
        guard let pulseLayer = pulseLayer else { return }
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        pulseLayer.path = path.cgPath
    }
    
    private func addPulseAnimation() {
        pulseLayer = CAShapeLayer()
        guard let pulseLayer = pulseLayer else { return }
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        
        pulseLayer.path = path.cgPath
        pulseLayer.fillColor = backgroundColor?.cgColor
        pulseLayer.opacity = 0.6
        
        layer.insertSublayer(pulseLayer, at: 0)
        
        // 创建脉冲动画
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 2.0
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.6
        opacityAnimation.toValue = 0.0
        
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [scaleAnimation, opacityAnimation]
        animationGroup.duration = 1.5
        animationGroup.repeatCount = .infinity
        animationGroup.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        pulseLayer.add(animationGroup, forKey: "pulse")
    }
}

// MARK: - Status Extension

extension DeviceStatusIndicator.Status: RawRepresentable {
    public typealias RawValue = Int
    
    public init?(rawValue: Int) {
        switch rawValue {
        case 0: self = .online
        case 1: self = .offline
        case 2: self = .connecting
        case 3: self = .error
        case 4: self = .unknown
        default: return nil
        }
    }
    
    public var rawValue: Int {
        switch self {
        case .online: return 0
        case .offline: return 1
        case .connecting: return 2
        case .error: return 3
        case .unknown: return 4
        }
    }
}

// MARK: - Device Card View

/// 设备卡片视图
open class DeviceCardView: ThemedCardView {
    
    // MARK: - UI Components
    
    private let containerStackView = UIStackView()
    private let headerStackView = UIStackView()
    private let contentStackView = UIStackView()
    private let footerStackView = UIStackView()
    
    private let deviceImageView = UIImageView()
    private let statusIndicator = DeviceStatusIndicator()
    private let nameLabel = UILabel()
    private let typeLabel = UILabel()
    private let locationLabel = UILabel()
    private let batteryView = BatteryIndicatorView()
    private let signalView = SignalStrengthView()
    private let lastSeenLabel = UILabel()
    
    // MARK: - Properties
    
    public var device: DeviceInfo? {
        didSet {
            updateContent()
        }
    }
    
    public var onTap: ((DeviceInfo) -> Void)?
    
    private var theme: Theme {
        return ThemeManager.shared.currentTheme
    }
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        setupStackViews()
        setupComponents()
        setupConstraints()
        setupGestures()
        updateAppearance()
    }
    
    private func setupStackViews() {
        // 主容器
        containerStackView.axis = .vertical
        containerStackView.spacing = theme.spacing.md
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 头部
        headerStackView.axis = .horizontal
        headerStackView.alignment = .center
        headerStackView.spacing = theme.spacing.md
        
        // 内容
        contentStackView.axis = .vertical
        contentStackView.spacing = theme.spacing.sm
        
        // 底部
        footerStackView.axis = .horizontal
        footerStackView.alignment = .center
        footerStackView.spacing = theme.spacing.md
        
        // 添加到主容器
        containerStackView.addArrangedSubview(headerStackView)
        containerStackView.addArrangedSubview(contentStackView)
        containerStackView.addArrangedSubview(footerStackView)
        
        addSubview(containerStackView)
    }
    
    private func setupComponents() {
        // 设备图像
        deviceImageView.contentMode = .scaleAspectFit
        deviceImageView.tintColor = theme.colors.primary
        
        // 状态指示器
        statusIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // 标签配置
        nameLabel.font = theme.typography.titleMedium
        nameLabel.textColor = theme.colors.onSurface
        nameLabel.numberOfLines = 1
        
        typeLabel.font = theme.typography.bodySmall
        typeLabel.textColor = theme.colors.neutral600
        typeLabel.numberOfLines = 1
        
        locationLabel.font = theme.typography.bodySmall
        locationLabel.textColor = theme.colors.neutral600
        locationLabel.numberOfLines = 1
        
        lastSeenLabel.font = theme.typography.caption
        lastSeenLabel.textColor = theme.colors.neutral500
        lastSeenLabel.numberOfLines = 1
        
        // 添加到堆栈视图
        let deviceInfoStack = UIStackView()
        deviceInfoStack.axis = .horizontal
        deviceInfoStack.alignment = .center
        deviceInfoStack.spacing = theme.spacing.sm
        
        let imageContainer = UIView()
        imageContainer.addSubview(deviceImageView)
        imageContainer.addSubview(statusIndicator)
        
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = theme.spacing.xs
        textStack.addArrangedSubview(nameLabel)
        textStack.addArrangedSubview(typeLabel)
        
        deviceInfoStack.addArrangedSubview(imageContainer)
        deviceInfoStack.addArrangedSubview(textStack)
        
        headerStackView.addArrangedSubview(deviceInfoStack)
        
        contentStackView.addArrangedSubview(locationLabel)
        
        footerStackView.addArrangedSubview(batteryView)
        footerStackView.addArrangedSubview(signalView)
        footerStackView.addArrangedSubview(UIView()) // Spacer
        footerStackView.addArrangedSubview(lastSeenLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 主容器约束
            containerStackView.topAnchor.constraint(equalTo: topAnchor, constant: theme.spacing.md),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: theme.spacing.md),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -theme.spacing.md),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -theme.spacing.md),
            
            // 设备图像约束
            deviceImageView.widthAnchor.constraint(equalToConstant: 48),
            deviceImageView.heightAnchor.constraint(equalToConstant: 48),
            deviceImageView.topAnchor.constraint(equalTo: deviceImageView.superview!.topAnchor),
            deviceImageView.leadingAnchor.constraint(equalTo: deviceImageView.superview!.leadingAnchor),
            deviceImageView.trailingAnchor.constraint(equalTo: deviceImageView.superview!.trailingAnchor),
            deviceImageView.bottomAnchor.constraint(equalTo: deviceImageView.superview!.bottomAnchor),
            
            // 状态指示器约束
            statusIndicator.widthAnchor.constraint(equalToConstant: 12),
            statusIndicator.heightAnchor.constraint(equalToConstant: 12),
            statusIndicator.topAnchor.constraint(equalTo: deviceImageView.topAnchor, constant: -2),
            statusIndicator.trailingAnchor.constraint(equalTo: deviceImageView.trailingAnchor, constant: 2)
        ])
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }
    
    private func updateContent() {
        guard let device = device else { return }
        
        nameLabel.text = device.name
        typeLabel.text = device.type
        locationLabel.text = device.location
        
        // 设置设备图标
        deviceImageView.image = getDeviceIcon(for: device.type)
        
        // 设置状态
        statusIndicator.status = mapDeviceStatus(device.status)
        
        // 设置电池电量
        if let batteryLevel = device.batteryLevel {
            batteryView.isHidden = false
            batteryView.batteryLevel = batteryLevel
        } else {
            batteryView.isHidden = true
        }
        
        // 设置信号强度
        if let signalStrength = device.signalStrength {
            signalView.isHidden = false
            signalView.signalStrength = signalStrength
        } else {
            signalView.isHidden = true
        }
        
        // 设置最后在线时间
        if let lastSeen = device.lastSeen {
            lastSeenLabel.text = formatLastSeen(lastSeen)
        } else {
            lastSeenLabel.text = ""
        }
    }
    
    // MARK: - Helper Methods
    
    private func getDeviceIcon(for type: String) -> UIImage? {
        let iconName: String
        
        switch type.lowercased() {
        case "light", "灯泡":
            iconName = "lightbulb"
        case "switch", "开关":
            iconName = "switch.2"
        case "sensor", "传感器":
            iconName = "sensor"
        case "camera", "摄像头":
            iconName = "camera"
        case "lock", "门锁":
            iconName = "lock"
        case "thermostat", "温控器":
            iconName = "thermometer"
        default:
            iconName = "cube.box"
        }
        
        return UIImage(systemName: iconName)
    }
    
    private func mapDeviceStatus(_ status: String) -> DeviceStatusIndicator.Status {
        switch status.lowercased() {
        case "online", "在线":
            return .online
        case "offline", "离线":
            return .offline
        case "connecting", "连接中":
            return .connecting
        case "error", "错误":
            return .error
        default:
            return .unknown
        }
    }
    
    private func formatLastSeen(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale.current
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    @objc private func cardTapped() {
        guard let device = device else { return }
        
        // 添加点击动画
        UIView.animate(withDuration: theme.animations.buttonPress, animations: {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: theme.animations.buttonPress) {
                self.transform = .identity
            }
        }
        
        onTap?(device)
    }
}

// MARK: - Battery Indicator View

/// 电池指示器视图
open class BatteryIndicatorView: UIView {
    
    // MARK: - Properties
    
    public var batteryLevel: Float = 0.0 {
        didSet {
            updateAppearance()
        }
    }
    
    private let batteryImageView = UIImageView()
    private let levelLabel = UILabel()
    
    private var theme: Theme {
        return ThemeManager.shared.currentTheme
    }
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = theme.spacing.xs
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        batteryImageView.contentMode = .scaleAspectFit
        
        levelLabel.font = theme.typography.caption
        levelLabel.textAlignment = .center
        
        stackView.addArrangedSubview(batteryImageView)
        stackView.addArrangedSubview(levelLabel)
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            batteryImageView.widthAnchor.constraint(equalToConstant: 16),
            batteryImageView.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        let batteryIcon: String
        let batteryColor: UIColor
        
        switch batteryLevel {
        case 0.0...0.2:
            batteryIcon = "battery.0"
            batteryColor = theme.colors.error
        case 0.2...0.5:
            batteryIcon = "battery.25"
            batteryColor = theme.colors.warning
        case 0.5...0.8:
            batteryIcon = "battery.75"
            batteryColor = theme.colors.success
        default:
            batteryIcon = "battery.100"
            batteryColor = theme.colors.success
        }
        
        batteryImageView.image = UIImage(systemName: batteryIcon)
        batteryImageView.tintColor = batteryColor
        
        levelLabel.text = "\(Int(batteryLevel * 100))%"
        levelLabel.textColor = batteryColor
    }
}

// MARK: - Signal Strength View

/// 信号强度视图
open class SignalStrengthView: UIView {
    
    // MARK: - Properties
    
    public var signalStrength: Float = 0.0 {
        didSet {
            updateAppearance()
        }
    }
    
    private let signalImageView = UIImageView()
    private let strengthLabel = UILabel()
    
    private var theme: Theme {
        return ThemeManager.shared.currentTheme
    }
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = theme.spacing.xs
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        signalImageView.contentMode = .scaleAspectFit
        
        strengthLabel.font = theme.typography.caption
        strengthLabel.textAlignment = .center
        
        stackView.addArrangedSubview(signalImageView)
        stackView.addArrangedSubview(strengthLabel)
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            signalImageView.widthAnchor.constraint(equalToConstant: 16),
            signalImageView.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        let signalIcon: String
        let signalColor: UIColor
        
        switch signalStrength {
        case 0.0...0.25:
            signalIcon = "wifi.exclamationmark"
            signalColor = theme.colors.error
        case 0.25...0.5:
            signalIcon = "wifi"
            signalColor = theme.colors.warning
        case 0.5...0.75:
            signalIcon = "wifi"
            signalColor = theme.colors.success
        default:
            signalIcon = "wifi"
            signalColor = theme.colors.success
        }
        
        signalImageView.image = UIImage(systemName: signalIcon)
        signalImageView.tintColor = signalColor
        
        strengthLabel.text = "\(Int(signalStrength * 100))%"
        strengthLabel.textColor = signalColor
    }
}

// MARK: - Device Info Model

/// 设备信息模型
public struct DeviceInfo {
    public let id: String
    public let name: String
    public let type: String
    public let status: String
    public let location: String?
    public let batteryLevel: Float?
    public let signalStrength: Float?
    public let lastSeen: Date?
    
    public init(
        id: String,
        name: String,
        type: String,
        status: String,
        location: String? = nil,
        batteryLevel: Float? = nil,
        signalStrength: Float? = nil,
        lastSeen: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.status = status
        self.location = location
        self.batteryLevel = batteryLevel
        self.signalStrength = signalStrength
        self.lastSeen = lastSeen
    }
}