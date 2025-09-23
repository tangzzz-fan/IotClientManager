import Foundation
import CoreBluetooth

protocol BLEManagerDelegate: AnyObject {
    func bleManagerDidUpdateState(_ state: CBManagerState)
    func bleManager(_ manager: BLEManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber)
    func bleManager(_ manager: BLEManager, didConnect peripheral: CBPeripheral)
    func bleManager(_ manager: BLEManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
    func bleManager(_ manager: BLEManager, didDisconnect peripheral: CBPeripheral, error: Error?)
}

class BLEManager: NSObject {
    static let shared = BLEManager()
    
    private override init() {}
    
    weak var delegate: BLEManagerDelegate?
    
    private var centralManager: CBCentralManager!
    private var connectedPeripherals: [CBPeripheral] = []
    private var discoveredPeripherals: [CBPeripheral] = []
    
    // 存储发现的特征和服务
    private var characteristics: [CBUUID: CBCharacteristic] = [:]
    private var services: [CBUUID: CBService] = [:]
    
    // 初始化状态
    private(set) var isInitialized = false
    
    // MARK: - 初始化
    
    func initialize() {
        print("[BLEManager] 初始化BLE管理器")
        centralManager = CBCentralManager(delegate: self, queue: nil)
        isInitialized = true
    }
    
    func shutdown() {
        print("[BLEManager] 关闭BLE管理器")
        stopScanning()
        disconnectAll()
        centralManager = nil
        connectedPeripherals.removeAll()
        discoveredPeripherals.removeAll()
        characteristics.removeAll()
        services.removeAll()
        isInitialized = false
    }
    
    // MARK: - 扫描控制
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth is not powered on")
            return
        }
        
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        print("Started scanning for BLE devices...")
    }
    
    func stopScanning() {
        centralManager.stopScan()
        print("Stopped scanning for BLE devices")
    }
    
    // MARK: - 连接管理
    
    func connect(to peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect(from peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func disconnectAll() {
        connectedPeripherals.forEach { peripheral in
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    // MARK: - 数据传输
    
    func writeData(_ data: Data, to characteristicUUID: CBUUID, for peripheral: CBPeripheral) {
        guard let characteristic = characteristics[characteristicUUID] else {
            print("Characteristic not found")
            return
        }
        
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    func readData(from characteristicUUID: CBUUID, for peripheral: CBPeripheral) {
        guard let characteristic = characteristics[characteristicUUID] else {
            print("Characteristic not found")
            return
        }
        
        peripheral.readValue(for: characteristic)
    }
    
    func enableNotifications(for characteristicUUID: CBUUID, for peripheral: CBPeripheral) {
        guard let characteristic = characteristics[characteristicUUID] else {
            print("Characteristic not found")
            return
        }
        
        peripheral.setNotifyValue(true, for: characteristic)
    }
    
    // MARK: - 设备管理
    
    func getConnectedPeripherals() -> [CBPeripheral] {
        return connectedPeripherals
    }
    
    func getDiscoveredPeripherals() -> [CBPeripheral] {
        return discoveredPeripherals
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        delegate?.bleManagerDidUpdateState(central.state)
        
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
        case .poweredOff:
            print("Bluetooth is powered off")
        case .unauthorized:
            print("Bluetooth is unauthorized")
        case .unknown:
            print("Bluetooth state is unknown")
        case .resetting:
            print("Bluetooth is resetting")
        case .unsupported:
            print("Bluetooth is unsupported")
        @unknown default:
            print("Bluetooth state is unknown")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // 避免重复添加相同的设备
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
        }
        
        delegate?.bleManager(self, didDiscover: peripheral, advertisementData: advertisementData, rssi: RSSI)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if !connectedPeripherals.contains(peripheral) {
            connectedPeripherals.append(peripheral)
        }
        
        // 连接后开始发现服务
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        
        delegate?.bleManager(self, didConnect: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        delegate?.bleManager(self, didFailToConnect: peripheral, error: error)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // 从连接列表中移除
        if let index = connectedPeripherals.firstIndex(of: peripheral) {
            connectedPeripherals.remove(at: index)
        }
        
        delegate?.bleManager(self, didDisconnect: peripheral, error: error)
    }
}

// MARK: - CBPeripheralDelegate

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error)")
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            self.services[service.uuid] = service
            // 发现服务的特征
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            self.characteristics[characteristic.uuid] = characteristic
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error updating value for characteristic: \(error)")
            return
        }
        
        if let value = characteristic.value {
            print("Received data from characteristic \(characteristic.uuid): \(value)")
            // 这里可以处理接收到的数据
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error writing value for characteristic: \(error)")
        } else {
            print("Successfully wrote value to characteristic \(characteristic.uuid)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error updating notification state for characteristic: \(error)")
        } else {
            if characteristic.isNotifying {
                print("Notifications enabled for characteristic \(characteristic.uuid)")
            } else {
                print("Notifications disabled for characteristic \(characteristic.uuid)")
            }
        }
    }
}