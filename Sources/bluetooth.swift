import CoreBluetooth
import Foundation
import KituraNet
import KituraWebSocket

class BluetoothManager: NSObject {
  var centralManager: CBCentralManager!
  var treadmillPeripheral: CBPeripheral?

  var treadmillCommandCharacteristic: CBCharacteristic?
  var treadmillStatsCharacteristic: CBCharacteristic?

  override init() {
    print("BluetoothManager is being initialized")
    super.init()
    centralManager = CBCentralManager(delegate: self, queue: nil)
  }

  deinit {
    print("BluetoothManager is being deallocated")
  }

  func scan() {
    guard let treadmillPeripheral = treadmillPeripheral else {
      print("No treadmill peripheral found")
      return
    }

    loop: while treadmillCommandCharacteristic == nil {
      print("Discovering services")
      treadmillPeripheral.discoverServices(nil)

      print("Waiting for services to be discovered")
      sleep(2)
      print("Checking for services")

      guard let services = treadmillPeripheral.services else {
        print("No services found")
        continue
      }

      for service in services {
        print("service", service.uuid.uuidString)

        print("Discovering characteristics")

        treadmillPeripheral.discoverCharacteristics(nil, for: service)

        print("Waiting for characteristics to be discovered")
        sleep(2)
        print("Checking for characteristics")

        guard let characteristics = service.characteristics else {
          print("No characteristics found")
          continue
        }

        for characteristic in characteristics {
          print("characteristic", characteristic.uuid.uuidString)

          if characteristic.uuid.uuidString == "FE01" {
            treadmillStatsCharacteristic = characteristic

            print("Found stats characteristic", characteristic)

            treadmillPeripheral.setNotifyValue(true, for: characteristic)
          }

          if characteristic.uuid.uuidString == "FE02" {
            treadmillCommandCharacteristic = characteristic
            print("Found command characteristic", characteristic)
          }

          if treadmillStatsCharacteristic != nil && treadmillCommandCharacteristic != nil {
            break loop
          }
        }
      }
    }

    print("Done scanning")
  }
}

extension BluetoothManager: CBCentralManagerDelegate {
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    print("Central Manager did update state", central.state.rawValue)
    if central.state == .poweredOn {
      central.scanForPeripherals(withServices: [
        CBUUID(string: "00001800-0000-1000-8000-00805f9b34fb"),
        CBUUID(string: "0000180a-0000-1000-8000-00805f9b34fb"),
        CBUUID(string: "00010203-0405-0607-0809-0a0b0c0d1912"),
        CBUUID(string: "0000fe00-0000-1000-8000-00805f9b34fb"),
        CBUUID(string: "00002902-0000-1000-8000-00805f9b34fb"),
        CBUUID(string: "00010203-0405-0607-0809-0a0b0c0d1912"),
        CBUUID(string: "00002901-0000-1000-8000-00805f9b34fb"),
        CBUUID(string: "00002a00-0000-1000-8000-00805f9b34fb"),
        CBUUID(string: "00002a01-0000-1000-8000-00805f9b34fb"),
        CBUUID(string: "00002a04-0000-1000-8000-00805f9b34fb"),
        CBUUID(string: "00002a25-0000-1000-8000-00805f9b34fb"),
        CBUUID(string: "00002a26-0000-1000-8000-00805f9b34fb"),
        CBUUID(string: "00002a28-0000-1000-8000-00805f9b34fb"),
        CBUUID(string: "00002a24-0000-1000-8000-00805f9b34fb"),
        CBUUID(string: "00002a29-0000-1000-8000-00805f9b34fb"),
        CBUUID(string: "0000fe01-0000-1000-8000-00805f9b34fb"),
        CBUUID(string: "0000fe02-0000-1000-8000-00805f9b34fb"),
        CBUUID(string: "00010203-0405-0607-0809-0a0b0c0d2b12"),
      ])
    }
  }

  func centralManager(
    _ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?
  ) {
    print("Disconnected from peripheral", peripheral, error!)
  }

  // func centralManager(
  //   _ central: CBCentralManager,
  //   connectionEventDidOccur event: CBConnectionEvent,
  //   for peripheral: CBPeripheral
  // ) {
  //   print("Connection event did occur", event, peripheral)
  // }

  func centralManager(
    _ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any], rssi RSSI: NSNumber
  ) {
    print("Peripheral Discovered: \(peripheral)")
    print("Peripheral name: \(String(describing: peripheral.name))")
    print("Advertisement Data : \(advertisementData)")
    if peripheral.name == "KS-ST-A1P" {
      print("Found Treadmill")
      treadmillPeripheral = peripheral
      if let treadmillPeripheral = treadmillPeripheral {
        print("Connecting to peripheral Treadmill")
        central.connect(treadmillPeripheral, options: nil)
      }
    }
    central.stopScan()
  }

  func centralManager(
    _ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?
  ) {
    print("Failed to connect to peripheral", peripheral, error!)
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    if let treadmillPeripheral = treadmillPeripheral {
      print("Connected to peripheral", peripheral, treadmillPeripheral)
      treadmillPeripheral.delegate = self
      print("delegate", treadmillPeripheral.delegate)

    }
  }
}

extension BluetoothManager: CBPeripheralDelegate {
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    print("Discovered services", peripheral.services ?? "")
    for service in peripheral.services! {
      print("service", service.uuid.uuidString)
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?
  ) {
    print("Discovered characteristics", service.characteristics ?? "")
    for characteristic in service.characteristics! {
      print("characteristic", characteristic.uuid.uuidString)
    }
  }

  func peripheral(
    _ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?
  ) {
    print("Updated value for characteristic", characteristic)
  }
}
