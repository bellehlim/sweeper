//
//  BluetoothManager.swift
//  Sweeper
//
//  Created by Belle Lim on 7/23/24.
//

import CoreBluetooth
import CoreLocation

class BluetoothManager: NSObject, CBCentralManagerDelegate, ObservableObject {
    
    @Published var discoveredPeripherals = [Device]()
    private var cachedPeripherals = [UUID: Device]()
    
    private var centralManager: CBCentralManager!
    private var scanTimer: Timer?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        scanTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.scanForPeripherals()
        }
    }
    
    deinit {
        scanTimer?.invalidate()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            scanForPeripherals()
        }
    }
    
    private func scanForPeripherals() {
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let device = cachedPeripherals[peripheral.identifier] {
            updateDevice(device, with: RSSI, advertisementData: advertisementData)
        } else {
            let newDevice = createDevice(from: peripheral, RSSI: RSSI, advertisementData: advertisementData)
            cachedPeripherals[peripheral.identifier] = newDevice
            discoveredPeripherals.append(newDevice)
        }
    }
    
    private func updateDevice(_ device: Device, with RSSI: NSNumber, advertisementData: [String: Any]) {
        device.lastRssi = device.rssi
        device.rssi = RSSI.intValue
    }
    
    private func createDevice(from peripheral: CBPeripheral, RSSI: NSNumber, advertisementData: [String: Any]) -> Device {
        let newDevice = Device(
            name: peripheral.name ?? String("Unknown \(discoveredPeripherals.count)"),
            rssi: RSSI.intValue,
            lastRssi: RSSI.intValue,
            txPower: advertisementData[CBAdvertisementDataTxPowerLevelKey] as? Int ?? -59,
            peripheral: peripheral
        )
        return newDevice
    }
}
