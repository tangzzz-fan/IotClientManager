//
//  BaseComponents.swift
//  SharedUI
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import UIKit
import SwiftUI
import Combine

// MARK: - Base View Controller

/// 基础视图控制器，提供主题支持和通用功能
open class BaseViewController: UIViewController {
    
    // MARK: - Properties
    
    protected var theme: Theme {
        return ThemeManager.shared.currentTheme
    }
    
    protected var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupTheme()
        setupObservers()
    }
    
    // MARK: - Setup Methods
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: .themeDidChange)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.themeDidChange()
                }
            }
            .store(in: &cancellables)
    }
    
    /// 设置主题
    open func setupTheme() {
        view.backgroundColor = theme.colors.background
        
        // 设置导航栏样式
        if let navigationController = navigationController {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = theme.colors.surface
            appearance.titleTextAttributes = [
                .foregroundColor: theme.colors.onSurface,
                .font: theme.typography.titleLarge
            ]
            
            navigationController.navigationBar.standardAppearance = appearance
            navigationController.navigationBar.scrollEdgeAppearance = appearance
            navigationController.navigationBar.tintColor = theme.colors.primary
        }
    }
    
    /// 主题变更回调
    open func themeDidChange() {
        setupTheme()
    }
}

// MARK: - Base Table View Controller

/// 基础表格视图控制器
open class BaseTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    protected var theme: Theme {
        return ThemeManager.shared.currentTheme
    }
    
    protected var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupTheme()
        setupObservers()
    }
    
    // MARK: - Setup Methods
    
    private func setupObservers() {
        NotificationCenter.default.publisher(for: .themeDidChange)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.themeDidChange()
                }
            }
            .store(in: &cancellables)
    }
    
    /// 设置主题
    open func setupTheme() {
        view.backgroundColor = theme.colors.background
        tableView.backgroundColor = theme.colors.background
        tableView.separatorColor = theme.colors.divider
    }
    
    /// 主题变更回调
    open func themeDidChange() {
        setupTheme()
        tableView.reloadData()
    }
}

// MARK: - Themed Button

/// 主题化按钮
@IBDesignable
open class ThemedButton: UIButton {
    
    // MARK: - Button Style
    
    public enum ButtonStyle {
        case primary
        case secondary
        case outline
        case text
        case destructive
    }
    
    // MARK: - Properties
    
    @IBInspectable public var buttonStyleRawValue: Int = 0 {
        didSet {
            if let style = ButtonStyle(rawValue: buttonStyleRawValue) {
                self.buttonStyle = style
            }
        }
    }
    
    public var buttonStyle: ButtonStyle = .primary {
        didSet {
            updateAppearance()
        }
    }
    
    @IBInspectable public var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    private var theme: Theme {
        return ThemeManager.shared.currentTheme
    }
    
    private var cancellables = Set<AnyCancellable>()
    
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
        
