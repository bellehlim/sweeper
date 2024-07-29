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
    // TODO: implement haptic feedback
    let generator = UIImpactFeedbackGenerator(style: .soft)
    
    private func determineSize() -> CGFloat {
        let converted = CGFloat(minSize + (maxSize - minSize) * (calculateDistance() / 30.0))
        if converted < minSize {
            return minSize
        }
        if converted > maxSize {
            return maxSize
        }
        return converted
    }
    
    private func calculateDistance() -> Double {
        guard let rssi = device.rssi, let txPower = device.txPower else { return 0.0 }
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
    
    private var backgroundColor: Color {
        guard let rssi = device.rssi, let lastRssi = device.lastRssi else { return .gray }
        return rssi > lastRssi ? .green : .red
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                Circle()
                    .fill(.white.shadow(.drop(color: .black, radius: 3)))
                    .frame(width: determineSize(), height: determineSize())
                    .position(x: geometry.size.width / 2 , y: geometry.size.height / 2)
                    .animation(.easeInOut(duration: 1.0), value: device.rssi)
            }
            Spacer()
            Text("RSSI: \(String(device.rssi ?? 0))")
                .padding()
                .foregroundColor(.white)
            if let txPower = device.txPower {
                Text("Tx Power: \(String(txPower))")
                    .padding()
                    .foregroundColor(.white)
            }
            Text("Device Name: \(device.peripheral.name ?? "Unknown")")
                .padding()
                .foregroundColor(.white)
            Text("Distance: \(calculateDistance()) m")
                .foregroundColor(.white)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
    }
}
