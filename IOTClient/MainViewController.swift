//
//  MainViewController.swift
//  IOTClient
//
//  Created by Tang Tango on 2025/1/4.
//

import UIKit
import Combine

/// 主视图控制器 - 整合所有功能模块的统一界面
class MainViewController: UIViewController {
    
    // MARK: - UI Properties
    
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var stackView: UIStackView!
    
    // 状态显示
    private var statusLabel: UILabel!
    private var connectionStatusView: UIView!
    
    // 设备控制区域
    private var deviceControlSection: UIView!
    private var discoverDevicesButton: UIButton!
    private var connectedDevicesLabel: UILabel!
    
    // 连接管理区域
    private var connectionSection: UIView!
    private var bleConnectionButton: UIButton!
    private var mqttConnectionButton: UIButton!
    private var connectivityLayerButton: UIButton!
    
    // 配网区域
    private var provisioningSection: UIView!
    private var startProvisioningButton: UIButton!
    
    // MARK: - Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let deviceControlModule = DeviceControlModule.shared
    private let provisioningModule = ProvisioningModule.shared
    private let bleManager = BLEManager.shared
    private let mqttClientManager = MQTTClientManager.shared
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshStatus()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "智能家居控制中心"
        
        setupScrollView()
        setupStatusSection()
        setupDeviceControlSection()
        setupConnectionSection()
        setupProvisioningSection()
        setupConstraints()
    }
    
    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
    }
    
    private func setupStatusSection() {
        let sectionView = createSectionView(title: "系统状态")
        
        statusLabel = UILabel()
        statusLabel.text = "正在初始化..."
        statusLabel.font = UIFont.systemFont(ofSize: 16)
        statusLabel.textColor = .systemBlue
        statusLabel.numberOfLines = 0
        
        connectionStatusView = UIView()
        connectionStatusView.backgroundColor = .systemGray5
        connectionStatusView.layer.cornerRadius = 8
        connectionStatusView.translatesAutoresizingMaskIntoConstraints = false
        
        sectionView.addSubview(statusLabel)
        sectionView.addSubview(connectionStatusView)
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: sectionView.topAnchor, constant: 40),
            statusLabel.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: sectionView.trailingAnchor, constant: -16),
            
            connectionStatusView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 10),
            connectionStatusView.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor, constant: 16),
            connectionStatusView.trailingAnchor.constraint(equalTo: sectionView.trailingAnchor, constant: -16),
            connectionStatusView.heightAnchor.constraint(equalToConstant: 60),
            connectionStatusView.bottomAnchor.constraint(equalTo: sectionView.bottomAnchor, constant: -16)
        ])
        
        stackView.addArrangedSubview(sectionView)
    }
    
    private func setupDeviceControlSection() {
        deviceControlSection = createSectionView(title: "设备控制")
        
        discoverDevicesButton = createButton(
            title: "发现设备",
            backgroundColor: .systemBlue,
            action: #selector(discoverDevicesButtonTapped)
        )
        
        connectedDevicesLabel = UILabel()
        connectedDevicesLabel.text = "已连接设备: 0"
        connectedDevicesLabel.font = UIFont.systemFont(ofSize: 16)
        connectedDevicesLabel.textColor = .systemGray
        
        deviceControlSection.addSubview(discoverDevicesButton)
        deviceControlSection.addSubview(connectedDevicesLabel)
        
        discoverDevicesButton.translatesAutoresizingMaskIntoConstraints = false
        connectedDevicesLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            discoverDevicesButton.topAnchor.constraint(equalTo: deviceControlSection.topAnchor, constant: 40),
            discoverDevicesButton.leadingAnchor.constraint(equalTo: deviceControlSection.leadingAnchor, constant: 16),
            discoverDevicesButton.trailingAnchor.constraint(equalTo: deviceControlSection.trailingAnchor, constant: -16),
            discoverDevicesButton.heightAnchor.constraint(equalToConstant: 50),
            
            connectedDevicesLabel.topAnchor.constraint(equalTo: discoverDevicesButton.bottomAnchor, constant: 16),
            connectedDevicesLabel.leadingAnchor.constraint(equalTo: deviceControlSection.leadingAnchor, constant: 16),
            connectedDevicesLabel.trailingAnchor.constraint(equalTo: deviceControlSection.trailingAnchor, constant: -16),
            connectedDevicesLabel.bottomAnchor.constraint(equalTo: deviceControlSection.bottomAnchor, constant: -16)
        ])
        
        stackView.addArrangedSubview(deviceControlSection)
    }
    
    private func setupConnectionSection() {
        connectionSection = createSectionView(title: "连接管理")
        
        bleConnectionButton = createButton(
            title: "BLE连接状态",
            backgroundColor: .systemGreen,
            action: #selector(bleConnectionButtonTapped)
        )
        
        mqttConnectionButton = createButton(
            title: "MQTT连接状态",
            backgroundColor: .systemPurple,
            action: #selector(mqttConnectionButtonTapped)
        )
        
        connectivityLayerButton = createButton(
            title: "连接层状态",
            backgroundColor: .systemOrange,
            action: #selector(connectivityLayerButtonTapped)
        )
        
        let buttonStackView = UIStackView(arrangedSubviews: [
            bleConnectionButton,
            mqttConnectionButton,
            connectivityLayerButton
        ])
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 12
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        
        connectionSection.addSubview(buttonStackView)
        
        NSLayoutConstraint.activate([
            buttonStackView.topAnchor.constraint(equalTo: connectionSection.topAnchor, constant: 40),
            buttonStackView.leadingAnchor.constraint(equalTo: connectionSection.leadingAnchor, constant: 16),
            buttonStackView.trailingAnchor.constraint(equalTo: connectionSection.trailingAnchor, constant: -16),
            buttonStackView.bottomAnchor.constraint(equalTo: connectionSection.bottomAnchor, constant: -16)
        ])
        
        stackView.addArrangedSubview(connectionSection)
    }
    
    private func setupProvisioningSection() {
        provisioningSection = createSectionView(title: "设备配网")
        
        startProvisioningButton = createButton(
            title: "开始配网",
            backgroundColor: .systemTeal,
            action: #selector(startProvisioningButtonTapped)
        )
        
        provisioningSection.addSubview(startProvisioningButton)
        
        startProvisioningButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            startProvisioningButton.topAnchor.constraint(equalTo: provisioningSection.topAnchor, constant: 40),
            startProvisioningButton.leadingAnchor.constraint(equalTo: provisioningSection.leadingAnchor, constant: 16),
            startProvisioningButton.trailingAnchor.constraint(equalTo: provisioningSection.trailingAnchor, constant: -16),
            startProvisioningButton.heightAnchor.constraint(equalToConstant: 50),
            startProvisioningButton.bottomAnchor.constraint(equalTo: provisioningSection.bottomAnchor, constant: -16)
        ])
        
        stackView.addArrangedSubview(provisioningSection)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Helper Methods
    
    private func createSectionView(title: String) -> UIView {
        let sectionView = UIView()
        sectionView.backgroundColor = .systemBackground
        sectionView.layer.cornerRadius = 12
        sectionView.layer.borderWidth = 1
        sectionView.layer.borderColor = UIColor.systemGray4.cgColor
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        sectionView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: sectionView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: sectionView.trailingAnchor, constant: -16)
        ])
        
        return sectionView
    }
    
    private func createButton(title: String, backgroundColor: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = backgroundColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        return button
    }
    
    // MARK: - Bindings
    
    private func setupBindings() {
        // 监听设备控制模块状态变化
        // 这里可以添加 Combine 绑定来实时更新UI
    }
    
    // MARK: - Actions
    
    @objc private func discoverDevicesButtonTapped() {
        print("[MainViewController] 开始设备发现")
        deviceControlModule.startDeviceDiscovery()
        
        // 更新按钮状态
        discoverDevicesButton.setTitle("正在发现设备...", for: .normal)
        discoverDevicesButton.isEnabled = false
        
        // 3秒后恢复按钮状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.discoverDevicesButton.setTitle("发现设备", for: .normal)
            self?.discoverDevicesButton.isEnabled = true
        }
    }
    
    @objc private func bleConnectionButtonTapped() {
        print("[MainViewController] BLE连接按钮点击")
        // 显示BLE连接详情或切换连接状态
        showAlert(title: "BLE连接", message: "BLE管理器状态: \(bleManager.isInitialized ? "已初始化" : "未初始化")")
    }
    
    @objc private func mqttConnectionButtonTapped() {
        print("[MainViewController] MQTT连接按钮点击")
        // 显示MQTT连接详情或切换连接状态
        showAlert(title: "MQTT连接", message: "MQTT客户端状态: \(mqttClientManager.isConnected ? "已连接" : "未连接")")
    }
    
    @objc private func connectivityLayerButtonTapped() {
        print("[MainViewController] 连接层按钮点击")
        // 显示连接层详情
        showAlert(title: "连接层", message: "连接层管理器状态正常")
    }
    
    @objc private func startProvisioningButtonTapped() {
        print("[MainViewController] 开始配网")
        // 启动配网流程
        showAlert(title: "设备配网", message: "配网功能即将启动")
    }
    
    // MARK: - UI Updates
    
    private func updateUI() {
        refreshStatus()
        updateConnectionStatus()
        updateDeviceCount()
    }
    
    private func refreshStatus() {
        let appStatus = AppCoordinator.shared.getApplicationStatus()
        
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = "系统状态: \(appStatus.isInitialized ? "已初始化" : "初始化中")"
            self?.statusLabel.textColor = appStatus.isInitialized ? .systemGreen : .systemOrange
        }
    }
    
    private func updateConnectionStatus() {
        // 更新连接状态视图
        DispatchQueue.main.async { [weak self] in
            self?.connectionStatusView.backgroundColor = .systemGreen.withAlphaComponent(0.3)
        }
    }
    
    private func updateDeviceCount() {
        let deviceCount = deviceControlModule.controllers.count
        
        DispatchQueue.main.async { [weak self] in
            self?.connectedDevicesLabel.text = "已连接设备: \(deviceCount)"
        }
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}