        // 添加触摸动画
        addTarget(self, action: #selector(buttonPressed), for: .touchDown)
        addTarget(self, action: #selector(buttonReleased), for: [.touchUpInside, .touchUpOutside, .touchCancel])
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
        titleLabel?.font = theme.typography.button
        
        switch buttonStyle {
        case .primary:
            backgroundColor = theme.colors.buttonPrimary
            setTitleColor(theme.colors.onPrimary, for: .normal)
            setTitleColor(theme.colors.onPrimary.withAlphaComponent(0.7), for: .highlighted)
            setTitleColor(theme.colors.neutral400, for: .disabled)
            layer.borderWidth = 0
            
        case .secondary:
            backgroundColor = theme.colors.buttonSecondary
            setTitleColor(theme.colors.onSurface, for: .normal)
            setTitleColor(theme.colors.onSurface.withAlphaComponent(0.7), for: .highlighted)
            setTitleColor(theme.colors.neutral400, for: .disabled)
            layer.borderWidth = 0
            
        case .outline:
            backgroundColor = UIColor.clear
            setTitleColor(theme.colors.primary, for: .normal)
            setTitleColor(theme.colors.primary.withAlphaComponent(0.7), for: .highlighted)
            setTitleColor(theme.colors.neutral400, for: .disabled)
            layer.borderWidth = 1
            layer.borderColor = theme.colors.border.cgColor
            
        case .text:
            backgroundColor = UIColor.clear
            setTitleColor(theme.colors.primary, for: .normal)
            setTitleColor(theme.colors.primary.withAlphaComponent(0.7), for: .highlighted)
            setTitleColor(theme.colors.neutral400, for: .disabled)
            layer.borderWidth = 0
            
        case .destructive:
            backgroundColor = theme.colors.error
            setTitleColor(theme.colors.onPrimary, for: .normal)
            setTitleColor(theme.colors.onPrimary.withAlphaComponent(0.7), for: .highlighted)
            setTitleColor(theme.colors.neutral400, for: .disabled)
            layer.borderWidth = 0
        }
        
        // 设置圆角
        if cornerRadius == 0 {
            layer.cornerRadius = theme.cornerRadius.button
        }
        
        // 设置阴影
        if buttonStyle == .primary || buttonStyle == .destructive {
            applyShadow(theme.shadows.button)
        } else {
            layer.shadowOpacity = 0
        }
        
        // 设置内边距
        contentEdgeInsets = theme.spacing.buttonPadding
    }
    
    private func applyShadow(_ shadow: ShadowStyle) {
        layer.shadowColor = shadow.color.cgColor
        layer.shadowOffset = shadow.offset
        layer.shadowRadius = shadow.radius
        layer.shadowOpacity = shadow.opacity
    }
    
    // MARK: - Animation Methods
    
    @objc private func buttonPressed() {
        UIView.animate(withDuration: theme.animations.buttonPress) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonReleased() {
        UIView.animate(withDuration: theme.animations.buttonPress) {
            self.transform = .identity
        }
    }
}

// MARK: - Button Style Extension

extension ThemedButton.ButtonStyle: RawRepresentable {
    public typealias RawValue = Int
    
    public init?(rawValue: Int) {
        switch rawValue {
        case 0: self = .primary
        case 1: self = .secondary
        case 2: self = .outline
        case 3: self = .text
        case 4: self = .destructive
        default: return nil
        }
    }
    
    public var rawValue: Int {
        switch self {
        case .primary: return 0
        case .secondary: return 1
        case .outline: return 2
        case .text: return 3
        case .destructive: return 4
        }
    }
}

// MARK: - Themed Text Field

/// 主题化文本输入框
@IBDesignable
open class ThemedTextField: UITextField {
    
    // MARK: - Properties
    
    @IBInspectable public var placeholderText: String = "" {
        didSet {
            updatePlaceholder()
        }
    }
    
    @IBInspectable public var isError: Bool = false {
        didSet {
            updateAppearance()
        }
    }
    
    private var theme: Theme {
        return ThemeManager.shared.currentTheme
    }
    
    private var cancellables = Set<AnyCancellable>()
    
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
        
        // 添加编辑状态监听
        addTarget(self, action: #selector(editingDidBegin), for: .editingDidBegin)
        addTarget(self, action: #selector(editingDidEnd), for: .editingDidEnd)
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
        font = theme.typography.bodyMedium
        textColor = theme.colors.onSurface
        backgroundColor = theme.colors.surface
        
        // 设置边框
        layer.borderWidth = 1
        if isError {
            layer.borderColor = theme.colors.borderError.cgColor
        } else if isFirstResponder {
            layer.borderColor = theme.colors.borderFocus.cgColor
        } else {
            layer.borderColor = theme.colors.border.cgColor
        }
        
        // 设置圆角
        layer.cornerRadius = theme.cornerRadius.input
        
        // 设置内边距
        let padding = theme.spacing.md
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: frame.height))
        leftViewMode = .always
        rightView = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: frame.height))
        rightViewMode = .always
        
        updatePlaceholder()
    }
    
    private func updatePlaceholder() {
        if !placeholderText.isEmpty {
            attributedPlaceholder = NSAttributedString(
                string: placeholderText,
                attributes: [
                    .foregroundColor: theme.colors.neutral500,
                    .font: theme.typography.bodyMedium
                ]
            )
        }
    }
    
    // MARK: - Editing Methods
    
    @objc private func editingDidBegin() {
        updateAppearance()
    }
    
    @objc private func editingDidEnd() {
        updateAppearance()
    }
}

// MARK: - Themed Card View

/// 主题化卡片视图
@IBDesignable
open class ThemedCardView: UIView {
    
