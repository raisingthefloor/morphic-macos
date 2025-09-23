// Copyright 2021 Raising the Floor - US, Inc.
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/raisingthefloor/morphic-macos/blob/master/LICENSE.txt
//
// The R&D leading to these results received funding from the:
// * Rehabilitation Services Administration, US Dept. of Education under
//   grant H421A150006 (APCP)
// * National Institute on Disability, Independent Living, and
//   Rehabilitation Research (NIDILRR)
// * Administration for Independent Living & Dept. of Education under grants
//   H133E080022 (RERC-IT) and H133E130028/90RE5003-01-00 (UIITA-RERC)
// * European Union's Seventh Framework Programme (FP7/2007-2013) grant
//   agreement nos. 289016 (Cloud4all) and 610510 (Prosperity4All)
// * William and Flora Hewlett Foundation
// * Ontario Ministry of Research and Innovation
// * Canadian Foundation for Innovation
// * Adobe Foundation
// * Consumer Electronics Association Foundation

import Foundation
import MQTTNIO
import NIO
import MorphicCore

public class MorphicTelemetryClient {

    private var mqttClient: MQTTClient
    private var mqttClientConfig: TelemetryClientConfig

    private let clientId: String
    private let softwareVersion: String

    private var messagesToSend: [MqttEventMessage]
    private var messagesToSendQueue: DispatchQueue
    
    private enum SessionState
    {
        case stopped
        case starting
        case started
        case stopping
    }
    private var sessionState: SessionState = .stopped
    private var isConnected = false
    private var isPermanentlyClosed = false

    public var siteId: String? = nil

    public class TelemetryClientConfig
    {
        public var clientId: String
        public var username: String
        public var password: String
        
        public init(clientId: String, username: String, password: String) {
            self.clientId = clientId
            self.username = username
            self.password = password
        }
    }
    //
    public class TcpTelemetryClientConfig: TelemetryClientConfig
    {
        public var hostname: String // = "localhost"
        public var port: UInt16? // = nil
        public var useTls: Bool // = false
        
        public init(clientId: String, username: String, password: String, hostname: String, port: UInt16?, useTls: Bool) {
            self.hostname = hostname
            self.port = port
            self.useTls = useTls
            
            super.init(clientId: clientId, username: username, password: password)
        }
    }
    //
    public class WebsocketTelemetryClientConfig: TelemetryClientConfig
    {
        public var hostname: String // = "localhost"
        public var port: UInt16? // = nil
        public var path: String? // = nil
        public var useTls: Bool // = false
        
        public init(clientId: String, username: String, password: String, hostname: String, port: UInt16?, path: String?, useTls: Bool) {
            self.hostname = hostname
            self.port = port
            self.path = path
            self.useTls = useTls
            
            super.init(clientId: clientId, username: username, password: password)
        }
    }

    public init(config: TelemetryClientConfig, softwareVersion: String) {
        self.mqttClientConfig = config
        self.softwareVersion = softwareVersion
        
        self.messagesToSend = []
        self.messagesToSendQueue = DispatchQueue(label: "telemetry_message_queue")

        // initialize and capture our MQTT client and its configuration options

        var hostname: String
        var mqttPort: Int
        var mqttClientConfiguration: MQTTClient.Configuration

        // configure a keepAliveInterval of 45 seconds (since the default for this library is 90 seconds...and RabbitMQ times out after 60 seconds)
        let keepAliveInterval = TimeAmount.seconds(45)
        
        if let config = self.mqttClientConfig as? TcpTelemetryClientConfig {
            hostname = config.hostname
            
            if config.useTls == false {
                mqttPort = Int(config.port ?? 1883)
                mqttClientConfiguration = .init(keepAliveInterval: keepAliveInterval, userName: config.username, password: config.password)
            } else {
                mqttPort = Int(config.port ?? 8883)
                mqttClientConfiguration = .init(keepAliveInterval: keepAliveInterval, userName: config.username, password: config.password, useSSL: true)
            }
        } else if let config = self.mqttClientConfig as? WebsocketTelemetryClientConfig {
            hostname = config.hostname

            var webSocketURLPath: String

            if config.useTls == false {
                mqttPort = Int(config.port ?? 80)
                webSocketURLPath = "http://"
            } else {
                mqttPort = Int(config.port ?? 443)
                webSocketURLPath = "https://"
            }
                        
            webSocketURLPath += config.hostname
            webSocketURLPath += ":" + String(mqttPort)
            if var pathComponent = config.path {
                // sanity check: make sure the path component starts with "/" or "#"
                if let firstLetterOfPathComponent = pathComponent.first {
                    if firstLetterOfPathComponent != "/" && firstLetterOfPathComponent != "#" {
                        pathComponent = "/" + pathComponent
                    }
                }
                
                webSocketURLPath += pathComponent
            }
            
            mqttClientConfiguration = .init(keepAliveInterval: keepAliveInterval, userName: config.username, password: config.password, useSSL: config.useTls, useWebSockets: true, webSocketURLPath: webSocketURLPath)
        } else {
            fatalError("unknown config type")
        }
        
        let mqttClient = MQTTClient(
            host: hostname,
            port: mqttPort,
            identifier: self.mqttClientConfig.clientId,
            // TODO: should I use .createNew or shared() ???
            eventLoopGroupProvider: .createNew,
            configuration: mqttClientConfiguration
        )
        self.mqttClient = mqttClient
        
        self.clientId = self.mqttClientConfig.clientId

        // set up disconnect handler (to handle automatic reconnection)
        mqttClient.addCloseListener(named: "closed") { result in
            self.mqttClientDisconnected()
        }
    }
    
