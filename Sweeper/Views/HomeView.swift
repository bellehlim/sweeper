//
//  HomeView.swift
//  Sweeper
//
//  Created by Belle Lim on 7/23/24.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var bluetoothManager = BluetoothManager()
    
    private func calculateDistance(device: Device) -> Double {
        guard let rssi = device.rssi else { return 0.0 }
        var txPower = device.txPower ?? 0
        if txPower == 0 {
            txPower = -59
        }
        let pathLossExponent: Double = 2.0 // Typical value for indoor environments
        if rssi == 0 {
            return -1.0 // Invalid RSSI value
        }
        let ratio = Double(rssi) / Double(txPower)
        if ratio < 1.0 {
            return pow(ratio, pathLossExponent)
        } else {
            return (0.89976) * pow(ratio, pathLossExponent)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ZStack(alignment: .bottom){
                    Rectangle()
                        .frame(maxWidth: .infinity, maxHeight: 60)
                        .foregroundColor(.blue)
                        .cornerRadius(15)
                    Rectangle()
                        .frame(maxWidth: .infinity, maxHeight: 15)
                        .foregroundColor(.blue)
                }
                List(bluetoothManager.discoveredPeripherals, id: \.id) { device in
                    NavigationLink(destination: DeviceLocationView(device: device)) {
                        HStack {
                            Text(device.peripheral.name ?? "Unknown")
                            Spacer()
                            Text(String(device.rssi ?? 0))
                            Image(systemName: "dot.radiowaves.right")
                                .opacity(Double(Float(device.rssi ?? Int(10.0))) / -100)
                        }
                    }
                }.padding(.top, -30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Sweeper").font(.headline)
                    }
                }
            }
        }
    }
}
