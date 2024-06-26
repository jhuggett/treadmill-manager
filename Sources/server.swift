//
//  File.swift
//
//
//  Created by Joel Huggett on 2024-04-05.
//

import CoreBluetooth
import Foundation
import KituraNet
import KituraWebSocket

struct AnyCodable: Codable {
  let value: Any

  init<T>(_ value: T?) {
    self.value = value ?? ()
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let v = try? container.decode(Bool.self) {
      value = v
    } else if let v = try? container.decode(Int.self) {
      value = v
    } else if let v = try? container.decode(Double.self) {
      value = v
    } else if let v = try? container.decode(String.self) {
      value = v
    } else if let v = try? container.decode([AnyCodable].self) {
      value = v.map { $0.value }
    } else if let v = try? container.decode([String: AnyCodable].self) {
      value = v.mapValues { $0.value }
    } else {
      throw DecodingError.typeMismatch(
        AnyCodable.self,
        DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Not a JSON"))
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch value {
    case let v as Bool:
      try container.encode(v)
    case let v as Int:
      try container.encode(v)
    case let v as Double:
      try container.encode(v)
    case let v as String:
      try container.encode(v)
    case let v as [Any?]:
      try container.encode(v.map { AnyCodable($0) })
    case let v as [String: Any?]:
      try container.encode(v.mapValues { AnyCodable($0) })
    default:
      throw EncodingError.invalidValue(
        value, EncodingError.Context(codingPath: [], debugDescription: "Not a JSON"))
    }
  }
}

struct Request: Decodable {
  let method: String
  let params: AnyCodable?
  let id: String
}

struct Response: Encodable {
  let id: String
  let result: String
}

class WSService: WebSocketService {

  private var connection: WebSocketConnection?

  public func connected(connection: WebSocketConnection) {
    print("Connected to server")
    self.connection = connection
  }

  public func disconnected(connection: WebSocketConnection, reason: WebSocketCloseReasonCode) {
    print("Disconnected from server")
    self.connection = nil
  }

  public func received(message: Data, from: WebSocketConnection) {
    print("Received INVALID data message")
  }

  public func received(message: String, from: WebSocketConnection) {
    print("Received message", message)

    let request: Request = try! JSONDecoder().decode(
      Request.self, from: message.data(using: .utf8)!)

    if let method = methods[request.method] {
      method(request.params)
    }

    from.send(
      message: String(
        data: try! JSONEncoder().encode(
          Response(id: request.id, result: "success")), encoding: .utf8)!)

  }
}

extension WSService: TreadmillManagerDelegate {
  func treadmillManager(
    _ treadmillManager: TreadmillManager, didUpdateStats stats: TreadmillStats
  ) {
    print("Received stats", stats)

  }
}

func StartServer(_ with: WSService) {
  WebSocket.register(service: with, onPath: "wb")

  // Add HTTP Server to listen on port 8080
  let server = HTTP.createServer()

  if #available(macOS 10.15, *) {
    Task {
      do {
        print("Starting server on port 8080")
        try server.listen(on: 8080)
        ListenerGroup.waitForListeners()
      } catch {
        print("Error listening on port 8080: \(error).")
      }
    }
  } else {
    // Fallback on earlier versions
    print("Not available")
  }
}

let methods =
  [
    "run": { (params: AnyCodable?) -> Void in
      print("STARTING BELT")
      treadmillManager.sendCommand([247, 162, 4, 1, 0xff, 253])
    },
    "stop": { (params: AnyCodable?) -> Void in
      print("STOPPING BELT")
      treadmillManager.sendCommand([247, 162, 1, 0, 0xff, 253])
    },
    "manual_mode": { (params: AnyCodable?) -> Void in
      print("SET MODE MANUAL")
      treadmillManager.sendCommand([247, 162, 2, 1, 0xff, 253])
    },
    "standby_mode": { (params: AnyCodable?) -> Void in
      print("SET MODE STANDBY")
      treadmillManager.sendCommand([247, 162, 2, 2, 0xff, 253])
    },
    "get_stats": { (params: AnyCodable?) -> Void in
      print("REQUESTING STATS")
      treadmillManager.sendCommand([247, 162, 0, 0, 162, 253])
    },
    "set_speed": setSpeed,
  ]

struct SetSpeedParams: Codable {
  let speed: Double
}

func setSpeed(params: AnyCodable?) {
  let params = try! JSONDecoder().decode(
    SetSpeedParams.self, from: try! JSONEncoder().encode(params))

  print("SETTING SPEED", params)

  treadmillManager.sendCommand([247, 162, 1, UInt8(params.speed), 0xff, 253])
}
