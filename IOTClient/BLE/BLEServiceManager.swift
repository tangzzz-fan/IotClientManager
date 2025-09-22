import Foundation
import CoreBluetooth

class BLEServiceManager {
    static let shared = BLEServiceManager()
    
    // 常见的智能家居设备服务UUID
    static let robotServiceUUID = CBUUID(string: "18B0") // 示例服务UUID
    static let deviceInfoServiceUUID = CBUUID(string: "180A") // 设备信息服务
    static let batteryServiceUUID = CBUUID(string: "180F") // 电池服务
    
    // 常见的特征UUID
    static let robotControlCharacteristicUUID = CBUUID(string: "2A00") // 示例控制特征
    static let robotStatusCharacteristicUUID = CBUUID(string: "2A01") // 示例状态特征
    static let batteryLevelCharacteristicUUID = CBUUID(string: "2A19") // 电池电量特征
    
    private init() {}
    
    // MARK: - 扫地机器人控制命令
    
    func sendCleanCommand(to peripheral: CBPeripheral) {
        let command = Data([0x01]) // 示例清洁命令
        BLEManager.shared.writeData(command, to: BLEServiceManager.robotControlCharacteristicUUID, for: peripheral)
    }
    
    func sendPauseCommand(to peripheral: CBPeripheral) {
        let command = Data([0x02]) // 示例暂停命令
        BLEManager.shared.writeData(command, to: BLEServiceManager.robotControlCharacteristicUUID, for: peripheral)
    }
    
    func sendHomeCommand(to peripheral: CBPeripheral) {
        let command = Data([0x03]) // 示例回家命令
        BLEManager.shared.writeData(command, to: BLEServiceManager.robotControlCharacteristicUUID, for: peripheral)
    }
    
    func sendStopCommand(to peripheral: CBPeripheral) {
        let command = Data([0x04]) // 示例停止命令
        BLEManager.shared.writeData(command, to: BLEServiceManager.robotControlCharacteristicUUID, for: peripheral)
    }
    
    // MARK: - 泳池清洁机器人控制命令
    
    func sendPoolCleanCommand(to peripheral: CBPeripheral) {
        let command = Data([0x11]) // 示例泳池清洁命令
        BLEManager.shared.writeData(command, to: BLEServiceManager.robotControlCharacteristicUUID, for: peripheral)
    }
    
    func sendPoolPauseCommand(to peripheral: CBPeripheral) {
        let command = Data([0x12]) // 示例泳池暂停命令
        BLEManager.shared.writeData(command, to: BLEServiceManager.robotControlCharacteristicUUID, for: peripheral)
    }
    
    // MARK: - 具身机器人控制命令
    
    func sendMoveForwardCommand(to peripheral: CBPeripheral) {
        let command = Data([0x21]) // 示例前进命令
        BLEManager.shared.writeData(command, to: BLEServiceManager.robotControlCharacteristicUUID, for: peripheral)
    }
    
    func sendMoveBackwardCommand(to peripheral: CBPeripheral) {
        let command = Data([0x22]) // 示例后退命令
        BLEManager.shared.writeData(command, to: BLEServiceManager.robotControlCharacteristicUUID, for: peripheral)
    }
    
    func sendTurnLeftCommand(to peripheral: CBPeripheral) {
        let command = Data([0x23]) // 示例左转命令
        BLEManager.shared.writeData(command, to: BLEServiceManager.robotControlCharacteristicUUID, for: peripheral)
    }
    
    func sendTurnRightCommand(to peripheral: CBPeripheral) {
        let command = Data([0x24]) // 示例右转命令
        BLEManager.shared.writeData(command, to: BLEServiceManager.robotControlCharacteristicUUID, for: peripheral)
    }
    
    func sendStopMovementCommand(to peripheral: CBPeripheral) {
        let command = Data([0x25]) // 示例停止移动命令
        BLEManager.shared.writeData(command, to: BLEServiceManager.robotControlCharacteristicUUID, for: peripheral)
    }
    
    // MARK: - 通用控制命令
    
    func sendCustomCommand(_ command: Data, to peripheral: CBPeripheral) {
        BLEManager.shared.writeData(command, to: BLEServiceManager.robotControlCharacteristicUUID, for: peripheral)
    }
    
    // MARK: - 状态查询
    
    func requestDeviceStatus(from peripheral: CBPeripheral) {
        BLEManager.shared.readData(from: BLEServiceManager.robotStatusCharacteristicUUID, for: peripheral)
    }
    
    func requestBatteryLevel(from peripheral: CBPeripheral) {
        BLEManager.shared.readData(from: BLEServiceManager.batteryLevelCharacteristicUUID, for: peripheral)
    }
    
    // MARK: - 通知订阅
    
    func subscribeToDeviceStatus(from peripheral: CBPeripheral) {
        BLEManager.shared.enableNotifications(for: BLEServiceManager.robotStatusCharacteristicUUID, for: peripheral)
    }
    
    func subscribeToBatteryLevel(from peripheral: CBPeripheral) {
        BLEManager.shared.enableNotifications(for: BLEServiceManager.batteryLevelCharacteristicUUID, for: peripheral)
    }
}