import CoreBluetooth
import Foundation

let commandQueue = DispatchQueue(label: "commandQueue")

protocol TreadmillManagerDelegate {
  func treadmillManager(_ treadmillManager: TreadmillManager, didUpdateStats stats: TreadmillStats)
}

class TreadmillManager: NSObject {
  var centralManager: CBCentralManager!
  var discoveredPeripherals = [CBPeripheral]()
  var treadmillPeripheral: CBPeripheral?

  var treadmillCommandCharacteristic: CBCharacteristic?
  var treadmillStatsCharacteristic: CBCharacteristic?

  var delegate: TreadmillManagerDelegate?

  override init() {
    print("TreadmillManager is being initialized")
    super.init()
    centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global())
  }

  deinit {
    print("TreadmillManager is being deallocated")
  }

  private func applyChecksum(_ bytes: [UInt8]) -> [UInt8] {
    print("Cleaning bytes", bytes)

    var cmd = bytes
    cmd[cmd.count - 2] = UInt8(UInt16(cmd[1..<cmd.count - 2].reduce(0, +)) % 256)
    print("Cleaned bytes", cmd)

    return cmd
  }

  func sendCommand(_ command: [UInt8]) {
    guard let peripheral = self.treadmillPeripheral else {
      print("No peripheral found")
      return
    }

    guard let treadmillCommandCharacteristic = self.treadmillCommandCharacteristic
    else {
      print("No command characteristic found")
      return
    }

    commandQueue.sync {
      peripheral.writeValue(
        Data(applyChecksum(command)),
        for: treadmillCommandCharacteristic,
        type: .withoutResponse)

      usleep(700)
    }
  }

  // func scan() {
  //   guard let treadmillPeripheral = treadmillPeripheral else {
  //     print("No treadmill peripheral found")
  //     return
  //   }

  //   loop: while treadmillCommandCharacteristic == nil {
  //     print("Discovering services")
  //     treadmillPeripheral.discoverServices(nil)

  //     print("Waiting for services to be discovered")
  //     sleep(2)
  //     print("Checking for services")

  //     guard let services = treadmillPeripheral.services else {
  //       print("No services found")
  //       continue
  //     }

  //     for service in services {
  //       print("service", service.uuid.uuidString)

  //       print("Discovering characteristics")

  //       treadmillPeripheral.discoverCharacteristics(nil, for: service)

  //       print("Waiting for characteristics to be discovered")
  //       sleep(2)
  //       print("Checking for characteristics")

  //       guard let characteristics = service.characteristics else {
  //         print("No characteristics found")
  //         continue
  //       }

  //       for characteristic in characteristics {
  //         print("characteristic", characteristic.uuid.uuidString)

  //         if characteristic.uuid.uuidString == "FE01" {
  //           treadmillStatsCharacteristic = characteristic

  //           print("Found stats characteristic", characteristic)

  //           treadmillPeripheral.setNotifyValue(true, for: characteristic)
  //         }

  //         if characteristic.uuid.uuidString == "FE02" {
  //           treadmillCommandCharacteristic = characteristic
  //           print("Found command characteristic", characteristic)
  //         }

  //         if treadmillStatsCharacteristic != nil && treadmillCommandCharacteristic != nil {
  //           break loop
  //         }
  //       }
  //     }
  //   }

  //   print("Done scanning")
  // }
}

extension TreadmillManager: CBCentralManagerDelegate {
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
      self.discoveredPeripherals.append(peripheral)
      // 1if let treadmillPeripheral = treadmillPeripheral {
      print("Connecting to peripheral Treadmill")
      central.connect(peripheral, options: nil)
      //}
    }
    central.stopScan()
  }

  func centralManager(
    _ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?
  ) {
    print("Failed to connect to peripheral", peripheral, error!)
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    self.treadmillPeripheral = peripheral
    print("Connected to peripheral", peripheral, treadmillPeripheral)

    peripheral.delegate = self
    print("delegate", peripheral.delegate)
    peripheral.discoverServices(nil)
  }
}

extension TreadmillManager: CBPeripheralDelegate {
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    print(error)
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
      if characteristic.uuid.uuidString == "FE01" {
        treadmillStatsCharacteristic = characteristic

        print("Found stats characteristic", characteristic)

        treadmillPeripheral?.setNotifyValue(true, for: characteristic)
      }

      if characteristic.uuid.uuidString == "FE02" {
        treadmillCommandCharacteristic = characteristic
        print("Found command characteristic", characteristic)
      }
    }
  }

  private func threeBigEndianBytesToInt(_ bytes: [UInt8]) -> Int {
    return Int(bytes[0]) * 256 * 256 + Int(bytes[1]) * 256 + Int(bytes[2])
  }

  func peripheral(
    _ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?
  ) {
    print("Updated value for characteristic", characteristic)
    if characteristic.uuid.uuidString == "FE01" {
      guard let value = characteristic.value else {
        print("No value found")
        return
      }

      let stats = [UInt8](value)
      print("Stats", stats)

      let beltState = stats[2]
      let beltSpeed = stats[3]
      let beltMode = stats[4]
      let currentRunningTime = threeBigEndianBytesToInt(Array(stats[5...7]))
      let currentDistance = threeBigEndianBytesToInt(Array(stats[8...10]))
      let currentSteps = threeBigEndianBytesToInt(Array(stats[11...13]))

      let treadmillStats = TreadmillStats(
        beltState: beltState,
        beltSpeed: beltSpeed,
        beltMode: beltMode,
        currentRunningTime: currentRunningTime,
        currentDistance: currentDistance,
        currentSteps: currentSteps)

      delegate?.treadmillManager(self, didUpdateStats: treadmillStats)
    }
  }
}

struct TreadmillStats: Encodable {
  let beltState: UInt8
  let beltSpeed: UInt8
  let beltMode: UInt8
  let currentRunningTime: Int
  let currentDistance: Int
  let currentSteps: Int
}
