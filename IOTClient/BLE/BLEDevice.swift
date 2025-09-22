import Foundation
import CoreBluetooth

struct BLEDevice {
    let identifier: UUID
    let name: String?
    let rssi: NSNumber
    let peripheral: CBPeripheral
    let advertisementData: [String: Any]
    
    init(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        self.identifier = peripheral.identifier
        self.name = peripheral.name
        self.rssi = rssi
        self.peripheral = peripheral
        self.advertisementData = advertisementData
    }
    
    var displayName: String {
        return name ?? "Unknown Device"
    }
    
    var manufacturerData: Data? {
        return advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
    }
    
    var serviceUUIDs: [CBUUID]? {
        return advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
    }
    
    var txPower: NSNumber? {
        return advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber
    }
}