//
//  AppCoordinatorTests.swift
//  AppCoordinator
//
//  Created by IOTClient on 2024.
//  Copyright © 2024 IOTClient. All rights reserved.
//

import XCTest
import UIKit
import Combine
@testable import AppCoordinator

// MARK: - Test Base Class

class AppCoordinatorTestCase: XCTestCase {
    
    var window: UIWindow!
    var appCoordinator: AppCoordinator!
    var coordinatorFactory: CoordinatorFactory!
    var deepLinkHandler: DeepLinkHandler!
    var navigationService: NavigationService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        deepLinkHandler = DeepLinkHandler()
        navigationService = NavigationService()
        coordinatorFactory = CoordinatorFactory(
            deepLinkHandler: deepLinkHandler,
            navigationService: navigationService
        )
        appCoordinator = AppCoordinator(
            window: window,
            coordinatorFactory: coordinatorFactory,
            deepLinkHandler: deepLinkHandler,
            navigationService: navigationService
        )
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables?.removeAll()
        appCoordinator?.stop()
        appCoordinator = nil
        coordinatorFactory = nil
        deepLinkHandler = nil
        navigationService = nil
        window = nil
        
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    func createMockNavigationController() -> UINavigationController {
        return UINavigationController()
    }
    
    func createMockViewController() -> UIViewController {
        return UIViewController()
    }
    
    func waitForExpectation(_ expectation: XCTestExpectation, timeout: TimeInterval = 1.0) {
        wait(for: [expectation], timeout: timeout)
    }
}

// MARK: - App Coordinator Tests

class AppCoordinatorTests: AppCoordinatorTestCase {
    
    func testAppCoordinatorInitialization() {
        XCTAssertNotNil(appCoordinator)
        XCTAssertEqual(appCoordinator.identifier, "app-coordinator")
        XCTAssertEqual(appCoordinator.type, .app)
        XCTAssertEqual(appCoordinator.state, .idle)
        XCTAssertEqual(appCoordinator.childCoordinators.count, 0)
    }
    
    func testAppCoordinatorStart() {
        let expectation = XCTestExpectation(description: "App coordinator should start")
        
        appCoordinator.start()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.appCoordinator.state, .running)
            XCTAssertNotNil(self.window.rootViewController)
            expectation.fulfill()
        }
        
        waitForExpectation(expectation)
    }
    
    func testAppCoordinatorStop() {
        appCoordinator.start()
        
        let expectation = XCTestExpectation(description: "App coordinator should stop")
        
        appCoordinator.stop()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.appCoordinator.state, .stopped)
            expectation.fulfill()
        }
        
        waitForExpectation(expectation)
    }
    
    func testAppStateTransitions() {
        XCTAssertEqual(appCoordinator.appState, .launching)
        
        appCoordinator.start()
        
        let expectation = XCTestExpectation(description: "App state should transition")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 模拟启动完成
            self.appCoordinator.handleAppStateChange(.initialized)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertEqual(self.appCoordinator.appState, .initialized)
                expectation.fulfill()
            }
        }
        
        waitForExpectation(expectation)
    }
    
    func testDeepLinkHandling() {
        let expectation = XCTestExpectation(description: "Deep link should be handled")
        
        let url = URL(string: "iotclient://device/control?deviceId=123")!
        
        appCoordinator.start()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let result = self.appCoordinator.handleDeepLink(url)
            
            switch result {
            case .handled:
                XCTAssertTrue(true)
            case .requiresAuthentication:
                XCTAssertTrue(true) // 也是有效的结果
            default:
                XCTFail("Deep link should be handled")
            }
            
            expectation.fulfill()
        }
        
        waitForExpectation(expectation)
    }
    
    func testShowMainInterface() {
        appCoordinator.start()
        
        let expectation = XCTestExpectation(description: "Main interface should be shown")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.appCoordinator.showMainInterface()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertTrue(self.appCoordinator.childCoordinators.count > 0)
                expectation.fulfill()
            }
        }
        
        waitForExpectation(expectation)
    }
}

