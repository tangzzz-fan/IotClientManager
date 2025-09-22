import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    // MARK: - UI Properties
    
    private var scanButton: UIButton!
    private var connectTCPButton: UIButton!
    private var connectUDPButton: UIButton!
    private var connectMQTTButton: UIButton!
    
    // MARK: - Properties
    
    private var isScanning = false
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotifications()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "智能家居控制器"
        
        // 创建和设置UI控件
        setupButtons()
    }
    
    private func setupButtons() {
        // 扫描设备按钮
        scanButton = UIButton(type: .system)
        scanButton.setTitle("扫描设备", for: .normal)
        scanButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        scanButton.backgroundColor = .systemBlue
        scanButton.setTitleColor(.white, for: .normal)
        scanButton.layer.cornerRadius = 8
        scanButton.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        
        // TCP连接按钮
        connectTCPButton = UIButton(type: .system)
        connectTCPButton.setTitle("连接TCP服务器", for: .normal)
        connectTCPButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        connectTCPButton.backgroundColor = .systemGreen
        connectTCPButton.setTitleColor(.white, for: .normal)
        connectTCPButton.layer.cornerRadius = 8
        connectTCPButton.addTarget(self, action: #selector(connectTCPButtonTapped), for: .touchUpInside)
        
        // UDP连接按钮
        connectUDPButton = UIButton(type: .system)
        connectUDPButton.setTitle("设置UDP套接字", for: .normal)
        connectUDPButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        connectUDPButton.backgroundColor = .systemOrange
        connectUDPButton.setTitleColor(.white, for: .normal)
        connectUDPButton.layer.cornerRadius = 8
        connectUDPButton.addTarget(self, action: #selector(connectUDPButtonTapped), for: .touchUpInside)
        
        // MQTT连接按钮
        connectMQTTButton = UIButton(type: .system)
        connectMQTTButton.setTitle("连接MQTT Broker", for: .normal)
        connectMQTTButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        connectMQTTButton.backgroundColor = .systemPurple
        connectMQTTButton.setTitleColor(.white, for: .normal)
        connectMQTTButton.layer.cornerRadius = 8
        connectMQTTButton.addTarget(self, action: #selector(connectMQTTButtonTapped), for: .touchUpInside)
        
        // 设置自动布局
        setupConstraints()
    }
    
    private func setupConstraints() {
        // 启用自动布局
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        connectTCPButton.translatesAutoresizingMaskIntoConstraints = false
        connectUDPButton.translatesAutoresizingMaskIntoConstraints = false
        connectMQTTButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加到视图
        view.addSubview(scanButton)
        view.addSubview(connectTCPButton)
        view.addSubview(connectUDPButton)
        view.addSubview(connectMQTTButton)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 扫描按钮
            scanButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            scanButton.widthAnchor.constraint(equalToConstant: 200),
            scanButton.heightAnchor.constraint(equalToConstant: 50),
            
            // TCP连接按钮
            connectTCPButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectTCPButton.topAnchor.constraint(equalTo: scanButton.bottomAnchor, constant: 20),
            connectTCPButton.widthAnchor.constraint(equalToConstant: 200),
            connectTCPButton.heightAnchor.constraint(equalToConstant: 50),
            
            // UDP连接按钮
            connectUDPButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectUDPButton.topAnchor.constraint(equalTo: connectTCPButton.bottomAnchor, constant: 20),
            connectUDPButton.widthAnchor.constraint(equalToConstant: 200),
            connectUDPButton.heightAnchor.constraint(equalToConstant: 50),
            
            // MQTT连接按钮
            connectMQTTButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectMQTTButton.topAnchor.constraint(equalTo: connectUDPButton.bottomAnchor, constant: 20),
            connectMQTTButton.widthAnchor.constraint(equalToConstant: 200),
            connectMQTTButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupNotifications() {
        // 设置通知观察者
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMQTTMessage),
            name: .mqttNewMessage,
            object: nil
        )
    }
    
    // MARK: - Button Actions
    
    @objc private func scanButtonTapped(_ sender: UIButton) {
        if isScanning {
            BLEManager.shared.stopScanning()
            sender.setTitle("扫描设备", for: .normal)
            isScanning = false
        } else {
            BLEManager.shared.startScanning()
            sender.setTitle("停止扫描", for: .normal)
            isScanning = true
        }
    }
    
    @objc private func connectTCPButtonTapped(_ sender: UIButton) {
        do {
            try SocketManager.shared.connectToTCPServer(host: "192.168.1.100", port: 8080)
        } catch {
            print("Failed to connect to TCP server: \(error)")
        }
    }
    
    @objc private func connectUDPButtonTapped(_ sender: UIButton) {
        do {
            try SocketManager.shared.setupUDPSocket()
        } catch {
            print("Failed to setup UDP socket: \(error)")
        }
    }
    
    @objc private func connectMQTTButtonTapped(_ sender: UIButton) {
        print("MQTT Connect button tapped")
        // 使用现有的MQTTClientManager连接到Broker
        print("Attempting to connect to MQTT broker...")
        MQTTClientManager.shared.connect { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Connected to MQTT broker")
                    sender.setTitle("MQTT已连接", for: .normal)
                    sender.backgroundColor = .systemGreen
                    // 订阅主题
                    print("Subscribing to topics...")
                    MQTTClientManager.shared.subscribe(to: ["home/devices/+/status"])
                case .failure(let error):
                    print("Failed to connect to MQTT broker: \(error)")
                    sender.setTitle("MQTT连接失败", for: .normal)
                    sender.backgroundColor = .systemRed
                }
            }
        }
    }
    
    // MARK: - MQTT Handling
    
    @objc private func handleMQTTMessage(_ notification: Notification) {
        // 处理MQTT消息
        print("Received MQTT message: \(notification)")
    }
    
    // MARK: - BLE Actions
    
    private func connectToPeripheral(_ peripheral: CBPeripheral) {
        BLEManager.shared.connect(to: peripheral)
    }
    
    // MARK: - Device Control
    
    private func sendCleanCommand(to peripheral: CBPeripheral) {
        BLEServiceManager.shared.sendCleanCommand(to: peripheral)
    }
    
    private func sendHomeCommand(to peripheral: CBPeripheral) {
        BLEServiceManager.shared.sendHomeCommand(to: peripheral)
    }
    
    private func sendMoveForwardCommand(to peripheral: CBPeripheral) {
        BLEServiceManager.shared.sendMoveForwardCommand(to: peripheral)
    }
    
    // MARK: - Deinit
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - BLEManagerDelegate