    // MARK: - Properties
    
    @IBInspectable public var elevation: Int = 1 {
        didSet {
            updateAppearance()
        }
    }
    
    private var theme: Theme {
        return ThemeManager.shared.currentTheme
    }
    
    private var cancellables = Set<AnyCancellable>()
    
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
        backgroundColor = theme.colors.surface
        layer.cornerRadius = theme.cornerRadius.card
        
        // 根据elevation设置阴影
        let shadow: ShadowStyle
        switch elevation {
        case 0:
            shadow = theme.shadows.none
        case 1:
            shadow = theme.shadows.xs
        case 2:
            shadow = theme.shadows.sm
        case 3:
            shadow = theme.shadows.md
        case 4:
            shadow = theme.shadows.lg
        default:
            shadow = theme.shadows.xl
        }
        
        applyShadow(shadow)
    }
    
    private func applyShadow(_ shadow: ShadowStyle) {
        layer.shadowColor = shadow.color.cgColor
        layer.shadowOffset = shadow.offset
        layer.shadowRadius = shadow.radius
        layer.shadowOpacity = shadow.opacity
    }
}

// MARK: - Loading View

/// 加载视图
open class LoadingView: UIView {
    
    // MARK: - Properties
    
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let messageLabel = UILabel()
    private let stackView = UIStackView()
    
    private var theme: Theme {
        return ThemeManager.shared.currentTheme
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupObservers()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupObservers()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        // 配置堆栈视图
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = theme.spacing.md
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置活动指示器
        activityIndicator.hidesWhenStopped = true
        
        // 配置消息标签
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        // 添加子视图
        stackView.addArrangedSubview(activityIndicator)
        stackView.addArrangedSubview(messageLabel)
        addSubview(stackView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: theme.spacing.lg),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -theme.spacing.lg)
        ])
        
        updateAppearance()
    }
    
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
        backgroundColor = theme.colors.background.withAlphaComponent(0.8)
        activityIndicator.color = theme.colors.primary
        messageLabel.font = theme.typography.bodyMedium
        messageLabel.textColor = theme.colors.onBackground
    }
    
    // MARK: - Public Methods
    
    /// 显示加载
    public func show(message: String = "加载中...") {
        messageLabel.text = message
        activityIndicator.startAnimating()
        isHidden = false
    }
    
    /// 隐藏加载
    public func hide() {
        activityIndicator.stopAnimating()
        isHidden = true
    }
}

// MARK: - Empty State View

/// 空状态视图
open class EmptyStateView: UIView {
    
    // MARK: - Properties
    
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let actionButton = ThemedButton()
    private let stackView = UIStackView()
    
    private var theme: Theme {
        return ThemeManager.shared.currentTheme
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    public var actionHandler: (() -> Void)?
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupObservers()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupObservers()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        // 配置堆栈视图
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = theme.spacing.lg
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置图像视图
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = theme.colors.neutral400
        
        // 配置标题标签
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        // 配置消息标签
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        // 配置操作按钮
        actionButton.buttonStyle = .primary
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        
        // 添加子视图
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(actionButton)
        addSubview(stackView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 120),
            imageView.heightAnchor.constraint(equalToConstant: 120),
            
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: theme.spacing.xl),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -theme.spacing.xl)
        ])
        
        updateAppearance()
    }
    
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
        backgroundColor = theme.colors.background
        imageView.tintColor = theme.colors.neutral400
        titleLabel.font = theme.typography.headlineSmall
        titleLabel.textColor = theme.colors.onBackground
        messageLabel.font = theme.typography.bodyMedium
        messageLabel.textColor = theme.colors.neutral600
    }
    
    // MARK: - Public Methods
    
    /// 配置空状态视图
    public func configure(
        image: UIImage?,
        title: String,
        message: String,
        actionTitle: String? = nil,
        actionHandler: (() -> Void)? = nil
    ) {
        imageView.image = image
        titleLabel.text = title
        messageLabel.text = message
        
        if let actionTitle = actionTitle {
            actionButton.setTitle(actionTitle, for: .normal)
            actionButton.isHidden = false
            self.actionHandler = actionHandler
        } else {
            actionButton.isHidden = true
            self.actionHandler = nil
        }
    }
    
    @objc private func actionButtonTapped() {
        actionHandler?()
    }
}