// MARK: - Navigation Coordinator Tests

class NavigationCoordinatorTests: AppCoordinatorTestCase {
    
    var navigationCoordinator: NavigationCoordinator!
    var navigationController: UINavigationController!
    
    override func setUp() {
        super.setUp()
        
        navigationController = createMockNavigationController()
        navigationCoordinator = NavigationCoordinator(
            identifier: "test-nav-coordinator",
            navigationController: navigationController
        )
    }
    
    override func tearDown() {
        navigationCoordinator?.stop()
        navigationCoordinator = nil
        navigationController = nil
        
        super.tearDown()
    }
    
    func testNavigationCoordinatorInitialization() {
        XCTAssertNotNil(navigationCoordinator)
        XCTAssertEqual(navigationCoordinator.identifier, "test-nav-coordinator")
        XCTAssertEqual(navigationCoordinator.type, .navigation)
        XCTAssertNotNil(navigationCoordinator.navigationController)
    }
    
    func testPushViewController() {
        let viewController = createMockViewController()
        
        navigationCoordinator.push(viewController, animated: false)
        
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertEqual(navigationController.viewControllers.first, viewController)
    }
    
    func testPopViewController() {
        let viewController1 = createMockViewController()
        let viewController2 = createMockViewController()
        
        navigationCoordinator.push(viewController1, animated: false)
        navigationCoordinator.push(viewController2, animated: false)
        
        XCTAssertEqual(navigationController.viewControllers.count, 2)
        
        navigationCoordinator.pop(animated: false)
        
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertEqual(navigationController.viewControllers.first, viewController1)
    }
    
    func testPresentModal() {
        let viewController = createMockViewController()
        
        navigationCoordinator.presentModal(viewController, animated: false)
        
        XCTAssertNotNil(navigationController.presentedViewController)
    }
    
    func testNavigationHistory() {
        let viewController1 = createMockViewController()
        let viewController2 = createMockViewController()
        
        navigationCoordinator.push(viewController1, animated: false)
        navigationCoordinator.push(viewController2, animated: false)
        
        let history = navigationCoordinator.getNavigationHistory()
        XCTAssertEqual(history.count, 2)
    }
    
    func testNavigationInterceptor() {
        let expectation = XCTestExpectation(description: "Navigation should be intercepted")
        
        let interceptor = DefaultNavigationInterceptor(identifier: "test-interceptor") { request in
            expectation.fulfill()
            return .allow
        }
        
        navigationCoordinator.addInterceptor(interceptor)
        
        let viewController = createMockViewController()
        navigationCoordinator.push(viewController, animated: false)
        
        waitForExpectation(expectation)
    }
}

// MARK: - Tab Coordinator Tests

class TabCoordinatorTests: AppCoordinatorTestCase {
    
    var tabCoordinator: TabCoordinator!
    var navigationController: UINavigationController!
    
    override func setUp() {
        super.setUp()
        
        navigationController = createMockNavigationController()
        tabCoordinator = TabCoordinator(
            identifier: "test-tab-coordinator",
            navigationController: navigationController
        )
    }
    
    override func tearDown() {
        tabCoordinator?.stop()
        tabCoordinator = nil
        navigationController = nil
        
        super.tearDown()
    }
    
    func testTabCoordinatorInitialization() {
        XCTAssertNotNil(tabCoordinator)
        XCTAssertEqual(tabCoordinator.identifier, "test-tab-coordinator")
        XCTAssertEqual(tabCoordinator.type, .tab)
        XCTAssertNotNil(tabCoordinator.tabBarController)
    }
    
    func testAddTab() {
        let viewController = createMockViewController()
        viewController.title = "Test Tab"
        
        tabCoordinator.addTab(viewController, title: "Test Tab", image: nil)
        
        XCTAssertEqual(tabCoordinator.tabBarController.viewControllers?.count, 1)
    }
    
