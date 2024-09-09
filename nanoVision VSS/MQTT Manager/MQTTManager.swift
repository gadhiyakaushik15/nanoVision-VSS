//
//  MQTTManager.swift
//  SwiftUI_MQTT
//
//  Created by Anoop M on 2021-01-19.
//

import Foundation
import UIKit
import CocoaMQTT
import Combine

final class MQTTManager: ObservableObject {
    
    private var mqttClient: CocoaMQTT5?
    private let currentAppState = MQTTAppState.shared()
    private var accessControllerName: String?
    private var relay: Int?
    private var subscriberTopic: String?
    private var publisherTopic: String?
    
    // MARK: Shared Instance
    private static let _shared = MQTTManager()

    // MARK: - Accessors
    class func shared() -> MQTTManager {
        return _shared
    }
    
    func initializeMQTT() {
        // If any previous instance exists then clean it
        if mqttClient != nil {
            mqttClient = nil
        }
        let clientID = "MQTT-\(MQTT.Identifier)-" + Date().timestamp
        mqttClient = CocoaMQTT5(clientID: clientID, host: MQTT.Host, port: MQTT.Port)
        
        let connectProperties = MqttConnectProperties()
        connectProperties.topicAliasMaximum = 0
        connectProperties.sessionExpiryInterval = 0
        connectProperties.receiveMaximum = 100
        connectProperties.maximumPacketSize = 500
        mqttClient!.connectProperties = connectProperties
        
//        let lastWillMessage = CocoaMQTT5Message(topic: "/will", string: "dieout")
//        lastWillMessage.contentType = "JSON"
//        lastWillMessage.willExpiryInterval = .max
//        lastWillMessage.willDelayInterval = 0
//        lastWillMessage.qos = .qos1
//        mqttClient!.willMessage = lastWillMessage
//        
        mqttClient?.username = MQTT.Username
        mqttClient?.password = MQTT.Password
        mqttClient!.logLevel = .error
        mqttClient!.keepAlive = 60
        mqttClient!.enableSSL = true
        mqttClient!.allowUntrustCACertificate = true
        mqttClient!.sslSettings = [kCFStreamSSLPeerName as String: MQTT.Host as NSObject]
        mqttClient?.autoReconnect = true
        mqttClient!.delegate = self
        
        self.connect()
        
//        let clientCertArray = getClientCertFromP12File(certName: "client-keycert", certPassword: "MySecretPassword")
//
//        var sslSettings: [String: NSObject] = [:]
//        sslSettings[kCFStreamSSLCertificates as String] = clientCertArray
//
//        mqttClient!.sslSettings = sslSettings
    }

    
//    func getClientCertFromP12File(certName: String, certPassword: String) -> CFArray? {
//        // get p12 file path
//        let resourcePath = Bundle.main.path(forResource: certName, ofType: "p12")
//        
//        guard let filePath = resourcePath, let p12Data = NSData(contentsOfFile: filePath) else {
//            print("Failed to open the certificate file: \(certName).p12")
//            return nil
//        }
//        
//        // create key dictionary for reading p12 file
//        let key = kSecImportExportPassphrase as String
//        let options : NSDictionary = [key: certPassword]
//        
//        var items : CFArray?
//        let securityError = SecPKCS12Import(p12Data, options, &items)
//        
//        guard securityError == errSecSuccess else {
//            if securityError == errSecAuthFailed {
//                print("ERROR: SecPKCS12Import returned errSecAuthFailed. Incorrect password?")
//            } else {
//                print("Failed to open the certificate file: \(certName).p12")
//            }
//            return nil
//        }
//        
//        guard let theArray = items, CFArrayGetCount(theArray) > 0 else {
//            return nil
//        }
//        
//        let dictionary = (theArray as NSArray).object(at: 0)
//        guard let identity = (dictionary as AnyObject).value(forKey: kSecImportItemIdentity as String) else {
//            return nil
//        }
//        let certArray = [identity] as CFArray
//        
//        return certArray
//    }
    
    // Connect to server
    func connect() {
        if let success = mqttClient?.connect(), success {
            currentAppState.setAppConnectionState(state: .connecting)
        } else {
            currentAppState.setAppConnectionState(state: .disconnected)
        }
    }
    
    // Disconnect to server
    func disconnect() {
        mqttClient?.disconnect()
    }

    // subscribe to a topic
    func subscribe(topic: String, accessControllerName: String, relay: Int) {
        self.subscriberTopic = topic
        self.accessControllerName = accessControllerName
        self.relay = relay
        mqttClient?.subscribe(String(format: topic, accessControllerName, relay), qos: .qos1)
    }
    
    // publish to a topic
    func publish(topic: String, message: String) {
        self.publisherTopic = topic
        if let accessControllerName = self.accessControllerName, let relay = self.relay {
            let publishProperties = MqttPublishProperties()
            publishProperties.contentType = "JSON"
            mqttClient?.publish(String(format: topic, accessControllerName, relay), withString: message, qos: .qos1, properties: publishProperties)
        }
    }

    // Unsubscribe from a topic
    func unSubscribe() {
        if let topic = self.subscriberTopic, let accessControllerName = self.accessControllerName, let relay = self.relay {
            mqttClient?.unsubscribe(String(format: topic, accessControllerName, relay))
        }
    }
    
