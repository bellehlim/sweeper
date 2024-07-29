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
                List(
                    bluetoothManager.discoveredPeripherals.sorted {
                        ($0.rssi ?? Int.min) > ($1.rssi ?? Int.min)
                    },
                    id: \.id
                ) { device in
                    NavigationLink(destination: DeviceLocationView(device: device)) {
                        HStack {
                            Text(device.peripheral.name ?? "Unknown")
                            Spacer()
                            Text(String(device.rssi ?? 0))
                            Image(systemName: "dot.radiowaves.right")
                                .opacity(Double(Float(device.rssi ?? Int(10.0))) / -100)
                        }
                    }
                }
                .padding(.top, -30)
                
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