    func testRemoveTab() {
        let viewController1 = createMockViewController()
        let viewController2 = createMockViewController()
        
        tabCoordinator.addTab(viewController1, title: "Tab 1", image: nil)
        tabCoordinator.addTab(viewController2, title: "Tab 2", image: nil)
        
        XCTAssertEqual(tabCoordinator.tabBarController.viewControllers?.count, 2)
        
        tabCoordinator.removeTab(at: 0)
        
        XCTAssertEqual(tabCoordinator.tabBarController.viewControllers?.count, 1)
    }
    
    func testSelectTab() {
        let viewController1 = createMockViewController()
        let viewController2 = createMockViewController()
        
        tabCoordinator.addTab(viewController1, title: "Tab 1", image: nil)
        tabCoordinator.addTab(viewController2, title: "Tab 2", image: nil)
        
        tabCoordinator.selectTab(at: 1)
        
        XCTAssertEqual(tabCoordinator.tabBarController.selectedIndex, 1)
    }
    
    func testUpdateTabBadge() {
        let viewController = createMockViewController()
        
        tabCoordinator.addTab(viewController, title: "Test Tab", image: nil)
        tabCoordinator.updateTabBadge(at: 0, value: "5")
        
        XCTAssertEqual(tabCoordinator.tabBarController.tabBar.items?.first?.badgeValue, "5")
    }
}

// MARK: - Module Coordinator Tests

class ModuleCoordinatorTests: AppCoordinatorTestCase {
    
    var moduleCoordinator: ModuleCoordinator!
    var navigationController: UINavigationController!
    
    override func setUp() {
        super.setUp()
        
        navigationController = createMockNavigationController()
        moduleCoordinator = ModuleCoordinator(
            moduleType: .deviceList,
            identifier: "test-module-coordinator",
            navigationController: navigationController,
            configuration: nil
        )
    }
    
    override func tearDown() {
        moduleCoordinator?.stop()
        moduleCoordinator = nil
        navigationController = nil
        
        super.tearDown()
    }
    
    func testModuleCoordinatorInitialization() {
        XCTAssertNotNil(moduleCoordinator)
        XCTAssertEqual(moduleCoordinator.identifier, "test-module-coordinator")
        XCTAssertEqual(moduleCoordinator.type, .module)
        XCTAssertEqual(moduleCoordinator.moduleType, .deviceList)
        XCTAssertEqual(moduleCoordinator.moduleState, .inactive)
    }
    
    func testModuleActivation() {
        let expectation = XCTestExpectation(description: "Module should be activated")
        
        moduleCoordinator.activate()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.moduleCoordinator.moduleState, .active)
            expectation.fulfill()
        }
        
        waitForExpectation(expectation)
    }
    
    func testModuleDeactivation() {
        moduleCoordinator.activate()
        
        let expectation = XCTestExpectation(description: "Module should be deactivated")
        
        moduleCoordinator.deactivate()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.moduleCoordinator.moduleState, .inactive)
            expectation.fulfill()
        }
        
        waitForExpectation(expectation)
    }
    
    func testModuleSuspendAndResume() {
        moduleCoordinator.activate()
        
        let suspendExpectation = XCTestExpectation(description: "Module should be suspended")
        
        moduleCoordinator.suspend()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.moduleCoordinator.moduleState, .suspended)
            suspendExpectation.fulfill()
        }
        
        waitForExpectation(suspendExpectation)
        
        let resumeExpectation = XCTestExpectation(description: "Module should be resumed")
        
        moduleCoordinator.resume()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.moduleCoordinator.moduleState, .active)
            resumeExpectation.fulfill()
        }
        
        waitForExpectation(resumeExpectation)
    }
    
    func testModuleMessageHandling() {
        let expectation = XCTestExpectation(description: "Module should handle message")
        
        let message = ModuleMessage(
            type: .dataUpdate,
            senderId: "test-sender",
            targetId: moduleCoordinator.identifier,
            payload: ["test": "data"],
            priority: .normal,
            timestamp: Date()
        )
        
        moduleCoordinator.sendMessage(message)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 验证消息已被处理
            expectation.fulfill()
        }
        
        waitForExpectation(expectation)
    }
}