    public func startSession() {
        switch self.sessionState {
        case .started,
             .starting:
            // if our session is already started (or is starting), just return
            return
        case .stopping:
            // if our session is stopping, fail
            fatalError("Cannot re-start a session after the object has been disposed");
        case .stopped:
            // if our session is stopped, continue; if it's a permanent closure then we'll fail below
            break
        }

        if self.isPermanentlyClosed == true {
            fatalError("Cannot re-start a session after the object has been disposed");
        }
        
        self.sessionState = .starting
        
        // connect to the telemetry server asynchronously
        self.connect()

        self.sessionState = .started
    }

    public func endSession() {
        switch self.sessionState {
        case .started:
            // this is the proper state from which to call this function
            break
        case .starting:
            // wait until the connection is started
            DispatchQueue.main.async {
                Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { timer in
                    // if the state has moved on, re-call this function; otherwise just wait for the next timer callback
                    if self.sessionState != .starting {
                        timer.invalidate()
                        self.endSession()
                    }
                }
            }
        case .stopping,
             .stopped:
            // if our session is already stopping/stopped, just return
            return
        }

        self.sessionState = .stopping
        
        let mqttClient = self.mqttClient

        // attempt to shut down the mqttClient gracefully
        _ = try? mqttClient.syncShutdownGracefully()

        // mark our object as permanently closed
        self.isPermanentlyClosed = true
        
        // TODO: manually set "isConnected" to false just in case our handler didn't get called in the event of failure...and to prevent any timing issues in regards to "messagesToSendEvent.Set()" getting called before the event handler
        self.isConnected = false
        
        mqttClient.removeCloseListener(named: "disconnected")
        
        _ = mqttClient.disconnect()
        self.sessionState = .stopped
    }
    
    private func mqttClientConnected() {
        if self.isPermanentlyClosed == true {
            return
        }
        
        self.isConnected = true
        
        // start the action message queue (in case there are messages already queued to be sent)
        self.dequeueAndSendActionMessages()
    }

    // NOTE: this callback handles both disconnections (post-successful-connection) and connection attempt failures
    private func mqttClientDisconnected() {
        self.isConnected = false

        if self.isPermanentlyClosed == true {
            // if our object instance's connection is permanently closed, do not attempt to reconnect
            return
        }

        // could not connect; call our disconnected callback to try again (after a waiting period)
        self.connect(afterInterval: TimeInterval(30.0))
    }
    
    private func connect(afterInterval waitTime: TimeInterval = 0.0) {
        if self.isPermanentlyClosed == true {
            // if our object instance's connection is permanently closed, do nothing
            return
        }
        
        if waitTime > 0 {
            // re-call our function every 250ms (or so) until the full wait time has elapsed
            // NOTE: ideally we would measure the elapsed time against "ms since boot" as the Timer fires _at or after_ the specified time
            DispatchQueue.main.async {
                Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { timer in
                    let callAgainAfterInterval = waitTime - 0.25
                    self.connect(afterInterval: callAgainAfterInterval)
                }
            }
            return
        }
        
        // connect after the specified wait interval
        let _ = mqttClient.connect(cleanSession: true, will: nil).always({ result in
            switch result {
            case .success(_):
                // connected
                self.mqttClientConnected()
                // TODO: we might want to consider letting our caller know that we are connected
            case .failure:
                // could not connect; call our disconnected callback to try again (after a waiting period)
                self.connect(afterInterval: TimeInterval(30.0))
                // TODO: we might want to consider letting our caller know that we are in a "connecting" or "failure" state
            }
        })
    }
    
