import MQTTClient
import XCTest

@testable import IOTClient

final class MQTTClientManagerTests: XCTestCase {

    private var sut: MQTTClientManager!
    private var mockSessionManager: MockMQTTSessionManager!
    private var mockSecurityPolicyFactory: MockMQTTSecurityPolicyFactory!
    private var mockConfiguration: MockMQTTConfiguration!

    override func setUp() {
        super.setUp()
        mockSessionManager = MockMQTTSessionManager()
        mockSecurityPolicyFactory = MockMQTTSecurityPolicyFactory()
        mockConfiguration = MockMQTTConfiguration()
        sut = MQTTClientManager(
            sessionManager: mockSessionManager,
            configuration: mockConfiguration,
            securityPolicyFactory: mockSecurityPolicyFactory
        )
    }

    override func tearDown() {
        sut = nil
        mockSessionManager = nil
        mockSecurityPolicyFactory = nil
        mockConfiguration = nil
        super.tearDown()
    }

    // MARK: - Connection Tests

    func testConnect_Success() {
        // Given
        let expectation = expectation(description: "Connect completion called")
        var resultError: Error?

        // When
        sut.connect { result in
            switch result {
            case .success:
                resultError = nil
            case .failure(let error):
                resultError = error
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertTrue(mockSessionManager.connectCalled)
    }

    func testConnect_Failure() {
        // Given
        let expectation = expectation(description: "Connect completion called")
        let expectedError = MQTTError.connectionFailed
        mockSessionManager.mockError = expectedError
        var resultError: Error?

        // When
        sut.connect { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                resultError = error
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(resultError as? MQTTError, expectedError)
    }

    // MARK: - Subscription Tests

    func testSubscribe_Success() {
        // Given
        let topics = ["test/topic1", "test/topic2"]

        // When
        sut.subscribe(to: topics)

        // Then
        XCTAssertEqual(mockSessionManager.subscriptions?.count, 2)
        XCTAssertTrue(((mockSessionManager.subscriptions?.keys.contains("test/topic1")) != nil))
        XCTAssertTrue(((mockSessionManager.subscriptions?.keys.contains("test/topic2")) != nil))
    }

    func testUnsubscribe_Success() {
        // Given
        let topics = ["test/topic1", "test/topic2"]
        sut.subscribe(to: topics)

        // When
        sut.unsubscribe(from: ["test/topic1"])

        // Then
        XCTAssertEqual(mockSessionManager.subscriptions?.count, 1)
        XCTAssertTrue(((mockSessionManager.subscriptions?.keys.contains("test/topic2")) != nil))
    }

    // MARK: - Publish Tests

    func testPublish_Success() {
        // Given
        let expectation = expectation(description: "Publish completion called")
        let message = "test message".data(using: .utf8)!
        let topic = "test/topic"
        var resultError: Error?

        // When
        sut.publish(message: message, to: topic) { result in
            switch result {
            case .success:
                resultError = nil
            case .failure(let error):
                resultError = error
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(resultError)
        XCTAssertTrue(mockSessionManager.sendCalled)
    }

    // MARK: - Network Change Tests

    func testNetworkChange_Reconnects() {
        // Given
        mockSessionManager.state = .closed

        // When
        NotificationCenter.default.post(
            name: .connectivityStatusChanged,
            object: true
        )

        // Then
        XCTAssertTrue(mockSessionManager.connectCalled)
    }

    // MARK: - Disconnect Tests

    func testDisconnect_Success() {
        // Given
        sut.connect { _ in }
        let topics = ["test/topic"]
        sut.subscribe(to: topics)

        // When
        sut.disconnect()

        // Then
        XCTAssertTrue(mockSessionManager.disconnectCalled)
        XCTAssertNil(mockSessionManager.delegate)
        XCTAssertTrue(((mockSessionManager.subscriptions?.isEmpty) != nil))
    }

    func testDisconnect_Failure() {
        // Given
        mockSessionManager.mockError = MQTTError.disconnectionFailed
        sut.connect { _ in }

        // When
        sut.disconnect()

        // Then
        XCTAssertTrue(mockSessionManager.disconnectCalled)
        XCTAssertFalse(((mockSessionManager.subscriptions?.isEmpty) != nil))
    }

    // MARK: - Message Handler Tests

    func testMessageHandler_CallbackReceived() {
        // Given
        let expectation = expectation(description: "Message handled")
        let testData = "test".data(using: .utf8)!
        let testTopic = "test/topic"

        // When
        NotificationCenter.default.addObserver(
            forName: .mqttNewMessage,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }

        if let messageHandler = mockSessionManager.messageHandler {
            messageHandler(testData, testTopic, false)
        }

        // Then
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - State Change Tests

    func testStateChange_NotifiesDelegate() {
        // Given
        let expectation = expectation(description: "State changed")
        expectation.expectedFulfillmentCount = 2
        var states: [MQTTSessionManagerState] = []

        // When
        mockSessionManager.stateChangeHandler = { state in
            states.append(state)
            expectation.fulfill()
        }

        mockSessionManager.simulateStateChange(.connecting)
        mockSessionManager.simulateStateChange(.connected)

        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(states, [.connecting, .connected])
    }

    // MARK: - Keep Alive Tests

    func testKeepAlive_ReconnectsWhenDisconnected() {
        // Given
        let expectation = expectation(description: "Reconnection attempted")
        mockSessionManager.state = .closed

        // When
        sut.connect { _ in
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(mockSessionManager.connectCalled)
    }
}

// MARK: - Mock Objects

private class MockMQTTSessionManager: MQTTSessionManager {
    var connectCalled = false
    var sendCalled = false
    var mockError: Error?
    var disconnectCalled = false
    var stateChangeHandler: ((MQTTSessionManagerState) -> Void)?
    private(set) var currentState: MQTTSessionManagerState = .closed

    override var state: MQTTSessionManagerState {
        get { currentState }
        set { currentState = newValue }
    }

    var messageHandler: ((Data, String, Bool) -> Void)? {
        get {
            return delegate?.handleMessage(_:onTopic:retained:)
        }
        set {

        }
    }

    func simulateStateChange(_ newState: MQTTSessionManagerState) {
        state = newState
        delegate?.sessionManager!(self, didChange: newState)
        stateChangeHandler?(newState)
    }

    override func connect(
        to host: String,
        port: Int,
        tls: Bool,
        keepalive: Int,
        clean: Bool,
        auth: Bool,
        user: String?,
        pass: String?,
        will: Bool,
        willTopic: String?,
        willMsg: Data?,
        willQos: MQTTQosLevel,
        willRetainFlag: Bool,
        withClientId clientId: String?,
        securityPolicy: MQTTSSLSecurityPolicy?,
        certificates: [Any]?,
        protocolLevel: MQTTProtocolVersion,
        connectHandler: MQTTConnectHandler?
    ) {
        connectCalled = true
        if let error = mockError {
            connectHandler?(error)
        } else {
            connectHandler?(nil)
        }
    }

    override func send(
        _ data: Data,
        topic: String,
        qos: MQTTQosLevel,
        retain: Bool
    ) -> UInt16 {
        sendCalled = true
        return mockError == nil ? 1 : 0
    }

    override func disconnect(disconnectHandler completion: MQTTDisconnectHandler? = nil) {
        disconnectCalled = true
        if let error = mockError {
            completion?(error)
        } else {
            completion?(nil)
        }
    }

    override var subscriptions: [String: NSNumber]? {
        get { _subscriptions }
        set { _subscriptions = newValue ?? nil }
    }
    private var _subscriptions: [String: NSNumber]? = nil
}

private class MockMQTTSecurityPolicyFactory: MQTTSecurityPolicyCreating {
    func createSecurityPolicy() -> MQTTSSLSecurityPolicy {
        return MQTTSSLSecurityPolicy()
    }
}

private class MockMQTTConfiguration: MQTTConfigurable {
    var host: String = "test.host.com"
    var port: UInt32 = 8883
    var clientId: String = "testClientId"
    var username: String = "testUser"
    var password: String = "testPass"
    var willTopic: String = "test/will"
    var willMessage: Data = "offline".data(using: .utf8)!
}

extension XCTestCase {
    func waitForCondition(
        timeout: TimeInterval = 5.0,
        description: String = "Condition not met",
        condition: @escaping () -> Bool
    ) {
        let expectation = expectation(description: description)

        DispatchQueue.global().async {
            let start = Date()
            while !condition() {
                if Date().timeIntervalSince(start) > timeout {
                    break
                }
                Thread.sleep(forTimeInterval: 0.1)
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: timeout + 1)
    }
}