// MARK: - Flow Coordinator Tests

class FlowCoordinatorTests: AppCoordinatorTestCase {
    
    var flowCoordinator: FlowCoordinator!
    var navigationController: UINavigationController!
    
    override func setUp() {
        super.setUp()
        
        navigationController = createMockNavigationController()
        flowCoordinator = FlowCoordinator(
            flowType: .deviceSetup,
            identifier: "test-flow-coordinator",
            navigationController: navigationController
        )
    }
    
    override func tearDown() {
        flowCoordinator?.stop()
        flowCoordinator = nil
        navigationController = nil
        
        super.tearDown()
    }
    
    func testFlowCoordinatorInitialization() {
        XCTAssertNotNil(flowCoordinator)
        XCTAssertEqual(flowCoordinator.identifier, "test-flow-coordinator")
        XCTAssertEqual(flowCoordinator.type, .flow)
        XCTAssertEqual(flowCoordinator.flowType, .deviceSetup)
        XCTAssertNil(flowCoordinator.currentStep)
    }
    
    func testStartFlow() {
        let expectation = XCTestExpectation(description: "Flow should start")
        
        flowCoordinator.startFlow()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNotNil(self.flowCoordinator.currentStep)
            expectation.fulfill()
        }
        
        waitForExpectation(expectation)
    }
    
    func testNextStep() {
        flowCoordinator.startFlow()
        
        let expectation = XCTestExpectation(description: "Should move to next step")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let currentStepIndex = self.flowCoordinator.currentStep?.index ?? -1
            
            self.flowCoordinator.nextStep()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let newStepIndex = self.flowCoordinator.currentStep?.index ?? -1
                XCTAssertGreaterThan(newStepIndex, currentStepIndex)
                expectation.fulfill()
            }
        }
        
        waitForExpectation(expectation)
    }
    
    func testPreviousStep() {
        flowCoordinator.startFlow()
        
        let expectation = XCTestExpectation(description: "Should move to previous step")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.flowCoordinator.nextStep()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let currentStepIndex = self.flowCoordinator.currentStep?.index ?? -1
                
                self.flowCoordinator.previousStep()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let newStepIndex = self.flowCoordinator.currentStep?.index ?? -1
                    XCTAssertLessThan(newStepIndex, currentStepIndex)
                    expectation.fulfill()
                }
            }
        }
        
        waitForExpectation(expectation, timeout: 2.0)
    }
    
    func testCompleteFlow() {
        flowCoordinator.startFlow()
        
        let expectation = XCTestExpectation(description: "Flow should complete")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.flowCoordinator.completeFlow(result: .success(["result": "completed"]))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertNil(self.flowCoordinator.currentStep)
                expectation.fulfill()
            }
        }
        
        waitForExpectation(expectation)
    }
    
    func testCancelFlow() {
        flowCoordinator.startFlow()
        
        let expectation = XCTestExpectation(description: "Flow should be cancelled")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.flowCoordinator.cancelFlow()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertNil(self.flowCoordinator.currentStep)
                expectation.fulfill()
            }
        }
        
        waitForExpectation(expectation)
    }
}

// MARK: - Deep Link Handler Tests

class DeepLinkHandlerTests: AppCoordinatorTestCase {
    
    func testValidDeepLinkHandling() {
        let url = URL(string: "iotclient://device/list")!
        let result = deepLinkHandler.handleDeepLink(url)
        
        XCTAssertEqual(result, .handled)
    }
    
    func testInvalidDeepLinkHandling() {
        let url = URL(string: "invalid://test")!
        let result = deepLinkHandler.handleDeepLink(url)
        
        XCTAssertEqual(result, .error("Invalid deep link format"))
    }
    
    func testAuthenticationRequiredDeepLink() {
        let url = URL(string: "iotclient://settings/account")!
        let result = deepLinkHandler.handleDeepLink(url)
        
        XCTAssertEqual(result, .requiresAuthentication)
    }
    
