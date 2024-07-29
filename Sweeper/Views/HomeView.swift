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
                    .fill(Color.blue)
                    .frame(height: 100)
                    .overlay(
                        VStack {
                            Text("Welcome to **Sweeper**🧹")
                                .foregroundStyle(.white)
                                .font(.title)
                            Text("Tap on a discovered device to locate it")
                                .foregroundColor(.white)
                                .lineLimit(3)
                                .font(.body)
                            Text("Devices in Range: \(bluetoothManager.sortedDevices.count)")
                                .foregroundColor(.white)
                                .font(.body)
                        }.padding(10)
                            .multilineTextAlignment(.center)
                    )
                    .padding(10)
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
                            CustomRadioWaveIcon()
                        }
                    }
                }.backgroundStyle(.blue)
            }
        }.onAppear {
            // first scan
            bluetoothManager.startScanning()
        }.alert(isPresented: $showAlert) {
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


struct CustomRadioWaveIcon: View {
    var band1Opacity: Double = 0.30
    var band2Opacity: Double = 0.70
    var band3Opacity: Double = 1.00
    let size = 20.0 // 50
    
    var body: some View {
        ZStack {
            // right-most band
            Image(systemName: "dot.radiowaves.right")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundColor(.black) // Base color of the icon
            
            .opacity(0.2)
            
            Image(systemName: "dot.radiowaves.right")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .mask(
                    Circle()
                        .frame(width: size, height: size)
                        .offset(x: -5)// Size of the cropped area
                )
                .opacity(0.2)
            
            
            Image(systemName: "dot.radiowaves.right")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .mask(
                    Circle()
                        .frame(width: size, height: size)
                        .offset(x: -10)// Size of the cropped area
                )
                .opacity(0.5)
            
            // left-most band
            Image(systemName: "dot.radiowaves.right")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .mask(
                    Circle()
                        .frame(width: size, height: size)
                        .offset(x: -12)// Size of the cropped area
                )
        }
    }
}
