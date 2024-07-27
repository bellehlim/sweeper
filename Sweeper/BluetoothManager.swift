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
    @Published var distance: Double?

    private var centralManager: CBCentralManager!
    private var location: CLLocationManager!
    private var cachedPeripherals = [UUID: Device]()

    private var scanTimer: Timer?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        location = CLLocationManager()
        location.delegate = self
        
        // Rescan peripherals every second
        scanTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.scanForPeripherals()
            self.location.startRangingBeacons(satisfying: <#T##CLBeaconIdentityConstraint#>)
        }
    }

    deinit {
        scanTimer?.invalidate()
    }

    private func scanForPeripherals() {
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            scanForPeripherals()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // existing device
        if let device = cachedPeripherals[peripheral.identifier] {
            device.lastRssi = device.rssi
            device.rssi = RSSI.intValue
            device.distance = calculateDistanceFromRSSI(RSSI.intValue)
            if let index = discoveredPeripherals.firstIndex(where: { $0.id == device.id }) {
                discoveredPeripherals[index] = device
            }
        // new device
        } else {
            let newDevice = Device(
                name: peripheral.name,
                distance: calculateDistanceFromRSSI(RSSI.intValue),
                rssi: RSSI.intValue,
                lastRssi: nil,
                peripheral: peripheral
            )
            cachedPeripherals[peripheral.identifier] = newDevice
            discoveredPeripherals.append(newDevice)
            centralManager.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.readRSSI()
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let error = error {
            print("Error reading RSSI: \(error.localizedDescription)")
            return
        }
        
        if let device = cachedPeripherals[peripheral.identifier] {
            device.lastRssi = device.rssi
            device.rssi = RSSI.intValue
            device.distance = calculateDistanceFromRSSI(RSSI.intValue)
            
            if let index = discoveredPeripherals.firstIndex(where: { $0.id == device.id }) {
                discoveredPeripherals[index] = device
            }
        }
    }
    
    private func calculateDistanceFromRSSI(_ rssi: Int) -> Double {
        // TODO: research distance calculation from RSSI
        let txPower = -59 // This is the reference power value (typically fixed)
        return Double(truncating: pow(10.0, (Double(txPower) - Double(rssi)) / 20.0) as NSNumber)
    }
}

extension BluetoothManager: CLLocationManagerDelegate {
    // TODO: figure this out
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        guard let beacon = beacons.first else { return }
        distance = beacon.accuracy
    }
}
