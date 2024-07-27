//
//  HomeView.swift
//  Sweeper
//
//  Created by Belle Lim on 7/23/24.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var bluetoothManager = BluetoothManager()

    var body: some View {
        NavigationView {
            VStack {
                List(bluetoothManager.discoveredPeripherals, id: \.id) { device in
                    NavigationLink(destination: DeviceLocationView(device: device)) {
                        Text("RSSI: \(String(device.rssi ?? 0))   \(device.peripheral.name ?? "Unknown")")
                    }
                }
            }
            .navigationTitle("Devices")
        }
    }
}
