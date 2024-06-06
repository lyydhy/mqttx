//
//  MqttClient.swift
//  mqttx
//
//  Created by ios on 2024/6/4.
//

import Foundation
import CocoaMQTT
import Flutter

class MqttClient {
    // 单例
    static let instance = MqttClient()
    // mqtt实例
    private var mqttClient: CocoaMQTT5? = nil
    // 事件通道。用于异步向flutter 发送消息
    private var eventSink: FlutterEventSink? = nil
    // 保存一下qos 主要是订阅失败的时候用
    private var _qos: [Int] = []
    // 当前连接状态
    private var connectState: CocoaMQTTConnState = CocoaMQTTConnState.disconnected
    // 当前是否是重连
    private var isReconnect: Bool = false
    // 是否是主动断开连接
    private var isInitiativeDisconnect: Bool = false
    private var connectData: [String: Any?] = [:]
    /**
      连接mqtt服务
     */
    func connect(call: FlutterMethodCall, eventSink: FlutterEventSink?) {
        if (self.eventSink == nil) {
            self.eventSink = eventSink
        }
        if (mqttClient != nil) {
            return;
        }
        let args = call.arguments as!  [String: Any]
        let server =  args["server"] as? String
        let port = args["port"] as? UInt16
        let clientId = args["clientId"] as? String
        if (server == nil || port == nil || clientId == nil) {
            self.createResult( type: "connect", isSuccess: false, message: "参数错误", data: nil)
            return
        }
        let keepAlive = args["keepAlive"] as? UInt16
        let connectionTimeout = args["connectionTimeout"] as? UInt16
        let autoReconnect = args["autoReconnect"] as? Bool
        connectData = [
            "server": server,
            "port": port,
            "clientId": clientId,
            "keepAlive": keepAlive,
            "autoReconnect": autoReconnect,
            "connectionTimeout": connectionTimeout
        ]
        mqttClient = CocoaMQTT5(clientID: clientId!, host: server!, port: port!)
        mqttClient!.keepAlive = keepAlive!
        mqttClient!.autoReconnect = autoReconnect == true
        mqttClient!.delegate = self
        let isConnect =  mqttClient!.connect()
        print(isConnect)
    }
    
    /**
      获取当前连接状态
     */
    func getStatus(result: FlutterResult) {
        if (self.mqttClient == nil) {
            result(false)
        } else {
            result(self.connectState == CocoaMQTTConnState.connected)
        }
    }
    
    /**
     订阅主题
     */
    func subscribe(call: FlutterMethodCall, eventSink: FlutterEventSink?) {
        if (self.eventSink == nil) {
            self.eventSink = eventSink
        }
        if (self.mqttClient == nil) {
            self.createResult(type: "subscribe", isSuccess: false, message: "mqtt未初始化", data: "")
            return
        }
        let args = call.arguments as!  [String: Any]
        let topics = args["topic"] as?  [String]
        let qos = args["qos"] as? [Int]
        if (topics == nil || qos == nil) {
            self.createResult(type: "subscribe", isSuccess: false, message: "参数错误", data: "")
            return
        }
        self._qos = qos!
        for i in 0..<topics!.count {
            let q = qos![i]
            mqttClient?.subscribe(topics![i], qos: self.intToCocoaMQTTQoS(qos:q))
        }
    }
    
    /**
     取消订阅
     */
    func unSubscribe(call: FlutterMethodCall, eventSink: FlutterEventSink?) {
        if (self.eventSink == nil) {
            self.eventSink = eventSink
        }
        if (self.mqttClient == nil) {
            self.createResult(type: "subscribe", isSuccess: false, message: "mqtt未初始化", data: "")
            return
        }
        let args = call.arguments as!  [String: Any]
        let topics = args["topic"] as?  [String]
        if (topics == nil) {
            self.createResult(type: "unSubscribe", isSuccess: false, message: "参数错误", data: "")
            return
        }
        for topic in topics! {
            mqttClient?.unsubscribe(topic)
        }
  
    }
    
    /**
     重连
     */
    func reconnect(call: FlutterMethodCall, eventSink: FlutterEventSink?) {
        if (self.eventSink == nil) {
            self.eventSink = eventSink
        }
        let args = call.arguments as!  [String: Any]
        let clientId = args["clientId"] as? String
        if (clientId != nil && self.connectState == CocoaMQTTConnState.disconnected) {
            self.mqttClient?.disconnect()
            self.mqttClient = nil
            self.isReconnect = true
            // 当重新传递clientId的时候 断开之前的重新初始化连接
            self.connectState = CocoaMQTTConnState.disconnected
   
            connectData["clientId"] = clientId;
            
            mqttClient = CocoaMQTT5(clientID: clientId!, host: connectData["server"] as! String, port: connectData["port"] as! UInt16)
            mqttClient!.keepAlive = connectData["keepAlive"] as! UInt16
            mqttClient!.autoReconnect = connectData["autoReconnect"] as! Bool == true
            mqttClient!.delegate = self
            let isConnect =  mqttClient!.connect()
            print(isConnect)
            return
        }
        if (self.mqttClient == nil) {
            self.createResult(type: "subscribe", isSuccess: false, message: "mqtt未初始化", data: "")
            return
        }
        if (self.connectState == CocoaMQTTConnState.disconnected) {
            self.isReconnect = true
            let r = mqttClient?.connect()
        }
        
    }
        
    /**
     断开连接
     */
    func disconnect( eventSink: FlutterEventSink?) {
        if (self.eventSink == nil) {
            self.eventSink = eventSink
        }
        if (self.mqttClient == nil) {
            self.createResult(type: "disconnect", isSuccess: false, message: "mqtt未初始化", data: "")
            return
        }
        mqttClient?.disconnect()
        self.isInitiativeDisconnect = true
//        mqttClient = nil
    }
    