extension ViewController: BLEManagerDelegate {
    func bleManagerDidUpdateState(_ state: CBManagerState) {
        DispatchQueue.main.async {
            switch state {
            case .poweredOn:
                print("Bluetooth is powered on")
            case .poweredOff:
                print("Bluetooth is powered off")
                // 可以更新UI提示用户打开蓝牙
            default:
                print("Bluetooth state: \(state)")
            }
        }
    }
    
    func bleManager(_ manager: BLEManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        DispatchQueue.main.async {
            let device = BLEDevice(peripheral: peripheral, advertisementData: advertisementData, rssi: rssi)
            print("Discovered device: \(device.displayName)")
            
            // 可以在这里更新UI显示发现的设备
        }
    }
    
    func bleManager(_ manager: BLEManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            print("Connected to peripheral: \(peripheral.name ?? "Unknown")")
            // 可以在这里更新UI显示连接状态
        }
    }
    
    func bleManager(_ manager: BLEManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            print("Failed to connect to peripheral: \(peripheral.name ?? "Unknown")")
            // 可以在这里更新UI显示连接失败
        }
    }
    
    func bleManager(_ manager: BLEManager, didDisconnect peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            print("Disconnected from peripheral: \(peripheral.name ?? "Unknown")")
            // 可以在这里更新UI显示断开连接
        }
    }
}

// MARK: - SocketManagerDelegate

extension ViewController: SocketManagerDelegate {
    func socketManagerDidConnect(_ socketManager: SocketManager) {
        DispatchQueue.main.async {
            print("Connected to socket server")
            // 可以在这里更新UI显示连接状态
        }
    }
    
    func socketManagerDidDisconnect(_ socketManager: SocketManager, withError error: Error?) {
        DispatchQueue.main.async {
            print("Disconnected from socket server: \(String(describing: error))")
            // 可以在这里更新UI显示断开连接
        }
    }
    
    func socketManager(_ socketManager: SocketManager, didReceive data: Data) {
        DispatchQueue.main.async {
            print("Received socket data: \(data)")
            // 处理接收到的数据
        }
    }
}