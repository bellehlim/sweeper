//
//  Device.swift
//  Sweeper
//
//  Created by Belle Lim on 7/26/24.
//

import CoreBluetooth
import Foundation

class Device: ObservableObject {
    var id: UUID = UUID()
    var name: String
    @Published var rssi: Int?
    @Published var lastRssi: Int?
    @Published var txPower: Int?
    @Published var peripheral: CBPeripheral
    var mostRecentScan: Int
        
    init(name: String, rssi: Int?, lastRssi: Int?, txPower: Int?, peripheral: CBPeripheral, mostRecentScan: Int) {
        self.name = name
        self.rssi = rssi
        self.lastRssi = lastRssi
        self.txPower = txPower
        self.peripheral = peripheral
        self.mostRecentScan = mostRecentScan
    }
}
