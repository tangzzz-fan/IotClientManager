//
//  ModuleCoordinator.swift
//  AppCoordinator
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import UIKit
import Combine

// MARK: - Module Coordinator Implementation

/// 模块协调器实现
public final class ModuleCoordinator: BaseCoordinator, ModuleCoordinatorProtocol {
    
    // MARK: - Properties
    
    public let moduleType: ModuleType
    public private(set) var moduleState: ModuleState = .inactive
    public private(set) var configuration: ModuleConfiguration?
    
    private var moduleStateSubject = CurrentValueSubject<ModuleState, Never>(.inactive)
    public var moduleStatePublisher: AnyPublisher<ModuleState, Never> {
        return moduleStateSubject.eraseToAnyPublisher()
    }
    
    private var messageSubject = PassthroughSubject<ModuleMessage, Never>()
    public var messagePublisher: AnyPublisher<ModuleMessage, Never> {
        return messageSubject.eraseToAnyPublisher()
    }
    
    private var messageQueue: [ModuleMessage] = []
    private let maxQueueSize = 100
    
    // MARK: - Initialization
    
    public init(
        moduleType: ModuleType,
        identifier: String? = nil,
        navigationController: UINavigationController,
        configuration: ModuleConfiguration? = nil
    ) {
        self.moduleType = moduleType
        self.configuration = configuration
        
        super.init(
            identifier: identifier ?? "module-\(moduleType.rawValue)",
            type: .module,
            navigationController: navigationController
        )
        
        setupModuleObservations()
    }
    
    // MARK: - Module Coordinator Protocol
    
    public func initializeModule() {
        guard canTransitionModuleState(to: .initializing) else {
            print("⚠️ Cannot initialize module \(moduleType.displayName) from state \(moduleState.displayName)")
            return
        }
        
        setModuleState(.initializing)
        
        print("🔧 Initializing module: \(moduleType.displayName)")
        
        // 根据模块类型执行不同的初始化逻辑
        switch moduleType {
        case .deviceList:
            initializeDeviceListModule()
        case .deviceProvisioning:
            initializeDeviceProvisioningModule()
        case .deviceControl:
            initializeDeviceControlModule()
        case .settings:
            initializeSettingsModule()
        }
    }
    
    public func configureModule(_ configuration: ModuleConfiguration) {
        self.configuration = configuration
        
        print("⚙️ Configuring module \(moduleType.displayName) with configuration: \(configuration.parameters.keys.joined(separator: ", "))")
        
        // 应用配置
        applyConfiguration(configuration)
    }
    
    public func activateModule() {
        guard canTransitionModuleState(to: .active) else {
            print("⚠️ Cannot activate module \(moduleType.displayName) from state \(moduleState.displayName)")
            return
        }
        
        setModuleState(.active)
        
        print("✅ Activated module: \(moduleType.displayName)")
        
        // 处理队列中的消息
        processQueuedMessages()
    }
    
    public func deactivateModule() {
        guard canTransitionModuleState(to: .inactive) else {
            print("⚠️ Cannot deactivate module \(moduleType.displayName) from state \(moduleState.displayName)")
            return
        }
        
        setModuleState(.inactive)
        
        print("⏸️ Deactivated module: \(moduleType.displayName)")
        
        // 清理资源
        cleanupModuleResources()
    }
    
    public func suspendModule() {
        guard canTransitionModuleState(to: .suspended) else {
            print("⚠️ Cannot suspend module \(moduleType.displayName) from state \(moduleState.displayName)")
            return
        }
        
        setModuleState(.suspended)
        
        print("💤 Suspended module: \(moduleType.displayName)")
        
        // 保存模块状态
        saveModuleState()
    }
    
    public func resumeModule() {
        guard canTransitionModuleState(to: .active) else {
            print("⚠️ Cannot resume module \(moduleType.displayName) from state \(moduleState.displayName)")
            return
        }
        
        setModuleState(.active)
        
        print("🔄 Resumed module: \(moduleType.displayName)")
        
        // 恢复模块状态
        restoreModuleState()
    }
    