    private struct MqttEventMessage: Codable {
        var id: UUID
        var recordType: String
        var recordVersion: Int
        var sentAt: Date
        var siteId: String?
        var deviceId: String
        var softwareVersion: String
        var osName: String
        var osVersion: String
        var eventName: String
        var data: TelemetryEventData?
        
        enum CodingKeys: String, CodingKey {
            case id
            case recordType = "record_type"
            case recordVersion = "record_version"
            case sentAt = "sent_at"
            case siteId = "site_id"
            case deviceId = "device_id"
            case softwareVersion = "software_version"
            case osName = "os_name"
            case osVersion = "os_version"
            case eventName = "event_name"
            case data = "data"
        }
    }
    
    public struct SessionTelemetryEventData: Codable {
        public var state: String
        public var sessionId: String
        
        public init(state: String, sessionId: String) {
            self.state = state
            self.sessionId = sessionId
        }
        
        enum CodingKeys: String, CodingKey {
            case state
            case sessionId = "session_id"
        }
    }
    
    public enum TelemetryEventData: Codable {
        case session(SessionTelemetryEventData)
        
        // MARK: - Decodable
        
        // NOTE: ideally, we would decode the telemetry event data based on the event name rather than trying to determine its type through deserialization; in Morphic telemetry v2 we should do this decoding based on the parent's event_name property instead
        public init(from decoder: Decoder) throws {
            // SessionTelemetryEventData
            if let value = try? decoder.singleValueContainer().decode(SessionTelemetryEventData.self) {
                self = .session(value)
                return
            }
            
            throw DecodingError.unknownType
        }
        
        enum DecodingError : Error {
            case unknownType
        }

        // MARK: - Encodable
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            
            switch self {
            case .session(let data):
                try container.encode(data)
            }
        }
    }
    
    public func enqueueActionMessage(eventName: String) {
        self.enqueueActionMessage(eventName: eventName, data: nil)
    }
    
    public func enqueueActionMessage(eventName: String, data: TelemetryEventData?) {
        // NOTE: we capture the timestamp up front just to alleviate any potential for the timestamp to be captured late
        let capturedAtTimestamp = Date()

        let operatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
        let osVersionAsString = String(operatingSystemVersion.majorVersion) + "." + String(operatingSystemVersion.minorVersion) + "." + String(operatingSystemVersion.patchVersion)
        
        let actionMessage = MqttEventMessage(
            id: UUID(),
            recordType: "event",
            recordVersion: 1,
            sentAt: capturedAtTimestamp,
            siteId: self.siteId,
            deviceId: self.clientId,
            softwareVersion: self.softwareVersion,
            osName: "macOS",
            osVersion: osVersionAsString,
            eventName: eventName,
            data: data
        )

        // add the actionMessage to our outgoing message queue; do this via the same DispatchQueue which dequeues messages from the queue
        messagesToSendQueue.async {
            self.messagesToSend.append(actionMessage)
        }

        // dequeue and send the action message (via the dispatch queue)
        self.dequeueAndSendActionMessages()
    }
    
    public func dequeueAndSendActionMessages() {
        messagesToSendQueue.async {
            if self.isPermanentlyClosed == true {
                return
            }
            if self.isConnected == false {
                return
            }
            
            while true {
                // dequeue a message; note that we do this in a dispatch queue so that another message isn't added at the same time
                if self.messagesToSend.count == 0 {
                    // if there are no messages to send, exit now
                    return
                }
                let actionMessage = self.messagesToSend.removeFirst()
                
                let jsonEncoder = JSONEncoder()
                jsonEncoder.dateEncodingStrategy = .iso8601
                
                let jsonAsData = try! jsonEncoder.encode(actionMessage)
                let jsonAsString = String(data: jsonAsData, encoding: .utf8)!
                let payload = ByteBufferAllocator().buffer(string: jsonAsString)
                
                do {
                    _ = try self.mqttClient.publish(
                        to: "telemetry",
                        payload: payload,
                        qos: .atLeastOnce
                    ).wait()
                } catch {
                    // if the message could not be send, re-queue it and exit for now; we'll retry the send at the next connection or with the next telemetry message
                    self.messagesToSend.insert(actionMessage, at: 0)
                    return
                }
            }
        }
    }

}
