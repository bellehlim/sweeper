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
                Button(action: { bluetoothManager.toggleBluetooth() }) {
                    Text(bluetoothManager.isBluetoothEnabled ? "Turn Off Bluetooth" : "Turn On Bluetooth").padding()
                }

                Text("Bluetooth is \(bluetoothManager.isBluetoothEnabled ? "enabled" : "disabled")").padding()

                List(bluetoothManager.discoveredPeripherals, id: \.id) { device in
                    NavigationLink(destination: DetailView(device: device)) {
                        Text("RSSI: \(String(device.rssi ?? 0))   \(device.peripheral.name ?? "Unknown")")
                    }
                }
            }
            .navigationTitle("Devices")
        }
    }
}

struct DetailView: View {
    let device: Device

    var body: some View {
        VStack {
            Text("Detail View")
                .font(.title)

            Text("RSSI: \(String(device.rssi ?? 0))")
                .padding()

            Text("Device Name: \(device.peripheral.name ?? "Unknown")")
                .padding()
            
            Text("Distance: \(device.distance ?? 0)")
            
        }
        .navigationTitle(device.peripheral.name ?? "Unknown Device")
    }
}