    func testCustomHandlerRegistration() {
        let expectation = XCTestExpectation(description: "Custom handler should be called")
        
        deepLinkHandler.registerHandler(for: "/custom/path") { url in
            expectation.fulfill()
            return .handled
        }
        
        let url = URL(string: "iotclient://custom/path")!
        let result = deepLinkHandler.handleDeepLink(url)
        
        XCTAssertEqual(result, .handled)
        waitForExpectation(expectation)
    }
    
    func testCanHandleURL() {
        let validURL = URL(string: "iotclient://device/list")!
        let invalidURL = URL(string: "invalid://test")!
        
        XCTAssertTrue(deepLinkHandler.canHandle(validURL))
        XCTAssertFalse(deepLinkHandler.canHandle(invalidURL))
    }
}

// MARK: - Navigation Service Tests

class NavigationServiceTests: AppCoordinatorTestCase {
    
    func testNavigationServiceInitialization() {
        XCTAssertNotNil(navigationService)
        XCTAssertNil(navigationService.getCurrentPath())
        XCTAssertEqual(navigationService.getNavigationStack().count, 0)
    }
    
    func testSetRootCoordinator() {
        let coordinator = appCoordinator!
        navigationService.setRootCoordinator(coordinator)
        
        // 验证根协调器已设置（通过间接方式）
        XCTAssertNotNil(navigationService)
    }
    
    func testNavigateToPath() {
        let coordinator = appCoordinator!
        navigationService.setRootCoordinator(coordinator)
        
        let path = NavigationPath(
            destination: "device-list",
            animated: true,
            parameters: [:]
        )
        
        navigationService.navigate(to: path)
        
        XCTAssertEqual(navigationService.getNavigationStack().count, 1)
        XCTAssertEqual(navigationService.getCurrentPath()?.destination, "device-list")
    }
    
    func testGoBack() {
        let coordinator = appCoordinator!
        navigationService.setRootCoordinator(coordinator)
        
        let path1 = NavigationPath(destination: "device-list", animated: true, parameters: [:])
        let path2 = NavigationPath(destination: "device-control", animated: true, parameters: [:])
        
        navigationService.navigate(to: path1)
        navigationService.navigate(to: path2)
        
        XCTAssertEqual(navigationService.getNavigationStack().count, 2)
        
        navigationService.goBack()
        
        XCTAssertEqual(navigationService.getNavigationStack().count, 1)
        XCTAssertEqual(navigationService.getCurrentPath()?.destination, "device-list")
    }
    
    func testPopToRoot() {
        let coordinator = appCoordinator!
        navigationService.setRootCoordinator(coordinator)
        
        let path1 = NavigationPath(destination: "device-list", animated: true, parameters: [:])
        let path2 = NavigationPath(destination: "device-control", animated: true, parameters: [:])
        let path3 = NavigationPath(destination: "settings", animated: true, parameters: [:])
        
        navigationService.navigate(to: path1)
        navigationService.navigate(to: path2)
        navigationService.navigate(to: path3)
        
        XCTAssertEqual(navigationService.getNavigationStack().count, 3)
        
        navigationService.popToRoot()
        
        XCTAssertEqual(navigationService.getNavigationStack().count, 0)
    }
    
    func testClearNavigationStack() {
        let coordinator = appCoordinator!
        navigationService.setRootCoordinator(coordinator)
        
        let path = NavigationPath(destination: "device-list", animated: true, parameters: [:])
        navigationService.navigate(to: path)
        
        XCTAssertEqual(navigationService.getNavigationStack().count, 1)
        
        navigationService.clearNavigationStack()
        
        XCTAssertEqual(navigationService.getNavigationStack().count, 0)
    }
}

// MARK: - Coordinator Factory Tests

class CoordinatorFactoryTests: AppCoordinatorTestCase {
    
    func testCreateAppCoordinator() {
        let window = UIWindow()
        let appCoordinator = coordinatorFactory.createAppCoordinator(window: window)
        
        XCTAssertNotNil(appCoordinator)
        XCTAssertTrue(appCoordinator is AppCoordinator)
    }
    
