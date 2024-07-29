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
    let maxDistance = 4.0
    let minDistance = 0.0
    // TODO: implement haptic feedback
    let generator = UIImpactFeedbackGenerator(style: .soft)
    
    private func determineSize() -> CGFloat {
        let clampedInput = max(min(calculateDistance(), maxDistance), minDistance)
        let normalizedInput = (clampedInput - minDistance) / (maxDistance - minDistance)
        let clampedNormalizedInput = max(min(normalizedInput, 1), 0)

        // Apply a logarithmic scale to make smaller changes more sensitive at the lower end
        let logScale = log10(clampedNormalizedInput * 9 + 1)

        let circleWidth = minSize + CGFloat(logScale) * (maxSize - minSize) / log10(10)
        return circleWidth
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
            return (0.89976) * pow(ratio, pathLossExponent) // in meteres
        }
    }
    
    private var backgroundColor: Color {
        guard let rssi = device.rssi, let lastRssi = device.lastRssi else { return .gray }
        return rssi > lastRssi ? .green : .red
    }
    
    var body: some View {
        VStack {
            Text("Device Name:")
                .foregroundColor(.white)
                .font(.title2)
            Text(device.peripheral.name ?? "Unknown")
                .foregroundColor(.white)
                .font(.title)
            GeometryReader { geometry in
                Circle()
                    .fill(.white.shadow(.drop(color: .black, radius: 3)))
                    .frame(width: determineSize(), height: determineSize())
                    .position(x: geometry.size.width / 2 , y: geometry.size.height / 2)
                    .animation(.easeInOut(duration: 1.0), value: device.rssi)
            }
            Text("Estimated Distance:")
                .foregroundColor(.white)
                .font(.title2)
            Text("\(String(format: "%.3f", calculateDistance())) m")
                .foregroundColor(.white)
                .font(.title)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
    }
}