    public func sendMessage(_ message: ModuleMessage) {
        print("📤 Module \(moduleType.displayName) sending message: \(message.type.rawValue)")
        
        // 发布消息给其他模块
        messageSubject.send(message)
        
        // 通知父协调器
        if let parent = parent as? AppCoordinatorProtocol {
            // 可以通过父协调器转发消息给其他模块
            handleMessageForwarding(message)
        }
    }
    
    public func receiveMessage(_ message: ModuleMessage) {
        print("📥 Module \(moduleType.displayName) received message: \(message.type.rawValue) from \(message.sender.displayName)")
        
        // 如果模块未激活，将消息加入队列
        if moduleState != .active {
            queueMessage(message)
            return
        }
        
        // 处理消息
        processMessage(message)
    }
    
    public func getModuleInfo() -> [String: Any] {
        return [
            "type": moduleType.rawValue,
            "state": moduleState.rawValue,
            "identifier": identifier,
            "isActive": moduleState == .active,
            "configuration": configuration?.parameters ?? [:],
            "queuedMessages": messageQueue.count,
            "childrenCount": children.count
        ]
    }
    
    // MARK: - Coordinator Lifecycle
    
    public override func coordinatorWillStart() {
        super.coordinatorWillStart()
        initializeModule()
    }
    
    public override func coordinatorDidStart() {
        super.coordinatorDidStart()
        activateModule()
    }
    
    public override func coordinatorWillStop() {
        super.coordinatorWillStop()
        deactivateModule()
    }
    
    // MARK: - Private Methods
    