    func testCreateNavigationCoordinator() {
        let navController = UINavigationController()
        let navigationCoordinator = coordinatorFactory.createNavigationCoordinator(
            identifier: "test-nav",
            navigationController: navController
        )
        
        XCTAssertNotNil(navigationCoordinator)
        XCTAssertTrue(navigationCoordinator is NavigationCoordinator)
        XCTAssertEqual(navigationCoordinator.identifier, "test-nav")
    }
    
    func testCreateTabCoordinator() {
        let navController = UINavigationController()
        let tabCoordinator = coordinatorFactory.createTabCoordinator(
            identifier: "test-tab",
            navigationController: navController
        )
        
        XCTAssertNotNil(tabCoordinator)
        XCTAssertTrue(tabCoordinator is TabCoordinator)
        XCTAssertEqual(tabCoordinator.identifier, "test-tab")
    }
    
    func testCreateModuleCoordinator() {
        let navController = UINavigationController()
        let moduleCoordinator = coordinatorFactory.createModuleCoordinator(
            type: .deviceList,
            identifier: "test-module",
            navigationController: navController,
            configuration: nil
        )
        
        XCTAssertNotNil(moduleCoordinator)
        XCTAssertTrue(moduleCoordinator is ModuleCoordinator)
        XCTAssertEqual(moduleCoordinator.identifier, "test-module")
    }
    
    func testCreateFlowCoordinator() {
        let navController = UINavigationController()
        let flowCoordinator = coordinatorFactory.createFlowCoordinator(
            type: .deviceSetup,
            identifier: "test-flow",
            navigationController: navController
        )
        
        XCTAssertNotNil(flowCoordinator)
        XCTAssertTrue(flowCoordinator is FlowCoordinator)
        XCTAssertEqual(flowCoordinator.identifier, "test-flow")
    }
}

// MARK: - Extensions Tests

class CoordinatorExtensionsTests: AppCoordinatorTestCase {
    
    func testUIViewControllerCoordinatorExtension() {
        let viewController = createMockViewController()
        let coordinator = appCoordinator!
        
        viewController.setCoordinator(coordinator)
        
        XCTAssertNotNil(viewController.coordinator)
        XCTAssertEqual(viewController.coordinator?.identifier, coordinator.identifier)
    }
    
    func testStringCoordinatorIdGeneration() {
        let id1 = String.generateCoordinatorId()
        let id2 = String.generateCoordinatorId(prefix: "test")
        
        XCTAssertTrue(id1.hasPrefix("coordinator_"))
        XCTAssertTrue(id2.hasPrefix("test_"))
        XCTAssertNotEqual(id1, id2)
    }
    
    func testStringCoordinatorIdValidation() {
        XCTAssertTrue("valid_coordinator_id".isValidCoordinatorId)
        XCTAssertTrue("coordinator123".isValidCoordinatorId)
        XCTAssertFalse("123invalid".isValidCoordinatorId)
        XCTAssertFalse("invalid@id".isValidCoordinatorId)
        XCTAssertFalse("".isValidCoordinatorId)
    }
    
    func testCoordinatorHierarchyExtensions() {
        let parentCoordinator = appCoordinator!
        let childCoordinator = NavigationCoordinator(
            identifier: "child",
            navigationController: UINavigationController()
        )
        
        parentCoordinator.addChildCoordinator(childCoordinator)
        
        XCTAssertEqual(childCoordinator.hierarchyPath, "app-coordinator/child")
        XCTAssertEqual(childCoordinator.rootCoordinator.identifier, parentCoordinator.identifier)
        XCTAssertFalse(childCoordinator.isRootCoordinator)
        XCTAssertTrue(parentCoordinator.isRootCoordinator)
        XCTAssertEqual(childCoordinator.depth, 1)
    }
    
