//
//  BluetoothManager.swift
//  Sweeper
//
//  Created by Belle Lim on 7/23/24.
//

import CoreBluetooth
import CoreLocation

class BluetoothManager: NSObject, CBCentralManagerDelegate, ObservableObject {
    
    @Published var state: CBManagerState?
    @Published var sortedDevices: [Device] = []
    @Published var cachedPeripherals = [UUID: Device]() {
        didSet {
            updateSortedDevices()
        }
    }
    private func updateSortedDevices() {
        sortedDevices = cachedPeripherals.values.sorted {
            ($0.rssi ?? Int.min) > ($1.rssi ?? Int.min)
        }
    }
    
    private var centralManager: CBCentralManager!
    private var scanTimer: Timer!
    private(set) var currentScanIndex: Int = 0
    var lastDeviceLocated: Device?
    var deviceToBeLocated: Device?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        scanTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.scanForPeripherals()
            self.currentScanIndex += 1
        }
    }
    
    deinit {
        scanTimer.invalidate()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) { 
        state = central.state
    }
    
    func startScanning() {
        scanTimer.fire()
    }
    
    func stopScanning() {
        centralManager.stopScan()
        scanTimer.invalidate()
    }
    
    private func scanForPeripherals() {
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard RSSI.intValue < 0 else { return }
        if let device = deviceToBeLocated, peripheral.identifier == device.id {
            device.lastRssi = device.rssi
            device.rssi = RSSI.intValue
            return
        }
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
