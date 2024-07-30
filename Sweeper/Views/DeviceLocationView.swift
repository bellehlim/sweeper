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
    
    @Binding var showAlert: Bool
    
    @State private var interval: Float = 0.5
    @State private var timer: Timer?
    
    let maxSize = 400.0
    let minSize = 20.0
    let maxDistance = 4.0
    let minDistance = 0.0
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    
    @State private var animate = true
    @State private var circleSize: CGFloat = 100 // Main circle size
    private let triggerSize: CGFloat = 175 // Size at which concentric circles start to appear
    private let circleCount = 5 // Number of concentric circles
    
    // from: https://stackoverflow.com/questions/20416218/understanding-ibeacon-distancing/20434019#20434019
    private func calculateDistance() -> Double {
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
    
    private func calculateSize() -> CGFloat {
        let clampedInput = max(min(calculateDistance(), maxDistance), minDistance)
        let normalizedInput = (clampedInput - minDistance) / (maxDistance - minDistance)
        let logScale = log10(normalizedInput * 9 + 1)
        return minSize + CGFloat(logScale) * (maxSize - minSize) / log10(10)
    }
    
    private func calculateFrequency() -> Float {
        let maxSpeed = 0.05
        let minSpeed = 1.5
        let clampedInput = max(min(calculateDistance(), maxDistance), minDistance)
        let normalizedInput = (clampedInput - minDistance) / (maxDistance - minDistance)
        let logScale = log10(normalizedInput * 9 + 1)
        let pingFrequency = maxSpeed + CGFloat(logScale) * (minSpeed - maxSpeed) / log10(10)
        return Float(max(pingFrequency, maxSpeed))
    }
    
    
    private var backgroundColor: Color {
        guard let rssi = device.rssi, let lastRssi = device.lastRssi else { return .gray }
        guard calculateDistance() > 0.35 else { return .green }
        return rssi > lastRssi ? Color.green : Color.red
    }
    
    private func updateHapticFeedback() {
        timer?.invalidate()
        let frequency = calculateFrequency()
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(frequency), repeats: true) { _ in
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
                        .frame(width: calculateSize(), height: calculateSize())
                        .position(x: geo.size.width / 2 , y: geo.size.height / 2)
                        .animation(.easeInOut(duration: 1.0), value: device.rssi)
                        .onAppear(perform: startAnimation)
                    
                    // Concentric circles
                    ForEach(0..<circleCount, id: \.self) { index in
                        Circle()
                            .stroke(.white.opacity(1 - Double(index) / Double(circleCount)),
                                    lineWidth: 2)
                            .frame(width: circleSize + CGFloat(index * 20), height: circleSize + CGFloat(index * 20))
                            .opacity(calculateDistance() <= 0.3 ? 1 : 0)
                            .animation(.easeOut.repeatForever(autoreverses: false), value: animate)
                    }
                }
            }
            
            Text("Estimated Distance:")
                .foregroundColor(.white)
                .font(.headline)
            Text("\(String(format: "%.3f", calculateDistance())) m")
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
            bluetoothManager.lastDeviceLocated = device
            bluetoothManager.deviceToBeLocated = nil
            
            timer?.invalidate()
            
            guard let uuid = bluetoothManager.lastDeviceLocated?.peripheral.identifier else { return }
            showAlert = bluetoothManager.cachedPeripherals[uuid] == nil
            || bluetoothManager.lastDeviceLocated?.mostRecentScan != bluetoothManager.currentScanIndex
        }
        
    }
}