    func checkRelayChange() {
        if let relay = Utilities.shared.getAssignedRelay(), let accessControllerName = Utilities.shared.getAccessControllerName(), ((relay != self.relay || accessControllerName != self.accessControllerName) && self.currentAppState.appConnectionState.isConnected) {
            self.unSubscribe()
            self.subscribe(topic: MQTT.SubscriberTopic, accessControllerName: accessControllerName, relay: relay)
        }
    }
}

extension MQTTManager: CocoaMQTT5Delegate {
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveDisconnectReasonCode reasonCode: CocoaMQTTDISCONNECTReasonCode) {
        debugPrint("disconnect res : \(reasonCode)")
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveAuthReasonCode reasonCode: CocoaMQTTAUTHReasonCode) {
        debugPrint("auth res : \(reasonCode)")
    }
    
    // Optional ssl CocoaMQTT5Delegate
    func mqtt5(_ mqtt5: CocoaMQTT5, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        TRACE("trust: \(trust)")
        completionHandler(true)
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didConnectAck ack: CocoaMQTTCONNACKReasonCode, connAckData: MqttDecodeConnAck?) {
        TRACE("ack: \(ack)")
        if ack == .success {
            currentAppState.setAppConnectionState(state: .connected)
        }
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didStateChangeTo state: CocoaMQTTConnState) {
        TRACE("new state: \(state)")
        if state == .connected {
            currentAppState.setAppConnectionState(state: .connected)
            if let accessControllerName = Utilities.shared.getAccessControllerName(), let relay = Utilities.shared.getAssignedRelay() {
                self.subscribe(topic: MQTT.SubscriberTopic, accessControllerName: accessControllerName, relay: relay)
            }
        } else if state == .disconnected {
            currentAppState.setAppConnectionState(state: .disconnected)
        } else if state == .connecting {
            currentAppState.setAppConnectionState(state: .connecting)
        }
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishMessage message: CocoaMQTT5Message, id: UInt16) {
        TRACE("message: \(message.description), id: \(id)")
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishAck id: UInt16, pubAckData: MqttDecodePubAck?) {
        TRACE("id: \(id)")
        if(pubAckData != nil){
            debugPrint("pubAckData reasonCode: \(String(describing: pubAckData!.reasonCode))")
        }
    }

    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishRec id: UInt16, pubRecData: MqttDecodePubRec?) {
        TRACE("id: \(id)")
        if(pubRecData != nil){
            debugPrint("pubRecData reasonCode: \(String(describing: pubRecData!.reasonCode))")
        }
    }

    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishComplete id: UInt16,  pubCompData: MqttDecodePubComp?){
        TRACE("id: \(id)")
        if(pubCompData != nil){
            debugPrint("pubCompData reasonCode: \(String(describing: pubCompData!.reasonCode))")
        }
    }

    func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveMessage message: CocoaMQTT5Message, id: UInt16, publishData: MqttDecodePublish?){
        if(publishData != nil){
            debugPrint("publish.contentType \(String(describing: publishData!.contentType))")
        }
        if let topic = self.publisherTopic, message.string.description.lowercased() == MQTT.OnCommand.lowercased() {
            var delay = Constants.NextScanDelayDefault
            if !UserDefaultsServices.shared.isTapScanSuccess() {
                delay = UserDefaultsServices.shared.getNextScanDelay()
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(Int(delay))) {
                self.publish(topic: topic, message: MQTT.OffCommand)
            }
        }
        TRACE("topic \(message.topic), message: \(message.string.description), id: \(id)")
    }
    
    func mqtt5(_ mqtt5: CocoaMQTT5, didSubscribeTopics success: NSDictionary, failed: [String], subAckData: MqttDecodeSubAck?) {
        TRACE("subscribed: \(success), failed: \(failed)")
        if(subAckData != nil){
            debugPrint("subAckData.reasonCodes \(String(describing: subAckData!.reasonCodes))")
            currentAppState.setAppConnectionState(state: .connectedSubscribed)
        }
    }
        
    func mqtt5(_ mqtt5: CocoaMQTT5, didUnsubscribeTopics topics: [String], unsubAckData: MqttDecodeUnsubAck?) {
        TRACE("topic: \(topics)")
        if(unsubAckData != nil){
            debugPrint("unsubAckData.reasonCodes \(String(describing: unsubAckData!.reasonCodes))")
            currentAppState.setAppConnectionState(state: .connectedUnSubscribed)
        }
    }
    
    func mqtt5DidPing(_ mqtt5: CocoaMQTT5) {
        TRACE()
    }
    
    func mqtt5DidReceivePong(_ mqtt5: CocoaMQTT5) {
        TRACE()
    }

    func mqtt5DidDisconnect(_ mqtt5: CocoaMQTT5, withError err: Error?) {
        TRACE("\(err.description)")
        currentAppState.setAppConnectionState(state: .disconnected)
    }
}

extension MQTTManager {
    func TRACE(_ message: String = "", fun: String = #function) {
        let names = fun.components(separatedBy: ":")
        var prettyName: String
        if names.count == 2 {
            prettyName = names[0]
        } else {
            prettyName = names[1]
        }
        
        if fun == "mqttDidDisconnect(_:withError:)" {
            prettyName = "didDisconnect"
        }

        debugPrint("[TRACE] [\(prettyName)]: \(message)")
    }
}

extension Optional {
    // Unwrap optional value for printing log only
    var description: String {
        if let self = self {
            return "\(self)"
        }
        return ""
    }
}
