//
//  DeviceLocationView.swift
//  Sweeper
//
//  Created by Belle Lim on 7/26/24.
//

import SwiftUI

struct DeviceLocationView: View {
    @ObservedObject var device: Device
    let maxSize = 400.0
    let minSize = 30.0
    
    private func determineSize(_ dist: Int?) -> CGFloat {
        guard let dist else { return CGFloat(maxSize)}
        let rssi = abs(dist)
        let scaled = Double(rssi) / 100.00
        return CGFloat(minSize + (maxSize - minSize) * scaled)
    }

    var body: some View {
        Circle()
            .fill(.blue)
            .frame(width: determineSize(device.rssi), height: determineSize(device.rssi))
            .animation(.easeInOut(duration: 1.0), value: device.rssi)
            .padding(.bottom, 20)
        ScrollView {
            Text("RSSI: \(String(device.rssi ?? 0))")
                .padding()
            Text("Device Name: \(device.peripheral.name ?? "Unknown")")
                .padding()
            Text("Distance: \(device.distance ?? 0) m")
        }
        .navigationTitle(device.peripheral.name ?? "Unknown Device")
        .background((device.rssi ?? 0) > (device.lastRssi ?? 0) ? .green : .red)
    }
}
