//
//  HomeView.swift
//  Sweeper
//
//  Created by Belle Lim on 7/23/24.
//

import SwiftUI

struct HomeView: View {
    
    @ObservedObject var bluetoothManager = BluetoothManager()
    @Environment(\.presentationMode) var presentationMode
    @State private var showAlert: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blue) // Adjust the color as needed
                    .frame(height: 100)
                    .overlay(
                        Text("Devices in Range: \(bluetoothManager.sortedDevices.count)")
                            .foregroundColor(.white)
                            .font(.headline)
                    )
                    .padding(.vertical, 10)
                List(
                    bluetoothManager.sortedDevices,
                    id: \.id
                ) { device in
                    NavigationLink(destination: DeviceLocationView(device: device, 
                                                                   bluetoothManager: bluetoothManager,
                                                                   showAlert: $showAlert)) {
                        HStack {
                            Text(device.name)
                            Spacer()
                            Text(String(device.rssi ?? 0))
                            Image(systemName: "dot.radiowaves.right")
                                .opacity(Double(Float(device.rssi ?? Int(10.0))) / -100)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Sweeper").font(.headline)
                    }
                }
            }
        }.onAppear {
            // first scan
            bluetoothManager.startScanning()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Device No Longer in Range"),
                message: Text("\(bluetoothManager.lastDeviceLocated?.name ?? "The device you were viewing") is no longer in range."),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
