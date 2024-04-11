// The Swift Programming Language
// https://docs.swift.org/swift-book

import CoreBluetooth
import Foundation
import KituraNet
import KituraWebSocket

let server = WSService()
let treadmillManager = TreadmillManager()

treadmillManager.delegate = server

StartServer(server)

let runLoop = RunLoop.current
let distantFuture = Date.distantFuture
var shouldKeepRunning = true

while shouldKeepRunning == true && runLoop.run(mode: RunLoop.Mode.default, before: distantFuture) {

}