    private func setupModuleObservations() {
        moduleStatePublisher
            .sink { [weak self] state in
                self?.handleModuleStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    private func setModuleState(_ newState: ModuleState) {
        let oldState = moduleState
        moduleState = newState
        moduleStateSubject.send(newState)
        
        print("🔄 Module \(moduleType.displayName) state changed: \(oldState.displayName) -> \(newState.displayName)")
    }
    
    private func canTransitionModuleState(to newState: ModuleState) -> Bool {
        return moduleState.canTransitionTo.contains(newState)
    }
    
    private func handleModuleStateChange(_ state: ModuleState) {
        // 子类可以重写此方法处理模块状态变化
        switch state {
        case .inactive:
            handleModuleInactive()
        case .initializing:
            handleModuleInitializing()
        case .active:
            handleModuleActive()
        case .suspended:
            handleModuleSuspended()
        case .error:
            handleModuleError()
        }
    }
    
    private func initializeDeviceListModule() {
        // 初始化设备列表模块
        let deviceListViewController = createDeviceListViewController()
        navigationController.setViewControllers([deviceListViewController], animated: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.setModuleState(.active)
        }
    }
    
    private func initializeDeviceProvisioningModule() {
        // 初始化设备配网模块
        let provisioningViewController = createProvisioningViewController()
        navigationController.setViewControllers([provisioningViewController], animated: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.setModuleState(.active)
        }
    }
    
    private func initializeDeviceControlModule() {
        // 初始化设备控制模块
        let deviceControlViewController = createDeviceControlViewController()
        navigationController.setViewControllers([deviceControlViewController], animated: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.setModuleState(.active)
        }
    }
    
    private func initializeSettingsModule() {
        // 初始化设置模块
        let settingsViewController = createSettingsViewController()
        navigationController.setViewControllers([settingsViewController], animated: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.setModuleState(.active)
        }
    }
    
    private func applyConfiguration(_ configuration: ModuleConfiguration) {
        // 应用模块配置
        for (key, value) in configuration.parameters {
            print("🔧 Applying configuration: \(key) = \(value)")
        }
    }
    
    private func queueMessage(_ message: ModuleMessage) {
        messageQueue.append(message)
        
        // 限制队列大小
        if messageQueue.count > maxQueueSize {
            messageQueue.removeFirst(messageQueue.count - maxQueueSize)
        }
        
        print("📬 Queued message for module \(moduleType.displayName): \(message.type.rawValue)")
    }
    
    private func processQueuedMessages() {
        let queuedMessages = messageQueue
        messageQueue.removeAll()
        
        for message in queuedMessages {
            processMessage(message)
        }
        
        if !queuedMessages.isEmpty {
            print("📮 Processed \(queuedMessages.count) queued messages for module \(moduleType.displayName)")
        }
    }
    
    private func processMessage(_ message: ModuleMessage) {
        switch message.type {
        case .dataUpdate:
            handleDataUpdateMessage(message)
        case .stateChange:
            handleStateChangeMessage(message)
        case .userAction:
            handleUserActionMessage(message)
        case .systemEvent:
            handleSystemEventMessage(message)
        case .error:
            handleErrorMessage(message)
        }
    }
    
    private func handleDataUpdateMessage(_ message: ModuleMessage) {
        print("📊 Handling data update message in module \(moduleType.displayName)")
        // 处理数据更新消息
    }
    
    private func handleStateChangeMessage(_ message: ModuleMessage) {
        print("🔄 Handling state change message in module \(moduleType.displayName)")
        // 处理状态变化消息
    }
    
    private func handleUserActionMessage(_ message: ModuleMessage) {
        print("👤 Handling user action message in module \(moduleType.displayName)")
        // 处理用户操作消息
    }
    
    private func handleSystemEventMessage(_ message: ModuleMessage) {
        print("⚙️ Handling system event message in module \(moduleType.displayName)")
        // 处理系统事件消息
        
        if let appState = message.payload["appState"] as? String {
            print("📱 Module \(moduleType.displayName) received app state change: \(appState)")
        }
        
        if let isAuthenticated = message.payload["isAuthenticated"] as? Bool {
            print("🔐 Module \(moduleType.displayName) received auth state change: \(isAuthenticated)")
        }
    }
    
    private func handleErrorMessage(_ message: ModuleMessage) {
        print("❌ Handling error message in module \(moduleType.displayName)")
        // 处理错误消息
    }
    
    private func handleMessageForwarding(_ message: ModuleMessage) {
        // 转发消息给其他模块
        print("🔄 Forwarding message from module \(moduleType.displayName)")
    }
    
    private func cleanupModuleResources() {
        // 清理模块资源
        messageQueue.removeAll()
        print("🧹 Cleaned up resources for module \(moduleType.displayName)")
    }
    
    private func saveModuleState() {
        // 保存模块状态
        print("💾 Saved state for module \(moduleType.displayName)")
    }
    
    private func restoreModuleState() {
        // 恢复模块状态
        print("🔄 Restored state for module \(moduleType.displayName)")
    }
    
    private func handleModuleInactive() {
        print("⏸️ Module \(moduleType.displayName) is now inactive")
    }
    
    private func handleModuleInitializing() {
        print("🔧 Module \(moduleType.displayName) is initializing")
    }
    
    private func handleModuleActive() {
        print("✅ Module \(moduleType.displayName) is now active")
    }
    
    private func handleModuleSuspended() {
        print("💤 Module \(moduleType.displayName) is suspended")
    }
    
    private func handleModuleError() {
        print("❌ Module \(moduleType.displayName) encountered an error")
        setModuleState(.inactive)
    }
    
    // MARK: - View Controller Creation
    
    private func createDeviceListViewController() -> UIViewController {
        let viewController = UIViewController()
        viewController.title = "设备列表"
        viewController.view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "设备列表模块"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        viewController.view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])
        
        return viewController
    }
    
    private func createProvisioningViewController() -> UIViewController {
        let viewController = UIViewController()
        viewController.title = "设备配网"
        viewController.view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "设备配网模块"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        viewController.view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])
        
        return viewController
    }
    
    private func createDeviceControlViewController() -> UIViewController {
        let viewController = UIViewController()
        viewController.title = "设备控制"
        viewController.view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "设备控制模块"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        viewController.view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])
        
        return viewController
    }
    
    private func createSettingsViewController() -> UIViewController {
        let viewController = UIViewController()
        viewController.title = "设置"
        viewController.view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "设置模块"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        viewController.view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])
        
        return viewController
    }
}

// MARK: - Flow Coordinator Implementation

