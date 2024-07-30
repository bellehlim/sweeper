//
//  HomeView.swift
//  Sweeper
//
//  Created by Belle Lim on 7/23/24.
//

import SwiftUI
import CoreBluetooth

struct HomeView: View {
    
    @ObservedObject var bluetoothManager = BluetoothManager()
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showTransition: Bool = true
    @State private var showCBAlert: Bool = false
    @State private var showDeviceAlert: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                headerView
                if shouldShowList {
                    deviceListView
                        .transition(showTransition ? .move(edge: .bottom) : .identity) // Slide in from the top or no transition
                        .transaction { transaction in
                            transaction.animation = showTransition ? .easeInOut(duration: 0.3) : nil
                        }
                } else {
                    ProgressView().progressViewStyle(.circular)
                        .padding(10)
                }
            }
        }.onAppear {
            // first scan
            bluetoothManager.startScanning()
        }.onChange(of: bluetoothManager.sortedDevices.count) { newCount in
            // only show the transition one time at startup
            if newCount > 0 && showTransition {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
                    showTransition = false
                }
            }
        }.onChange(of: bluetoothManager.state) { state in
            showCBAlert = state != .poweredOn
        }.alert(isPresented: $showDeviceAlert) {
            Alert(
                title: Text("Error Scanning Device"),
                message: Text("\(bluetoothManager.lastDeviceLocated?.name ?? "The device you were viewing") could not be scanned."),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }.accentColor(.white)
    }
    
    private var headerView: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.black)
            .frame(height: 120)
            .overlay(
                VStack {
                    Text("Welcome to **Sweeper**🧹")
                        .foregroundStyle(.white)
                        .font(.title)
                    if shouldShowList {
                        Text("Devices in Range: \(bluetoothManager.sortedDevices.count)")
                            .foregroundColor(.white)
                            .font(.body)
                        Text("Tap on a discovered device to locate it")
                            .foregroundColor(.white)
                            .font(.body)
                    }
                }
                .padding(10)
                .multilineTextAlignment(.center)
            )
            .padding([.top, .leading, .trailing], 20)
            .alert(isPresented: $showCBAlert) {
                Alert(
                    title: Text("Bluetooth Error"),
                    message: Text("Sweeper needs to use Bluetooth. Please check your Bluetooth is on."),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
    }
    
    private var shouldShowList: Bool {
        return bluetoothManager.sortedDevices.count != 0 && bluetoothManager.state == .poweredOn
    }
    
    private var deviceListView: some View {
        VStack {
            List(bluetoothManager.sortedDevices, id: \.id) { device in
                NavigationLink(destination: DeviceLocationView(device: device,
                                                               bluetoothManager: bluetoothManager,
                                                               showDeviceAlert: $showDeviceAlert,
                                                               showCBAlert: $showCBAlert)) {
                    HStack {
                        Text(device.name)
                        Spacer()
                        Text(String(device.rssi ?? 0))
                        CustomRadioWaveIcon(fillAmount: fillAmount(rssi: device.rssi))
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
    }
    
    private func fillAmount(rssi: Int?) -> Int {
        guard let rssi else { return 0 }
        switch rssi {
        case -50...(-10): return 4 // strong
        case -70...(-51): return 3
        case -90...(-71): return 2
        default: return 1 // weak
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
