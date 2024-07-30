//
//  DeviceLocationView.swift
//  Sweeper
//
//  Created by Belle Lim on 7/26/24.
//

import SwiftUI

struct DeviceLocationView: View {
    
    @ObservedObject var device: Device
    @ObservedObject var bluetoothManager: BluetoothManager
    
    @Binding var showDeviceAlert: Bool
    @Binding var showCBAlert: Bool
    
    @State private var interval: Float = 0.5
    @State private var timer: Timer?
    
    
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    
    @State private var animate = true
    @State private var circleSize: CGFloat = 50 // Main circle size
    private let triggerSize: CGFloat = 100 // Size at which concentric circles start to appear
    private let circleCount = 5 // Number of concentric circles
    
    // from: https://stackoverflow.com/questions/20416218/understanding-ibeacon-distancing/20434019#20434019
    private var distance: Double {
        guard let rssi = device.rssi, let txPower = device.txPower else { return 0.0 }
        if rssi == 0 { return -1.0 }
        
        let pathLossExponent: Double = 2.0 // Typical value for indoor environments
        
        // found txPowers tend to be large and positive, causing very off distance calculations -- just use -59 for now
        let ratio = Double(rssi) / Double(-59)
        if ratio < 1.0 {
            return pow(ratio, pathLossExponent)
        } else {
            return (0.89976) * pow(ratio, pathLossExponent) // in meters
        }
    }
    
    /// for display values
    private var scaledDistance: CGFloat {
        let maxDistance = 4.0
        let minDistance = 0.2 // closest reasonable distance
        let clampedInput = max(min(distance, maxDistance), minDistance)
        let normalizedInput = (clampedInput - minDistance) / (maxDistance - minDistance)
        return log10(normalizedInput * 9 + 1)
    }
    
    private var scaledSize: CGFloat {
        let maxSize = 400.0
        let minSize = 20.0
        return minSize + CGFloat(scaledDistance) * (maxSize - minSize) / log10(10)
    }
    
    private var scaledFrequency: Float {
        let maxSpeed = 0.05
        let minSpeed = 1.5
        let pingFrequency = maxSpeed + CGFloat(scaledDistance) * (minSpeed - maxSpeed) / log10(10)
        return Float(max(pingFrequency, maxSpeed))
    }
    
    private var backgroundColor: Color {
        guard let rssi = device.rssi, let lastRssi = device.lastRssi else { return .gray }
        guard distance > 0.35 else { return .green }
        return rssi > lastRssi ? Color.green : Color.red
    }
    
    private func updateHapticFeedback() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(scaledFrequency), repeats: true) { _ in
            generator.impactOccurred()
        }
    }
    
    private func startAnimation() {
        withAnimation(.easeInOut(duration: 2).repeatForever()) {
            circleSize = triggerSize
        }
    }
    
    var body: some View {
        VStack {
            Text("Device Name:")
                .foregroundColor(.white)
                .font(.headline)
            Text(device.peripheral.name ?? "Unknown")
                .foregroundColor(.white)
                .font(.title)
            
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(.white.shadow(.drop(color: .black, radius: 3)))
                        .frame(width: scaledSize, height: scaledSize)
                        .position(x: geo.size.width / 2 , y: geo.size.height / 2)
                        .animation(.easeInOut(duration: 1.0), value: device.rssi)
                        .onAppear(perform: startAnimation)
                    
                    // concentric circles for positive animation
                    ForEach(0..<circleCount, id: \.self) { index in
                        Circle()
                            .stroke(.white.opacity(1 - Double(index) / Double(circleCount)),
                                    lineWidth: 2)
                            .frame(width: circleSize + CGFloat(index * 20), height: circleSize + CGFloat(index * 20))
                            .opacity(distance <= 0.3 ? 1 : 0)
                            .animation(.easeOut.repeatForever(autoreverses: false), value: animate)
                    }
                }
            }
            
            Text("Estimated Distance:")
                .foregroundColor(.white)
                .font(.headline)
            Text("\(String(format: "%.3f", distance)) m")
                .foregroundColor(.white)
                .font(.title)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
        .onAppear {
            bluetoothManager.deviceToBeLocated = device
            updateHapticFeedback()
        }.onChange(of: device.rssi) { _ in
            updateHapticFeedback()
        }
        .onDisappear {
            timer?.invalidate()
            
            // show device alert if device info is outdated or no longer available
            bluetoothManager.lastDeviceLocated = device
            bluetoothManager.deviceToBeLocated = nil
            if let uuid = bluetoothManager.lastDeviceLocated?.peripheral.identifier {
                showDeviceAlert = bluetoothManager.cachedPeripherals[uuid] == nil
                || bluetoothManager.lastDeviceLocated?.mostRecentScan != bluetoothManager.currentScanIndex
            }
            
        }
        
    }
}