/// 流程协调器实现
public final class FlowCoordinator: BaseCoordinator, FlowCoordinatorProtocol {
    
    // MARK: - Properties
    
    public let flowType: FlowType
    public private(set) var currentStep: FlowStep?
    public private(set) var flowSteps: [FlowStep] = []
    public private(set) var completedSteps: [FlowStep] = []
    
    private var flowResultSubject = PassthroughSubject<FlowResult, Never>()
    public var flowResultPublisher: AnyPublisher<FlowResult, Never> {
        return flowResultSubject.eraseToAnyPublisher()
    }
    
    private var stepChangeSubject = PassthroughSubject<FlowStep, Never>()
    public var stepChangePublisher: AnyPublisher<FlowStep, Never> {
        return stepChangeSubject.eraseToAnyPublisher()
    }
    
    public var onStepCompleted: ((FlowStep, FlowResult) -> Void)?
    public var onFlowCompleted: ((FlowResult) -> Void)?
    
    // MARK: - Initialization
    
    public init(
        flowType: FlowType,
        identifier: String? = nil,
        navigationController: UINavigationController
    ) {
        self.flowType = flowType
        
        super.init(
            identifier: identifier ?? "flow-\(flowType.rawValue)",
            type: .flow,
            navigationController: navigationController
        )
        
        setupFlowSteps()
    }
    
    // MARK: - Flow Coordinator Protocol
    
    public func startFlow() {
        guard !flowSteps.isEmpty else {
            print("❌ Cannot start flow \(flowType.displayName): no steps defined")
            completeFlow(with: .failure("No steps defined"))
            return
        }
        
        print("🚀 Starting flow: \(flowType.displayName) with \(flowSteps.count) steps")
        
        completedSteps.removeAll()
        moveToStep(flowSteps[0])
    }
    
    public func moveToStep(_ step: FlowStep) {
        guard flowSteps.contains(where: { $0.identifier == step.identifier }) else {
            print("❌ Invalid step for flow \(flowType.displayName): \(step.identifier)")
            return
        }
        
        currentStep = step
        stepChangeSubject.send(step)
        
        print("➡️ Flow \(flowType.displayName) moved to step: \(step.title)")
        
        // 创建并显示步骤视图控制器
        let stepViewController = createStepViewController(for: step)
        
        if navigationController.viewControllers.isEmpty {
            navigationController.setViewControllers([stepViewController], animated: false)
        } else {
            navigationController.pushViewController(stepViewController, animated: true)
        }
    }
    
    public func moveToNextStep() {
        guard let currentStep = currentStep,
              let currentIndex = flowSteps.firstIndex(where: { $0.identifier == currentStep.identifier }),
              currentIndex < flowSteps.count - 1 else {
            print("✅ Flow \(flowType.displayName) completed: no more steps")
            completeFlow(with: .success([:]))
            return
        }
        
        let nextStep = flowSteps[currentIndex + 1]
        moveToStep(nextStep)
    }
    
    public func moveToPreviousStep() {
        guard let currentStep = currentStep,
              let currentIndex = flowSteps.firstIndex(where: { $0.identifier == currentStep.identifier }),
              currentIndex > 0 else {
            print("⚠️ Flow \(flowType.displayName): already at first step")
            return
        }
        
        navigationController.popViewController(animated: true)
        
        let previousStep = flowSteps[currentIndex - 1]
        self.currentStep = previousStep
        stepChangeSubject.send(previousStep)
        
        print("⬅️ Flow \(flowType.displayName) moved back to step: \(previousStep.title)")
    }
    
    public func completeStep(_ step: FlowStep, result: FlowResult) {
        guard let currentStep = currentStep,
              currentStep.identifier == step.identifier else {
            print("❌ Cannot complete step \(step.identifier): not current step")
            return
        }
        
        completedSteps.append(step)
        onStepCompleted?(step, result)
        
        print("✅ Completed step: \(step.title) in flow \(flowType.displayName)")
        
        switch result {
        case .success:
            moveToNextStep()
        case .failure(let error):
            print("❌ Step \(step.title) failed: \(error)")
            handleStepFailure(step, error: error)
        case .cancelled:
            print("⏹️ Step \(step.title) was cancelled")
            cancelFlow()
        case .retry:
            print("🔄 Retrying step: \(step.title)")
            // 重新显示当前步骤
            moveToStep(step)
        }
    }
    
