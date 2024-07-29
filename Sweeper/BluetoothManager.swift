//
//  BluetoothManager.swift
//  Sweeper
//
//  Created by Belle Lim on 7/23/24.
//

import CoreBluetooth
import CoreLocation

class BluetoothManager: NSObject, CBCentralManagerDelegate, ObservableObject, CBPeripheralManagerDelegate, CLLocationManagerDelegate {
    
    @Published var discoveredBeacons = [CLBeacon]()
    
    // BluetoothScanner
    @Published var discoveredPeripherals = [Device]()
    private var centralManager: CBCentralManager!

    // BeaconAdvertiser
    var peripheralManager: CBPeripheralManager!
    private var cachedPeripherals = [UUID: Device]()
    
    // BeaconDetector
    private var location: CLLocationManager!
    var major: UInt16 = 0
    var minor: UInt16 = 0
    var beaconConstraints = [CLBeaconIdentityConstraint: [CLBeacon]]()
    var beacons = [CLProximity: [CLBeacon]]()
    
    private var scanTimer: Timer?
    
    override init() {
        super.init()
        // BluetoothScanner
        centralManager = CBCentralManager(delegate: self, queue: nil)
        // Rescan peripherals every second
        scanTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.scanForPeripherals()
        }
        
        // BeaconAdvertiser
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        
        // BeaconDetector
        location = CLLocationManager()
        location.delegate = self
        location.requestAlwaysAuthorization()
    }
    
    deinit {
        scanTimer?.invalidate()
    }
    
    // BluetoothScanner
    private func scanForPeripherals() {
        if centralManager.state == .poweredOn {
            print("scanning for peripherals")
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        scanForPeripherals()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.readRSSI()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let device = cachedPeripherals[peripheral.identifier] {
            device.lastRssi = device.rssi
            device.rssi = RSSI.intValue
            if let txPower = advertisementData[CBAdvertisementDataTxPowerLevelKey] as? Int {
                device.txPower = txPower
            }
            // not allowed
            if let txPower = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Int {
                device.txPower = txPower
            }
        } else {
            print("found new peripheral with uuid", peripheral.identifier)
            let newDevice = Device(
                name: peripheral.name,
                rssi: RSSI.intValue,
                lastRssi: RSSI.intValue,
                txPower: nil,
                peripheral: peripheral
            )
            if let txPower = advertisementData[CBAdvertisementDataTxPowerLevelKey] as? Int {
                newDevice.txPower = txPower
            }
            // not allowed
            if let txPower = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Int {
                newDevice.txPower = txPower
            }
            cachedPeripherals[peripheral.identifier] = newDevice
            discoveredPeripherals.append(newDevice)
            // BluetoothScanner
            advertiseNewPeripheral(uuid: peripheral.identifier)
            location.requestWhenInUseAuthorization()
            location.startRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: peripheral.identifier, major: major, minor: minor))
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    // BeaconAdvertiser
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            for discoveredPeripheral in discoveredPeripherals {
                advertiseNewPeripheral(uuid: discoveredPeripheral.peripheral.identifier)
            }
        }
    }
    
    func advertiseNewPeripheral(uuid: UUID) {
        let bundleURL = Bundle.main.bundleIdentifier!
        
        // Defines the beacon identity characteristics the device broadcasts.
        let constraint = CLBeaconIdentityConstraint(uuid: uuid, major: major, minor: minor)
        let region = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: bundleURL)
        
        let peripheralData = region.peripheralData(withMeasuredPower: nil) as? [String: Any]
        
        // Start broadcasting the beacon identity characteristics.
        print("advertising beacon with uuid", uuid)
        peripheralManager.startAdvertising(peripheralData)
    }
    
    // BeaconDetector
    func startScanning() {
        for peripheral in discoveredPeripherals {
            print("looking for beacon with uuid", peripheral.peripheral.identifier)
            location.startRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: peripheral.peripheral.identifier, major: major, minor: minor))
        }
    }
    
    func locationManager( _ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint
    ) {
        print("FOUND:", beacons.description, "for uuid", beaconConstraint.uuid)
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
