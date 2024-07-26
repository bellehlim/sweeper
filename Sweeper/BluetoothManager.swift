//
//  BluetoothManager.swift
//  Sweeper
//
//  Created by Belle Lim on 7/23/24.
//
import Foundation
import CoreLocation
import CoreBluetooth

struct Device {
    var id: UUID = UUID()
    var peripheral: CBPeripheral
    var rssi: Int?
    var distance: Double?
}

class BluetoothManager: NSObject, CBCentralManagerDelegate, ObservableObject {
    @Published var isBluetoothEnabled = false
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
        
        // Start a timer to scan for peripherals every second
        scanTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.scanForPeripherals()
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
            isBluetoothEnabled = true
            scanForPeripherals()
        } else {
            isBluetoothEnabled = false
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if cachedPeripherals[peripheral.identifier] != nil {
            cachedPeripherals[peripheral.identifier]?.rssi = RSSI.intValue
            cachedPeripherals[peripheral.identifier]?.distance = calculateDistanceFromRSSI(RSSI.intValue)
            if let index = discoveredPeripherals.firstIndex(where: { $0.id == cachedPeripherals[peripheral.identifier]?.id }) {
                guard let cachedPeripheral = cachedPeripherals[peripheral.identifier] else { return }
                discoveredPeripherals[index] = cachedPeripheral
            }
        } else {
            let newDevice = Device(peripheral: peripheral, rssi: RSSI.intValue, distance: calculateDistanceFromRSSI(RSSI.intValue))
            cachedPeripherals[peripheral.identifier] = newDevice
            discoveredPeripherals.append(newDevice)
            centralManager.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.readRSSI()
    }

    func toggleBluetooth() {
        if centralManager.state == .poweredOn {
            centralManager.stopScan()
        } else {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }
}

extension BluetoothManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        guard let beacon = beacons.first else { return }
        distance = beacon.accuracy
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        // Handle RSSI reading completion
        if let error = error {
            print("Error reading RSSI: \(error.localizedDescription)")
            return
        }
        
        if cachedPeripherals[peripheral.identifier] != nil {
            cachedPeripherals[peripheral.identifier]?.rssi = RSSI.intValue
            cachedPeripherals[peripheral.identifier]?.distance = calculateDistanceFromRSSI(RSSI.intValue)
            if let index = discoveredPeripherals.firstIndex(where: { $0.id == cachedPeripherals[peripheral.identifier]?.id }) {
                guard let cachedPeripheral = cachedPeripherals[peripheral.identifier] else { return }
                discoveredPeripherals[index] = cachedPeripheral
            }
        }
    }
    
    private func calculateDistanceFromRSSI(_ rssi: Int) -> Double {
        // Use the RSSI value to estimate distance
        // Formula or algorithm to estimate distance from RSSI
        // Example calculation:
        let txPower = -59 // This is the reference power value (typically fixed)
        return Double(truncating: pow(10.0, (Double(txPower) - Double(rssi)) / 20.0) as NSNumber)
    }
}
