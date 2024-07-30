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
    
    private func fillAmount(rssi: Int?) -> Int {
        guard let rssi = rssi else { return 0 }
        switch rssi {
        case -50...(-10): return 4 // strong
        case -70...(-51): return 3
        case -90...(-71): return 2
        default: return 1 // weak
        }
    }
    
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
                            CustomRadioWaveIcon(fillAmount: fillAmount(rssi: device.rssi))
                        }
                    }
                }.scrollContentBackground(.hidden)
            }
        }.onAppear {
            // first scan
            bluetoothManager.startScanning()
        }.alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error Scanning Device"),
                message: Text("\(bluetoothManager.lastDeviceLocated?.name ?? "The device you were viewing") could not be scanned."),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}


struct CustomRadioWaveIcon: View {
    var fillAmount: Int
    let size: CGFloat = 20.0
    
    private func opacity(for index: Int) -> Double {
        print(fillAmount > index ? 1.0 : 0.2)
        return fillAmount > index ? 1.0 : 0.2
    }
    
    var body: some View {
        ZStack {
            // base
            Image(systemName: "dot.radiowaves.right")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundColor(.black)
                .opacity(0.2)
            // actual fill
            Image(systemName: "dot.radiowaves.right")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .mask(
                    Circle()
                        .frame(width: size, height: size)
                        .offset(x: CGFloat(-5 * (-fillAmount + 4)))
                )
        }
    }
}
