//
//  CentralManager.swift
//  BLE101
//
//  Created by Shawn Veader on 2/19/16.
//  Copyright © 2016 V8 Logic. All rights reserved.
//

import Foundation
import CoreBluetooth

// MARK: - CentralManagerDelegate Protocol
protocol CentralManagerDelegate {
    func managerConnectedToPeripheral(peripheral: CBPeripheral, manager: CentralManager)
    func managerDisconnectedFromPeripheral(peripheral: CBPeripheral, manager: CentralManager)
    func managerDiscoveredPeripheral(manager: CentralManager)
    func managerDidUpdateValueOfCharacteristic(characteristic: CBCharacteristic, manager: CentralManager)
    func managerDidUpdateCharacteristicsOfPeripheral(peripheral: CBPeripheral, manager: CentralManager)
}


// MARK: - CentralManager Class
class CentralManager : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let sharedInstance = CentralManager()

    let gyroServiceUUID = CBUUID(string: "7C27A67C-8E46-4AE6-8BC0-8A0865E7293F")
    let gyroXCharUUID = CBUUID(string: "FF125EA1-E5B1-4323-9913-957826EB5059")
    let gyroYCharUUID = CBUUID(string: "24676112-6E73-4159-90E1-147288DD11DD")
    let gyroZCharUUID = CBUUID(string: "593DCD1B-749B-4697-8DC3-709EED98887B")

    var gyroX: Int16 = 0
    var gyroY: Int16 = 0
    var gyroZ: Int16 = 0

    let centralManager: CBCentralManager
    var peripherals: [CBPeripheral]

    var delegate: CentralManagerDelegate?

    // MARK: - Initialization
    convenience override init() {
        self.init(manager: CBCentralManager())
    }

    init(manager: CBCentralManager) {
        self.centralManager = manager
        self.peripherals = [CBPeripheral]()
        super.init()
        self.centralManager.delegate = self
    }

    // MARK: - Scan Methods
    func startScan() {
        print("BT: starting scan...")
        self.peripherals = [CBPeripheral]() // clear out old peripherals
        // only look for peripherals broadcasting our gyro service
        self.centralManager.scanForPeripheralsWithServices([gyroServiceUUID], options: nil)
    }

    func stopScan() {
        print("BT: stop scan.")
        self.centralManager.stopScan()
    }

    // MARK: - Peripheral Methods
    func connectToPeripheral(peripheral: CBPeripheral) {
        print("BT: Connecting to peripheral \(peripheral)")
        self.centralManager.connectPeripheral(peripheral, options: .None)
    }

    func disconnectFromPeripheral(peripheral: CBPeripheral) {
        print("BT: Disconnecting from peripheral \(peripheral)")
        self.centralManager.cancelPeripheralConnection(peripheral)
    }

    // MARK: - Characteristic Methods
    func subscribeToGyroCharacteristics(peripheral: CBPeripheral) {
        if let gyroChars = gyroCharacteristicsOfPeripheral(peripheral) {
            for char in gyroChars {
                subscribeToUpdatesForCharacteristic(char, peripheral: peripheral)
            }
        }
    }

    func unsubscribeToGyroCharacteristics(peripheral: CBPeripheral) {
        if let gyroChars = gyroCharacteristicsOfPeripheral(peripheral) {
            for char in gyroChars {
                unsubscribeToUpdatesForCharacteristic(char, peripheral: peripheral)
            }
        }
    }

    func gyroCharUUIDS() -> [CBUUID] {
        let uuids = [self.gyroXCharUUID, self.gyroYCharUUID, self.gyroZCharUUID]
        return uuids
    }

    func gyroCharacteristicsOfPeripheral(peripheral: CBPeripheral) -> [CBCharacteristic]? {
        let uuids = gyroCharUUIDS()

        if let services: [CBService] = peripheral.services {
            if let service = services.filter({ $0.UUID == self.gyroServiceUUID }).first {
                if let characteristics: [CBCharacteristic] = service.characteristics {
                    let gyroCharacteristics = characteristics.filter({ uuids.contains($0.UUID) })
                    return gyroCharacteristics
                }
            }
        }

        return nil
    }

    func subscribeToUpdatesForCharacteristic(characteristic: CBCharacteristic, peripheral: CBPeripheral) {
        peripheral.setNotifyValue(true, forCharacteristic: characteristic)
    }

    func unsubscribeToUpdatesForCharacteristic(characteristic: CBCharacteristic, peripheral: CBPeripheral) {
        // guard characteristic.isNotifying == true else { return }
        peripheral.setNotifyValue(false, forCharacteristic: characteristic)
    }

    // MARK: - CBCentralManagerDelegate Methods
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("didConnectPeripheral:")
        print(peripheral)
        peripheral.delegate = self 
        peripheral.discoverServices([gyroServiceUUID])
        self.delegate?.managerConnectedToPeripheral(peripheral, manager: self)
    }

    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("didDisconnectPeripheral:error:")
        print(peripheral)
        print(error)
        print(error?.description)
        self.delegate?.managerDisconnectedFromPeripheral(peripheral, manager: self)
    }

    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        print("didDiscoverPeripheral:")

        if !self.peripherals.contains(peripheral) {
            print("Adding... \(peripheral)")
            print(advertisementData)
            self.peripherals.append(peripheral)
            self.delegate?.managerDiscoveredPeripheral(self)
        }
    }

    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("didFailToConnectPeripheral:")
        print(peripheral)
        print(error)
    }

    func centralManager(central: CBCentralManager, willRestoreState dict: [String : AnyObject]) {
        print("willRestoreState:")
        print(dict)
    }

    func centralManagerDidUpdateState(central: CBCentralManager) {
        print("centralManagerDidUpdateState:")
        print(central)
    }

    // MARK: - CBPeripheralDelegate Methods
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        print("peripheral:didDiscoverCharacteristicsForService:")

        if let characteristics = service.characteristics {
            print(characteristics)
            self.delegate?.managerDidUpdateCharacteristicsOfPeripheral(peripheral, manager: self)
        }
    }

    func peripheral(peripheral: CBPeripheral, didDiscoverDescriptorsForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("peripheral:didDiscoverDescriptorsForCharacteristic:")

        if let desciptors = characteristic.descriptors {
            print(desciptors)
        }
    }

    func peripheral(peripheral: CBPeripheral, didDiscoverIncludedServicesForService service: CBService, error: NSError?) {
        print("peripheral:didDiscoverIncludedServicesForService:")
        if let services = service.includedServices {
            print(services)
        }
    }

    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("peripheral:didDiscoverServices:")

        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(gyroCharUUIDS(), forService: service)
            }
        }
    }

    func peripheral(peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("peripheral:didModifyServices:")
    }

    func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
        print("peripheral:didReadRSSI:")
    }

    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("peripheral:didUpdateNotificationStateForCharacteristic:")
    }

    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("peripheral:didUpdateValueForCharacteristic:")

        if let err = error {
            print(err)
        } else {
            print(characteristic)

            let intValue = dataAsInt16(characteristic.value)
            switch characteristic.UUID {
            case gyroXCharUUID:
                self.gyroX = intValue
            case gyroYCharUUID:
                self.gyroY = intValue
            case gyroZCharUUID:
                self.gyroZ = intValue
            default:
                print("Unknown characteristic")
            }
            self.delegate?.managerDidUpdateValueOfCharacteristic(characteristic, manager: self)
        }
    }

    func peripheral(peripheral: CBPeripheral, didUpdateValueForDescriptor descriptor: CBDescriptor, error: NSError?) {
        print("peripheral:didUpdateValueForDescriptor:")
        print(descriptor)
    }

    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("peripheral:didWriteValueForCharacteristic:")
    }

    func peripheral(peripheral: CBPeripheral, didWriteValueForDescriptor descriptor: CBDescriptor, error: NSError?) {
        print("peripheral:didWriteValueForDescriptor:")
    }

    func peripheralDidUpdateName(peripheral: CBPeripheral) {
        print("peripheralDidUpdateName:")
        print(peripheral)
    }

    func peripheralDidUpdateRSSI(peripheral: CBPeripheral, error: NSError?) {
        print("peripheralDidUpdateRSSI:")
    }

    // MARK: - Helper Methods
    func dataAsInt16(data: NSData?) -> Int16 {
        guard let d = data else { return 0 }
        var intValue: Int16 = 0
        d.getBytes(&intValue, length: sizeof(Int16))
        return intValue
    }
}