    /**
     发送消息
     */
    func publish(call: FlutterMethodCall, eventSink: FlutterEventSink?) {
        if (self.eventSink == nil) {
            self.eventSink = eventSink
        }
        if (self.mqttClient == nil) {
            self.createResult(type: "publish", isSuccess: false, message: "mqtt未初始化", data: "")
            return
        }
        let args = call.arguments as!  [String: Any]
        let topic =  args["topic"] as? String
        let message = args["message"] as? String
        let qos = args["qos"] as? Int
        let msg = CocoaMQTT5Message(topic: topic!, string: message!, qos: intToCocoaMQTTQoS(qos: qos!), retained: false)
        self.mqttClient?.publish(msg, properties: MqttPublishProperties())
    }

    /**
     获取CocoaMQTTQoS
     */
    private func intToCocoaMQTTQoS(qos: Int) -> CocoaMQTTQoS {
        switch qos {
        case 0:
            return CocoaMQTTQoS.qos0
        case 1:
            return CocoaMQTTQoS.qos1
        case 2:
            return CocoaMQTTQoS.qos2
        default:
            return CocoaMQTTQoS.FAILURE
        }
    }
    
    /**
     包装结果
     */
    private func createResult(type: String, isSuccess: Bool,message:String?, data: Any?) {
        let result: [String: Any?] = ["type": type, "code": isSuccess ? "success": "fail", "message": message, "data": data]
        self.eventSink?(result)
    }
}


extension MqttClient: CocoaMQTT5Delegate {
    func mqtt5(_ mqtt5: CocoaMQTT5, didConnectAck ack: CocoaMQTTCONNACKReasonCode, connAckData: MqttDecodeConnAck?) {
        if (ack == CocoaMQTTCONNACKReasonCode.success) {
            
            self.createResult(type: self.isReconnect ? "reconnect" : "connect", isSuccess: true, message: nil, data: nil)
        } else {
            self.createResult(type: self.isReconnect ? "reconnect" : "connect", isSuccess: false, message: self.isReconnect ? "重连失败" : "连接失败", data: nil)
        }
        self.isReconnect = false
    }
    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishMessage message: CocoaMQTT5Message, id: UInt16) {
        print("")
    }
    func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveMessage message: CocoaMQTT5Message, id: UInt16, publishData: MqttDecodePublish?) {
        let messageString = String(bytes: message.payload, encoding: .utf8)
        let data: [String: Any?] = ["message": messageString, "topic": message.topic]
        self.createResult(type: "message", isSuccess: true, message: "", data: data)
    }
    func mqtt5(_ mqtt5: CocoaMQTT5, didSubscribeTopics success: NSDictionary, failed: [String], subAckData: MqttDecodeSubAck?) {
        for(topic,qos) in success {
            // 订阅成功
            let data: [String: Any] = ["topic":topic, "qos": qos]
            self.createResult(type: "subscribe", isSuccess: true, message: "", data: data)
        }
        if (!failed.isEmpty) {
            //  订阅失败
            for i in  0..<failed.count {
                let data: [String: Any] = ["topic":failed[i], "qos": self._qos[i]]
                self.createResult(type: "subscribe", isSuccess: false, message: "", data: data)
            }
        }
    }
    func mqtt5(_ mqtt5: CocoaMQTT5, didStateChangeTo state: CocoaMQTTConnState) {
        if (state == CocoaMQTTConnState.connected) {
            self.connectState = CocoaMQTTConnState.connected
        }
        if (state == CocoaMQTTConnState.disconnected) {
            self.connectState = CocoaMQTTConnState.disconnected
        }
    }
    func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveAuthReasonCode reasonCode: CocoaMQTTAUTHReasonCode) {
        print("")
    }
    func mqtt5(_ mqtt5: CocoaMQTT5, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        print("")
    }
    func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveDisconnectReasonCode reasonCode: CocoaMQTTDISCONNECTReasonCode) {
        print("")
    }
    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishAck id: UInt16, pubAckData: MqttDecodePubAck?) {
        print("")
    }
    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishRec id: UInt16, pubRecData: MqttDecodePubRec?) {
        print("")
    }
    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishComplete id: UInt16, pubCompData: MqttDecodePubComp?) {
        print("")
    }
    func mqtt5(_ mqtt5: CocoaMQTT5, didUnsubscribeTopics topics: [String], unsubAckData: MqttDecodeUnsubAck?) {
        // 取消订阅
        if (!topics.isEmpty) {
            for i in  0..<topics.count {
                self.createResult(type: "unSubscribe", isSuccess: true, message: "", data: topics[i])
            }
        }
    }
    func mqtt5UrlSession(_ mqtt: CocoaMQTT5, didReceiveTrust trust: SecTrust, didReceiveChallenge challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("")
    }
    func mqtt5DidPing(_ mqtt5: CocoaMQTT5) {
        print("")
    }
    func mqtt5DidReceivePong(_ mqtt5: CocoaMQTT5) {
        print("")
    }
    func mqtt5DidDisconnect(_ mqtt5: CocoaMQTT5, withError err: Error?) {
        self.connectState = CocoaMQTTConnState.disconnected
        self.isReconnect = false
        self.createResult(type: "disconnect", isSuccess: true, message: "连接断开", data: nil)
        if (self.isInitiativeDisconnect) {
            self.mqttClient = nil
        }
        self.isInitiativeDisconnect = false
    }
}
