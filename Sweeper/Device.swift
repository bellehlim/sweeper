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
    var name: String?
    @Published var distance: Double?
    @Published var rssi: Int?
    @Published var lastRssi: Int?
    @Published var peripheral: CBPeripheral
        
    init(name: String?, distance: Double?, rssi: Int?, lastRssi: Int?, peripheral: CBPeripheral) {
        self.name = name
        self.distance = distance
        self.rssi = rssi
        self.lastRssi = lastRssi
        self.peripheral = peripheral
    }
}
