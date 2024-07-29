//
//  BluetoothManager.swift
//  Sweeper
//
//  Created by Belle Lim on 7/23/24.
//

import CoreBluetooth
import CoreLocation

class BluetoothManager: NSObject, CBCentralManagerDelegate, ObservableObject {
    
    @Published var cachedPeripherals = [UUID: Device]() {
        didSet {
            updateSortedDevices()
        }
    }
    
    @Published var sortedDevices: [Device] = []
    
    private func updateSortedDevices() {
        sortedDevices = cachedPeripherals.values.sorted {
            ($0.rssi ?? Int.min) > ($1.rssi ?? Int.min)
        }
    }
    private var centralManager: CBCentralManager!
    private var scanTimer: Timer?
    
    private var currentScanIndex: Int = 0
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        scanTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.scanForPeripherals()
            currentScanIndex += 1
        }
    }
    
    deinit {
        scanTimer?.invalidate()
    }
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
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
        }
        // remove stale peripherals
        for (uuid, device) in cachedPeripherals {
            if device.mostRecentScan + 2 < currentScanIndex {
                cachedPeripherals.removeValue(forKey: uuid)
            }
        }
    }
    
    private func updateDevice(_ device: Device, with RSSI: NSNumber, advertisementData: [String: Any]) {
        device.lastRssi = device.rssi
        device.rssi = RSSI.intValue
        device.mostRecentScan = currentScanIndex
    }
    
    private func createDevice(from peripheral: CBPeripheral, RSSI: NSNumber, advertisementData: [String: Any]) -> Device {
        let newDevice = Device(
            name: peripheral.name ?? String("Unknown"),
            rssi: RSSI.intValue,
            lastRssi: RSSI.intValue,
            txPower: advertisementData[CBAdvertisementDataTxPowerLevelKey] as? Int ?? -59,
            peripheral: peripheral,
            mostRecentScan: currentScanIndex
        )
        return newDevice
    }
}