    public func completeFlow(with result: FlowResult) {
        flowResultSubject.send(result)
        onFlowCompleted?(result)
        
        switch result {
        case .success:
            print("✅ Flow \(flowType.displayName) completed successfully")
        case .failure(let error):
            print("❌ Flow \(flowType.displayName) failed: \(error)")
        case .cancelled:
            print("⏹️ Flow \(flowType.displayName) was cancelled")
        case .retry:
            print("🔄 Restarting flow \(flowType.displayName)")
            startFlow()
            return
        }
        
        // 完成后停止协调器
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.stop()
        }
    }
    
    public func cancelFlow() {
        print("⏹️ Cancelling flow: \(flowType.displayName)")
        completeFlow(with: .cancelled)
    }
    
    public func getFlowProgress() -> Float {
        guard !flowSteps.isEmpty else { return 0.0 }
        return Float(completedSteps.count) / Float(flowSteps.count)
    }
    
    // MARK: - Coordinator Lifecycle
    
    public override func coordinatorWillStart() {
        super.coordinatorWillStart()
        startFlow()
    }
    
    // MARK: - Private Methods
    
    private func setupFlowSteps() {
        switch flowType {
        case .deviceSetup:
            setupDeviceSetupFlow()
        case .userOnboarding:
            setupUserOnboardingFlow()
        case .deviceConfiguration:
            setupDeviceConfigurationFlow()
        case .troubleshooting:
            setupTroubleshootingFlow()
        }
    }
    
    private func setupDeviceSetupFlow() {
        flowSteps = [
            FlowStep(
                identifier: "scan-devices",
                title: "扫描设备",
                description: "搜索附近的可配网设备",
                isRequired: true,
                canSkip: false
            ),
            FlowStep(
                identifier: "select-device",
                title: "选择设备",
                description: "从扫描到的设备中选择要配网的设备",
                isRequired: true,
                canSkip: false
            ),
            FlowStep(
                identifier: "connect-device",
                title: "连接设备",
                description: "建立与设备的连接",
                isRequired: true,
                canSkip: false
            ),
            FlowStep(
                identifier: "configure-network",
                title: "配置网络",
                description: "设置设备的网络连接",
                isRequired: true,
                canSkip: false
            ),
            FlowStep(
                identifier: "verify-connection",
                title: "验证连接",
                description: "验证设备网络连接是否正常",
                isRequired: true,
                canSkip: false
            ),
            FlowStep(
                identifier: "complete-setup",
                title: "完成配置",
                description: "配网完成，设备已添加到您的设备列表",
                isRequired: true,
                canSkip: false
            )
        ]
    }
    
    private func setupUserOnboardingFlow() {
        flowSteps = [
            FlowStep(
                identifier: "welcome",
                title: "欢迎",
                description: "欢迎使用IOTClient",
                isRequired: true,
                canSkip: false
            ),
            FlowStep(
                identifier: "permissions",
                title: "权限设置",
                description: "设置应用所需的权限",
                isRequired: true,
                canSkip: false
            ),
            FlowStep(
                identifier: "account-setup",
                title: "账户设置",
                description: "创建或登录您的账户",
                isRequired: false,
                canSkip: true
            ),
            FlowStep(
                identifier: "tutorial",
                title: "使用教程",
                description: "了解如何使用应用",
                isRequired: false,
                canSkip: true
            )
        ]
    }
    
    private func setupDeviceConfigurationFlow() {
        flowSteps = [
            FlowStep(
                identifier: "device-info",
                title: "设备信息",
                description: "查看和编辑设备基本信息",
                isRequired: true,
                canSkip: false
            ),
            FlowStep(
                identifier: "network-settings",
                title: "网络设置",
                description: "配置设备网络参数",
                isRequired: false,
                canSkip: true
            ),
            FlowStep(
                identifier: "security-settings",
                title: "安全设置",
                description: "配置设备安全参数",
                isRequired: false,
                canSkip: true
            ),
            FlowStep(
                identifier: "apply-settings",
                title: "应用设置",
                description: "将配置应用到设备",
                isRequired: true,
                canSkip: false
            )
        ]
    }
    
    private func setupTroubleshootingFlow() {
        flowSteps = [
            FlowStep(
                identifier: "problem-identification",
                title: "问题识别",
                description: "识别设备遇到的问题",
                isRequired: true,
                canSkip: false
            ),
            FlowStep(
                identifier: "basic-checks",
                title: "基础检查",
                description: "执行基础的连接和状态检查",
                isRequired: true,
                canSkip: false
            ),
            FlowStep(
                identifier: "advanced-diagnostics",
                title: "高级诊断",
                description: "执行更详细的诊断测试",
                isRequired: false,
                canSkip: true
            ),
            FlowStep(
                identifier: "solution-application",
                title: "应用解决方案",
                description: "应用推荐的解决方案",
                isRequired: true,
                canSkip: false
            )
        ]
    }
    
    private func createStepViewController(for step: FlowStep) -> UIViewController {
        let viewController = UIViewController()
        viewController.title = step.title
        viewController.view.backgroundColor = .systemBackground
        
        // 创建主要内容
        let titleLabel = UILabel()
        titleLabel.text = step.title
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = step.description
        descriptionLabel.font = .systemFont(ofSize: 16, weight: .medium)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建进度条
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progress = getFlowProgress()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建按钮
        let buttonStackView = UIStackView()
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 16
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 上一步按钮
        if let currentIndex = flowSteps.firstIndex(where: { $0.identifier == step.identifier }),
           currentIndex > 0 {
            let previousButton = UIButton(type: .system)
            previousButton.setTitle("上一步", for: .normal)
            previousButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            previousButton.addTarget(self, action: #selector(previousButtonTapped), for: .touchUpInside)
            buttonStackView.addArrangedSubview(previousButton)
        }
        
        // 下一步/完成按钮
        let nextButton = UIButton(type: .system)
        let isLastStep = flowSteps.last?.identifier == step.identifier
        nextButton.setTitle(isLastStep ? "完成" : "下一步", for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        nextButton.backgroundColor = .systemBlue
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 12
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        buttonStackView.addArrangedSubview(nextButton)
        
        // 跳过按钮（如果允许）
        if step.canSkip {
            let skipButton = UIButton(type: .system)
            skipButton.setTitle("跳过", for: .normal)
            skipButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            skipButton.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
            buttonStackView.addArrangedSubview(skipButton)
        }
        
        // 添加子视图
        viewController.view.addSubview(titleLabel)
        viewController.view.addSubview(descriptionLabel)
        viewController.view.addSubview(progressView)
        viewController.view.addSubview(buttonStackView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor, constant: 16),
            progressView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 32),
            progressView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -32),
            
            titleLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 48),
            titleLabel.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -32),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 32),
            descriptionLabel.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -32),
            
            buttonStackView.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            buttonStackView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 32),
            buttonStackView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -32),
            buttonStackView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        return viewController
    }
    
    @objc private func previousButtonTapped() {
        moveToPreviousStep()
    }
    
    @objc private func nextButtonTapped() {
        guard let currentStep = currentStep else { return }
        completeStep(currentStep, result: .success(["completed": true]))
    }
    
    @objc private func skipButtonTapped() {
        guard let currentStep = currentStep else { return }
        completeStep(currentStep, result: .success(["skipped": true]))
    }
    
    private func handleStepFailure(_ step: FlowStep, error: String) {
        // 处理步骤失败
        let alert = UIAlertController(
            title: "步骤失败",
            message: "\(step.title) 执行失败：\(error)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "重试", style: .default) { [weak self] _ in
            self?.completeStep(step, result: .retry)
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { [weak self] _ in
            self?.cancelFlow()
        })
        
        navigationController.present(alert, animated: true)
    }
}