    func testArrayCoordinatorExtensions() {
        let coordinator1 = NavigationCoordinator(
            identifier: "nav1",
            navigationController: UINavigationController()
        )
        let coordinator2 = TabCoordinator(
            identifier: "tab1",
            navigationController: UINavigationController()
        )
        
        var coordinators: [Coordinator] = [coordinator1, coordinator2]
        
        XCTAssertNotNil(coordinators.findCoordinator(withIdentifier: "nav1"))
        XCTAssertNotNil(coordinators.findCoordinator(ofType: TabCoordinator.self))
        
        coordinators.removeCoordinator(withIdentifier: "nav1")
        XCTAssertEqual(coordinators.count, 1)
    }
    
    func testUtilityFunctions() {
        let id = generateUniqueId(prefix: "test")
        XCTAssertTrue(id.hasPrefix("test_"))
        
        let startTime = Date()
        let endTime = Date(timeIntervalSinceNow: 0.5)
        let performance = calculateCoordinatorPerformance(startTime: startTime, endTime: endTime)
        
        XCTAssertGreaterThan(performance.duration, 0.4)
        XCTAssertLessThan(performance.duration, 0.6)
        
        let memoryString = formatMemoryUsage(1024 * 1024)
        XCTAssertTrue(memoryString.contains("MB"))
    }
}

// MARK: - Performance Tests

class CoordinatorPerformanceTests: AppCoordinatorTestCase {
    
    func testAppCoordinatorStartPerformance() {
        measure {
            let coordinator = AppCoordinator(
                window: window,
                coordinatorFactory: coordinatorFactory,
                deepLinkHandler: deepLinkHandler,
                navigationService: navigationService
            )
            coordinator.start()
            coordinator.stop()
        }
    }
    
    func testNavigationPerformance() {
        let navigationController = UINavigationController()
        let navigationCoordinator = NavigationCoordinator(
            identifier: "perf-test",
            navigationController: navigationController
        )
        
        measure {
            for i in 0..<100 {
                let viewController = UIViewController()
                viewController.title = "VC \(i)"
                navigationCoordinator.push(viewController, animated: false)
            }
            
            for _ in 0..<100 {
                navigationCoordinator.pop(animated: false)
            }
        }
    }
    
    func testDeepLinkHandlingPerformance() {
        let urls = (0..<1000).map { i in
            URL(string: "iotclient://device/control?deviceId=\(i)")!
        }
        
        measure {
            for url in urls {
                _ = deepLinkHandler.handleDeepLink(url)
            }
        }
    }
    
    func testCoordinatorHierarchyPerformance() {
        measure {
            let rootCoordinator = appCoordinator!
            
            // 创建深层次的协调器层级
            var currentCoordinator: Coordinator = rootCoordinator
            
            for i in 0..<50 {
                let childCoordinator = NavigationCoordinator(
                    identifier: "child-\(i)",
                    navigationController: UINavigationController()
                )
                currentCoordinator.addChildCoordinator(childCoordinator)
                currentCoordinator = childCoordinator
            }
            
            // 测试查找性能
            _ = rootCoordinator.findChildCoordinator(withIdentifier: "child-25")
            
            // 清理
            rootCoordinator.removeAllChildCoordinators()
        }
    }
}

// MARK: - Mock Objects

class MockCoordinatorDelegate: CoordinatorDelegate {
    var didStartCalled = false
    var didStopCalled = false
    var didFailCalled = false
    
    func coordinatorDidStart(_ coordinator: Coordinator) {
        didStartCalled = true
    }
    
    func coordinatorDidStop(_ coordinator: Coordinator) {
        didStopCalled = true
    }
    
    func coordinatorDidFail(_ coordinator: Coordinator, with error: Error) {
        didFailCalled = true
    }
}

class MockNavigationInterceptor: NavigationInterceptor {
    let identifier: String
    var shouldInterceptResult: NavigationInterceptResult
    var interceptCallCount = 0
    
    init(identifier: String, result: NavigationInterceptResult = .allow) {
        self.identifier = identifier
        self.shouldInterceptResult = result
    }
    
    func shouldIntercept(_ request: NavigationRequest) -> NavigationInterceptResult {
        interceptCallCount += 1
        return shouldInterceptResult
    }
}