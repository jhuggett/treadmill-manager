// The Swift Programming Language
// https://docs.swift.org/swift-book

import CoreBluetooth
import Foundation
import KituraNet
import KituraWebSocket

let bluetoothManager = BluetoothManager()

StartServer()

let runLoop = RunLoop.current
let distantFuture = Date.distantFuture
var shouldKeepRunning = true

while shouldKeepRunning == true && runLoop.run(mode: RunLoop.Mode.default, before: distantFuture) {

}
